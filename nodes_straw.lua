---------------------------------------------------------------------------------------
-- straw - a very basic material
---------------------------------------------------------------------------------------
--  * straw mat - for animals and very poor NPC; also basis for other straw things
--  * straw bale - well, just a good source for building and decoration

local S = contraptions_mod.S

-- add to this table what you want the handmill to convert;
-- add a stack size if you want a higher yield
contraptions_mod.handmill_product = {};
contraptions_mod.handmill_product[ "farming:seed_wheat" ] = 'farming:flour 1';
--[[ some examples:
contraptions_mod.handmill_product[ 'default:cobble' ] = 'default:gravel';
contraptions_mod.handmill_product[ 'default:gravel' ] = 'default:sand';
contraptions_mod.handmill_product[ 'default:sand'   ] = 'default:dirt 2';
contraptions_mod.handmill_product[ 'flowers:rose'   ] = 'dye:red 6';
contraptions_mod.handmill_product[ 'default:cactus' ] = 'dye:green 6';
contraptions_mod.handmill_product[ 'default:coal_lump'] = 'dye:black 6';
--]]
-- process that many inputs per turn
contraptions_mod.handmill_max_per_turn = 20;
contraptions_mod.handmill_min_per_turn = 0;


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

contraptions_mod.allow_sit = function( player )
	-- no check possible
	if( not( player.get_player_velocity )) then
		return true;
	end
	local velo = player:get_player_velocity();
	if( not( velo )) then
		return false;
	end
	local max_velo = 0.0001;
	if(   math.abs(velo.x) < max_velo
	  and math.abs(velo.y) < max_velo
	  and math.abs(velo.z) < max_velo ) then
		return true;
	end
	return false;
end

contraptions_mod.sleep_in_bed = function( pos, node, clicker, itemstack )
	if( not( clicker ) or not( node ) or not( node.name ) or not( pos ) or not( contraptions_mod.allow_sit( clicker))) then
		return;
	end

	local animation = default.player_get_animation( clicker );
	local pname = clicker:get_player_name();

	local place_name = 'place';
	-- if only one node is present, the player can only sit;
	-- sleeping requires a bed head+foot or two sleeping mats
	local allow_sleep = false;
	local new_animation = 'sit';

	-- let players get back up
	if( animation and animation.animation=="lay" ) then
		default.player_attached[pname] = false
		clicker:setpos({x=pos.x,y=pos.y-0.5,z=pos.z})
		clicker:set_eye_offset({x=0,y=0,z=0}, {x=0,y=0,z=0})
		clicker:set_physics_override(1, 1, 1)
		default.player_set_animation(clicker, "stand", 30)
		minetest.chat_send_player( pname, S("That was enough sleep for now. You stand up again."));
		return;
	end

	-- the node that will contain the head of the player
	local p = {x=pos.x, y=pos.y, z=pos.z};
	-- the player's head is pointing in this direction
	local dir = node.param2;
	-- it would be odd to sleep in half a bed
        if( node.name=='cottages:sleeping_mat' or node.name=='cottages:straw_mat') then
		place_name = 'mat';
		dir = node.param2;
		allow_sleep = false;
		-- search for a second mat right next to this one
		local offset = {{x=0,z=-1}, {x=-1,z=0}, {x=0,z=1}, {x=1,z=0}};
		for i,off in ipairs( offset ) do
			local node2 = minetest.get_node( {x=pos.x+off.x, y=pos.y, z=pos.z+off.z} );
			if( node2.name == 'cottages:sleeping_mat' or node2.name=='cottages:straw_mat' ) then
				-- if a second mat is found, sleeping is possible
				allow_sleep = true;
				dir = i-1;
			end
		end
	end

	-- set the right height for the bed
	if( place_name=='bed' ) then
		p.y = p.y+0.4;
	end
	if( allow_sleep==true ) then
		-- set the right position (middle of the bed)
		if(     dir==0 ) then
			p.z = p.z-0.5;
		elseif( dir==1 ) then
			p.x = p.x-0.5;
		elseif( dir==2 ) then
			p.z = p.z+0.5;
		elseif( dir==3 ) then
			p.x = p.x+0.5;
		end
	end

	if( default.player_attached[pname] and animation.animation=="sit") then
		-- just changing the animation...
		if( allow_sleep==true ) then
			default.player_set_animation(clicker, "lay", 30)
			clicker:set_eye_offset({x=0,y=-14,z=2}, {x=0,y=0,z=0})
			minetest.chat_send_player( pname, S("You lie down and take a nap. A right-click will wake you up."));
			return;
		-- no sleeping on this place
		else
			default.player_attached[pname] = false
			clicker:setpos({x=pos.x,y=pos.y-0.5,z=pos.z})
			clicker:set_eye_offset({x=0,y=0,z=0}, {x=0,y=0,z=0})
			clicker:set_physics_override(1, 1, 1)
			default.player_set_animation(clicker, "stand", 30)
			minetest.chat_send_player( pname, S("That was enough sitting around for now. You stand up again."));
			return;
		end
	end


	clicker:set_eye_offset({x=0,y=-7,z=2}, {x=0,y=0,z=0})
	clicker:setpos( p );
	default.player_set_animation(clicker, new_animation, 30)
	clicker:set_physics_override(0, 0, 0)
	default.player_attached[pname] = true
	local msg
	if( allow_sleep==true) then
		msg = S("Aaah! What a comftable "..place_name..". A second right-click will let you sleep.")
		minetest.chat_send_player(pname, msg);
	else
		msg = S("Comftable, but not good enough for a nap. Right-click again if you want to get back up.")
		minetest.chat_send_player(pname, msg);
	end
end

-- an even simpler from of bed - usually for animals
-- it is a nodebox and not wallmounted because that makes it easier to replace beds with straw mats
minetest.register_node(":cottages:straw_mat", {
        description = S("layer of straw"),
        drawtype = 'nodebox',
        tiles = { 'cottages_darkage_straw.png' }, -- done by VanessaE
        wield_image = 'cottages_darkage_straw.png',
        inventory_image = 'cottages_darkage_straw.png',
        sunlight_propagates = true,
        paramtype = 'light',
        paramtype2 = "facedir",
        walkable = false,
        groups = { snappy = 3 },
        sounds = default.node_sound_leaves_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
					{-0.48, -0.5,-0.48,  0.48, -0.45, 0.48},
			}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.48, -0.5,-0.48,  0.48, -0.25, 0.48},
			}
	},
	is_ground_content = false,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		return contraptions_mod.sleep_in_bed( pos, node, clicker, itemstack, pointed_thing );
	end
})

-- straw bales are a must for farming environments
minetest.register_node(":cottages:straw_bale", {
	drawtype = "nodebox",
	description = S("straw bale"),
	tiles = {"cottages_darkage_straw_bale.png"},
	paramtype = "light",
	groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	sounds = default.node_sound_wood_defaults(),
        -- the bale is slightly smaller than a full node
	node_box = {
		type = "fixed",
		fixed = {
					{-0.45, -0.5,-0.45,  0.45,  0.45, 0.45},
			}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.45, -0.5,-0.45,  0.45,  0.45, 0.45},
			}
	},
	is_ground_content = false,
})

local cottages_formspec_treshing_floor =
                               "size[8,8]"..
				"image[1.5,0;1,1;".."default_stick.png".."]"..
				"image[0,1;1,1;farming_wheat.png]"..
                                "list[current_name;harvest;1,1;2,1;]"..
                                "list[current_name;straw;5,0;2,2;]"..
                                "list[current_name;seeds;5,2;2,2;]"..
					"label[1,0.5;"..S("Harvested wheat:").."]"..
					"label[4,0.0;"..S("Straw:").."]"..
					"label[4,2.0;"..S("Seeds:").."]"..
					"label[0,-0.5;"..S("Threshing floor").."]"..
					"label[0,2.5;"..S("Punch threshing floor with a stick").."]"..
					"label[0,3.0;"..S("to get straw and seeds from wheat.").."]"..
                                "list[current_player;main;0,4;8,4;]";

minetest.register_node(":cottages:threshing_floor", {
	drawtype = "nodebox",
	description = S("threshing floor"),
-- TODO: stone also looks pretty well for this
	tiles = {"cottages_junglewood.png^farming_wheat.png","cottages_junglewood.png","cottages_junglewood.png^".."default_stick.png"},
	paramtype  = "light",
        paramtype2 = "facedir",
	groups = {cracky=2},
	is_ground_content = false,
	node_box = {
		type = "fixed",
		fixed = {
					{-0.50, -0.5,-0.50, 0.50, -0.40, 0.50},

					{-0.50, -0.4,-0.50,-0.45, -0.20, 0.50},
					{ 0.45, -0.4,-0.50, 0.50, -0.20, 0.50},

					{-0.45, -0.4,-0.50, 0.45, -0.20,-0.45},
					{-0.45, -0.4, 0.45, 0.45, -0.20, 0.50},
			}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.50, -0.5,-0.50, 0.50, -0.20, 0.50},
			}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		meta:set_string("infotext", S("Threshing floor"));
		local inv = meta:get_inventory();
		inv:set_size("harvest", 2);
		inv:set_size("straw", 4);
		inv:set_size("seeds", 4);
		meta:set_string("formspec", cottages_formspec_treshing_floor );
	end,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos);
		meta:set_string("owner", placer:get_player_name() or "");
		meta:set_string("infotext", S("Threshing floor (owned by %s)"):format(meta:get_string("owner") or ""));
		meta:set_string("formspec",
				cottages_formspec_treshing_floor..
				"label[2.5,-0.5;"..S("Owner: %s"):format(meta:get_string("owner") or "").."]" );
        end,

        can_dig = function(pos,player)

                local meta  = minetest.get_meta(pos);
                local inv   = meta:get_inventory();
		local owner = meta:get_string('owner');

                if(  not( inv:is_empty("harvest"))
		  or not( inv:is_empty("straw"))
		  or not( inv:is_empty("seeds"))
		  or not( player )
		  or ( owner and owner ~= ''  and player:get_player_name() ~= owner )) then

		   return false;
		end
                return true;
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
		    or (listname=='harvest' and stack and stack:get_name() ~= 'farming:wheat' )) then
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


	on_punch = function(pos, node, puncher)
		if( not( pos ) or not( node ) or not( puncher )) then
			return;
		end
		-- only punching with a normal stick is supposed to work
		local wielded = puncher:get_wielded_item();
		if(    not( wielded )
		    or not( wielded:get_name() )
		    or not( minetest.registered_items[ wielded:get_name() ])
		    or not( minetest.registered_items[ wielded:get_name() ].groups )
		    or not( minetest.registered_items[ wielded:get_name() ].groups.stick )) then
			return;
		end
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory();

		-- we have two input slots
		local stack1 = inv:get_stack( 'harvest', 1);
		local stack2 = inv:get_stack( 'harvest', 2);

		if(       (      stack1:is_empty()  and stack2:is_empty())
			or( not( stack1:is_empty()) and stack1:get_name() ~= 'farming:wheat')
			or( not( stack2:is_empty()) and stack2:get_name() ~= 'farming:wheat')) then

			-- update the formspec
			meta:set_string("formspec",
				cottages_formspec_treshing_floor..
				"label[2.5,-0.5;"..S("Owner: %s"):format(meta:get_string("owner") or "").."]" );
			return;
		end

		-- on average, process 25 wheat at each punch (10..40 are possible)
		local anz_wheat = 10 + math.random( 0, 30 );
		-- we already made sure there is only wheat inside
		local found_wheat = stack1:get_count() + stack2:get_count();

		-- do not process more wheat than present in the input slots
		if( found_wheat < anz_wheat ) then
			anz_wheat = found_wheat;
		end

		local overlay1 = "^farming_wheat.png";
		local overlay2 = "^cottages_darkage_straw.png";
		local overlay3 = "^".."farming_wheat_seed.png";

		-- this can be enlarged by a multiplicator if desired
		local anz_straw = anz_wheat;
		local anz_seeds = anz_wheat;

		if(    inv:room_for_item('straw','cottages:straw_mat '..tostring( anz_straw ))
		   and inv:room_for_item('seeds',"farming:seed_wheat"..' '..tostring( anz_seeds ))) then

			-- the player gets two kind of output
			inv:add_item("straw",'cottages:straw_mat '..tostring( anz_straw ));
			inv:add_item("seeds","farming:seed_wheat"..' '..tostring( anz_seeds ));
			-- consume the wheat
			inv:remove_item("harvest", 'farming:wheat '..tostring( anz_wheat ));

			local anz_left = found_wheat - anz_wheat;
			if( anz_left == 0 ) then
--				minetest.chat_send_player( name, S('You have threshed the last %s wheat.'):format(anz_wheat));
				overlay1 = "";
--[[			else
				minetest.chat_send_player( name, S('You have threshed %s wheat (%s are left).'):format(anz_wheat,anz_left));--]]
			end
		end

		local hud0 = puncher:hud_add({
			hud_elem_type = "image",
			scale = {x = 38, y = 38},
			text = "cottages_junglewood.png^[colorize:#888888:128",
			position = {x = 0.5, y = 0.5},
			alignment = {x = 0, y = 0}
		});

		local hud1 = puncher:hud_add({
			hud_elem_type = "image",
			scale = {x = 15, y = 15},
			text = "cottages_junglewood.png"..overlay1,
			position = {x = 0.4, y = 0.5},
			alignment = {x = 0, y = 0}
		});
		local hud2 = puncher:hud_add({
			hud_elem_type = "image",
			scale = {x = 15, y = 15},
			text = "cottages_junglewood.png"..overlay2,
			position = {x = 0.6, y = 0.35},
			alignment = {x = 0, y = 0}
		});
		local hud3 = puncher:hud_add({
			hud_elem_type = "image",
			scale = {x = 15, y = 15},
			text = "cottages_junglewood.png"..overlay3,
			position = {x = 0.6, y = 0.65},
			alignment = {x = 0, y = 0}
		});

		local hud4 = puncher:hud_add({
			hud_elem_type = "text",
			text = tostring( found_wheat-anz_wheat ),
			number = 0x00CC00,
			alignment = {x = 0, y = 0},
			scale = {x = 100, y = 100}, -- bounding rectangle of the text
			position = {x = 0.4, y = 0.5},
		});
		if( not( anz_straw )) then
			anz_straw = "0";
		end
		if( not( anz_seeds )) then
			anz_seeds = "0";
		end
		local hud5 = puncher:hud_add({
			hud_elem_type = "text",
			text = '+ '..tostring( anz_straw )..S(' straw'),
			number = 0x00CC00,
			alignment = {x = 0, y = 0},
			scale = {x = 100, y = 100}, -- bounding rectangle of the text
			position = {x = 0.6, y = 0.35},
		});
		local hud6 = puncher:hud_add({
			hud_elem_type = "text",
			text = '+ '..tostring( anz_seeds )..S(' seeds'),
			number = 0x00CC00,
			alignment = {x = 0, y = 0},
			scale = {x = 100, y = 100}, -- bounding rectangle of the text
			position = {x = 0.6, y = 0.65},
		});

		minetest.after(3, function()
			if( puncher ) then
				puncher:hud_remove(hud1);
				puncher:hud_remove(hud2);
				puncher:hud_remove(hud3);
				puncher:hud_remove(hud4);
				puncher:hud_remove(hud5);
				puncher:hud_remove(hud6);
				puncher:hud_remove(hud0);
			end
		end)
	end,
})


local cottages_handmill_formspec = "size[8,8]"..
				"image[0,1;1,1;".."farming_wheat_seed.png".."]"..
                                "list[current_name;seeds;1,1;1,1;]"..
                                "list[current_name;flour;5,1;2,2;]"..
					"label[0,0.5;"..S("Wheat seeds:").."]"..
					"label[4,0.5;"..S("Flour:").."]"..
					"label[0,-0.3;"..S("Mill").."]"..
					"label[0,2.5;"..S("Punch this hand-driven mill").."]"..
					"label[0,3.0;"..S("to convert wheat seeds into flour.").."]"..
                                "list[current_player;main;0,4;8,4;]";

minetest.register_node(":cottages:handmill", {
	description = S("mill, powered by punching"),
	drawtype = "mesh",
	mesh = "cottages_handmill.obj",
	tiles = {"cottages_stone.png"},
	paramtype  = "light",
	paramtype2 = "facedir",
	groups = {cracky=2},
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {
				{-0.50, -0.5,-0.50, 0.50,  0.25, 0.50},
			}
	},
	collision_box = {
		type = "fixed",
		fixed = {
				{-0.50, -0.5,-0.50, 0.50,  0.25, 0.50},
			}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		meta:set_string("infotext", S("Mill, powered by punching"));
		local inv = meta:get_inventory();
		inv:set_size("seeds", 1);
		inv:set_size("flour", 4);
		meta:set_string("formspec", cottages_handmill_formspec );
	end,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos);
		meta:set_string("owner", placer:get_player_name() or "");
		meta:set_string("infotext", S("Mill, powered by punching (owned by %s)"):format(meta:get_string("owner") or ""));
		meta:set_string("formspec",
				cottages_handmill_formspec..
				"label[2.5,-0.5;"..S("Owner: %s"):format(meta:get_string('owner') or "").."]" );
        end,

        can_dig = function(pos,player)

                local meta  = minetest.get_meta(pos);
                local inv   = meta:get_inventory();
		local owner = meta:get_string('owner');

                if(  not( inv:is_empty("flour"))
		  or not( inv:is_empty("seeds"))
		  or not( player )
		  or ( owner and owner ~= ''  and player:get_player_name() ~= owner )) then

		   return false;
		end
                return true;
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
		if(    listname=='flour'
		    or (listname=='seeds' and stack and not( contraptions_mod.handmill_product[ stack:get_name()] ))) then
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

        -- this code is very similar to the threshing floor; except that it has only one input- and output-slot
	-- and does not require the usage of a stick
	on_punch = function(pos, node, puncher)
		if( not( pos ) or not( node ) or not( puncher )) then
			return;
		end
		local name = puncher:get_player_name();

               	local meta = minetest.get_meta(pos);
               	local inv = meta:get_inventory();

		local stack1 = inv:get_stack( 'seeds', 1);

		if(       (      stack1:is_empty())
			or( not( stack1:is_empty())
			and not( contraptions_mod.handmill_product[ stack1:get_name() ] ))) then

			if not( stack1:is_empty() ) then
				minetest.chat_send_player(name,"Nothing happens...")
			end
			-- update the formspec
			meta:set_string("formspec",
				cottages_handmill_formspec..
				"label[2.5,-0.5;"..S("Owner: %s"):format(meta:get_string('owner') or "").."]" );
			return;
		end

		-- turning the mill is a slow process; 1-21 flour are generated per turn
		local anz = 1 + math.random( contraptions_mod.handmill_min_per_turn, contraptions_mod.handmill_max_per_turn );
		-- we already made sure there is only wheat inside
		local found = stack1:get_count();

		-- do not process more wheat than present in the input slots
		if( found < anz ) then
			anz = found;
		end

		local product_stack = ItemStack( contraptions_mod.handmill_product[ stack1:get_name() ]);
		local anz_result = anz;
		-- items that produce more
		if( product_stack:get_count()> 1 ) then
			anz_result = anz * product_stack:get_count();
		end

		if(    inv:room_for_item('flour', product_stack:get_name()..' '..tostring( anz_result ))) then

			inv:add_item(    'flour', product_stack:get_name()..' '..tostring( anz_result ));
			inv:remove_item( 'seeds', stack1:get_name()..' '..tostring( anz ));

			local anz_left = found - anz;
			if( anz_left > 0 ) then
				minetest.chat_send_player( name, S('You have ground some %s (%s are left).'):format(stack1:get_definition().description,(anz_left)));
			else
				minetest.chat_send_player( name, S('You have ground the last %s.'):format(stack1:get_definition().description));
			end

			-- if the version of MT is recent enough, rotate the mill a bit
			if( minetest.swap_node ) then
				node.param2 = node.param2 + 1;
				if( node.param2 > 3 ) then
					node.param2 = 0;
				end
				minetest.swap_node( pos, node );
			end
		end
	end,
})




---------------------------------------------------------------------------------------
-- crafting receipes
---------------------------------------------------------------------------------------
-- this returns corn as well
-- the replacements work only if the replaced slot gets empty...
minetest.register_craft({
	output = "cottages:straw_mat 6",
	recipe = {
                {"default:stone",'',''},
		{"farming:wheat", "farming:wheat", "farming:wheat", },
	},
        replacements = {{ "default:stone", "farming:seed_wheat".." 3" }},
})

-- this is a better way to get straw mats
minetest.register_craft({
	output = "cottages:threshing_floor",
	recipe = {
		{"default:junglewood", "default:chest_locked", "default:junglewood", },
		{"default:junglewood", "default:stone",        "default:junglewood", },
	},
})

-- and a way to turn wheat seeds into flour
minetest.register_craft({
	output = "cottages:handmill",
	recipe = {
		{"group:stick",     "default:stone",    "", },
		{"",               "default:steel_ingot", "", },
		{"",                  "default:stone",    "", },
	},
})

minetest.register_craft({
	output = "cottages:straw_bale",
	recipe = {
		{"cottages:straw_mat"},
		{"cottages:straw_mat"},
		{"cottages:straw_mat"},
	},
})

minetest.register_craft({
	output = "farming:straw",
	recipe = {
		{"cottages:straw_bale"},
	},
})

minetest.register_craft({
	output = "cottages:straw_bale",
	recipe = {
		{"farming:straw"},
	},
})

minetest.register_craft({
	output = "cottages:straw_mat 3",
	recipe = {
		{"cottages:straw_bale"},
	},
})
