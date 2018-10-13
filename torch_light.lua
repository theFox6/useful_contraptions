local function check_for_torch(player)
	if player==nil then return false end
	if player:get_wielded_item():get_name() == "default:torch" then
			return true
	end
	return false
end

minetest.register_on_joinplayer(function(player)
	player:get_meta():set_string("torch_wielded","false")
end)

minetest.register_globalstep(function()
	for _,player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()
		if check_for_torch(player) then
			if player:get_meta():get_string("torch_wielded")~="true" then
				--add glow
				player:set_properties({glow=14})
				player:get_meta():set_string("torch_wielded","true")
			end
		elseif player:get_meta():get_string("torch_wielded")=="true" then
			--remove glow
			player:set_properties({glow=0})
			player:get_meta():set_string("torch_wielded","false")
		end
	end
end)
