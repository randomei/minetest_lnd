
-- == Liquid features == --
-- Tank wagons can get support for Techage liquids.
-- advtrains provides a "Tank car filling spigot" and a "Tank car unloading funnel" which are placed above resp. below the tracks.
-- They act as proxy nodes from/to which liquids can be pumped using the Techage pumps
-- Note: for tank cars to support filling with liquid, add the "techage_liquid_capacity = <capacity_in_liquid_units>" property to the wagon definition.

-- Get Techage variables
local Pipe = techage.LiquidPipe
local liquid = networks.liquid

-- Nodes


-- checks for and gets a tank car at given reference position. Ref Pos must be the track this node relates to.
-- For a wagon to be valid it must be standing at the node in question
-- If found, returns liquid_info, capacity, wagon_id (where liquid_info is {name=..., amount=...} in same format as the techage tank nvms)
-- If not found, returns nil
local function get_tank_car_liquidinfo(ref_pos)
	local trains = advtrains.occ.get_trains_at(ref_pos)
	for train_id, index in pairs(trains) do
		local train = advtrains.trains[train_id]
		-- make sure that the train is stopped
		if train.velocity == 0 then
			local wagon_num, wid, data, offset_from_center = advtrains.get_wagon_at_index(train_id, index)
			if wagon_num and offset_from_center < 1 then
				-- this wagon is possibly a tank car. Check the wagon def
				local _, proto = advtrains.get_wagon_prototype(data)
				if proto.techage_liquid_capacity then
					-- Found a tank car. Get its liquid info from the data table, create it if necessary
					if not data.techage_liquid then
						data.techage_liquid = {}
					end
					return data.techage_liquid, proto.techage_liquid_capacity, wid
				end
			end
		end
	end
	return nil
end

local function loader_relpos(pos)
	return {x=pos.x, y=pos.y-3, z=pos.z}
end

local function tankcar_put_liquid(pos, name, amount)
	local lic, capa, wid = get_tank_car_liquidinfo(pos)
	if lic then
		if lic.name then
			if lic.name ~= name then
				-- different liquid than already in here - deny
				return amount
			end
			-- else add the amount
			lic.amount = lic.amount + amount
		else
			-- does not contain liquid yet, set name and amount to 0
			lic.name = name
			lic.amount = amount
		end
		--atdebug("tankcar_put_liquid: put",name,amount,", now contains ",lic)
		if lic.amount > capa then
			-- capacity was hit, reject too much liquid
			local reject = lic.amount - capa
			lic.amount = capa
			--atdebug("tankcar_put_liquid: over capa", capa, ", rejects ", reject)
			return reject
		end
		return 0
	end
	return amount
end


local function unloader_relpos(pos)
	return {x=pos.x, y=pos.y+1, z=pos.z}
end

local function tankcar_take_liquid(pos, name, amount)
	local lic, capa, wid = get_tank_car_liquidinfo(pos)
	if lic then
		if lic.name then
			-- note: name parameter may be nil (aka any), then do not prevent
			if name and lic.name ~= name then
				-- different liquid than already in here - deny
				return 0
			end
		else
			-- does not contain liquid, nothing to take
			return 0
		end
		if lic.amount <= amount then
			-- pumping last bit of liquid
			local rest, oldname = lic.amount, lic.name
			lic.amount = 0
			lic.name = nil -- reset the name since car is now empty
			--atdebug("tankcar_take_liquid: took",name,amount,", now empty")
			return rest, oldname
		end
		-- no underflow, subtract
		lic.amount = lic.amount - amount
		--atdebug("tankcar_take_liquid: took",name,amount,", now left ",lic)
		return amount, lic.name
	end
	return 0 -- no wagon here
end

minetest.register_node("advtrains_techage:liquid_loader", {
	description = attrans("Tank Car Filling Spigot"),
	tiles = {
		"advtrains_ta_spigot_back.png^[transformR180",
		"advtrains_ta_spigot_ahead.png",
		"advtrains_ta_spigot_side.png",
		"advtrains_ta_spigot_side.png^[transformR270",
		"advtrains_ta_spigot_ahead.png",
		"advtrains_ta_spigot_back.png",
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Pipe:after_dig_tube(pos, oldnode, oldmetadata)
	end,

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-1/8, -6/8,  -1/8, 1/8,  1/8,  1/8},
			{-2/8, -5/8,  -2/8, 2/8, -1/4,  2/8},
			{-1/8, -1/8,   1/8, 1/8,  1/8,  4/8},
			{-2/8, -2/8, 13/32, 2/8,  2/8,  1/2},
		},
	},
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {crumbly = 2, cracky = 2, snappy = 2},
	sounds = default.node_sound_metal_defaults(),
})

liquid.register_nodes({"advtrains_techage:liquid_loader"},
	Pipe, "tank", {"B"}, {
		capa = 42, -- capa is ignored by put function, but needs to be given anyway.
		peek = function(pos, indir) -- should provide the type of liquid anyway, because pump uses it to check whether it can pump here
			local lic, capa, wid = get_tank_car_liquidinfo(loader_relpos(pos))
			--atdebug("loader peeked: ", lic, capa)
			if lic and lic.name and lic.amount > 0 then
				return lic.name
			end
			return nil
		end,
		put = function(pos, indir, name, amount)
			return tankcar_put_liquid(loader_relpos(pos), name, amount)
		end,
		take = function(pos, indir, name, amount)
			return 0 -- cannot take anything from the loader
		end,
		untake = function(pos, indir, name, amount)
			return tankcar_put_liquid(loader_relpos(pos), name, amount)
		end,
	}
)

minetest.register_node("advtrains_techage:liquid_unloader", {
	description = attrans("Tank Car Unloading Drain Funnel"),
	tiles = {
		"advtrains_ta_spigot_ahead.png^[transformR180",
		"advtrains_ta_spigot_back.png",
		"advtrains_ta_spigot_side.png^[transformR90",
		"advtrains_ta_spigot_side.png^[transformR180",
		"advtrains_ta_spigot_ahead.png^[transformR180",
		"advtrains_ta_spigot_back.png^[transformR180",
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Pipe:after_dig_tube(pos, oldnode, oldmetadata)
	end,

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-1/8, -1/8, -1/8, 1/8, 5/8,  1/8},
			{-2/8,  1/4, -2/8, 2/8, 5/8,  2/8},
			{-1/8, -1/8,  1/8, 1/8, 1/8,  4/8},
			{-2/8, -2/8, 13/32, 2/8, 2/8, 4/8},
		},
	},
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {crumbly = 2, cracky = 2, snappy = 2},
	sounds = default.node_sound_metal_defaults(),
})

liquid.register_nodes({"advtrains_techage:liquid_unloader"},
	Pipe, "tank", {"B"}, {
		capa = 42,  -- capa is ignored by put function, but needs to be given anyway.
		peek = function(pos, indir)
			local lic, capa, wid = get_tank_car_liquidinfo(unloader_relpos(pos))
			--atdebug("unloader peeked: ", lic, capa)
			if lic and lic.name and lic.amount > 0 then
				return lic.name
			end
			return nil
		end,
		put = function(pos, indir, name, amount)
			return amount -- cannot put here
		end,
		take = function(pos, indir, name, amount)
			return tankcar_take_liquid(unloader_relpos(pos), name, amount)
		end,
		untake = function(pos, indir, name, amount)
			-- untake has to work like a put would!
			return tankcar_put_liquid(loader_relpos(pos), name, amount)
		end,
	}
)

minetest.register_craft({
	output = "advtrains_techage:liquid_loader",
	recipe = {
		{"techage:ta3_pipeS"},
		{"minecart:hopper"},
	},
})

minetest.register_craft({
	output = "advtrains_techage:liquid_unloader",
	recipe = {
		{"minecart:hopper"},
		{"techage:ta3_pipeS"},
	},
})
