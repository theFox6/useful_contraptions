contraptions_mod.torch_light = {}
contraptions_mod.torch_light.players = {}
contraptions_mod.torch_light.player_positions = {}
contraptions_mod.torch_light.torch_wielded = {}

function check_for_torch(player)
	if player==nil then return false end
	if player:get_wielded_item():get_name() == "default:torch" then
			return true
	end
	return false
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	table.insert(contraptions_mod.torch_light.players, player_name)
	contraptions_mod.torch_light.torch_wielded[player_name] = check_for_torch(player)
	local pos = player:getpos()
	local rounded_pos = vector.round(pos)
	rounded_pos.y = rounded_pos.y + 1
	if not check_for_torch(player) then
		minetest.add_node(rounded_pos,{type="node",name="air"})
	end
	contraptions_mod.torch_light.player_positions[player_name] = vector.new(rounded_pos)
end)

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	for i,v in ipairs(contraptions_mod.torch_light.players) do
		if v == player_name then
			local old_pos = contraptions_mod.torch_light.player_positions[player_name]
			local is_light = minetest.get_node_or_nil(old_pos)
			if is_light ~= nil and is_light.name == "useful_contraptions:light" then
				minetest.add_node(old_pos,{type="node",name="air"})
			end
			table.remove(contraptions_mod.torch_light.players, i)
			contraptions_mod.torch_light.torch_wielded[player_name] = nil
			contraptions_mod.torch_light.player_positions[player_name] = nil
		end
	end
end)

minetest.register_globalstep(function()
	for _,player_name in ipairs(contraptions_mod.torch_light.players) do
		local player = minetest.get_player_by_name(player_name)
		if check_for_torch(player) then
			local pos = player:getpos()
			local rounded_pos = vector.round(pos)
			rounded_pos.y = rounded_pos.y + 1
			if not(contraptions_mod.torch_light.torch_wielded[player_name]) or
			not(vector.equals(contraptions_mod.torch_light.player_positions[player_name],rounded_pos)) then
				local is_air  = minetest.get_node_or_nil(rounded_pos)
				if is_air == nil or (is_air ~= nil and (is_air.name == "air" or is_air.name == "useful_contraptions:light")) then
					minetest.add_node(rounded_pos,{type="node",name="useful_contraptions:light"})
				end
				if not vector.equals(contraptions_mod.torch_light.player_positions[player_name],rounded_pos) then
					local old_pos = vector.new(contraptions_mod.torch_light.player_positions[player_name])
					local is_light = minetest.get_node_or_nil(old_pos)
					if is_light ~= nil and is_light.name == "useful_contraptions:light" then
						minetest.add_node(old_pos,{type="node",name="air"})
					end
				end
				contraptions_mod.torch_light.player_positions[player_name] = vector.new(rounded_pos)
			end
				contraptions_mod.torch_light.torch_wielded[player_name] = true;
		elseif contraptions_mod.torch_light.torch_wielded[player_name] then
			local pos = player:getpos()
			local rounded_pos = vector.round(pos)
			rounded_pos.y = rounded_pos.y + 1
			repeat
				local is_light  = minetest.get_node_or_nil(rounded_pos)
				if is_light ~= nil and is_light.name == "useful_contraptions:light" then
					minetest.add_node(rounded_pos,{type="node",name="air"})
				end
			until minetest.get_node_or_nil(rounded_pos) ~= "useful_contraptions:light"
			local old_pos = vector.new(contraptions_mod.torch_light.player_positions[player_name])
			repeat
				local is_light  = minetest.get_node_or_nil(old_pos)
				if is_light ~= nil and is_light.name == "useful_contraptions:light" then
					minetest.add_node(old_pos,{type="node",name="air"})
				end
			until minetest.get_node_or_nil(old_pos) ~= "useful_contraptions:light"
			contraptions_mod.torch_light.torch_wielded[player_name] = false
		end
	end
end)

minetest.register_node("useful_contraptions:light", {
	drawtype = "airlike",
	inventory_image = "factory_transparent.png",
	paramtype = "light",
	walkable = false,
	pointable = false,
	light_propagates = true,
	sunlight_propagates = true,
	buildable_to = true,
	light_source = 11,
})