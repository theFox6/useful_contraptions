local S = contraptions_mod.S

minetest.register_node("useful_contraptions:putter_on", {
	description = S("Putter"),
	_doc_items_longdesc = S("A putter that puts items laying on top into a chest below."),
	_doc_items_usagehelp = S("Right-click the putter or send a mesecon signal to it, to switch it on or off."),
	tiles = {"factory_belt_bottom.png^factory_ring_green.png", "factory_belt_bottom.png", "factory_belt_side.png",
		"factory_belt_side.png", "factory_belt_side.png", "factory_belt_side.png"},
	groups = {cracky=3, not_in_creative_inventory=1, mesecon_effector_off = 1},
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = true,
	drop="useful_contraptions:putter_off",
	node_box = {
			type = "fixed",
			fixed = {{-0.5,-0.5,-0.5,0.5,0.0625,0.5},}
		},
	mesecons = {effector = {
		action_off = function(pos, node)
			minetest.swap_node(pos, {name = "useful_contraptions:putter_off", param2 = node.param2})
		end
	}},
	on_rightclick = function (pos, node)
		minetest.swap_node(pos, {name = "useful_contraptions:putter_off", param2 = node.param2})
	end
})

minetest.register_node("useful_contraptions:putter_off", {
	description = S("Putter"),
	_doc_items_longdesc = S("A putter that puts items laying on top into a chest below."),
	_doc_items_usagehelp = S("Right-click the putter or send a mesecon signal to it, to switch it on or off."),
	tiles = {"factory_belt_bottom.png^factory_ring_red.png", "factory_belt_bottom.png", "factory_belt_side.png",
		"factory_belt_side.png", "factory_belt_side.png", "factory_belt_side.png"},
	groups = {cracky=3, mesecon_effector_on = 1},
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = true,
	node_box = {
			type = "fixed",
			fixed = {{-0.5,-0.5,-0.5,0.5,0.0625,0.5},}
		},
	mesecons = {effector = {
		action_on = function(pos, node)
			minetest.swap_node(pos, {name = "useful_contraptions:putter_on", param2 = node.param2})
		end
	}},
	on_rightclick = function (pos, node)
		minetest.swap_node(pos, {name = "useful_contraptions:putter_on", param2 = node.param2})
	end
})

minetest.register_abm({
	nodenames = {"useful_contraptions:putter_on"},
	neighbors = nil,
	interval = 1,
	chance = 1,
	action = function(pos) --pos, node, active_object_count, active_object_count_wider
		local all_objects = minetest.get_objects_inside_radius(pos, 0.8)
		for _,obj in ipairs(all_objects) do
			if not obj:is_player() and obj:get_luaentity() and (obj:get_luaentity().name == "__builtin:item") then
				local b = {x = pos.x, y = pos.y - 1, z = pos.z,}
				local target = minetest.get_node(b)
				local stack = ItemStack(obj:get_luaentity().itemstring)
				if table.indexof(contraptions_mod.putter_targets, target.name) ~= -1 then
					local meta = minetest.env:get_meta(b)
					local inv = meta:get_inventory()
					if inv:room_for_item("main", stack) then
						inv:add_item("main", stack)
						obj:remove()
					end
				end
			end
		end
	end,
})