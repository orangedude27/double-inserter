require("init")

local function oposite_direction(direction)
    if direction == defines.direction.north then
        return defines.direction.south
    elseif direction == defines.direction.east then
        return defines.direction.west
    elseif direction == defines.direction.south then
        return defines.direction.north
    elseif direction == defines.direction.west then
        return defines.direction.east
    end
end

local function on_double_inserter_built(event)

    local entity = nil

    if event.entity and string.find(event.entity.name, "double_") then
        entity = event.entity
    elseif event.created_entity and string.find(event.created_entity.name, "double_") then
        entity = event.created_entity
    end

    if entity ~= nil then
        local surface = entity.surface
        local position = entity.position
        local direction = entity.direction

        if global.BiDirInserter[entity.unit_number] then
            log("Duplicate Inserter exists")
        else
            inserter_name = string.sub(entity.name, 8, -1)
            -- Create double_arm entity on top of double_inserter
            local double_arm_entity = surface.create_entity({
                name = "double_arm_" .. inserter_name,
                position = position,
                direction = oposite_direction(direction),
                force = entity.force,
            })

            double_arm_entity.operable = true
            double_arm_entity.minable = true
            double_arm_entity.destructible = false

            global.BiDirInserter[entity.unit_number] = {
                parent_inserter = entity,
                child_arm = double_arm_entity,
            }

            global.BiDirInserter[double_arm_entity.unit_number] = {
                parent_inserter = entity,
                child_arm = double_arm_entity,
            }
        end
    end
end

local function on_double_inserter_mined(event, create_ghosts)
    if event.entity and string.find(event.entity.name, "double_") then
        local entity = event.entity
        local double_inserter_pair = global.BiDirInserter[entity.unit_number]
        
        if double_inserter_pair then
            if string.find(event.entity.name, "arm") then
                if double_inserter_pair.parent_inserter and double_inserter_pair.parent_inserter.valid then
                    if create_ghosts then
                        double_inserter_pair.parent_inserter.destructible = true
                        double_inserter_pair.parent_inserter.die()
                    else
                        double_inserter_pair.parent_inserter.destroy()
                    end
                end
            else
                if double_inserter_pair.child_arm and double_inserter_pair.child_arm.valid then
                    if create_ghosts then
                        double_inserter_pair.child_arm.destructible = true
                        double_inserter_pair.child_arm.die()
                    else
                        double_inserter_pair.child_arm.destroy()
                    end
                end
            end
        end
    end
end

local function on_double_inserter_rotated(event)
    if event.entity and string.find(event.entity.name, "double_") then
        local entity = event.entity
        local double_inserter_pair = global.BiDirInserter[entity.unit_number]

        if double_inserter_pair then
            if string.find(event.entity.name, "arm") then
                if entity.direction == defines.direction.north then
                    double_inserter_pair.parent_inserter.direction = defines.direction.south
                elseif entity.direction == defines.direction.east then
                    double_inserter_pair.parent_inserter.direction = defines.direction.west
                elseif entity.direction == defines.direction.south then
                    double_inserter_pair.parent_inserter.direction = defines.direction.north
                elseif entity.direction == defines.direction.west then
                    double_inserter_pair.parent_inserter.direction = defines.direction.east
                end
            else
                if entity.direction == defines.direction.north then
                    double_inserter_pair.child_arm.direction = defines.direction.south
                elseif entity.direction == defines.direction.east then
                    double_inserter_pair.child_arm.direction = defines.direction.west
                elseif entity.direction == defines.direction.south then
                    double_inserter_pair.child_arm.direction = defines.direction.north
                elseif entity.direction == defines.direction.west then
                    double_inserter_pair.child_arm.direction = defines.direction.east
                end
            end
        end
    end
end

local filters_on_built = {{ filter="type", type="inserter" }}
local filters_on_mined = {{ filter="type", type="inserter" }}
local filters_on_pipette = {{ filter="type", type="inserter" }}

-- always track built/removed train stops for duplicate name list
script.on_event(defines.events.on_built_entity, on_double_inserter_built, filters_on_built)
script.on_event(defines.events.on_robot_built_entity, on_double_inserter_built, filters_on_built )
script.on_event({defines.events.script_raised_built, defines.events.script_raised_revive, defines.events.on_entity_cloned}, on_double_inserter_built)

script.on_event(defines.events.on_pre_player_mined_item, on_double_inserter_mined, filters_on_mined )
script.on_event(defines.events.on_robot_pre_mined, on_double_inserter_mined, filters_on_mined )
script.on_event(defines.events.on_entity_died, function(event) on_double_inserter_mined(event, true) end, filters_on_mined )
script.on_event(defines.events.script_raised_destroy, on_double_inserter_mined)

script.on_event(defines.events.on_player_rotated_entity, on_double_inserter_rotated)