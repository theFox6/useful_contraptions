windos = {}

local windos, sounds = {}, {}

function windos.play_sound(pos)
   local spos = minetest.hash_node_position(pos)
   sounds[spos] =minetest.sound_play("alarm",{pos=pos, max_hear_distance=20, gain=1.25, loop=true})
end

function windos.stop_sound(pos)
   local spos = minetest.hash_node_position(pos)
   if sounds[spos] then minetest.sound_stop(sounds[spos]) end
end

minetest.register_node(":windos:alarmblock_on", {
   description = "Alarmblock",
   tiles = {"default_steel_block.png^windos_alarm_block.png"},
   paramtype = "light",
   is_ground_content = false,
   drop = "windos:alarmblock_off",
   groups = {cracky = 3, alarm = 1, mesecon = 1, not_in_creative_inventory = 1},
   sounds = default.node_sound_metal_defaults(),
   on_destruct = function(pos)
            windos.stop_sound(pos)
   end,
   mesecons = {effector = {
        state = mesecon.state.off,
        action_off = function (pos, node)
            windos.stop_sound(pos)
            minetest.swap_node(pos, {name = "windos:alarmblock_off"})
        end,
    }},
})

minetest.register_node(":windos:alarmblock_off", {
   description = "Alarmblock",
   tiles = {"default_steel_block.png^windos_alarm_block.png"},
   paramtype = "light",
   is_ground_content = false,
   groups = {cracky = 3, alarm = 1, mesecon_effector_off = 1, mesecon = 1},
   sounds = default.node_sound_metal_defaults(),
   on_construct = function(pos)
            windos.stop_sound(pos)
   end,
   mesecons = {effector = {
        state = mesecon.state.on,
        action_on = function (pos, node)
            minetest.swap_node(pos, {name = "windos:alarmblock_on"})
            windos.play_sound(pos)
        end,
    }}
})

minetest.register_craft({
	output = "windos:alarmblock_off",
	recipe = {
		{'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
		{'default:steel_ingot','default:mese_crystal_fragment','default:steel_ingot'},
		{'default:steel_ingot','mesecons_materials:silicon','default:steel_ingot'}
	}
})
