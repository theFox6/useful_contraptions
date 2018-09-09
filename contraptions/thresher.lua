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

local cottages_formspec_treshing_machine = function(meta)
  local myFormspec = "size[8,8]"..
                     "image[0,1;1,1;farming_wheat.png]"..
                     "list[current_name;main;1,1.5;2,1;]"..
                     "list[current_name;straw;5,0;2,2;]"..
                     "list[current_name;seeds;5,2;2,2;]"..
                     "label[1,1;"..S("Harvested wheat:").."]"..
                     "label[4,0.0;"..S("Straw:").."]"..
                     "label[4,2.0;"..S("Seeds:").."]"..
                     "label[0,0;"..S("Threshing machine").."]"..
                     "list[current_player;main;0,4;8,4;]"..
                     "listring[current_player;main]"..
		     "listring[current_name;main]"..
		     "listring[current_player;main]"..
		     "listring[current_name;straw]"..
		     "listring[current_player;main]"..
		     "listring[current_name;seeds]"
  if minetest.get_modpath("pipeworks") then
    myFormspec = myFormspec..contraptions_mod.fs_helpers.cycling_button(meta, "button[1,2;3,3", "injectMode",
      {S("tube injection - off"),
       S("tube injection - on ")})
  else
    meta:set_int("injectMode", 0)
  end
  return myFormspec
end

minetest.register_node("useful_contraptions:threshing_machine", {
	drawtype = "nodebox",
	description = S("threshing machine"),
	_doc_items_longdesc = S("A threshing machine that makes straw and wheat seed out of wheat."),
	_doc_items_usagehelp = S("Right-click the threshing machine to access the inventory. "..
		"If you use the pipeworks mod there will be a button too. "..
		"You can use the button to make the threshing machine inject the outputs into a tube."),
	tiles = {"default_chest_top.png^default_stick.png","default_chest_top.png^factory_8x8_black_square_32x32.png",
	"default_chest_side.png","default_chest_side.png","default_chest_side.png","default_chest_side.png^farming_wheat.png"},
	paramtype  = "light",
        paramtype2 = "facedir",
	groups = {cracky=2, tubedevice = 1, tubedevice_receiver = 1},
	sounds = default.node_sound_wood_defaults(),
	tube = {
		can_insert = function(pos, _, stack)
			return ((stack:get_name() == 'farming:wheat') and minetest.get_meta(pos):get_inventory():room_for_item("main",stack))
		end,
		insert_object = function(pos, _, stack)
			return minetest.get_meta(pos):get_inventory():add_item("main",stack)
		end,
		connect_sides = {left=1, right=1, front=1, back=1, top=1, bottom=1},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		meta:set_string("infotext", S("Threshing machine"));
		local inv = meta:get_inventory();
		inv:set_size("main", 2);
		inv:set_size("straw", 4);
		inv:set_size("seeds", 4);
		meta:set_string("formspec", cottages_formspec_treshing_machine(meta) );
	end,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos);
		meta:set_string("owner", placer:get_player_name() or "");
		meta:set_string("infotext", S("Threshing machine (owned by %s)"):format(meta:get_string("owner") or ""));
		meta:set_string("formspec",
				cottages_formspec_treshing_machine(meta)..
				"label[0,0.5;"..S("Owner: %s"):format(meta:get_string("owner") or "").."]" );
		meta:set_int("slotseq",0)
		if pipeworks then
			pipeworks.after_place(pos, placer)
		end
        end,

        can_dig = function(pos,player)

                local meta  = minetest.get_meta(pos);
                local inv   = meta:get_inventory();
		local owner = meta:get_string('owner');

                if(  not( inv:is_empty("main"))
		  or not( inv:is_empty("straw"))
		  or not( inv:is_empty("seeds"))
		  or not( player )
		  or ( owner and owner ~= ''  and player:get_player_name() ~= owner )) then

		   return false;
		end
                return true;
        end,
	after_dig_node = function(pos)
		if minetest.get_modpath("pipeworks") then
			pipeworks.after_dig(pos);
		end
	end,

	allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
		local meta = minetest.get_meta(pos)
		if( not( cottages_can_use( meta, player ))) then
                        return 0
		end
		return count;
	end,

	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		local meta = minetest.get_meta(pos)
		-- only accept input the threshing floor can use/process
		if(    listname=='straw'
		    or listname=='seeds'
		    or (listname=='main' and stack and stack:get_name() ~= 'farming:wheat' )) then
			return 0;
		end

		if( not( cottages_can_use( meta, player ))) then
                        return 0
		end
		return stack:get_count()
	end,

	allow_metadata_inventory_take = function(pos, _, _, stack, player)
		local meta = minetest.get_meta(pos)
		if( not( cottages_can_use( meta, player ))) then
                        return 0
		end
		return stack:get_count()
	end,

	on_receive_fields = function(pos, _, fields, sender)
		local meta = minetest.get_meta(pos)
		if cottages_can_use( meta, sender ) then
			contraptions_mod.fs_helpers.on_receive_fields(pos, fields)
		end
		meta:set_string("formspec",
		cottages_formspec_treshing_machine(meta)..
		"label[0,0.5;"..S("Owner: %s"):format(meta:get_string("owner") or "").."]" );
	end;
})

minetest.register_abm({
	nodenames = {"useful_contraptions:threshing_machine"},
	neighbors = nil,
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if( not( pos ) or not( node )) then
			return;
		end
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory();
		-- we have two input slots
		local stack1 = inv:get_stack( 'main', 1);
		local stack2 = inv:get_stack( 'main', 2);

		if not((stack1:is_empty() and stack2:is_empty())
			or (stack1:get_name() ~= 'farming:wheat' and not(stack1:is_empty()))
			or (stack2:get_name() ~= 'farming:wheat' and not(stack2:is_empty()))) then

		-- on average, process 3 wheat at each cycle (1..5 are possible)
		local anz_wheat = 1 + math.random( 0, 4 );
		-- we already made sure there is only wheat inside
		local found_wheat = stack1:get_count() + stack2:get_count();
		-- do not process more wheat than present in the input slots
		if( found_wheat < anz_wheat ) then
			anz_wheat = found_wheat;
		end

		if(    inv:room_for_item('straw','cottages:straw_mat '..tostring( anz_wheat ))
		   and inv:room_for_item('seeds',"farming:seed_wheat"..' '..tostring( anz_wheat ))) then

			-- the player gets two kind of output
			inv:add_item("straw",'cottages:straw_mat '..tostring( anz_wheat ));
			inv:add_item("seeds","farming:seed_wheat"..' '..tostring( anz_wheat ));
			-- consume the wheat
			inv:remove_item("main", 'farming:wheat '..tostring( anz_wheat ));

		end
		end
		if meta:get_int("injectMode")==1 then
			if meta:get_int("slotseq")==0 then
				meta:set_int("slotseq",1)
				local i=0
				for _,stack in ipairs(inv:get_list("straw")) do
					i=i+1
					if stack then
						local item0=stack:to_table()
						if item0 then
							item0["count"] = "1"
							contraptions_mod.tube_inject_item(pos, pos, vector.new(0, -1, 0), item0)
							stack:take_item(1)
							inv:set_stack("straw", i, stack)
						end
					end
				end
			else
				meta:set_int("slotseq",0)
				local i=0
				for _,stack in ipairs(inv:get_list("seeds")) do
					i=i+1
					if stack then
						local item0=stack:to_table()
						if item0 then
							item0["count"] = "1"
							contraptions_mod.tube_inject_item(pos, pos, vector.new(0, -1, 0), item0)
							stack:take_item(1)
							inv:set_stack("seeds", i, stack)
						end
					end
				end
			end
		end
	end,
})

if minetest.get_modpath("pipeworks") then
  minetest.register_craft({
    output = "useful_contraptions:threshing_machine",
    recipe = {
      {"factory:small_steel_gear","default:stick","factory:small_steel_gear"},
      {"default:wood", "cottages:threshing_floor", "default:wood", },
      {"default:wood", "pipeworks:tube_1",        "default:wood", },
    },
  })
else
  minetest.register_craft({
    output = "useful_contraptions:threshing_machine",
    recipe = {
      {"factory:small_steel_gear","default:stick","factory:small_steel_gear"},
      {"default:wood", "cottages:threshing_floor", "default:wood", },
      {"default:wood", "default:wood",        "default:wood", },
    },
  })
end