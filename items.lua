local S = contraptions_mod.S

if not minetest.get_modpath("factory") then
  minetest.register_craftitem(":factory:small_steel_gear", {
    description = S("Small Steel Gear"),
    inventory_image = "factory_small_steel_gear.png"
  })
--[[
  minetest.register_craftitem(":factory:small_gold_gear", {
    description = S("Small Gold Gear"),
    inventory_image = "factory_small_gold_gear.png"
  })

  minetest.register_craftitem(":factory:small_diamond_gear", {
    description = S("Small Diamond Gear"),
    inventory_image = "factory_small_diamond_gear.png"
  })
--]]
  minetest.register_craft({
    output = ":factory:small_steel_gear 5",
    recipe = {
      {"default:steel_ingot", "", "default:steel_ingot"},
      {"", "default:steel_ingot", ""},
      {"default:steel_ingot", "", "default:steel_ingot"}
    }
  })
--[[
  minetest.register_craft({
    output = ":factory:small_gold_gear 4",
    recipe = {
      {"default:gold_ingot", "", "default:gold_ingot"},
      {"", ":factory:small_steel_gear", ""},
      {"default:gold_ingot", "", "default:gold_ingot"}
    }
  })

  minetest.register_craft({
    output = ":factory:small_diamond_gear 4",
    recipe = {
      {"default:diamond", "", "default:diamond"},
      {"", ":factory:small_gold_gear", ""},
      {"default:diamond", "", "default:diamond"}
    }
  })
--]]
end