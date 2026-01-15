require("init")

-- Configuration table for each inserter variant
-- Each variant has a parent arm (0°) plus N additional arms at specified offsets
-- Only 45° increments are supported: 45, 90, 135, 180, 225, 270, 315
local inserter_configs = {
    double_ = { offsets = {180} },                              -- 2 arms: 0°, 180°
    triple_ = { offsets = {180, 270} },                         -- 3 arms: 0°, 180°, 270°
    quad_   = { offsets = {90, 180, 270} },                     -- 4 arms: 0°, 90°, 180°, 270°
    quin_   = { offsets = {45, 90, 180, 270} },                 -- 5 arms: 0°, 45°, 90°, 180°, 270°
    sex_    = { offsets = {45, 90, 135, 180, 270} },            -- 6 arms: 0°, 45°, 90°, 135°, 180°, 270°
    sep_    = { offsets = {45, 90, 135, 180, 225, 270} },       -- 7 arms: 0°, 45°, 90°, 135°, 180°, 225°, 270° (skip 315)
    oct_    = { offsets = {45, 90, 135, 180, 225, 270, 315} },  -- 8 arms: 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
}

-- Helper to determine configuration based on entity name
local function get_inserter_config(name)
    -- Check longest prefixes first to avoid false matches
    for _, prefix in ipairs({"triple_", "double_", "quin_", "quad_", "sex_", "sep_", "oct_"}) do
        if string.find(name, prefix, 1, true) then
            local config = inserter_configs[prefix]
            return { prefix = prefix, offsets = config.offsets }
        end
    end
    return nil
end

-- Explicit rotation map using defines.direction
local rotation_map = {
    [defines.direction.north] = {
        [45]  = defines.direction.northeast,
        [90]  = defines.direction.east,
        [135] = defines.direction.southeast,
        [180] = defines.direction.south,
        [225] = defines.direction.southwest,
        [270] = defines.direction.west,
        [315] = defines.direction.northwest
    },
    [defines.direction.east] = {
        [45]  = defines.direction.southeast,
        [90]  = defines.direction.south,
        [135] = defines.direction.southwest,
        [180] = defines.direction.west,
        [225] = defines.direction.northwest,
        [270] = defines.direction.north,
        [315] = defines.direction.northeast
    },
    [defines.direction.south] = {
        [45]  = defines.direction.southwest,
        [90]  = defines.direction.west,
        [135] = defines.direction.northwest,
        [180] = defines.direction.north,
        [225] = defines.direction.northeast,
        [270] = defines.direction.east,
        [315] = defines.direction.southeast
    },
    [defines.direction.west] = {
        [45]  = defines.direction.northwest,
        [90]  = defines.direction.north,
        [135] = defines.direction.northeast,
        [180] = defines.direction.east,
        [225] = defines.direction.southeast,
        [270] = defines.direction.south,
        [315] = defines.direction.southwest
    }
}

local function on_double_inserter_built(event)
    local entity = event.entity or event.created_entity
    if not entity or not entity.valid then return end

    local config = get_inserter_config(entity.name)
    if not config then return end

    if storage.BiDirInserter[entity.unit_number] then
        log("Duplicate Inserter exists")
        return
    end

    local surface = entity.surface
    local position = entity.position
    local direction = entity.direction
    local force = entity.force

    -- Extract base name: prefix_name -> prefix_arm_name
    local base_name = string.sub(entity.name, string.len(config.prefix) + 1)
    local arm_name = config.prefix .. "arm_" .. base_name

    local arms = {}

    for i, offset in ipairs(config.offsets) do
        local final_arm_name, arm_dir

        -- Check if offset is diagonal (45, 135, 225, 315)
        -- Inserters only support 4 cardinal directions, so diagonals need special entities
        if offset % 90 ~= 0 then
            -- Use the diagonal 'ne_arm_' variant which has diagonal pickup/insert vectors
            final_arm_name = "ne_arm_" .. base_name
            -- Map diagonal offsets to cardinal rotations for the ne_arm entity
            -- ne_arm points NE (45°), so we rotate it in 90° steps:
            -- 45° -> 0 (north), 135° -> 4 (east), 225° -> 8 (south), 315° -> 12 (west)
            local diagonal_map = {
                [45] = 0,    -- NE diagonal, point north
                [135] = 4,   -- SE diagonal, point east
                [225] = 8,   -- SW diagonal, point south
                [315] = 12,  -- NW diagonal, point west
            }
            local base_dir = diagonal_map[offset]
            if base_dir then
                arm_dir = (direction + base_dir) % 16
            end
        else
            -- Use standard cardinal arm with rotation map
            final_arm_name = arm_name
            arm_dir = rotation_map[direction] and rotation_map[direction][offset]
        end

        if arm_dir then
            local success, result = pcall(function()
                return surface.create_entity({
                    name = final_arm_name,
                    position = position,
                    direction = arm_dir,
                    force = force,
                    create_build_effect_smoke = false,
                })
            end)

            if success and result then
                result.operable = true
                result.minable = true
                result.destructible = false
                table.insert(arms, result)
            end
        end
    end

    local data = {
        parent = entity,
        arms = arms
    }

    -- Store reference for parent
    storage.BiDirInserter[entity.unit_number] = data

    -- Store reference for all children
    for _, arm in pairs(arms) do
        storage.BiDirInserter[arm.unit_number] = data
    end
end

local function on_double_inserter_mined(event, create_ghosts)
    local entity = event.entity
    if not entity or not entity.valid then return end

    local data = storage.BiDirInserter[entity.unit_number]
    if not data then return end

    -- Handle Parent
    -- Support legacy data structure (parent_inserter) and new (parent)
    local parent = data.parent or data.parent_inserter
    if parent and parent.valid and parent ~= entity then
        if create_ghosts then
            parent.destructible = true
            parent.die()
        else
            parent.destroy()
        end
    end

    -- Handle Children
    -- Support legacy data structure (child_arm) and new (arms table)
    local arms = data.arms or (data.child_arm and {data.child_arm}) or {}
    
    for _, arm in pairs(arms) do
        if arm and arm.valid and arm ~= entity then
            if create_ghosts then
                arm.destructible = true
                arm.die()
            else
                arm.destroy()
            end
        end
    end
    
    -- Cleanup storage is handled by Lua garbage collection eventually if we nil the keys,
    -- but since we have multiple keys pointing to the same table, we rely on the fact that
    -- the entity unit_number won't be reused immediately.
    storage.BiDirInserter[entity.unit_number] = nil
end

local function on_double_inserter_rotated(event)
    local entity = event.entity
    local data = storage.BiDirInserter[entity.unit_number]
    if not data then return end

    -- Determine rotation offset using the map
    local rotation_offset = nil
    local map_for_prev = rotation_map[event.previous_direction]
    if map_for_prev then
        for offset, dir in pairs(map_for_prev) do
            if dir == entity.direction then
                rotation_offset = offset
                break
            end
        end
    end

    if not rotation_offset then return end

    -- Rotate Parent
    local parent = data.parent or data.parent_inserter
    if parent and parent.valid and parent ~= entity then
        local new_dir = rotation_map[parent.direction] and rotation_map[parent.direction][rotation_offset]
        if new_dir then parent.direction = new_dir end
    end

    -- Rotate Children
    local arms = data.arms or (data.child_arm and {data.child_arm}) or {}
    for _, arm in pairs(arms) do
        if arm and arm.valid and arm ~= entity then
            local new_dir = rotation_map[arm.direction] and rotation_map[arm.direction][rotation_offset]
            if new_dir then arm.direction = new_dir end
        end
    end
end

local filters_on_built = {{ filter="type", type="inserter" }}
local filters_on_mined = {{ filter="type", type="inserter" }}
local filters_on_pipette = {{ filter="type", type="inserter" }}

script.on_event(defines.events.on_built_entity, on_double_inserter_built, filters_on_built)
script.on_event(defines.events.on_robot_built_entity, on_double_inserter_built, filters_on_built )
script.on_event({defines.events.script_raised_built, defines.events.script_raised_revive, defines.events.on_entity_cloned}, on_double_inserter_built)

script.on_event(defines.events.on_pre_player_mined_item, on_double_inserter_mined, filters_on_mined )
script.on_event(defines.events.on_robot_pre_mined, on_double_inserter_mined, filters_on_mined )
script.on_event(defines.events.on_entity_died, function(event) on_double_inserter_mined(event, true) end, filters_on_mined )
script.on_event(defines.events.script_raised_destroy, on_double_inserter_mined)

script.on_event(defines.events.on_player_rotated_entity, on_double_inserter_rotated)