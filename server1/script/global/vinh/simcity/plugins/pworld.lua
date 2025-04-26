Include("\\script\\lib\\timerlist.lua")

SimCityWorld = {
	data = {},
	trangtri = {}
}

function SimCityWorld:modifyTongKimMap(data)
	if self:IsTongKimMap(data.worldId) == 0 then
		return
	end

	data.name = "Tèng Kim"
	data.showFightingArea = 0
	data.showThangCap = 1
	data.showBXH = 1
	data.announceBXHTick = 1 
	data.isTongKim = 1

	-- Tong Kim bao ve nguyen soai
	if data.worldId == 380 or data.worldId == 378 or data.worldId == 379 then

		-- Clear out all nodes
		data.nodes = {}
		data.presetPaths = {}

		-- Add the nodes of map 10000
		for k,v in SimCityMap[10000].nodes do				
			data.nodes[k] = {
				nodeType = 1,
				x = v.x,
				y = v.y,
				linkedNodes = v.linkedNodes,
				isExact = v.isExact,
				isNearAtraction = v.isNearAtraction,
			}
		end

		data.firstNode = SimCityMap[10000].firstNode

		-- Add haudoanh1 and haudoanh2
		data.presetPaths.haudoanh1 = SimCityMap[10000].presetPaths.haudoanh1
		data.presetPaths.haudoanh2 = SimCityMap[10000].presetPaths.haudoanh2
		data.presetPaths.campduoi = SimCityMap[10000].presetPaths.campduoi
		data.presetPaths.camptren = SimCityMap[10000].presetPaths.camptren
		data.presetPaths.baseDuoi = {"campduoi"}
		data.presetPaths.baseTren = {"camptren"}

		-- Chien tranh paths
		data.chienTranhPaths = 1
		local path1 = { "huong1phai", "huong1trai", "huong1giua", "duoitrai", "duoiphai", "duoigiua" }
		local path2 = { "huong2phai", "huong2trai", "huong2giua", "trentrai1", "trentrai2", "trenphai", "trengiua" }
		

		data.builtPaths["campduoi_camptren"] = {}

		-- Add all path combinations to presetPaths
		for i = 1, getn(path1) do
			for j = 1, getn(path2) do
				local pathName = path1[i] .. "_" .. path2[j]
				data.presetPaths[pathName] = {}
				
				-- Add nodes from path1
				for k=1, getn(SimCityMap[10000].presetPaths[path1[i]]) do
					tinsert(data.presetPaths[pathName], SimCityMap[10000].presetPaths[path1[i]][k])
				end
				
				-- Add nodes from path2  
				for k=1, getn(SimCityMap[10000].presetPaths[path2[j]]) do
					tinsert(data.presetPaths[pathName], SimCityMap[10000].presetPaths[path2[j]][k])
				end 

				tinsert(data.builtPaths["campduoi_camptren"], pathName)
			end
		end
	end

	-- Map: phong hoa lien thanh
	if data.worldId == 580 or data.worldId == 581 then
		
		tinsert(data.presetPaths.baseTren, "thuthanhtrai")
		tinsert(data.presetPaths.baseTren, "thuthanhphai")
		tinsert(data.presetPaths.baseTren, "thuthanhgiua")

		tinsert(data.presetPaths.baseTren, "camptrentrai")
		tinsert(data.presetPaths.baseTren, "camptrenphai")

		data.teamRatio = 0.8 --80% team 1, 20% team 2
 
		data.restrictedSpawns = {
			camptren = {
				["thuthanhtrai"] = 1,
				["thuthanhphai"] = 1,
				["thuthanhgiua"] = 1
			}
		}
	end
end
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
		data.decoration = data.decoration or {}
		data.tick = 0
		data.tick_showBXH = 0
		data.announceBXHTick = 3
		data.playerTracker = {}
		data.playerTrackerCount = 0
		data.builtPaths = {}
		data.restrictedSpawns = {}

		-- Tong Kim map?
		self:modifyTongKimMap(data)

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
			DelNpcSafe(fighter.result[i])
		end
		fighter.result = {}
		fighter.isShowing = 0
		info.showDecoration = 0
	end
end
function SimCityWorld:initThanhThi()
	for worldId, worldInfo in SimCityMap do
		self:New(worldInfo)
	end
end

function SimCityWorld:doShowBXH(mapID)
	SimCitizen:ThongBaoBXH(mapID)
end

function SimCityWorld:IsTongKimMap(nMapID)
	local tWorldMapIDs = {
        [375] = 1,
        [376] = 1,
        [377] = 1,
        [378] = 1,
        [379] = 1,
        [380] = 1,
        [381] = 1,
        [382] = 1,
        [383] = 1,
        [384] = 1,
        [385] = 1,
        [386] = 1,
		[580] = 1,
		[581] = 1,
        [868] = 1,
        [869] = 1,
        [870] = 1,
        [883] = 1,
        [884] = 1,
        [885] = 1,
        [900] = 1,
        [902] = 1,
        [903] = 1,
        [904] = 1
    }
    
    -- Check if the input map ID exists in our table
    if tWorldMapIDs[nMapID] then
        return 1
    else
        return 0
    end 
end

function SimCityWorld:IsThanhThiMap(pW)
	if pW == 37 or pW == 78 or pW == 176 or pW == 162 or pW == 80 or pW == 1 then
		return 1
	end
	return 0
end

function SimCityWorld:ATick(tickRate)
	local rate = tickRate or 1
	for wId, worldInfo in self.data do		
		worldInfo.tick = worldInfo.tick + 1*rate

		if worldInfo.showBXH == 1 then
			if (worldInfo.tick_showBXH < worldInfo.tick) then
				worldInfo.tick_showBXH = worldInfo.tick + worldInfo.announceBXHTick*60*18/REFRESH_RATE
				self:doShowBXH(worldInfo.worldId)
			end
		end
	end
end
