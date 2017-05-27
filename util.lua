-- Boilerplate to support localized strings if intllib mod is installed.
if minetest.get_modpath( "intllib" ) and intllib then
	contraptions_mod.S = intllib.Getter()
else
	contraptions_mod.S = function(s) return s end
end

--tube injection function
if pipeworks then
  if pipeworks.tube_inject_item then
    contraptions_mod.tube_inject_item = pipeworks.tube_inject_item
  else
    function contraptions_mod.tube_inject_item(pos, start_pos, velocity, item)
        local stack = ItemStack(item)
	local obj = luaentity.add_entity(pos, "pipeworks:tubed_item")
	obj:set_item(stack:to_string())
	obj.start_pos = vector.new(start_pos)
	obj:setvelocity(velocity)
	return obj
    end
  end
end

--useful formspec helpers

function string.startswith(str, substr)
	return str:sub(1, substr:len()) == substr
end

fs_helpers = fs_helpers or {}
function fs_helpers.on_receive_fields(pos, fields)
	local meta = minetest.get_meta(pos)
	for field, value in pairs(fields) do
		if field:startswith("fs_helpers_cycling:") then
			local l = field:split(":")
			local new_value = tonumber(l[2])
			local meta_name = l[3]
			meta:set_int(meta_name, new_value)
		end
	end
end

function fs_helpers.cycling_button(meta, base, meta_name, values)
	local current_value = meta:get_int(meta_name)
	local new_value = (current_value + 1) % (#values)
	local val = values[current_value + 1]
	local text
	local texture_name = nil
	local addopts = nil
	--when we get a table, we know the caller wants an image_button
	if type(val) == "table" then
		text = val["text"]
		texture_name = val["texture"]
		addopts = val["addopts"]
	else
		text = val
	end
	local field = "fs_helpers_cycling:"..new_value..":"..meta_name
	return base..";"..(texture_name and texture_name..";" or "")..field..";"..minetest.formspec_escape(text)..(addopts and ";"..addopts or "").."]"
end

function contraptions_mod.get_objects_with_square_radius(pos, rad)
  rad = rad + 0.5
  local objs = {}
  for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, math.sqrt(3)*rad)) do
    if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
      local opos = object:getpos()
      if pos.x - rad <= opos.x and opos.x <= pos.x + rad and pos.y - rad <= opos.y and opos.y <= pos.y + rad and pos.z - rad <= opos.z and opos.z <= pos.z + rad then
        objs[#objs + 1] = object
      end
    end
  end
  return objs
end