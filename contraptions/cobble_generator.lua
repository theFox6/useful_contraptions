local S = contraptions_mod.S

local function inject_items (pos, meta, inv)
	local mode = meta:get_string("mode")
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

local function set_cgen_formspec(meta)
	local is_stack = meta:get_string("mode") == "whole stacks"
	meta:set_string("formspec",
			"invsize[8,9;]"..
			"item_image[0,0;1,1;useful_contraptions:cobble_generator]"..
			"label[1,0;"..S("Cobblestone Generator").."]"..
			(is_stack and
				"button[0,1;2,1;mode_item;"..S("Stackwise").."]" or
				"button[0,1;2,1;mode_stack;"..S("Itemwise").."]")..
			"list[current_name;main;0,2;8,2;]"..
			"list[current_player;main;0,5;8,4;]"..
			"listring[]")
end

core.register_node("useful_contraptions:cobble_generator", {
	description = S("Cobblestone Generator"),
	_doc_items_longdesc = S("A machine that generates cobblestone."),
	_doc_items_usagehelp = S("Right-click the generator to access inventory. "..
		"With the button in the inventory you can change between injecting whole stacks or single items."),
	--TODO: textures
	tiles = {"contraptions_cobble_gen_top.png", "contraptions_cobble_gen_bottom.png", "contraptions_cobble_gen_side.png",
		"contraptions_cobble_gen_side.png", "contraptions_cobble_gen_front.png", "contraptions_cobble_gen_front.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	light_source = 7,
	tube = {
		can_insert = function(pos, _, stack) --pos, node, stack, direction
			return false
		end,
		insert_object = function(pos, _, stack) --pos, node, stack, direction
			return core.get_meta(pos):get_inventory():add_item("main",stack)
		end,
		connect_sides = {bottom=1},
	},
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("infotext", S("Cobblestone Generator"))
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		meta:set_string("mode","single items")
		set_cgen_formspec(meta)
	end,
	allow_metadata_inventory_put = function(_, _, _, stack)
		if stack:get_name() == "default:cobble" then
			return stack:get_count()
		end
		return 0
	end,
	on_receive_fields = function(pos, _, fields) --pos, formanme, fields, sender
		local meta = core.get_meta(pos)
		if fields.mode_item then meta:set_string("mode", "single items") end
		if fields.mode_stack then meta:set_string("mode", "whole stacks") end
		set_cgen_formspec(meta)
	end,
	after_place_node = pipeworks.after_place,
	after_dig_node = pipeworks.after_dig
})

core.register_abm({
	nodenames = {"useful_contraptions:cobble_generator"},
	interval = 1,
	chance = 1,
	action = function(pos) --pos, node, active_object_count, active_object_count_wider
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local cobble = ItemStack("default:cobble 1")
		local rnd = math.random(4)
		if rnd == 1 and inv:room_for_item("main", cobble) then
			if inv:room_for_item("main", cobble) then
				inv:add_item("main", cobble)
			end
		end
		if core.get_modpath("pipeworks") then
			local pos1 = vector.add(pos, vector.new(0, -1, 0))
			local node1 = core.get_node(pos1)
			if core.get_item_group(node1.name, "tubedevice") > 0 then
				inject_items(pos, meta, inv)
			end
		end
	end,
})

if core.get_modpath("mesecons_detector") and core.get_modpath("mesecons_microcontroller") and core.get_modpath("pipeworks") then
	core.register_craft({
		output = 'useful_contraptions:cobble_generator 1',
		recipe = {
			{'mesecons_microcontroller:microcontroller0000', 'mesecons_detector:node_detector_off','default:glass'},
			{'bucket:bucket_water', '', 'bucket:bucket_lava'},
			{'pipeworks:conductor_tube_off_1','pipeworks:nodebreaker_off','default:chest'}
		}
	})
end
