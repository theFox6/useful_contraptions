-- machine to change some iems into ores
local S = contraptions_mod.S

-- Exclude coal and diamond from being generated
local not_an_ore = {"default:stone_with_meme", "default:stone_with_NaN"}

local function is_not_an_ore(ore_name)
	for _,no_ore in ipairs(not_an_ore) do
		if ore_name == no_ore then
			return true
		end
	end
	return false
end

-- choose ore just as often as they occur in mapgen.
local function choose_ore()
	local cool_flowing = "default:stone"
	for _, ore in pairs(minetest.registered_ores) do
		if is_not_an_ore(ore.ore) then
			-- Do noting, keep cycling.
		elseif ore.wherein == cool_flowing and ore.ore_type == "scatter" then
			local rarity = math.floor(ore.clust_scarcity / ore.clust_size)
			if rarity > 1 then
				if math.random(rarity) == 1 then
					cool_flowing = ore.ore
					break
				end
			end
		end
	end
	return cool_flowing
end

local function give_drops(nodename, inv) -- gives apropriate drops when node is dug
	
	local table = minetest.registered_items[nodename];
	local dropname;
	if table~=nil then --put in chest
		if table.drop~= nil then -- drop handling 
			if table.drop.items then
			--handle drops better, emulation of drop code
			local max_items = table.drop.max_items or 0;
				if max_items==0 then -- just drop all the items (taking the rarity into consideration)
					max_items = #table.drop.items or 0;
				end
				local drop = table.drop;
				local i = 0;
				for k,v in pairs(drop.items) do
					if i > max_items then break end; i=i+1;								
					local rare = v.rarity or 1;
					if math.random(1, rare)==1 then
						dropname = v.items[math.random(1,#v.items)]; -- pick item randomly from list
						inv:add_item("out",dropname);
						
					end
				end
			else
				inv:add_item("out",table.drop);
			end	
		else
			inv:add_item("out",nodename);
		end
	end
	
end

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
    myFormspec = myFormspec..contraptions_mod.fs_helpers.cycling_button(meta, "button[1,2;3,3", "injectMode",
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
			contraptions_mod.fs_helpers.on_receive_fields(pos, fields)
		end
		meta:set_string("formspec",formspec_oregen(meta));
	end;
})

minetest.register_abm({
	nodenames = {"useful_contraptions:ore_generator"},
	neighbors = nil,
	interval = 2,
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

		-- on average, process 15 items at each cycle (10..20 are possible)
		local process_stuff = math.random( 10, 20 );
		local found_stuff = stack1:get_count() + stack2:get_count() + stack3:get_count() + stack4:get_count();
		
		-- do not process more items than present in the input slots
		if found_stuff >= process_stuff and math.random(0,1)==1 then
			local process_ore=choose_ore()
			if inv:room_for_item('out',process_ore) then
				-- the player gets output
				give_drops(process_ore, inv)
				--inv:add_item("out",process_ore..' '..tostring(ore_count));
				local i=0
				for _,stack in ipairs(inv:get_list("main")) do
					i=i+1
					if (process_stuff > stack:get_count()) then
						process_stuff = process_stuff - stack:get_count()
						stack:clear();
						inv:set_stack("main", i, stack);
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