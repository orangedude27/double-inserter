flib = require('__flib__.data-util')

-- Define the variants and their properties
local variants = {
  { prefix = "double_", count = 2, icon = "__double-inserter__/graphics/icons/two.png" },
  { prefix = "triple_", count = 3, icon = "__double-inserter__/graphics/icons/three.png" },
  { prefix = "quad_",   count = 4, icon = "__double-inserter__/graphics/icons/four.png" },
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
  if not string.find(inserter_name, "loader") and not string.find(inserter_name, "double_") and not string.find(inserter_name, "triple_") and not string.find(inserter_name, "quad_") and entity_prototype.minable and entity_prototype.minable.result then
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
        new_entity.selection_box = {{-0.25, 0}, {0.25, 0.5}}

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
        new_arm.selection_box = {{-0.25, 0}, {0.25, 0.5}}

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
            count = base_count * (5 ^ i),
            ingredients = base_ingredients,
            time = base_time
          },
          order = "c-a-" .. prefix .. inserter_name
        }

        data:extend({ new_item, new_entity, new_recipe, new_arm, new_tech })
        
        previous_tech = new_tech_name
        end
      end
  end
end
