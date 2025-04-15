--Include("\\script\\global\\vinh\\simcity\\head.lua")
Include("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua")
SimCityMainThanhThi = {
	worldStatus = {},
	autoAddThanhThi = STARTUP_AUTOADD_THANHTHI,
	thanhThiSize = THANHTHI_SIZE,
	batchesByMap = {}, -- Store batches by map ID
	timerIdsByMap = {}, -- Store current batch index for each map
	masterTimerId = nil, -- Global timer for all batch processing
	patrolMap = nil,
	patrolTimerId = nil
}

function createTaskSayThanhThi(extra)
	local tbOpt = {}
	local nSettingIdx = 1617
	local nActionId = 0
	if not extra then
		extra = ""
	end
	tinsert(tbOpt, 1, "<dec><link=image[8,15]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">TriÖu MÉn:<link> ThiÕp vèn kh«ng ph¶i ng­êi tèt, nh­ng thiÕp ®èi víi chµng... ch­a tõng gian dèi." .. extra);
	return tbOpt
end

SimCityWorld:initThanhThi()

function SimCityMainThanhThi:_createSingle(id, Map, config)
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)
	local kind = 4


	local hardsetName = (config.ngoaitrang and config.ngoaitrang == 1 and SimCityNPCInfo:generateName()) or
		SimCityNPCInfo:getName(id)

	local npcConfig = {
		nNpcId = id, -- required, main char ID
		nMapId = Map, -- required, map
		walkMode = "random",
		walkVar = 2,
		kind = kind,
		CHANCE_ATTACK_PLAYER = CHANCE_ATTACK_PLAYER, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = CHANCE_AUTO_ATTACK,  -- co hoi bat chien dau
		CHANCE_JOIN_FIGHT = CHANCE_JOIN_FIGHT, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		noRevive = 0,
		hardsetName = hardsetName,
		mode = "thanhthi",
		level = config.level or 95,
		resetPosWhenRevive = random(0, 1)
	}

	for k, v in config do
		npcConfig[k] = v
	end

	-- Create parent
	SimCitizen:New(objCopy(npcConfig))
end

function SimCityMainThanhThi:_createTeamPatrol(nW, thonglinh, linh, N, pathName)
	local children5 = {}
	N = N or 16
	for i = 1, N do
		tinsert(children5, { nNpcId = linh })
	end


	SimCitizen:New({
		nNpcId = thonglinh,   -- required, main char ID
		nMapId = nW,          -- required, map
		camp = 0,             -- optional, camp
		childrenSetup = children5, -- optional, children
		walkMode = "formation", -- optional: random or 1 for formation
		currentPathIndex = pathName,
		noStop = 1,           -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 0, -- optional: leave fight instantly after no enemy, otherwise there's waiting period
		noRevive = 0,         -- optional: 0: keep reviving, 1: dead
		CHANCE_ATTACK_PLAYER = nil, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = nil, -- co hoi bat chien dau ~= 0 vi day la linh di tuan
		CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		kind = 4

	})
end

function SimCityMainThanhThi:CreatePatrol()
	local nW = self.patrolMap

	local worldInfo = SimCityWorld:Get(nW)

	local allMap = worldInfo.walkPaths

	local linh = 682

	-- Them cho Tuong Duong
	if nW == 78 or nW == 37 then
		if nW == 37 then
			linh = 688
		end
		for pathName, pathValues in allMap do
			self:_createTeamPatrol(nW, linh + 2, linh, 6, pathName)
		end


		-- Pho tuong + 9 binh
		self:_createTeamPatrol(nW, linh + 3, linh, 6, "tuongduong_full")
		self:_createTeamPatrol(nW, linh + 3, linh, 6, "tuongduong_1vongTK")


		-- Dai Tuong
		self:_createTeamPatrol(nW, linh + 4, linh, 9, "tuongduong_trongthanh")
		self:_createTeamPatrol(nW, linh + 5, linh + 1, 9, "tuongduong_trongthanh")
	end
end

function SimCityMainThanhThi:createAnhHung(capHP, perPage, ngoaitrang)
	local pool = SimCityNPCInfo:getPoolByCap(capHP)

	local mapID, nX, nY = GetWorldPos()
	for i = 1, perPage do
		local id = pool[random(1, getn(pool))]
		self:_createSingle(id, mapID, { ngoaitrang = ngoaitrang or 0, capHP = capHP })
	end
end

function SimCityMainThanhThi:createNpcSet(cap, total, ngoaitrang)
	local mapID, nX, nY = GetWorldPos()
	local pool = SimCityNPCInfo:getQuaiByCap(cap)
	for i = 0, total do
		local id = pool[random(1, getn(pool))]
		if (SimCityNPCInfo:IsValidFighter(id) == 1) then
			self:_createSingle(id, mapID, { ngoaitrang = ngoaitrang or 0 })
		end
	end
end

function SimCityMainThanhThi:removeAll()
	local nW, nX, nY = GetWorldPos()
	
	-- Mark this map's batches as canceled
	if self.timerIdsByMap[nW] then
		self.timerIdsByMap[nW].canceled = true
		self.timerIdsByMap[nW] = nil
	end
	
	-- Clear batches for this map
	self.batchesByMap[nW] = nil
	
	-- Remove all NPCs from the map
	SimCitizen:ClearMap(nW, "thanhthi")
	
	-- Check if we can stop the master timer
	local anyActiveMaps = false
	for mapId, mapData in self.timerIdsByMap do
		if not mapData.canceled then
			anyActiveMaps = true
			break
		end
	end
	
	if not anyActiveMaps and self.masterTimerId then
		DelTimer(self.masterTimerId)
		self.masterTimerId = nil
	end

	if self.patrolTimerId then
		DelTimer(self.patrolTimerId)
		self.patrolTimerId = nil
	end
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
	self:caidat()
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

	local tbSay = createTaskSayThanhThi()

	if worldInfo.allowFighting == 1 then
		tinsert(tbSay, "Cho phÐp ®¸nh nhau [cã]/#SimCityMainThanhThi:allowFighting(0)")
	else
		tinsert(tbSay, "Cho phÐp ®¸nh nhau [kh«ng]/#SimCityMainThanhThi:allowFighting(1)")
	end

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


	local tbSay = createTaskSayThanhThi()
	tinsert(tbSay, "§Ö tö tinh anh (100 thiÕp)/#SimCityMainThanhThi:createAnhHung(1,100,1)")
	tinsert(tbSay, "Cao thñ nhÊt l­u (100 thiÕp)/#SimCityMainThanhThi:createAnhHung(2,100,1)")
	tinsert(tbSay, "TuyÖt ®Ønh cao thñ (100 thiÕp)/#SimCityMainThanhThi:createAnhHung(3,100,1)")
	tinsert(tbSay, "Vâ l©m chÝ t«n (100 thiÕp)/#SimCityMainThanhThi:createAnhHung(4,100,1)")

	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityMainThanhThi:goiAnhHungThiep()
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)


	local tbSay = createTaskSayThanhThi()
	tinsert(tbSay, "Cao cÊp 1 (100 thiÕp)/#SimCityMainThanhThi:createNpcSet(4,100)")
	tinsert(tbSay, "Cao cÊp 2 (100 thiÕp)/#SimCityMainThanhThi:createNpcSet(3,100)")
	tinsert(tbSay, "Cao cÊp 3 (100 thiÕp)/#SimCityMainThanhThi:createNpcSet(2,100)")
	tinsert(tbSay, "Trung cÊp (100 thiÕp)/#SimCityMainThanhThi:createNpcSet(1,100)")
	--tinsert(tbSay, "Tù chän/#SimCityMainThanhThi:createNpcCustomAsk()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityMainThanhThi:thanhthiMenu()
	local nW, nX, nY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(nW)

	if not worldInfo.name then
		local tbSay = createTaskSayThanhThi("<enter><enter>B¶n ®å nµy ch­a ®­îc më. Chµng cã thÓ gëi <color=yellow>®Þa ®å chÝ<color> ®Õn t¸c gi¶ trªn fb héi qu¸n.")
		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbSay)
	else
		local tbSay = createTaskSayThanhThi()
		self.patrolMap = nW
		tinsert(tbSay, "Ph¸t anh hïng thiÕp/#SimCityMainThanhThi:goiAnhHungThiepNgoaiTrang()")
		tinsert(tbSay, "Ph¸t qu¸i nh©n thiÕp/#SimCityMainThanhThi:goiAnhHungThiep()")
		tinsert(tbSay, "§iÒu ®éng qu©n binh/#SimCityMainThanhThi:CreatePatrol()")
		tinsert(tbSay, "Ban lÖnh/#SimCityMainThanhThi:caidat()")
		tinsert(tbSay, "Gi¶i t¸n/#SimCityMainThanhThi:removeAll()")
		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbSay)
	end
	return 1
end

function SimCityMainThanhThi:mainMenu()
	local nW, nX, nY = GetWorldPos()

	if SimCityWorld:IsTongKimMap(nW) == 1 then
		return SimCityMainTongKim:mainMenu()
	end

	local worldInfo = SimCityWorld:Get(nW)
	SimCityChienTranh:modeTongKim(0, 0)
	SimCityChienTranh.nW = nW

	if not worldInfo.name then
		local tbSay = createTaskSayThanhThi("<enter><enter>B¶n ®å nµy ch­a ®­îc më. Chµng cã thÓ gëi <color=yellow>®Þa ®å chÝ<color> ®Õn t¸c gi¶ trªn fb héi qu¸n.")
		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbSay)
	else
		local counter = self:countMap(nW)
		local tbSay = createTaskSayThanhThi("<enter><enter><color=yellow>Nh©n sè hiÖn t¹i: " .. counter .. "<color>")

		tinsert(tbSay, "Thµnh ThÞ - Bè c¸o thiªn h¹/#SimCityMainThanhThi:thanhthiMenu()")

		if (not worldInfo.chientranh) or (not worldInfo.chientranh.path1) or (not worldInfo.chientranh.path2) then
		else 
			tinsert(tbSay, "Ph¸t ®éng chiÕn tranh/#SimCityChienTranh:mainMenu()")
		end

		if self.autoAddThanhThi == 1 then
			tinsert(tbSay, "Tù ®éng thªm (më)/#SimCityMainThanhThi:autoThanhThi(0)")
		else
			tinsert(tbSay, "Tù ®éng thªm (t¾t)/#SimCityMainThanhThi:autoThanhThi(1)")
		end

		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbSay)
	end
	return 1
end

function SimCityMainThanhThi:addNpcs()
	add_dialognpc({
		{ 1617, 78,  1621, 3253, "\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua", "TriÖu MÉn" }, -- TD
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
		self:removeAll()
	else
		self:onPlayerEnterMap()
	end
	self:mainMenu()
end

function SimCityMainThanhThi:countMap(nW)
	local counter = 0
	for k, v in SimCitizen.fighterList do
		if v.nMapId and v.nMapId == nW then
			counter = counter + 1
		end
	end
	return counter
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

		if SimCityWorld:IsTongKimMap(nW) == 1 then
			SimCityMainTongKim:onPlayerEnterMap()
			return 1
		end

		local worldInfo = SimCityWorld:Get(nW)
		if (worldInfo.name ~= "" and self:countMap(nW) == 0) then
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

		if SimCityWorld:IsTongKimMap(nW) == 1 then
			SimCityMainTongKim:clearTongKimNpc(nW)
			return 1
		end

		self:removeAll()
	end
end

function SimCityMainThanhThi:createNpcSoCapByMap()
	local nW, _, _ = GetWorldPos()

	local worldInfo = SimCityWorld:Get(nW)
	if (worldInfo.name ~= "") then
		local tmpFound = {}
		local level
		local total = 100
		local capHP = "auto"

		-- Get level around
		local fighterList = GetAroundNpcList(60)
		local nNpcIdx
		local mapping = {}
		local map9x = 1
		local baoDanhTongKim = 0

		if nW == 323 or nW == 324 or nW == 325 then
			baoDanhTongKim = 1
		end

		for i = 1, getn(fighterList) do
			nNpcIdx = fighterList[i]
			local nSettingIdx = GetNpcSettingIdx(nNpcIdx)
			level = NPCINFO_GetLevel(nNpcIdx)
			local kind = GetNpcKind(nNpcIdx)
			if level < 90 and nSettingIdx > 0 and kind == 0 and not mapping[nSettingIdx] then
				tinsert(tmpFound, nSettingIdx)
				mapping[nSettingIdx] = 1
				map9x = 0
			end
		end

		local isThanhThi = SimCityWorld:IsThanhThiMap(nW) == 1
		local nv9x = SimCityNPCInfo:getPoolByCap(1)

		-- Them 9x vao Thanh Thi
		if isThanhThi or getn(tmpFound) == 0 then
			tmpFound = arrJoin({ tmpFound, nv9x})
			level = 95
			capHP = 1
		end


		if isThanhThi then
			total = self.thanhThiSize
			map9x = 0
		end

		local N = getn(tmpFound)

		if baoDanhTongKim == 1 then
			worldInfo.allowFighting = 0
			local table1 = {}

			-- Fill each table with 40 random NPCs
			for i = 1, random(20,40) do 
				self:_createSingle(
					tmpFound[random(1, N)], nW, { 
						ngoaitrang = 1, 
						level = level or 95, 
						capHP = capHP , 
						walkMode = "preset",
						baoDanhTongKim = 1,
						hardsetPathIndex = 1,
						camp = 0,
						walkVar = 4
					}
				)
			end
			for i = 1, random(20,40) do 
				self:_createSingle(
					tmpFound[random(1, N)], nW, { 
						ngoaitrang = 1, 
						level = level or 95, 
						capHP = capHP , 
						walkMode = "preset",
						baoDanhTongKim = 1,
						hardsetPathIndex = 2,
						camp = 0,
						walkVar = 4
					}
				)
			end

		elseif map9x == 0 then
			if isThanhThi then
			--	worldInfo.allowFighting = 0
			--else
			--	worldInfo.allowFighting = 1
			end
			
			-- Split into 4 tables of 50 NPCs each
			local table1 = {}
			local table2 = {}
			local table3 = {}
			local table4 = {}
			local table5 = {}

			-- Fill each table with 40 random NPCs
			local perTable = floor(total/5)
			for i = 1, perTable do

				if isThanhThi and THANHTHI_QUAI == 1 and random(1,3) == 1 then
					local capQuai = random(1,4)
					local pool = SimCityNPCInfo:getQuaiByCap(capQuai)
					local poolN = getn(pool)
					tinsert(table1, {pool[random(1, poolN)], nW, { ngoaitrang = 0, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table2, {pool[random(1, poolN)], nW, { ngoaitrang = 0, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table3, {pool[random(1, poolN)], nW, { ngoaitrang = 0, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table4, {pool[random(1, poolN)], nW, { ngoaitrang = 0, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table5, {pool[random(1, poolN)], nW, { ngoaitrang = 0, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
				else
					tinsert(table1, {tmpFound[random(1, N)], nW, { ngoaitrang = 1, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table2, {tmpFound[random(1, N)], nW, { ngoaitrang = 1, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table3, {tmpFound[random(1, N)], nW, { ngoaitrang = 1, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table4, {tmpFound[random(1, N)], nW, { ngoaitrang = 1, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
					tinsert(table5, {tmpFound[random(1, N)], nW, { ngoaitrang = 1, level = level or 95, capHP = capHP , walkMode = random(1, 4) == 1 and "preset" or "random"}})
				end
				
			end

			-- Add all tables to everything array
			self:_createBatch({
				table1,
				table2,
				table3,
				table4,
				table5
			})			
			if isThanhThi then
				self.patrolMap = nW
				self.patrolTimerId = AddTimer(20 * 18, "SimCityMainThanhThi:CreatePatrol", self)
			end 
		elseif LUYENCONG_AUTOADD == 1 then
			tmpFound = nv9x
			N = getn(tmpFound)
			worldInfo.allowFighting = 1
			total = floor(THANHTHI_SIZE/10) -- 20 PT tat ca
			local everything = {}
			for i = 1, total do
				local id = tmpFound[random(1, N)]
				local children5 = {}
				for j = 1, 7 do
					tinsert(children5, {
						mode = "train",
						szName = SimCityNPCInfo:generateName(),
						nNpcId = tmpFound[random(1, N)], -- required, main char ID
					})
				end
				tinsert(everything, {{id, nW,
					{
						szName = SimCityNPCInfo:generateName(),
						ngoaitrang = 1,
						mode = "train",
						level = level or 95,
						capHP = 1,
						childrenSetup = children5,
						walkMode =
						"random",
						CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
						CHANCE_ATTACK_NPC = 1, -- co hoi bat chien dau khi thay NPC khac phe
						CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
						RADIUS_FIGHT_PLAYER = 15, -- scan for player around and randomly attack
						RADIUS_FIGHT_NPC = 15, -- scan for NPC around and start randomly attack,
						RADIUS_FIGHT_SCAN = 15, -- scan for fight around and join/leave fight it
						noStop = 1, -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
						leaveFightWhenNoEnemy = 1, -- optional: leave fight instantly after no enemy, otherwise there's waiting period
						walkVar = 2, 
						kind = 0, -- quai mode
						TIME_FIGHTING_minTs = 1800,
						TIME_FIGHTING_maxTs = 3000,
						TIME_RESTING_minTs = 1,
						TIME_RESTING_maxTs = 3,
					}}});
			end
			
			self:_createBatch(everything)
		end
	end
end

-- Global batch processing function that handles all maps
function processBatches()
	local activeMapsCount = 0
	
	-- Process one batch for each active map
	for mapId, mapData in SimCityMainThanhThi.timerIdsByMap do
		if not mapData.canceled then
			activeMapsCount = activeMapsCount + 1
			
			local currentIndex = mapData.currentIndex or 1
			local batches = SimCityMainThanhThi.batchesByMap[mapId]
			
			if batches and currentIndex <= getn(batches) then
				local batch = batches[currentIndex]
				local counter = SimCityMainThanhThi:countMap(mapId)
				local threshold = SimCityMainThanhThi.thanhThiSize or 12				

				if counter < threshold then
					-- Process this batch of NPCs
					if type(batch) == "table" and getn(batch) > 0 then
						for i = 1, getn(batch) do
							if type(batch[i]) == "table" and getn(batch[i]) >= 2 then
								SimCityMainThanhThi:_createSingle(batch[i][1], batch[i][2], batch[i][3])
							end
						end
					end
					
					-- Move to next batch
					SimCityMainThanhThi.timerIdsByMap[mapId].currentIndex = currentIndex + 1
				else
					-- No more NPCs needed on this map
					SimCityMainThanhThi.batchesByMap[mapId] = nil
					SimCityMainThanhThi.timerIdsByMap[mapId] = nil
					activeMapsCount = activeMapsCount - 1
				end
			else
				-- All batches processed for this map
				SimCityMainThanhThi.batchesByMap[mapId] = nil
				SimCityMainThanhThi.timerIdsByMap[mapId] = nil
				activeMapsCount = activeMapsCount - 1
			end
		end
	end
	
	-- If no active maps, stop the timer
	if activeMapsCount <= 0 then
		if SimCityMainThanhThi.masterTimerId then
			DelTimer(SimCityMainThanhThi.masterTimerId)
			SimCityMainThanhThi.masterTimerId = nil
		end
	else
		SimCityMainThanhThi.masterTimerId = AddTimer(3 * 18, "processBatches", SimCityMainThanhThi)
	end
	
	-- Return 0 to keep the timer running
	return 0
end

function SimCityMainThanhThi:_createBatch(batches)
	if not batches or getn(batches) == 0 then
		return
	end
	
	-- Get current map ID if not provided in the batch
	local mapId = nil
	if getn(batches) > 0 and type(batches[1]) == "table" then
		-- Check if this is an array of arrays with NPC data
		if getn(batches[1]) > 0 and type(batches[1][1]) == "table" and getn(batches[1][1]) >= 2 then
			-- Extract mapId from the first batch item [npcId, mapId, config]
			mapId = batches[1][1][2]
		end
	end
	
	if not mapId then
		-- Try to get current map ID as fallback
		local nW, _, _ = GetWorldPos()
		mapId = nW
	end
	
	-- Initialize data structure for this map
	self.batchesByMap[mapId] = batches
	self.timerIdsByMap[mapId] = self.timerIdsByMap[mapId] or {}
	self.timerIdsByMap[mapId].canceled = false
	self.timerIdsByMap[mapId].currentIndex = 1
	
	-- Start the master timer if not already running
	if not self.masterTimerId then
		self.masterTimerId = AddTimer(3 * 18, "processBatches", self)
	end
end