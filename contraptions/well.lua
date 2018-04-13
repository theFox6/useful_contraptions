minetest.register_node(":homedecor:well", {
	mesh = "homedecor_well.obj",
	drawtype = "mesh",
	tiles = {
		"homedecor_rope_texture.png",
		{ name = "homedecor_generic_metal.png", color = 0xffa0a0a0 },
		"default_water.png",
		"default_cobble.png",
		"default_wood.png",
		"homedecor_shingles_wood.png"
	},
	inventory_image = "homedecor_well_inv.png",
	description = contraptions_mod.S("Water well"),
	groups = { snappy = 3 },
	paramtype = "light",
	paramtype2 = "facedir",
	selection_box = { -0.5, -0.5, -0.5, 0.5, 2.5, 0.5 },
	collision_box = { -0.5, -0.5, -0.5, 0.5, 2.5, 0.5 },
	sounds = default.node_sound_stone_defaults(),
	on_rotate = screwdriver.rotate_simple,
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under
		local node = minetest.get_node_or_nil(pos)
		local def = node and minetest.registered_nodes[node.name]
		if not def or not def.buildable_to then
			pos = pointed_thing.above
			node = minetest.get_node_or_nil(pos)
			def = node and minetest.registered_nodes[node.name]
		end
		local placer_name = placer:get_player_name() or ""
		if not (def and def.buildable_to) or minetest.is_protected(pos, placer_name) then
			print("no bottom space")
			return false
		end
		local top_pos = { x=pos.x, y=pos.y+1, z=pos.z }
		if not (def and def.buildable_to) or minetest.is_protected(top_pos, placer_name) then
			print("no top space")
			return false
		end
		local lfdir = minetest.dir_to_facedir(placer:get_look_dir())
		minetest.set_node(pos, { name = itemstack:get_name(), param2 = lfdir })
		minetest.set_node(top_pos, { name = "air"})
		if not creative.is_enabled_for(placer_name) then
			itemstack:take_item()
		end
		return itemstack
	end,
	on_punch = function(_, _, puncher)
		local wielded_item = puncher:get_wielded_item()
		if wielded_item:get_name() == "bucket:bucket_empty" then
			local inv = puncher:get_inventory()
			if inv:room_for_item("main", "bucket:bucket_water 1") then
				wielded_item:take_item()
				puncher:set_wielded_item(wielded_item)
				inv:add_item("main", "bucket:bucket_water 1")
			else
				minetest.chat_send_player(puncher:get_player_name(), "No room in your inventory to add a filled bucket!")
			end
		end
	end,
})