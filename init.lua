local init = os.clock()
if core.settings:get_bool("log_mods") then
  core.log("action", "[MOD] "..core.get_current_modname()..": loading")
else
  print("[MOD] "..core.get_current_modname()..": loading")
end

contraptions_mod={
	modpath=core.get_modpath("useful_contraptions"),
	putter_targets={"default:chest","default:chest_locked","technic:injector"}
}

--needed functions and craftitems
dofile(contraptions_mod.modpath.."/util.lua")
dofile(contraptions_mod.modpath.."/items.lua")

--a more convenient furnace
dofile(contraptions_mod.modpath.."/contraptions/lab_furnace.lua")

--ropes out of the castles mod
if not core.get_modpath("castle") and not core.get_modpath("ropes") then
  dofile(contraptions_mod.modpath.."/contraptions/rope.lua")
end

--straw out of the cottages mod
if not core.get_modpath("cottages") then
  dofile(contraptions_mod.modpath.."/nodes_straw.lua")
end

--threshing machine
dofile(contraptions_mod.modpath.."/contraptions/thresher.lua")

--stuff out of factory mod
if not core.get_modpath("factory") then
  dofile(contraptions_mod.modpath.."/contraptions/storage_tank.lua")
  dofile(contraptions_mod.modpath.."/contraptions/vacuum.lua")
end

--putter to put items into a chest
dofile(contraptions_mod.modpath.."/contraptions/putter.lua")

--putter that collects items in his radius
dofile(contraptions_mod.modpath.."/contraptions/vacuum_putter.lua")

--cobblestone generator
dofile(contraptions_mod.modpath.."/contraptions/cobble_generator.lua")

--injectors out of technic mod
if core.get_modpath("pipeworks") then
  if not core.get_modpath("technic") then
    dofile(contraptions_mod.modpath.."/contraptions/injector.lua")
  end
end

--ore generator as help for skyblock (can be replaced by gravel sieve)
if core.settings:get_bool("uselful_contraptions_ore_generator") == true then
  dofile(contraptions_mod.modpath.."/contraptions/skyblock.lua")
end

if core.settings:get_bool("uselful_contraptions_torch_light") ~= false then
	dofile(contraptions_mod.modpath.."/torch_light.lua")
end

if core.get_modpath("mesecons") then
  if not core.get_modpath("windos") then
     dofile(contraptions_mod.modpath.."/contraptions/alarm_block.lua")
  end
end

if not core.get_modpath("homedecor") then
  dofile(contraptions_mod.modpath.."/contraptions/well.lua")
end

--ready
local time_to_load= os.clock() - init
if core.settings:get_bool("log_mods") then
  core.log("action", string.format("[MOD] "..core.get_current_modname()..
	contraptions_mod.S(": loaded in %.4f s"), time_to_load))
else
  print(string.format("[MOD] "..core.get_current_modname()..contraptions_mod.S(": loaded in %.4f s"), time_to_load))
end
