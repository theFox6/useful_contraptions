-- machine to change some iems into ores
local S = contraptions_mod.S

local cottages_can_use = function( meta, player )
	if( not( player) or not( meta )) then
		return false;
	end
	local pname = player:get_player_name();
	local owner = meta:get_string('owner' );
	if( not(owner) or owner=="" or owner==pname ) then
		return true;
	end
	return false;
end

local formspec_oregen = function(meta)
  local myFormspec = "size[8,8]"..
                     "list[current_name;main;1,1;2,2;]"..
                     "list[current_name;out;5,1;2,2;]"..
                     "label[2,0.5;"..S("Input:").."]"..
                     "label[5,0.5;"..S("Output:").."]"..
                     "label[0,0;".."ore generator".."]"..
                     "label[5,0;"..S("Owner: %s"):format(meta:get_string("owner") or "").."]"..
                     "list[current_player;main;0,4;8,4;]";
  if minetest.get_modpath("pipeworks") then
    myFormspec = myFormspec..fs_helpers.cycling_button(meta, "button[1,2;3,3", "injectMode",
      {"tube injection - off",
       "tube injection - on "})
  else
    meta:set_int("injectMode", 0)
  end
  return myFormspec
end

minetest.register_node("useful_contraptions:ore_generator", {
	drawtype = "nodebox",
	description = "ore generator",
	_doc_items_longdesc = S("A machine that changes usual stuff into ores./nVery useful if you play something like skyblock."),
	_doc_items_usagehelp = S("Right-click the machine to access the inventory. If you use the pipeworks mod there will be a button too. You can use the button to make the generator inject the outputs into a tube."),
	tiles = {"lifter.png","default_chest_top.png^factory_8x8_black_square_32x32.png",
	"default_chest_side.png","default_chest_side.png","default_chest_side.png","default_chest_side.png"},
	paramtype  = "light",
        paramtype2 = "facedir",
	groups = {cracky=2, tubedevice = 1, tubedevice_receiver = 1},
	sounds = default.node_sound_wood_defaults(),
	tube = {
		can_insert = function(pos, node, stack, direction)
			return minetest.get_meta(pos):get_inventory():room_for_item("main",stack)
		end,
		insert_object = function(pos, node, stack, direction)
			return minetest.get_meta(pos):get_inventory():add_item("main",stack)
		end,
		connect_sides = {left=1, right=1, front=1, back=1, top=1, bottom=1},
	},
	on_construct = function(pos)
               	local meta = minetest.get_meta(pos);
               	meta:set_string("infotext", S("Threshing machine"));
               	local inv = meta:get_inventory();
               	inv:set_size("main", 4);
               	inv:set_size("out", 4);
                meta:set_string("formspec", formspec_oregen(meta) );
       	end,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos);
		meta:set_string("owner", placer:get_player_name() or "");
		meta:set_string("infotext", S("ore generator (owned by %s)"):format(meta:get_string("owner") or ""));
		meta:set_string("formspec",formspec_oregen(meta));
		if pipeworks then
			pipeworks.after_place(pos, placer)
		end
        end,

        can_dig = function(pos,player)

                local meta  = minetest.get_meta(pos);
                local inv   = meta:get_inventory();

                if(  not( inv:is_empty("main")) or not( inv:is_empty("out")) or not(cottages_can_use( meta, player ))) then
		   return false;
		end
                return true;
        end,
	
	after_dig_node = function(pos)
		if minetest.get_modpath("pipeworks") then
			pipeworks.after_dig(pos);
		end
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if( not( cottages_can_use( meta, player ))) then
                        return 0
		end
		return count;
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if( not( cottages_can_use( meta, player ))) then
                        return 0
		end
		return stack:get_count()
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if( not( cottages_can_use( meta, player ))) then
                        return 0
		end
		return stack:get_count()
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if cottages_can_use( meta, sender ) then
			fs_helpers.on_receive_fields(pos, fields)
		end
		meta:set_string("formspec",formspec_oregen(meta));
	end;
})

minetest.register_abm({
	nodenames = {"useful_contraptions:ore_generator"},
	neighbors = nil,
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if( not( pos ) or not( node )) then
			return;
		end
               	local meta = minetest.get_meta(pos);
               	local inv = meta:get_inventory();
		local input = inv:get_list('main');
		-- we have four input slots
		local stack1 = inv:get_stack( 'main', 1);
		local stack2 = inv:get_stack( 'main', 2);
		local stack3 = inv:get_stack( 'main', 3);
		local stack4 = inv:get_stack( 'main', 4);

		-- on average, process 50 items at each cycle (25..75 are possible)
		local process_stuff = math.random( 25, 50 );
		local found_stuff = stack1:get_count() + stack2:get_count() + stack3:get_count() + stack4:get_count();
		
		-- do not process more items than present in the input slots
		if found_stuff >= process_stuff then
			local ore_got=false
			for _,ore in ipairs(minetest.registered_ores) do
				print("randomized ore of type: "..type(ore))
				print("ore name: "..ore.ore)
				if math.random(0,10)==10 then
					local ore_count = math.random( 1, 8 );
					if inv:room_for_item('out',ore.ore..' '..tostring(ore_count)) then
						-- the player gets output
						inv:add_item("out",ore.ore..' '..tostring(ore_count));
						ore_got=true
					end
				end
			end
			
	
			-- consume the stuff
			if ore_got then
				local i=0
				for _,stack in ipairs(inv:get_list("main")) do
					i=i+1
					if (process_stuff > stack:get_count()) then
						process_stuff = process_stuff - stack:get_count()
						stack:clear();
					else
						stack:take_item(process_stuff);
						inv:set_stack("main", i, stack);
						break;
					end
				end
			end
		end
		--injet items into tube
		if meta:get_int("injectMode")==1 then
			local i=0
			for _,stack in ipairs(inv:get_list("out")) do
				i=i+1
				if stack then
					local item0=stack:to_table()
					if item0 then
						item0["count"] = "1"
						contraptions_mod.tube_inject_item(pos, pos, vector.new(0, -1, 0), item0)
						stack:take_item(1)
						inv:set_stack("out", i, stack)
					end
				end
			end
		end
	end,
})

-- ores are stored in minetest.registered_ores

-- some oredefs:

--[[
minetest.register_ore({
	ore_type         = "scatter",
	ore              = "technic:mineral_uranium",
	wherein          = "default:stone",
	clust_scarcity   = 8*8*8,
	clust_num_ores   = 4,
	clust_size       = 3,
	y_min       = -300,
	y_max       = -80,
	noise_params     = uranium_params,
	noise_threshold = uranium_threshold,
})
minetest.register_ore({
	ore_type       = "sheet",
	ore            = "technic:marble",
	wherein        = "default:stone",
	clust_scarcity = 1,
	clust_num_ores = 1,
	clust_size     = 3,
	y_min     = -31000,
	y_max     = -50,
	noise_threshold = 0.4,
	noise_params = {offset=0, scale=15, spread={x=150, y=150, z=150}, seed=23, octaves=3, persist=0.70}
})
--]]