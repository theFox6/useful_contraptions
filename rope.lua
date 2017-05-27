local S = contraptions_mod.S

minetest.register_node(":castle:ropes",{
	description = S("Rope"),
	_doc_items_longdesc = S("A rope you can climb up."),
	_doc_items_usagehelp = S("Just stand inside and jump."),
	drawtype = "nodebox",
	sunlight_propagates = true,
	tiles = {"castle_ropes.png"},
	groups = {choppy=3,snappy=3,oddly_breakable_by_hand=3,flammable=1},
	sounds = default.node_sound_defaults(),
	paramtype = "light",
	climbable = true,
	walkable = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-1/16, -8/16, -1/16, 1/16, 8/16, 1/16}, 
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-1/16, -8/16, -1/16, 1/16, 8/16, 1/16},
		},
	},
})

minetest.register_craft({
	output = "castle:ropes",
	recipe = {
		{"farming:string"},
		{"farming:string"},
		{"farming:string"},
	}
})

minetest.register_node(":castle:box_rope", {
	description = S("Rope from Ropebox"),
	_doc_items_longdesc = S("A rope that has been created from a ropebox."),
	_doc_items_usagehelp = S("Just stand inside and jump."),
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = {"castle_ropes.png"},
	groups = {not_in_creative_inventory=1},
	climbable = true,
	walkable = false,
	diggable = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-1/16, -8/16, -1/16, 1/16, 8/16, 1/16}, 
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-1/16, -8/16, -1/16, 1/16, 8/16, 1/16},
		},
	},
	after_destruct = function(pos,oldnode)
		local node = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
		if node.name == "castle:box_rope" then
			minetest.remove_node({x=pos.x,y=pos.y-1,z=pos.z})
		end
	end,
})

minetest.register_node(":castle:ropebox", {
	description = S("Ropebox"),
	_doc_items_longdesc = S("A ropebox that will create ropes under itself."),
	_doc_items_usagehelp = S("Place it somewhere and you will get a nice long rope."),
	drawtype = "nodebox",
	sunlight_propagates = true,
	tiles = {"castle_ropebox_top.png",
		"castle_ropebox_top.png",
		"castle_ropebox_side_1.png",
		"castle_ropebox_side_1.png",
		"castle_ropebox_side_2.png",
		"castle_ropebox_side_2.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {choppy=3},
	sounds = default.node_sound_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
			{-2/16, -2/16, -4/16, 2/16, 2/16, 4/16},
			{-2/16, -4/16, -2/16, 2/16, 4/16, 2/16},
			{-2/16, -3/16, -3/16, 2/16, 3/16, 3/16},
			{-3/16, -2/16, -2/16, -2/16, 8/16, 2/16},
			{2/16, -2/16, -2/16, 3/16, 8/16, 2/16},
			{-1/16, -8/16, -1/16, 1/16, -4/16, 1/16},
		},
	},
	after_destruct = function(pos,oldnode)
		local node = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
		if node.name == "castle:box_rope" then
			minetest.remove_node({x=pos.x,y=pos.y-1,z=pos.z})
		end
	end,
})

minetest.register_abm({
	nodenames = {"castle:ropebox"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
	if minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name ~= 'air'  then return end
		minetest.add_node({x=pos.x,y=pos.y-1,z=pos.z}, {name="castle:box_rope"})
	end
})

minetest.register_abm({
	nodenames = {"castle:box_rope"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
	if minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name ~= 'air'  then return end
		minetest.add_node({x=pos.x,y=pos.y-1,z=pos.z}, {name="castle:box_rope"})
	end
})

minetest.register_craft({
	output = "castle:ropebox",
	recipe = {
		{"default:wood"},
		{"castle:ropes"},
	}
})

