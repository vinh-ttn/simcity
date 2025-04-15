Include("\\script\\lib\\timerlist.lua")



function ComputeWalkGraph(worldMap)
	local walkPaths = worldMap.walkPaths
	-- Store all exact points (priority points) first
	local exactPoints = {}
	local normalPoints = {}
	
	-- Separate exact points and normal points
	local i, j
	for pathName, path in walkPaths do
		for j = 1, getn(path) do
			local point = path[j]
			if point[3] and point[3] == 1 then
				tinsert(exactPoints, {point[1], point[2], 1})
			else
				tinsert(normalPoints, {point[1], point[2]})
			end
		end
	end

	-- Process normal points and snap to exact points if within radius
	local SNAP_RADIUS = 5 -- Adjust this value as needed
	local processedPoints = {}
	local graph = {
		nodes = {},  -- Store node coordinates
		edges = {},   -- Store connections

		foundDialogNpc = {}
	}
	
	-- First add all exact points to processed
	for i = 1, getn(exactPoints) do
		local ep = exactPoints[i]
		tinsert(processedPoints, ep)
		local nodeKey = ep[1] .. "_" .. ep[2]
		graph.nodes[nodeKey] = ep
		graph.edges[nodeKey] = {}
	end
	
	-- Process normal points
	for i = 1, getn(normalPoints) do
		local np = normalPoints[i]
		local snapped = nil
		
		-- Check if point should snap to any exact point
		for j = 1, getn(exactPoints) do
			local ep = exactPoints[j]
			if GetDistanceRadius(np[1], np[2], ep[1], ep[2]) <= SNAP_RADIUS then
				snapped = ep
				break
			end
		end
		
		-- If no exact point to snap to, check other normal points
		if not snapped then
			for j = 1, getn(processedPoints) do
				local pp = processedPoints[j]
				if GetDistanceRadius(np[1], np[2], pp[1], pp[2]) <= SNAP_RADIUS then
					snapped = pp
					break
				end
			end
		end
		
		-- If no snap point found, use original point
		if not snapped then
			snapped = {np[1], np[2]}
			tinsert(processedPoints, snapped)
		end
		
		-- Initialize graph node if not exists
		local nodeKey = snapped[1] .. "_" .. snapped[2]
		if not graph.nodes[nodeKey] then
			graph.nodes[nodeKey] = snapped
			graph.edges[nodeKey] = {}
		end
	end
	
	-- Build connections between points based on original paths
	for pathName, path in walkPaths do
		for j = 1, getn(path)-1 do
			local p1 = path[j]
			local p2 = path[j+1]
			
			-- Find corresponding processed points
			local pp1, pp2 = nil, nil
			
			for k = 1, getn(processedPoints) do
				local pp = processedPoints[k]
				if GetDistanceRadius(p1[1], p1[2], pp[1], pp[2]) <= SNAP_RADIUS then
					pp1 = pp
				end
				if GetDistanceRadius(p2[1], p2[2], pp[1], pp[2]) <= SNAP_RADIUS then
					pp2 = pp
				end
				if pp1 and pp2 then break end
			end
			
			-- Add bidirectional connection
			if pp1 and pp2 then
				local key1 = pp1[1] .. "_" .. pp1[2]
				local key2 = pp2[1] .. "_" .. pp2[2]
				
				-- Check if connection already exists
				local found = nil
				for k = 1, getn(graph.edges[key1]) do
					if graph.edges[key1][k] == key2 then
						found = 1
						break
					end
				end
				
				if not found then
					tinsert(graph.edges[key1], key2)
					tinsert(graph.edges[key2], key1)
				end
			end
		end
	end
	worldMap.walkGraph = graph
	return worldMap.walkGraph
end




SimCityWorld = {
	data = {},
	trangtri = {}
}

function SimCityWorld:New(data)
	if not data then
		return nil
	end
	if self.data["w" .. data.worldId] == nil then
		data.showingId = 0
		data.allowFighting = 1
		data.allowChat = 1
		data.showFightingArea = 1
		data.showName = 1
		data.showDecoration = 0
		data.name = data.name or ""
		data.walkPaths = data.walkPaths or {}
		data.decoration = data.decoration or {}
		data.chientranh = data.chientranh or {}

		data.tick = 0
		data.announceBXHTick = 3
		
		self.data["w" .. data.worldId] = data
		return self.data["w" .. data.worldId]
	end
	return self.data["w" .. data.worldId]
end

function SimCityWorld:Get(nW)
	if self.data["w" .. nW] ~= nil and self.data["w" .. nW] ~= nil then
		return self.data["w" .. nW]
	else
		return {}
	end
end

function SimCityWorld:Update(nW, key, value)
	local data = self:Get(nW)
	data[key] = value
end

function SimCityWorld:ShowTrangTri(nW, show)
	local info = self:Get(nW)
	local fighter = self.trangtri["w" .. nW]
	-- Establish data
	if not fighter then
		self.trangtri["w" .. nW] = {
			result = {},
			isShowing = 0
		}
		fighter = self.trangtri["w" .. nW]
	end

	-- Show but not showing? Create it
	if show == 1 and fighter.isShowing == 0 then
		for i = 1, getn(info.decoration) do
			local item = info.decoration[i]
			local id = item[1]
			local nX = item[2]
			local nY = item[3]
			local name = item[4]
			if not name then
				name = " "
			end
			local index = AddNpcEx(id, 1, 5, SubWorldID2Idx(nW), nX * 32, nY * 32, 1, name, 0)
			tinsert(fighter.result, index)

			SetNpcAI(index, 0)
		end
		fighter.isShowing = 1
		info.showDecoration = 1

		-- Dont want to show but showing? Delete it
	elseif show == 0 and fighter.isShowing == 1 then
		for i = 1, getn(fighter.result) do
			DelNpc(fighter.result[i])
		end
		fighter.result = {}
		fighter.isShowing = 0
		info.showDecoration = 0
	end
end

function SimCityWorld:initThanhThi()
	for worldId, worldInfo in SimCityMap do
		local targetMap = self:New(worldInfo)		
		ComputeWalkGraph(targetMap)
	end
end

function SimCityWorld:doShowBXH(mapID)
	SimCitizen:ThongBaoBXH(mapID)
end

function SimCityWorld:IsTongKimMap(nW)
	if nW == 380 or nW == 378 or nW == 379 then
		return 1
	end
	return 0
end

function SimCityWorld:IsThanhThiMap(pW)
	if pW == 37 or pW == 78 or pW == 176 or pW == 162 or pW == 80 or pW == 1 then
		return 1
	end
	return 0
end

function SimCityWorld:ATick()
	for wId, worldInfo in self.data do
		worldInfo.tick = worldInfo.tick + 1
		if worldInfo.showBXH == 1 and mod(worldInfo.tick, worldInfo.announceBXHTick) == 0 then
			self:doShowBXH(worldInfo.worldId)
		end
	end
end
