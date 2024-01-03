local S = contraptions_mod.S

-- List of sound handles for active furnace
local furnace_fire_sounds = {}
-- Maximum stored fuel
local fuel_totaltime = 1000

--
-- Formspecs
--

local function get_furnace_formspec(active, fuel_time, item_percent)
	local fuel_percent = math.floor(fuel_time / fuel_totaltime * 100)
	return "size[8,8.5]"..
		"list[context;src;0.75,0.5;3,1;]"..
		-- Fuel
		"list[context;fuel;2.75,2.5;1,1;]"..
		"image[0.5,2.5;2.5,1;gui_lab_furnace_fuel_bg.png^[lowpart:"..
		(fuel_percent)..":gui_lab_furnace_fuel_fg.png^[transformR90]"..
		"tooltip[0.5,2.75;2,0.5;Fuel: " .. math.ceil(fuel_time)  .. "/" .. fuel_totaltime .. "]"..
		-- Activation and Progress
		"image[2.75,1.5;1,1;" .. (active and "default_furnace_fire_fg.png]" or "default_furnace_fire_bg.png]") ..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png" .. (active and ("^[lowpart:"..
		(item_percent)..":gui_furnace_arrow_fg.png") or "") .. "^[transformR270]"..
		"list[context;dst;4.75,0.96;2,2;]"..
		-- Player Inventory
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
end

--
-- Node callback functions that are the same for active and inactive furnace
--

local function can_dig(pos)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
end

local function allow_metadata_inventory_put(pos, listname, _, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "fuel" then
		if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
			if inv:is_empty("src") then
				meta:set_string("infotext", S("Advanced Furnace is empty"))
			end
			return stack:get_count()
		else
			return 0
		end
	elseif listname == "src" then
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, _, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, _, _, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function stop_furnace_sound(pos)
	local hash = minetest.hash_node_position(pos)
	local sound_ids = furnace_fire_sounds[hash]
	if sound_ids then
		for _, sound_id in ipairs(sound_ids) do
			minetest.sound_fade(sound_id, -1, 0)
		end
		furnace_fire_sounds[hash] = nil
	end
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function move_back(inv, listname)
	local invlist = inv:get_list(listname)
	local updated = false
	for i = #invlist, 1, -1 do
		if invlist[i]:is_empty() then
			local next_index, next_item
			for e = i, 1, -1 do
				next_item = invlist[e]
				if not next_item:is_empty() then
					next_index = e
					break
				end
			end
			if next_index then
				updated = true
				local temp = invlist[i]
				invlist[i] = invlist[next_index]
				invlist[next_index] = temp
			else
				break
			end
		end
	end
	if updated then
		inv:set_list(listname, invlist)
	end
end

local function crush_fuel(pos,inv, fuellist, fuel_time)
	local fuel,afterfuel
	fuel,afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})

	if fuel.time == 0 then
		-- No valid fuel in fuel list
		if fuel_time <= 0 then
			fuel_time = 0
		end
	else
		-- check if fuel is already full
		if fuel_time + fuel.time > fuel_totaltime then
			return fuel_time
		end
		-- prevent blocking of fuel inventory (for automatization mods)
		local is_fuel = minetest.get_craft_result({method = "fuel", width = 1, items = {afterfuel.items[1]:to_string()}})
		if is_fuel.time == 0 then
			table.insert(fuel.replacements, afterfuel.items[1])
			inv:set_stack("fuel", 1, "")
		else
			-- Take fuel from fuel list
			inv:set_stack("fuel", 1, afterfuel.items[1])
		end
		-- Put replacements in dst list or drop them on the furnace.
		local replacements = fuel.replacements
		if replacements[1] then
			local leftover = inv:add_item("dst", replacements[1])
			if not leftover:is_empty() then
				local above = vector.new(pos.x, pos.y + 1, pos.z)
				local drop_pos = minetest.find_node_near(above, 1, {"air"}) or above
				minetest.item_drop(replacements[1], nil, drop_pos)
			end
		end
		fuel_time = fuel.time + fuel_time
	end
	return fuel_time
end

local function furnace_node_timer(pos, elapsed)
	--
	-- Initialize metadata
	--
	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local src_time = meta:get_float("src_time") or 0

	local inv = meta:get_inventory()
	local srclist, fuellist
	local dst_full = false

	local timer_elapsed = meta:get_int("timer_elapsed") or 0
	meta:set_int("timer_elapsed", timer_elapsed + 1)

	local cookable, cooked

	local update = true
	while elapsed > 0 and update do
		update = false

		move_back(inv, "src")
		srclist = {inv:get_stack("src",3)}
		fuellist = inv:get_list("fuel")
		fuel_time = crush_fuel(pos, inv, fuellist, fuel_time)

		--
		-- Cooking
		--

		-- Check if we have cookable content
		local aftercooked
		cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
		cookable = cooked.time ~= 0

		local el = math.min(elapsed, fuel_time)
		if cookable then -- fuel lasts long enough, adjust el to cooking duration
			el = math.min(el, cooked.time - src_time)
		end

		-- Check if we have enough fuel to burn
		if el > 0 then
			-- The furnace is currently active and has enough fuel
			fuel_time = fuel_time - el
			-- If there is a cookable item then check if it is ready yet
			if cookable then
				src_time = src_time + el
				if src_time >= cooked.time then
					-- Place result in dst list if possible
					if inv:room_for_item("dst", cooked.item) then
						inv:add_item("dst", cooked.item)
						inv:set_stack("src", 3, aftercooked.items[1])
						src_time = src_time - cooked.time
						update = true
					else
						dst_full = true
					end
					-- Play cooling sound
					minetest.sound_play("default_cool_lava",
						{pos = pos, max_hear_distance = 16, gain = 0.07}, true)
				else
					-- Item could not be cooked: probably missing fuel
					update = true
				end
			end
		elseif fuel_time <= 0 then
			-- Furnace ran out of fuel
			src_time = math.max(src_time - el, 0)
		end
		elapsed = elapsed - el
	end

	if srclist and srclist[1]:is_empty() then
		src_time = 0
	end

	--
	-- Update formspec, infotext and node
	--
	local formspec
	local item_state
	local item_percent = 0
	if cookable then
		item_percent = math.floor(src_time / cooked.time * 100)
		if dst_full then
			item_state = S("100% (output full)")
		else
			item_state = S("@1%", item_percent)
		end
	else
		if srclist and not srclist[1]:is_empty() then
			item_state = S("Not cookable")
		else
			item_state = S("Empty")
		end
	end

	local fuel_state = S("Empty")
	local result = false
	local active

	if cookable and fuel_time > 0 then
		active = true
		local fuel_percent = math.floor(fuel_time / fuel_totaltime * 100)
		fuel_state = S("@1%", fuel_percent)
		formspec = get_furnace_formspec(true, fuel_time, item_percent)
		swap_node(pos, "useful_contraptions:lab_furnace_active")
		-- make sure timer restarts automatically
		result = true

		-- Play sound every 5 seconds while the furnace is active
		if timer_elapsed == 0 or (timer_elapsed + 1) % 5 == 0 then
			local sound_id = minetest.sound_play("default_furnace_active",
				{pos = pos, max_hear_distance = 16, gain = 0.25})
			local hash = minetest.hash_node_position(pos)
			furnace_fire_sounds[hash] = furnace_fire_sounds[hash] or {}
			table.insert(furnace_fire_sounds[hash], sound_id)
			-- Only remember the 3 last sound handles
			if #furnace_fire_sounds[hash] > 3 then
				table.remove(furnace_fire_sounds[hash], 1)
			end
			-- Remove the sound ID automatically from table after 11 seconds
			minetest.after(11, function()
				if not furnace_fire_sounds[hash] then
					return
				end
				for f=#furnace_fire_sounds[hash], 1, -1 do
					if furnace_fire_sounds[hash][f] == sound_id then
						table.remove(furnace_fire_sounds[hash], f)
					end
				end
				if #furnace_fire_sounds[hash] == 0 then
					furnace_fire_sounds[hash] = nil
				end
			end)
		end
	else
		local fuel_percent = math.floor(fuel_time / fuel_totaltime * 100)
		if fuel_percent > 0 or fuellist and not fuellist[1]:is_empty() then
			fuel_state = S("@1%", fuel_percent)
		end
		formspec = get_furnace_formspec(false, fuel_time, 0)
		swap_node(pos, "useful_contraptions:lab_furnace")
		fuellist = inv:get_list("fuel")
		local fuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})
		if fuel.time == 0 or fuel_totaltime < fuel_time + fuel.time then
			-- stop timer on the inactive furnace
			minetest.get_node_timer(pos):stop()
			meta:set_int("timer_elapsed", 0)
		else
			result = true
		end

		stop_furnace_sound(pos)
	end


	local infotext
	if active then
		infotext = S("Advanced Furnace active")
	else
		infotext = S("Advanced Furnace inactive")
	end
	infotext = infotext .. "\n" .. S("(Item: @1; Fuel: @2)", item_state, fuel_state)

	--
	-- Set meta values
	--
	meta:set_float("fuel_time", fuel_time)
	meta:set_float("src_time", src_time)
	meta:set_string("formspec", formspec)
	meta:set_string("infotext", infotext)

	return result
end

--
-- Node definitions
--

local lab_furnace_base = {
	description = S("Advanced Furnace"),
	paramtype2 = "facedir",
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-7/16, -1/2, -7/16, 7/16, 1/2, 1/2},
			{-1/2, -7/16, -7/16, 1/2, 7/16, 1/2},
			{-5/16, 0, -1/2, 5/16, 1/4, 3/8},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,0.5,0.5},
		}
	},
	on_timer = furnace_node_timer,
	can_dig = can_dig,
	preserve_metadata = function(_, _, oldmeta, drops)
		--TODO: check if the funace was dropped
		drops[1]:get_meta():set_float("fuel_time",oldmeta["fuel_time"])
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "src", drops)
		default.get_inventory_drops(pos, "fuel", drops)
		default.get_inventory_drops(pos, "dst", drops)
		drops[#drops+1] = "useful_contraptions:lab_furnace"
		minetest.remove_node(pos)
		return drops
	end,
	--pipeworks support
	after_dig_node = minetest.global_exists("pipeworks") and pipeworks.after_dig or nil,
	on_rotate = minetest.global_exists("pipeworks") and pipeworks.on_rotate or nil,
	tube = {
		insert_object = function(pos, _, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local timer = minetest.get_node_timer(pos)
			if not timer:is_started() then
				timer:start(1.0)
			end
			if direction.y == 1 then
				return inv:add_item("fuel", stack)
			else
				return inv:add_item("src", stack)
			end
		end,
		can_insert = function(pos, _, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if direction.y == 1 then
				return inv:room_for_item("fuel", stack)
			else
				return inv:room_for_item("src", stack)
			end
		end,
		input_inventory = "dst",
		connect_sides = {left = 1, right = 1, back = 1, bottom = 1, top = 1}
	},
}

minetest.register_node("useful_contraptions:lab_furnace", contraptions_mod.extend(lab_furnace_base, {
	tiles = {
		"contraptions_lab_furnace_side.png", "contraptions_lab_furnace_side.png",
		"contraptions_lab_furnace_side.png", "contraptions_lab_furnace_side.png",
		"contraptions_lab_furnace_back.png", "contraptions_lab_furnace_front.png"
	},
	groups = {cracky = 1, level = 2, tubedevice = 1, tubedevice_receiver = 1},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('src', 3)
		inv:set_size('fuel', 1)
		inv:set_size('dst', 4)
		furnace_node_timer(pos, 0)
	end,
	after_place_node = function(pos, _, itemstack)
		if minetest.global_exists("pipeworks") then
			pipeworks.after_place(pos)
		end
		local fuel_time = itemstack:get_meta():get_float("fuel_time") or 0
		local meta = minetest.get_meta(pos)
		meta:set_float("fuel_time", fuel_time)
		furnace_node_timer(pos, 0)
	end,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_take = function(pos)
		-- check whether the furnace is empty or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
}))

minetest.register_node("useful_contraptions:lab_furnace_active", contraptions_mod.extend(lab_furnace_base, {
	tiles = {
		"contraptions_lab_furnace_side.png", "contraptions_lab_furnace_side.png",
		"contraptions_lab_furnace_side.png", "contraptions_lab_furnace_side.png",
		"contraptions_lab_furnace_back.png",
		{
			image = "contraptions_lab_furnace_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	light_source = 8,
	drop = "useful_contraptions:lab_furnace",
	groups = {
		cracky = 1, level = 2,
		tubedevice = 1, tubedevice_receiver = 1,
		not_in_creative_inventory = 1
	},
	on_destruct = function(pos)
		stop_furnace_sound(pos)
	end,
}))

minetest.register_craft({
	output = "useful_contraptions:lab_furnace",
	recipe = {
		{"default:steel_ingot", "default:chest", "default:steel_ingot"},
		{"default:steel_ingot", "default:furnace", "default:steel_ingot"},
		{"default:steel_ingot", "factory:piston", "default:steel_ingot"},
	}
})

if minetest.global_exists("tubelib") then
	local function is_source(pos,meta,  item)
		local inv = minetest.get_inventory({type="node", pos=pos})
		local name = item:get_name()
		if meta:get_string("src_item") == name then
			return true
		elseif inv:get_stack("src", 1):get_name() == name then
			meta:set_string("src_item", name)
			return true
		end
		return false
	end

	tubelib.register_node("useful_contraptions:lab_furnace", {"useful_contraptions:lab_furnace_active"}, {
		on_pull_item = function(pos, side)
			local meta = minetest.get_meta(pos)
			return tubelib.get_item(meta, "dst")
		end,
		on_push_item = function(pos, side, item)
			local meta = minetest.get_meta(pos)
			minetest.get_node_timer(pos):start(1.0)
			if is_source(pos, meta, item) then
				return tubelib.put_item(meta, "src", item)
			elseif minetest.get_craft_result({method="fuel", width=1, items={item}}).time ~= 0 then
				return tubelib.put_item(meta, "fuel", item)
			else
				return tubelib.put_item(meta, "src", item)
			end
		end,
		on_unpull_item = function(pos, side, item)
			local meta = minetest.get_meta(pos)
			return tubelib.put_item(meta, "dst", item)
		end,
	})
end

