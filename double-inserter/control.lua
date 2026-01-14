require("init")

-- Helper to determine configuration based on entity name
local function get_inserter_config(name)
    if string.find(name, "quad_") then
        return { prefix = "quad_", offsets = {90, 180, 270} }
    elseif string.find(name, "triple_") then
        return { prefix = "triple_", offsets = {180, 270} }
    elseif string.find(name, "double_") then
        return { prefix = "double_", offsets = {180} }
    end
    return nil
end

-- Explicit rotation map using defines.direction
local rotation_map = {
    [defines.direction.north] = {
        [90]  = defines.direction.east,
        [180] = defines.direction.south,
        [270] = defines.direction.west
    },
    [defines.direction.east] = {
        [90]  = defines.direction.south,
        [180] = defines.direction.west,
        [270] = defines.direction.north
    },
    [defines.direction.south] = {
        [90]  = defines.direction.west,
        [180] = defines.direction.north,
        [270] = defines.direction.east
    },
    [defines.direction.west] = {
        [90]  = defines.direction.north,
        [180] = defines.direction.east,
        [270] = defines.direction.south
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

    for _, offset in ipairs(config.offsets) do
        local arm_dir = rotation_map[direction] and rotation_map[direction][offset]

        if arm_dir then
            local arm = surface.create_entity({
                name = arm_name,
                position = position,
                direction = arm_dir,
                force = force,
            })

            if arm then
                arm.operable = true
                arm.minable = true
                arm.destructible = false
                table.insert(arms, arm)
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