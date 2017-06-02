contraptions_mod={
modpath=minetest.get_modpath("useful_contraptions")
}

--needed functions and craftitems
dofile(contraptions_mod.modpath.."/util.lua")
dofile(contraptions_mod.modpath.."/items.lua")

--ropes out of the castles mod
if not minetest.get_modpath("castle") then
  dofile(contraptions_mod.modpath.."/rope.lua")
end

--straw out of the cottages mod
if not minetest.get_modpath("cottages") then
  dofile(contraptions_mod.modpath.."/nodes_straw.lua")
end

--threshing machine
dofile(contraptions_mod.modpath.."/thresher.lua")

--stuff out of factory mod
if not minetest.get_modpath("factory") then
  dofile(contraptions_mod.modpath.."/storage_tank.lua")
  dofile(contraptions_mod.modpath.."/vacuum.lua")
end

--putter to put items into a chest
dofile(contraptions_mod.modpath.."/putter.lua")

--putter that collects items in his radius
dofile(contraptions_mod.modpath.."/vacuum_putter.lua")

--injectors out of technic mod
if minetest.get_modpath("pipeworks") then
  if not minetest.get_modpath("technic") then
    dofile(contraptions_mod.modpath.."/injector.lua")
  end
end

--ore generator as help for skyblock
dofile(contraptions_mod.modpath.."/skyblock.lua")

--ready
if minetest.setting_getbool("log_mods") then
  minetest.log("action", "[Mod] useful_contraptions: loaded")
else
  print("[Mod] useful_contraptions: loaded")
end
