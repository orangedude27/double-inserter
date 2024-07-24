flib = require('__flib__.data-util')

local existing_inserters = table.deepcopy(data.raw["inserter"])
for inserter_name, entity_prototype in pairs(existing_inserters) do
  if not string.find(inserter_name, "loader") then
    if entity_prototype.minable and entity_prototype.minable.result then

      local bi_dir_inserter_item = flib.copy_prototype(data.raw.item[entity_prototype.minable.result], "bi_dir_" .. inserter_name)
      bi_dir_inserter_item.order = "a[inserter]a[stack-inserter]-c[bi_dir_" .. inserter_name .. "]"

      -- local bi_dir_inserter_arm_item = flib.copy_prototype(data.raw.item[entity_prototype.minable.result], "bi_dir_arm_" .. inserter_name)
      -- bi_dir_inserter_arm_item.order = "a[inserter]a[stack-inserter]-c[bi_dir_arm_" .. inserter_name .. "]"
      -- bi_dir_inserter_arm_item.hidden = true

      local bi_dir_inserter_entity = flib.copy_prototype(entity_prototype, "bi_dir_" .. inserter_name)
      bi_dir_inserter_entity.minable.result = "bi_dir_" .. inserter_name
      bi_dir_inserter_entity.place_result = "bi_dir_" .. inserter_name
      bi_dir_inserter_entity.selection_box = {{-0.5, 0}, {0.5, 0.5}}

      local bi_dir_arm_entity = flib.copy_prototype(entity_prototype, "bi_dir_arm_" .. inserter_name)
      bi_dir_arm_entity.icon = "__all-the-overhaul-modpack__/graphics/icons/empty.png"
      bi_dir_arm_entity.rotation_speed = bi_dir_arm_entity.rotation_speed * 0.50
      bi_dir_arm_entity.icon_size = 32
      bi_dir_arm_entity.icon_mipmaps = nil
      bi_dir_arm_entity.next_upgrade = nil
      bi_dir_arm_entity.minable = bi_dir_inserter_entity.minable
      bi_dir_arm_entity.placeable_by = {item = "bi_dir_" .. inserter_name, count = 1}
      bi_dir_arm_entity.flags = { "not-blueprintable", "placeable-off-grid", "player-creation"}
      bi_dir_arm_entity.selection_box = {{-0.5, 0}, {0.5, 0.5}}

      bi_dir_arm_entity.hand_base_shadow =
      {
        filename = "__all-the-overhaul-modpack__/graphics/icons/empty.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        frame_count = 1,
        shift = { 0.0, 0.0 },
      }
      bi_dir_arm_entity.hand_closed_shadow =
      {
        filename = "__all-the-overhaul-modpack__/graphics/icons/empty.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        frame_count = 1,
        shift = { 0.0, 0.0 },
      }
      bi_dir_arm_entity.hand_open_shadow =
      {
        filename = "__all-the-overhaul-modpack__/graphics/icons/empty.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        frame_count = 1,
        shift = { 0.0, 0.0 },
      }
      bi_dir_arm_entity.platform_picture =
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

      local bi_dir_inserter_recipe = flib.copy_prototype(data.raw.recipe[inserter_name], "bi_dir_" .. inserter_name)
      bi_dir_inserter_recipe.enabled = true
      bi_dir_inserter_recipe.ingredients = {
        { inserter_name,        2 },
        { "electronic-circuit", 2 },
      }

      data:extend({
        bi_dir_inserter_item,
        bi_dir_inserter_entity,
        bi_dir_inserter_recipe,
        bi_dir_arm_entity,
      })
    end
  end
end
