---@param player ObjectRef
---@param show_objects boolean
---@param show_liquids boolean
---@return PointedThing|nil
function fbt.get_pointed_thing(player, show_objects, show_liquids)
	local eye_height = player:get_properties().eye_height or 1.625
  local eye_offset = player:get_eye_offset()
	local eye_pos = {
    x = eye_offset.x * 0.1,
    y = eye_height + eye_offset.y * 0.1,
    z = eye_offset.z * 0.1,
  }

	local pos1 = vector.add(player:getpos(), eye_pos)

	local wield_item = player:get_wielded_item()
	local tool_range = 4.0
	if wield_item:is_known() then
		tool_range = wield_item:get_definition().range or 4.0
	end

	local look_dir = player:get_look_dir()
	local pos2 = vector.add(pos1, vector.multiply(look_dir, tool_range))

  local raycast = minetest.raycast(pos1, pos2, show_objects, show_liquids)
	local pointed = raycast:next()
	-- Skip the player selection box
	if pointed and pointed.type == "object" and pointed.ref == player then
		pointed = raycast:next()
	end
	return pointed
end


---@param player ObjectRef
---@param show_objects boolean
---@param show_liquids boolean
---@return NodeTable|nil
function fbt.get_pointed_node(player, show_objects, show_liquids)
  local pointed_thing = fbt.get_pointed_thing(
    player, show_objects, show_liquids)
  if pointed_thing == nil then
    return nil
  else
    return minetest.get_node_or_nil(pointed_thing.under)
  end
end


---@type table<string, boolean>
local cubic_icon = {
  normal = true,
  allfaces = true,
  allfaces_optional = true,
  glasslike = true,
  glasslike_framed = true,
  glasslike_framed_optional = true,
}

---@param node_def NodeDef
---@return string
function fbt.node_icon(node_def)
  ---@type string
  local img = ""
  if cubic_icon[node_def.drawtype] then
    img = fbt.node_cube(node_def)
  else
    img = node_def.tiles[1]
    if type(img) == "table" then img = img.name end
  end

  if type(img) ~= "string" or img == "" then
    return ""
  else
    return img .. "^[resize:64x64"
  end
end


---@param node_def NodeDef
---@return string
function fbt.node_cube(node_def)
  ---@type table
  local tiles = node_def.tiles
  for i,tile in pairs(tiles) do
    if type(tile) == "table" then
      tiles[i] = tile.name
    end
  end

  if #tiles == 1 then
    local tile = tiles[1]
    tiles = {tile, tile,  tile, tile,  tile, tile}
  elseif #tiles == 2 then
    local tile = tiles[1]
    tiles = {tile, tiles[2],  tile, tile,  tile, tile}
  elseif #tiles == 3 then
    tiles = {tiles[1], tiles[2],  tiles[3], tiles[3],  tiles[3], tiles[3]}
  elseif #tiles == 4 then
    tiles = {tiles[1], tiles[2],  tiles[3], tiles[4],  tiles[3], tiles[4]}
  -- else if #tiles == 5 then
  --   tiles = {tiles[1], tiles[2],  tiles[3], tiles[4],  tiles[5], tiles[4]}
  end

  -- local overlay_tiles = node_def.overlay_tiles
  -- local special_tiles = node_def.special_tiles
  -- local color = node_def.color

  return minetest.inventorycube(tiles[1], tiles[4], tiles[5])
end


---@param s string
---@return boolean
function fbt.nil_or_empty(s)
  return s == nil or s == ""
end


---@param str string
---@return integer
function fbt.utf8_len(s)
  local len = 0
  local i = 1
  local byte_count = #s

  -- minetest.log(string.format("finding the length of %s", s))
  while i <= byte_count do
    local byte = string.byte(s, i)
    -- minetest.log(dump({
    --   i, byte, string.char(byte)
    -- }))
    -- minetest.log(string.format(
      -- "s[%d] = %d (%s) | len: %d", i, byte, string.char(byte), len))
    if byte == 0 then
      return len
    elseif byte < 32 then
      i = i + 1
      len = len - 1
    elseif byte < 128 then
      i = i + 1
    elseif byte < 192 then
      return nil -- Invalid UTF-8 sequence
    elseif byte < 224 then
      i = i + 2
    elseif byte < 240 then
      i = i + 3
    elseif byte < 248 then
      i = i + 4
    else
        return nil -- Invalid UTF-8 sequence
    end
    len = len + 1
  end

  -- minetest.log(string.format("the length is %d", len))
  return len
end

