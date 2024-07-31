--Include("\\script\\global\\vinh\\simcity\\head.lua")
Include("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua")
SimCityMainThanhThi = {
	_dataStorage = {},
	worldStatus = {},
	autoAddThanhThi = STARTUP_AUTOADD_THANHTHI
}

SimCityWorld:initThanhThi()

function SimCityMainThanhThi:_createSingle(id, Map, config)
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)
	local kind = 4


	local hardsetName = (config.ngoaitrang and config.ngoaitrang == 1 and SimCityPlayerName:getName()) or
		SimCityNPCInfo:getName(id)

	local nListId = GroupFighter:New({


		nNpcId = id, -- required, main char ID
		nMapId = Map, -- required, map
		walkMode = "random",
		walkVar = 3,
		kind = kind,
		CHANCE_ATTACK_PLAYER = CHANCE_ATTACK_PLAYER, -- co hoi tan cong nguoi choi neu di ngang qua
		attackNpcChance = CHANCE_AUTO_ATTACK,  -- co hoi bat chien dau
		CHANCE_ATTACK_NPC = CHANCE_ATTACK_NPC, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		ngoaitrang = config.ngoaitrang or 0,
		noRevive = 0,
		hardsetName = hardsetName,
		mode = "thanhthi",
		lastHP = 500000,
		level = config.level or 95

	})

	if nListId > 0 then
		if (not self._dataStorage["n" .. nW]) then
			self._dataStorage["n" .. nW] = {}
		end
		tinsert(self._dataStorage["n" .. nW], nListId)
	end
end

function SimCityMainThanhThi:_createTeamPatrol(nW, thonglinh, linh, N, path)
	local children5 = {}
	N = N or 16
	for i = 1, N do
		tinsert(children5, { nNpcId = linh })
	end


	local nListId = GroupFighter:New({
		nNpcId = thonglinh,   -- required, main char ID
		nMapId = nW,          -- required, map
		camp = 0,             -- optional, camp
		children = children5, -- optional, children
		walkMode = 1,         -- optional: random or 1 for formation
		tbPos = path,
		noStop = 1,           -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 0, -- optional: leave fight instantly after no enemy, otherwise there's waiting period
		noRevive = 0,         -- optional: 0: keep reviving, 1: dead
		CHANCE_ATTACK_PLAYER = nil, -- co hoi tan cong nguoi choi neu di ngang qua
		attackNpcChance = nil, -- co hoi bat chien dau ~= 0 vi day la linh di tuan
		CHANCE_ATTACK_NPC = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		kind = 4

	})

	if nListId > 0 then
		if (not self._dataStorage["n" .. nW]) then
			self._dataStorage["n" .. nW] = {}
		end
		tinsert(self._dataStorage["n" .. nW], nListId)
	end
end

function SimCityMainThanhThi:CreatePatrol(nW)
	local nA, nX, nY = GetWorldPos()

	nW = nW or nA


	local worldInfo = SimCityWorld:Get(nW)

	local allMap = worldInfo.walkAreas

	local linh = 682

	-- Them cho Tuong Duong
	if nW == 78 or nW == 37 then
		if nW == 37 then
			linh = 688
		end
		for i = 1, getn(allMap) do
			self:_createTeamPatrol(nW, linh + 2, linh, 6, allMap[i])
		end


		-- Pho tuong + 9 binh
		self:_createTeamPatrol(nW, linh + 3, linh, 6, allMap[1])
		self:_createTeamPatrol(nW, linh + 3, linh, 6, allMap[4])


		-- Dai Tuong
		self:_createTeamPatrol(nW, linh + 4, linh, 9, allMap[2])
		self:_createTeamPatrol(nW, linh + 5, linh + 1, 9, allMap[2])
	end
end

function SimCityMainThanhThi:_clearMap(nW)
	if (not self._dataStorage["n" .. nW]) then
		self._dataStorage["n" .. nW] = {}
	end
	local tbl = self._dataStorage["n" .. nW]
	for i = 1, getn(tbl) do
		GroupFighter:ClearMap(nW, tbl[i])
	end
end

function SimCityMainThanhThi:createNpcSet(startNPCIndex, perPage, ngoaitrang)
	local mapID, nX, nY = GetWorldPos()

	for i = 0, perPage do
		local id = startNPCIndex + i
		self:_createSingle(id, mapID, { ngoaitrang = ngoaitrang or 0 })
	end
end

function SimCityMainThanhThi:removeAll()
	local nW, nX, nY = GetWorldPos()
	self:_clearMap(nW)
end

-- MAIN DIALOG FUNCTIONS
function SimCityMainThanhThi:showhideNpcId(show)
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:Update(nW, "showingId", show)
	self:caidat()
end

function SimCityMainThanhThi:allowFighting(show)
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:Update(nW, "allowFighting", show)
	self:thanhthiMenu()
end

function SimCityMainThanhThi:allowChat(show)
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:Update(nW, "allowChat", show)
	self:caidat()
end

function SimCityMainThanhThi:showFightingArea(show)
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:Update(nW, "showFightingArea", show)
	self:caidat()
end

function SimCityMainThanhThi:showName(show)
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:Update(nW, "showName", show)
	self:caidat()
end

function SimCityMainThanhThi:showDecoration(show)
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:ShowTrangTri(nW, show)
	self:caidat()
end

function SimCityMainThanhThi:caidat()
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)

	local tbSay = { worldInfo.name .. " Vâ L©m §¹i Héi - Bang lÖnh" }


	if getn(worldInfo.decoration) >= 1 then
		if worldInfo.showDecoration == 0 then
			tinsert(tbSay, "Më héi chî [kh«ng]/#SimCityMainThanhThi:showDecoration(1)")
		else
			tinsert(tbSay, "Më héi chî [cã]/#SimCityMainThanhThi:showDecoration(0)")
		end
	end


	if worldInfo.allowChat == 1 then
		tinsert(tbSay, "Trß chuyÖn [cã]/#SimCityMainThanhThi:allowChat(0)")
	else
		tinsert(tbSay, "Trß chuyÖn [kh«ng]/#SimCityMainThanhThi:allowChat(1)")
	end

	if worldInfo.showFightingArea == 1 then
		tinsert(tbSay, "Th«ng b¸o n¬i ®¸nh nhau [cã]/#SimCityMainThanhThi:showFightingArea(0)")
	else
		tinsert(tbSay, "Th«ng b¸o n¬i ®¸nh nhau [kh«ng]/#SimCityMainThanhThi:showFightingArea(1)")
	end

	if worldInfo.showingId == 1 then
		tinsert(tbSay, "H« sè b¸o danh [cã]/#SimCityMainThanhThi:showhideNpcId(0)")
	else
		tinsert(tbSay, "H« sè b¸o danh [kh«ng]/#SimCityMainThanhThi:showhideNpcId(1)")
	end


	if worldInfo.showName == 1 then
		tinsert(tbSay, "Tªn [tù ®éng]/#SimCityMainThanhThi:showName(0)")
	else
		tinsert(tbSay, "Tªn [t¾t]/#SimCityMainThanhThi:showName(1)")
	end

	tinsert(tbSay, "Quay l¹i/main")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityMainThanhThi:createNpcCustomAsk()
	g_AskClientStringEx(GetStringTask(TASK_S_POSITION), 0, 256, "<ID> <Sè L­îng>", { self.askNo_confirm, { self } })
end

function SimCityMainThanhThi:askNo_confirm(inp)
	local szCode = split(inp, " ")
	local perPage = 1
	local id = tonumber(szCode[1])
	if szCode[2] ~= nil and szCode[2] ~= "" then
		perPage = tonumber(szCode[2])
	end

	local mapID, nX, nY = GetWorldPos()
	for i = 0, perPage do
		self:_createSingle(id, mapID)
	end
end

function SimCityMainThanhThi:goiAnhHungThiepNgoaiTrang()
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)


	local tbSay = { worldInfo.name .. " Vâ L©m §¹i Héi" }
	tinsert(tbSay, "S¬ cÊp/#SimCityMainThanhThi:createNpcSoCap()")
	tinsert(tbSay, "Trung cÊp/#SimCityMainThanhThi:createNpcSet(500,500,1)")
	tinsert(tbSay, "Cao cÊp 1/#SimCityMainThanhThi:createNpcSet(1000,500,1)")
	tinsert(tbSay, "Cao cÊp 2/#SimCityMainThanhThi:createNpcSet(1500,500,1)")
	tinsert(tbSay, "Cao cÊp 3/#SimCityMainThanhThi:createNpcSet(2000,500,1)")

	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityMainThanhThi:goiAnhHungThiep()
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)


	local tbSay = { worldInfo.name .. " Vâ L©m §¹i Héi" }
	tinsert(tbSay, "Cao cÊp 1/#SimCityMainThanhThi:createNpcSet(1000,500)")
	tinsert(tbSay, "Cao cÊp 2/#SimCityMainThanhThi:createNpcSet(1500,500)")
	tinsert(tbSay, "Cao cÊp 3/#SimCityMainThanhThi:createNpcSet(2000,500)")
	tinsert(tbSay, "Trung cÊp/#SimCityMainThanhThi:createNpcSet(500,500)")
	--tinsert(tbSay, "Tù chän/#SimCityMainThanhThi:createNpcCustomAsk()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityMainThanhThi:thanhthiMenu()
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)

	if not worldInfo.name then
		Say(
			"TriÖu MÉn: thµnh thÞ nµy ch­a ®­îc më.<enter><enter>C¸c h¹ cã thÓ ®ãng gãp <color=yellow>b¶n ®å ®­îc ®­êng ®i<color> ®Õn t¸c gi¶ trªn fb héi qu¸n kh«ng?")
	else
		local tbSay = { "ThiÕt lËp "..worldInfo.name }

		if worldInfo.allowFighting == 1 then
			tinsert(tbSay, "Cho phÐp ®¸nh nhau [cã]/#SimCityMainThanhThi:allowFighting(0)")
		else
			tinsert(tbSay, "Cho phÐp ®¸nh nhau [kh«ng]/#SimCityMainThanhThi:allowFighting(1)")
		end

		tinsert(tbSay, "Thªm anh hïng/#SimCityMainThanhThi:goiAnhHungThiepNgoaiTrang()")
		tinsert(tbSay, "Thªm qu¸i nh©n/#SimCityMainThanhThi:goiAnhHungThiep()")
		tinsert(tbSay, "Thªm quan binh/#SimCityMainThanhThi:CreatePatrol()")
		tinsert(tbSay, "ThiÕt lËp kh¸c/#SimCityMainThanhThi:caidat()")
		tinsert(tbSay, "Gi¶i t¸n/#SimCityMainThanhThi:removeAll()")
		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbSay)
	end
	return 1
end

function SimCityMainThanhThi:mainMenu()
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)
	SimCityChienTranh:modeTongKim(0, 0)
	SimCityChienTranh.nW = nW

	if nW == 380 or nW == 378 or nW == 379 then
		return SimCityMainTongKim:mainMenu()
	end
	
	if not worldInfo.name then
		Say(
			"TriÖu MÉn: b¶n ®å nµy ch­a ®­îc më.<enter><enter>C¸c h¹ cã thÓ ®ãng gãp <color=yellow>b¶n ®å ®­îc ®­êng ®i<color> ®Õn t¸c gi¶ trªn fb héi qu¸n kh«ng?")
	else
		local tbSay = { "§¹i Héi Vâ L©m" }		
		
		tinsert(tbSay, "Thµnh thÞ/#SimCityMainThanhThi:thanhthiMenu()")
		tinsert(tbSay, "ChiÕn lo¹n/#SimCityChienTranh:mainMenu()")
		if self.autoAddThanhThi == 1 then
			tinsert(tbSay, "§¹i héi vâ l©m (më)/#SimCityMainThanhThi:autoThanhThi(0)")
		else
			tinsert(tbSay, "§¹i héi vâ l©m (®ãng)/#SimCityMainThanhThi:autoThanhThi(1)")
		end

		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbSay)
	end
	return 1
end

function SimCityMainThanhThi:addNpcs()
	add_dialognpc({
		{ 1617, 78,  1610, 3235, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- TD
		{ 1617, 37,  1719, 3091, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- BK
		{ 1617, 11,  3158, 5082, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- TD
		{ 1617, 1,   1569, 3198, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- PT
		{ 1617, 162, 1603, 3157, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- DL
		{ 1617, 80,  1785, 3034, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- DC
		{ 1617, 176, 1585, 2932, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- LA
	})
end

function main()
	return SimCityMainThanhThi:mainMenu()
end

function SimCityMainThanhThi:autoThanhThi(inp)
	self.autoAddThanhThi = inp
	if (inp == 0) then
		for k, v in self.worldStatus do
			self.worldStatus["w" .. v.world] = nil
			self:_clearMap(v.world)
		end
	else
		self:onPlayerEnterMap()
	end
	self:mainMenu()
end

function SimCityMainThanhThi:onPlayerEnterMap()
	if self.autoAddThanhThi ~= 1 then
		return 1
	end
	local nW, _, _ = GetWorldPos()
	if not self.worldStatus["w" .. nW] then
		self.worldStatus["w" .. nW] = {
			count = 1,
			enabled = 0,
			world = nW
		}
	else
		self.worldStatus["w" .. nW].count = self.worldStatus["w" .. nW].count + 1
	end

	-- If not enabled, create it
	if self.worldStatus["w" .. nW].enabled == 0 then
		self.worldStatus["w" .. nW].enabled = 1
		local worldInfo = SimCityWorld:Get(nW)
		if (worldInfo.name ~= "") then
			self:createNpcSoCapByMap()
			SimCityWorld:Update(nW, "showFightingArea", 0)
		end
	end
end

function SimCityMainThanhThi:onPlayerExitMap()
	if self.autoAddThanhThi ~= 1 then
		return 1
	end

	local nW, _, _ = GetWorldPos()
	if not self.worldStatus["w" .. nW] then
		return 1
	end

	self.worldStatus["w" .. nW].count = self.worldStatus["w" .. nW].count - 1

	-- If enabled but no one left, clean it
	if self.worldStatus["w" .. nW].count == 0 and self.worldStatus["w" .. nW].enabled == 1 then
		self.worldStatus["w" .. nW] = nil
		self:removeAll()
	end
end

function SimCityMainThanhThi:createNpcSoCap(forceIds, level)
	local nW, _, _ = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)
	if (worldInfo.name ~= "") then
		local perPage = 200
		local totalForceIds = 0
		if forceIds ~= nil then
			totalForceIds = getn(forceIds)
		end
		for i = 0, perPage do
			local id

			if totalForceIds == 0 then
				id = random(1786, 1795)
			else
				id = forceIds[random(1, totalForceIds)]
			end
			self:_createSingle(id, nW, { ngoaitrang = 1, level = level or 95 })
		end
	end
end

function SimCityMainThanhThi:createNpcSoCapByMap()
	local pW, pX, pY = GetWorldPos()

	-- bienkinh,tuongduong,laman,daily,duongchau,phuongtuong	
	if nW == 37 or pW == 78 or pW == 176 or pW == 162 or pW == 80 or pW == 1 then
		return self:createNpcSoCap()
	end

	-- Get level around
	local groupList = GetAroundNpcList(60)
	local tmpFound = {}
	local nNpcIdx
	local level
	local mapping = {}
	for i = 1, getn(groupList) do
		nNpcIdx = groupList[i]
		local nSettingIdx = GetNpcSettingIdx(nNpcIdx)
		level = NPCINFO_GetLevel(nNpcIdx)
		local kind = GetNpcKind(nNpcIdx)
		if level <= 90 and nSettingIdx > 0 and kind == 0 and not mapping[nSettingIdx] then
			tinsert(tmpFound, nSettingIdx)
			mapping[nSettingIdx] = 1
		end
	end
	local total = getn(tmpFound)

	if total == 0 then
		self:createNpcSoCap()
	else
		self:createNpcSoCap(tmpFound, level)
	end
end
