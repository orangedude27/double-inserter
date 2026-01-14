flib = require('__flib__.data-util')

-- Define the variants and their properties
local variants = {
  { prefix = "double_", count = 2, icon = "__double-inserter__/graphics/icons/two.png" },
  { prefix = "triple_", count = 3, icon = "__double-inserter__/graphics/icons/three.png" },
  { prefix = "quad_",   count = 4, icon = "__double-inserter__/graphics/icons/four.png" },
  { prefix = "quin_",   count = 5, icon = "__double-inserter__/graphics/icons/four.png" },
  { prefix = "sex_",    count = 6, icon = "__double-inserter__/graphics/icons/four.png" },
  { prefix = "sep_",    count = 7, icon = "__double-inserter__/graphics/icons/four.png" },
  { prefix = "oct_",    count = 8, icon = "__double-inserter__/graphics/icons/four.png" },
}

-- Map recipes to technologies to find prerequisites
local recipe_unlocks = {}
for name, tech in pairs(data.raw.technology) do
  if tech.effects then
    for _, effect in pairs(tech.effects) do
      if effect.type == "unlock-recipe" and effect.recipe then
        recipe_unlocks[effect.recipe] = name
      end
    end
  end
end

local existing_inserters = table.deepcopy(data.raw["inserter"])
for inserter_name, entity_prototype in pairs(existing_inserters) do
  if not string.find(inserter_name, "loader") and not string.find(inserter_name, "double_") and not string.find(inserter_name, "triple_") and not string.find(inserter_name, "quad_") and not string.find(inserter_name, "quin_") and not string.find(inserter_name, "sex_") and not string.find(inserter_name, "sep_") and not string.find(inserter_name, "oct_") and not string.find(inserter_name, "ne_") and not string.find(inserter_name, "se_") and not string.find(inserter_name, "sw_") and not string.find(inserter_name, "nw_") and entity_prototype.minable and entity_prototype.minable.result then
      local previous_tech = recipe_unlocks[inserter_name] or "logistics" -- Default to logistics if no tech found (e.g. burner)

      local base_tech = data.raw.technology[previous_tech]
      local tech_unit = base_tech and base_tech.unit or { count = 50, ingredients = {{"automation-science-pack", 1}}, time = 30 }
      local base_count = tech_unit.count or 50
      local base_ingredients = tech_unit.ingredients or {{"automation-science-pack", 1}}
      local base_time = tech_unit.time or 30

      if inserter_name == "inserter" then
        base_count = 10
      end

      for i, v in ipairs(variants) do
        local prefix = v.prefix
        local new_name = prefix .. inserter_name
        local arm_name = prefix .. "arm_" .. inserter_name
        local new_tech_name = prefix .. inserter_name

        -- Localization
        local prefix_key = string.sub(prefix, 1, -2)
        local result_name = entity_prototype.minable.result
        local original_item = data.raw.item[result_name] or data.raw["item-with-entity-data"][result_name]

        if original_item then
        local original_entity_locale = entity_prototype.localised_name or {"entity-name." .. inserter_name}
        -- Use entity locale as fallback for item to avoid "Unknown key: item-name.x" if item relies on entity fallback
        local original_item_locale = original_item.localised_name or original_entity_locale

        local item_localised_name = {"di-names.format", {"di-prefixes." .. prefix_key}, original_item_locale}
        local entity_localised_name = {"di-names.format", {"di-prefixes." .. prefix_key}, original_entity_locale}

        -- 1. Item
        local new_item = flib.copy_prototype(original_item, new_name)
        new_item.localised_name = item_localised_name
    
        new_item.icons = {
          {
            icon = new_item.icon
          },
          {
            icon = v.icon, scale = 0.25, shift = {0, 0}
          }
        }

        new_item.icon = nil
        new_item.order = (new_item.order or original_item.name) .. string.char(96 + i)

        -- 2. Entity (Main)
        local new_entity = flib.copy_prototype(entity_prototype, new_name)
        new_entity.localised_name = entity_localised_name
        if new_entity.next_upgrade then
          new_entity.next_upgrade = prefix .. new_entity.next_upgrade
        end
        new_entity.minable.result = new_name
        new_entity.place_result = new_name
        -- Selection box at the tip like the arms
        new_entity.selection_box = {{-0.25, 0.55}, {0.25, 1.05}}

        if v.insert_position then
          new_entity.insert_position = v.insert_position
          new_entity.pickup_position = {v.insert_position[1] * -1, v.insert_position[2] * -1}
        end

        -- 3. Entity (Arm - Dummy)
        local new_arm = flib.copy_prototype(entity_prototype, arm_name)
        new_arm.localised_name = entity_localised_name
        new_arm.icon = "__double-inserter__/graphics/icons/empty.png"
        new_arm.rotation_speed = new_arm.rotation_speed * 0.50
        new_arm.icon_size = 32
        new_arm.icon_mipmaps = nil
        new_arm.next_upgrade = nil
        new_arm.minable = new_entity.minable
        new_arm.placeable_by = {item = new_name, count = 1}
        new_arm.flags = { "not-blueprintable", "placeable-off-grid", "player-creation"}
        -- Selection box will rotate with the inserter automatically
        -- Bigger box positioned at the arm tip
        new_arm.selection_box = {{-0.25, 0.55}, {0.25, 1.05}}
        new_arm.collision_box = nil
        new_arm.collision_mask = {layers={}}

        if v.insert_position then
          new_arm.insert_position = v.insert_position
          new_entity.pickup_position = {v.insert_position[1] * -1, v.insert_position[2] * -1}
        end

        local empty_sprite = {
          filename = "__double-inserter__/graphics/icons/empty.png",
          priority = "extra-high",
          width = 1, height = 1, frame_count = 1, shift = { 0.0, 0.0 },
        }
        new_arm.hand_base_shadow = empty_sprite
        new_arm.hand_closed_shadow = empty_sprite
        new_arm.hand_open_shadow = empty_sprite
        new_arm.platform_picture = { sheet = empty_sprite }

        -- 4. Recipe
        local new_recipe = flib.copy_prototype(data.raw.recipe[inserter_name], new_name)
        new_recipe.enabled = false -- Enabled via technology
        new_recipe.ingredients = {
          { type="item", name=inserter_name,        amount=v.count },
          { type="item", name="copper-cable",       amount=v.count },
          { type="item", name="electronic-circuit", amount=2 * v.count },
        }

        -- 5. Technology
        local new_tech = {
          type = "technology",
          name = new_tech_name,
          localised_name = item_localised_name,
          icon_size = 256, icon_mipmaps = 4,
          icons = new_item.icons, -- Use the item icon for the tech
          effects = {
            {type = "unlock-recipe", recipe = new_name}
          },
          prerequisites = { previous_tech },
          unit = {
            count = base_count * (i * i * 10),  -- Quadratic scaling: 5x, 20x, 45x, 80x, 125x, 180x, 245x
            ingredients = base_ingredients,
            time = base_time
          },
          order = "c-a-" .. prefix .. inserter_name
        }

        data:extend({ new_item, new_entity, new_recipe, new_arm, new_tech })
        
        previous_tech = new_tech_name
        end
      end

      -- Create the diagonal arm variant (ne_) - this is the only one needed
      -- The ne_arm will be rotated in 90° increments to cover all 4 diagonals
      local ne_arm_name = "ne_arm_" .. inserter_name
      local ne_arm = flib.copy_prototype(entity_prototype, ne_arm_name)
      local original_entity_locale = entity_prototype.localised_name or {"entity-name." .. inserter_name}
      ne_arm.localised_name = {"di-names.format", {"di-prefixes.ne"}, original_entity_locale}

      ne_arm.icon = "__double-inserter__/graphics/icons/empty.png"
      ne_arm.rotation_speed = ne_arm.rotation_speed * 0.50
      ne_arm.icon_size = 32
      ne_arm.icon_mipmaps = nil
      ne_arm.next_upgrade = nil
      ne_arm.minable = {mining_time = 0.1, result = nil}
      ne_arm.flags = { "not-blueprintable", "placeable-off-grid", "player-creation"}
      ne_arm.collision_box = nil
      ne_arm.collision_mask = {layers={}}
      -- Selection box positioned diagonally (NE direction) at the arm tip
      -- This will rotate with the inserter to cover all 4 diagonal directions
      -- Bigger box for easier selection
      ne_arm.selection_box = {{0.35, -0.75}, {0.85, -0.25}}

      local ip = entity_prototype.insert_position or {0, 1.2}
      local len = math.sqrt(ip[1]^2 + ip[2]^2)
      -- NE direction: positive X (right), negative Y (up)
      ne_arm.insert_position = {0.707 * len, -0.707 * len}
      ne_arm.pickup_position = {-0.707 * len, 0.707 * len}

      local empty_sprite = {
        filename = "__double-inserter__/graphics/icons/empty.png",
        priority = "extra-high",
        width = 1, height = 1, frame_count = 1, shift = { 0.0, 0.0 },
      }
      ne_arm.hand_base_shadow = empty_sprite
      ne_arm.hand_closed_shadow = empty_sprite
      ne_arm.hand_open_shadow = empty_sprite
      ne_arm.platform_picture = { sheet = empty_sprite }

      data:extend({ ne_arm })
  end
end
