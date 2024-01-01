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
  minetest.register_craftitem(":factory:piston", {
    description = S("Piston"),
    inventory_image = "factory_piston.png",
    groups = { piston_craftable = 1 }
  })
  minetest.register_craft({
    output = "factory:piston",
    recipe = {
      {"group:wood", "group:wood", "group:wood"},
      {"group:stone", "default:steel_ingot", "group:stone"},
      {"group:stone", "", "group:stone"}
    }
  })
  if minetest.get_modpath("mesecons_pistons") then
    minetest.register_craft({
      output = "mesecons_pistons:piston_normal_off",
      recipe = {
        {"factory:piston"},
        {"group:mesecon_conductor_craftable"},
      }
    })
  end
end
