flib = require('__flib__.data-util')

local existing_inserters = table.deepcopy(data.raw["inserter"])
for inserter_name, entity_prototype in pairs(existing_inserters) do
  if not string.find(inserter_name, "loader") then
    if entity_prototype.minable and entity_prototype.minable.result then

      local double_inserter_item = flib.copy_prototype(data.raw.item[entity_prototype.minable.result], "double_" .. inserter_name)
      double_inserter_item.order = "a[inserter]a[double_" .. inserter_name .. "]"

      -- local double_inserter_arm_item = flib.copy_prototype(data.raw.item[entity_prototype.minable.result], "double_arm_" .. inserter_name)
      -- double_inserter_arm_item.order = "a[inserter]a[stack-inserter]-c[double_arm_" .. inserter_name .. "]"
      -- double_inserter_arm_item.hidden = true

      local double_inserter_entity = flib.copy_prototype(entity_prototype, "double_" .. inserter_name)
      double_inserter_entity.minable.result = "double_" .. inserter_name
      double_inserter_entity.place_result = "double_" .. inserter_name
      double_inserter_entity.selection_box = {{-0.5, 0}, {0.5, 0.5}}

      local double_arm_entity = flib.copy_prototype(entity_prototype, "double_arm_" .. inserter_name)
      double_arm_entity.icon = "__all-the-overhaul-modpack__/graphics/icons/empty.png"
      double_arm_entity.rotation_speed = double_arm_entity.rotation_speed * 0.50
      double_arm_entity.icon_size = 32
      double_arm_entity.icon_mipmaps = nil
      double_arm_entity.next_upgrade = nil
      double_arm_entity.minable = double_inserter_entity.minable
      double_arm_entity.placeable_by = {item = "double_" .. inserter_name, count = 1}
      double_arm_entity.flags = { "not-blueprintable", "placeable-off-grid", "player-creation"}
      double_arm_entity.selection_box = {{-0.5, 0}, {0.5, 0.5}}

      double_arm_entity.hand_base_shadow =
      {
        filename = "__all-the-overhaul-modpack__/graphics/icons/empty.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        frame_count = 1,
        shift = { 0.0, 0.0 },
      }
      double_arm_entity.hand_closed_shadow =
      {
        filename = "__all-the-overhaul-modpack__/graphics/icons/empty.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        frame_count = 1,
        shift = { 0.0, 0.0 },
      }
      double_arm_entity.hand_open_shadow =
      {
        filename = "__all-the-overhaul-modpack__/graphics/icons/empty.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        frame_count = 1,
        shift = { 0.0, 0.0 },
      }
      double_arm_entity.platform_picture =
      {
        sheet =
        {
          filename = "__all-the-overhaul-modpack__/graphics/icons/empty.png",
          priority = "extra-high",
          width = 1,
          height = 1,
          frame_count = 1,
          shift = { 0.0, 0.0 },
        }
      }

      local double_inserter_recipe = flib.copy_prototype(data.raw.recipe[inserter_name], "double_" .. inserter_name)
      double_inserter_recipe.enabled = true
      double_inserter_recipe.ingredients = {
        { inserter_name,        2 },
        { "copper-cable",       2 },
        { "electronic-circuit", 4 },
      }

      data:extend({
        double_inserter_item,
        double_inserter_entity,
        double_inserter_recipe,
        double_arm_entity,
      })
    end
  end
end
