local S = contraptions_mod.S

local function inject_items (pos)
		local meta=minetest.get_meta(pos) 
		local inv = meta:get_inventory()
		local mode=meta:get_string("mode")
		if mode=="single items" then
			local i=0
			for _,stack in ipairs(inv:get_list("main")) do
			i=i+1
				if stack then
				local item0=stack:to_table()
				if item0 then 
					item0["count"] = "1"
					contraptions_mod.tube_inject_item(pos, pos, vector.new(0, -1, 0), item0)
					stack:take_item(1)
					inv:set_stack("main", i, stack)
					return
					end
				end
			end
		end
		if mode=="whole stacks" then
			local i=0
			for _,stack in ipairs(inv:get_list("main")) do
			i=i+1
				if stack then
				local item0=stack:to_table()
				if item0 then 
					contraptions_mod.tube_inject_item(pos, pos, vector.new(0, -1, 0), item0)
					stack:clear()
					inv:set_stack("main", i, stack)
					return
					end
				end
			end
		end
		
end

minetest.register_craft({
	output = 'technic:injector 1',
	recipe = {
		{'', 'mesecons_blinkyplant:blinky_plant',''},
		{'', 'default:chest',''},
		{'', 'pipeworks:tube_1',''},
	}
})

local function set_injector_formspec(meta)
	local is_stack = meta:get_string("mode") == "whole stacks"
	meta:set_string("formspec",
			"invsize[8,9;]"..
			"item_image[0,0;1,1;technic:injector]"..
			"label[1,0;"..S("Self-Contained Injector").."]"..
			(is_stack and
				"button[0,1;2,1;mode_item;"..S("Stackwise").."]" or
				"button[0,1;2,1;mode_stack;"..S("Itemwise").."]")..
			"list[current_name;main;0,2;8,2;]"..
			"list[current_player;main;0,5;8,4;]"..
			"listring[]")
end

minetest.register_node(":technic:injector", {
	description = S("Self-Contained Injector"),
	_doc_items_longdesc = S("A machine that injects items put into it into a tube."),
	_doc_items_usagehelp = S("Right-click the injector to access inventory. With the button in the inventory you can change between injecting whole stacks or single items."),	
	tiles = {"technic_injector_top.png", "technic_injector_bottom.png", "technic_injector_side.png",
		"technic_injector_side.png", "technic_injector_side.png", "technic_injector_side.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2, tubedevice=1, tubedevice_receiver=1},
	tube = {
		can_insert = function(pos, node, stack, direction)
			return minetest.get_meta(pos):get_inventory():room_for_item("main",stack)
		end,
		insert_object = function(pos, node, stack, direction)
			return minetest.get_meta(pos):get_inventory():add_item("main",stack)
		end,
		connect_sides = {left=1, right=1, front=1, back=1, top=1, bottom=1},
	},
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Self-Contained Injector"))
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		meta:set_string("mode","single items")
		set_injector_formspec(meta)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	on_receive_fields = function(pos, formanme, fields, sender)
		local meta = minetest.get_meta(pos)
		if fields.mode_item then meta:set_string("mode", "single items") end
		if fields.mode_stack then meta:set_string("mode", "whole stacks") end
		set_injector_formspec(meta)
	end,
	after_place_node = pipeworks.after_place,
	after_dig_node = pipeworks.after_dig
})

minetest.register_abm({
	nodenames = {"technic:injector"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local pos1 = vector.add(pos, vector.new(0, -1, 0))
		local node1 = minetest.get_node(pos1) 
		if minetest.get_item_group(node1.name, "tubedevice") > 0 then
			inject_items(pos)
		end
	end,
})