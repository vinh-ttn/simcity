SimCityChienTranh = {

	nW = 0,

	path1 = {},
	path2 = {},
 
}

function createTaskSayChienTranh(mapId, extra)

	local worldInfo = SimCityWorld:Get(mapId)
	local tbOpt = {}
	local nSettingIdx = 1617
	local nActionId = 0
	if not extra then
		extra = ""
	end 

	local showVoKy = 0
	if worldInfo.isTongKim == 1 then
		local camp = GetCurCamp()
		if camp and camp == 1 then
			showVoKy = 1
		end
	end

	-- Show it
	if showVoKy == 1 then
		nSettingIdx = 103
		tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">V« Kþ:<link> Ng­êi H¸n lu«n cho r»ng ng­êi Kim lµ d· man, nh­ng ng­¬i cã biÕt chiÕn tranh b¾t ®Çu tõ ®©u kh«ng?" .. extra);
	else
		tinsert(tbOpt, 1, "<dec><link=image[8,15]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">TriÖu MÉn:<link> Ng­êi H¸n c¸c ng­¬i lu«n cho r»ng ng­êi Kim chóng ta lµ d· man, nh­ng c¸c ng­¬i cã biÕt chiÕn tranh b¾t ®Çu tõ ®©u kh«ng?" .. extra);
	end

	return tbOpt
end
 

function SimCityChienTranh:genWalkPath(forCamp) 
	local worldInfo = SimCityWorld:Get(self.nW)

	
	-- Duoi len tren
	local myPath = {}
	local mySpawnODuoi = 1
	
	if (worldInfo.camp2TopRight == 1) then
		if forCamp == 1 then
			mySpawnODuoi = 1
		else
			mySpawnODuoi = 0
		end
	else
		if forCamp == 1 then
			mySpawnODuoi = 0
		else
			mySpawnODuoi = 1
		end
	end

	local presetCampDuoiKey = worldInfo.presetPaths.baseDuoi
	local presetCampTrenKey = worldInfo.presetPaths.baseTren 

	if (mySpawnODuoi == 1) then
		
		if worldInfo.restrictedSpawns.campduoi then
			local filtered = {}
			for i=1, getn(presetCampDuoiKey) do
				local key = presetCampDuoiKey[i]
				if not worldInfo.restrictedSpawns.campduoi[key] then
					tinsert(filtered, key)
				end
			end
			presetCampDuoiKey = filtered
		end

		local mySpawn = presetCampDuoiKey[random(1, getn(presetCampDuoiKey))]
		local theirSpawn = presetCampTrenKey[random(1, getn(presetCampTrenKey))]
		local mainPath = SimCityGraphToChienTranh:autoFindPathNames(worldInfo, mySpawn, theirSpawn, 0)

 		tinsert(myPath, { mySpawn, 0 })
		tinsert(myPath, { mainPath, 1})
		tinsert(myPath, { theirSpawn, 1 })

	-- My spawn o tren
	else

		if worldInfo.restrictedSpawns.camptren then
			local filtered = {}
			for i=1, getn(presetCampTrenKey) do
				local key = presetCampTrenKey[i]
				if not worldInfo.restrictedSpawns.camptren[key] then
					tinsert(filtered, key)
				end
			end	
			presetCampTrenKey = filtered
		end

		local mySpawn = presetCampTrenKey[random(1, getn(presetCampTrenKey))]
		local theirSpawn = presetCampDuoiKey[random(1, getn(presetCampDuoiKey))]
		local mainPath = SimCityGraphToChienTranh:autoFindPathNames(worldInfo, mySpawn, theirSpawn, 1)
 		tinsert(myPath, { mySpawn, 0 })
		tinsert(myPath, { mainPath, -1})
		tinsert(myPath, { theirSpawn, 1 })
	end  
 
	return myPath
end
 
 

function SimCityChienTranh:taoNV(id, camp, worldInfo, walkPathNames, nt, theosau, capHP, extraConfig)
	if not walkPathNames then
		return nil
	end

	local mapID = worldInfo.worldId
	local name = "Kim"
	local rank = 1
	local realCamp = 5
	if camp == 1 then
		name = "Tèng"
		realCamp = 0
	end

	local hardsetName = (nt == 1 and SimCityNPCInfo:generateName()) or SimCityNPCInfo:getName(id)
	if worldInfo.isTongKim == 1 then
		realCamp = camp
		hardsetName = (nt == 1 and SimCityNPCInfo:generateName()) or nil
	end
 
	local tbNpc = {
		mode = "chiendau",
		szName = name or "",

		nNpcId = id,                            -- required, main char ID
		nMapId = mapID,                         -- required, map
		camp = realCamp,                        -- optional, camp

		walkMode = (theosau and "formation") or "preset", -- optional: random, keoxe, or formation for formation
		walkVar = (theosau and 3) or 4,         -- random walk of radius of 4*2
		walkPathNames = walkPathNames,

		noStop = 1,          -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5, -- optional: leave fight instantly after no enemy, otherwise there's waiting period

		noRevive = 0,        -- optional: 0: keep reviving, 1: dead
 

		CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = 1, -- co hoi bat chien dau khi thay NPC khac phe
		CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		RADIUS_FIGHT_PLAYER = 15, -- scan for player around and randomly attack
		RADIUS_FIGHT_NPC = 15, -- scan for NPC around and start randomly attack,
		RADIUS_FIGHT_SCAN = 15, -- scan for fight around and join/leave fight it
 
		kind = 0,           -- quai mode
		TIME_FIGHTING_minTs = 1800,
		TIME_FIGHTING_maxTs = 3000,
		TIME_RESTING_minTs = 1,
		TIME_RESTING_maxTs = 3,

		resetPosWhenRevive = 1,

		tongkim = 1,
		tongkim_name = name,

		ngoaitrang = nt or 0,
		hardsetName = hardsetName,

		capHP = capHP,

		childrenSetup = theosau or nil,
		childrenCheckDistance = (theosau and 8) or nil -- force distance check for child

	}

	if extraConfig then
		for k,v in extraConfig do
			tbNpc[k] = v
		end
	end

	return SimCitizen:New(tbNpc)
end

function SimCityChienTranh:taodoi(thonglinh, camp, worldInfo, walkPathNames, children5)
	if not walkPathNames then
		return nil
	end
	local children = nil
	local name = "Kim Binh"

	local realCamp = 5

	if camp == 1 then
		name = "Tèng Binh"
		realCamp = 0
	end
	if children5 then
		children = {}
		for i = 1, getn(children5) do
			children = spawnN(children, children5[i][1], children5[i][2], { szName = name })
		end
	end

	if worldInfo.isTongKim == 1 then
		realCamp = camp
	end

	local mapID = worldInfo.worldId

	return SimCitizen:New({
		mode = "chiendau",
		szName = name or "",
		tongkim = 1,

		nNpcId = thonglinh, -- required, main char ID
		nMapId = mapID,     -- required, map
		camp = realCamp,    -- optional, camp
		childrenSetup = children, -- optional, children
		walkMode = "formation", -- optional: random or 1 for formation
		walkPathNames = walkPathNames,
 
		noStop = 1,          -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5, -- optional: leave fight instantly after no enemy, otherwise there's waiting period

		noRevive = 0,        -- optional: 0: keep reviving, 1: dead
 
		CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = 1, -- co hoi bat chien dau khi thay NPC khac phe
		CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau

		RADIUS_FIGHT_PLAYER = 15, -- scan for player around and randomly attack
		RADIUS_FIGHT_NPC = 15, -- scan for NPC around and start randomly attack,
		RADIUS_FIGHT_SCAN = 15, -- scan for fight around and join/leave fight it
 
		kind = 0,           -- quai mode
		TIME_FIGHTING_minTs = 1800,
		TIME_FIGHTING_maxTs = 3000,
		TIME_RESTING_minTs = 1,
		TIME_RESTING_maxTs = 3,

		resetPosWhenRevive = 1,
	})
end

function SimCityChienTranh:taophe(nW, camp, linhthuong1, linhthuong2, hieuuy, photuong, daituong, nguyensoai, kybinh)
	local worldInfo = SimCityWorld:Get(nW)
	self:taodoi(nguyensoai, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 20 },
		{ linhthuong2, 20 },
		{ hieuuy,      4 },
		{ photuong,    2 },
		{ daituong,    2 },
	})

	-- Team thuong
	self:taodoi(hieuuy, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 20 },
		{ linhthuong2, 20 }
	})

	self:taodoi(kybinh, camp, worldInfo, self:genWalkPath(camp), {
		{ kybinh, 6 },
	})


	self:taodoi(linhthuong2, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 16 },
	})

	self:taodoi(photuong, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong2, 16 },
		{ hieuuy,      12 }
	})

	self:taodoi(hieuuy, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 16 },
	})


	-- Team nguyen soai
	self:taodoi(nguyensoai, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 20 },
		{ linhthuong2, 20 },
		{ hieuuy,      4 },
		{ photuong,    2 },
		{ daituong,    2 },
	})

	-- Team thuong
	self:taodoi(hieuuy, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 20 },
		{ linhthuong2, 20 }
	})

	self:taodoi(kybinh, camp, worldInfo, self:genWalkPath(camp), {
		{ kybinh, 6 },
	})


	self:taodoi(linhthuong2, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 16 },
	})

	self:taodoi(photuong, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong2, 16 },
		{ hieuuy,      12 }
	})


	self:taodoi(hieuuy, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 16 },
	})


	self:taodoi(hieuuy, camp, worldInfo, self:genWalkPath(camp), {
		{ linhthuong1, 16 },
	})
end

function SimCityChienTranh:phe_tudo(startNPCIndex, perPage, ngoaitrang)
 
	local worldInfo = SimCityWorld:Get(self.nW)

	local forCamp = 1
	for i = 0, perPage do
		local id = startNPCIndex + i
		if SimCityNPCInfo:IsValidFighter(id) == 1 then
			local myPath = self:genWalkPath(forCamp)

			local fighter = self:taoNV(id, forCamp, worldInfo, myPath, ngoaitrang or 0)
			if fighter then
				if forCamp == 1 then
					forCamp = 2
				else
					forCamp = 1
				end
			end
		end
	end
end

function SimCityChienTranh:phe_tudo_xe(startNPCIndex, perPage, ngoaitrang)
 
	local worldInfo = SimCityWorld:Get(self.nW)

	local forCamp = 1

	local maxIndex = startNPCIndex + perPage

	if maxIndex > SimCityNPCInfo.ALLNPCs_INFO_COUNT then
		maxIndex = SimCityNPCInfo.ALLNPCs_INFO_COUNT
	end

	for i = 1, 10 do
		local pid = random(startNPCIndex, maxIndex)
		local myPath = self:genWalkPath(forCamp)

		while SimCityNPCInfo:notFightingChar(pid) == 1 do
			pid = random(startNPCIndex, maxIndex)
		end

		-- 10 con theo sau
		local runSpeed = SimCityNPCInfo:getSpeed(pid) or 0

		local children = {}
		while getn(children) < 20 do
			local id = random(startNPCIndex, maxIndex)
			local mySpeed = SimCityNPCInfo:getSpeed(id) or 0
			if SimCityNPCInfo:notFightingChar(id) == 0 and (runSpeed == 0 or abs(mySpeed - runSpeed) <= 1) then
				tinsert(children, {
					nNpcId = id,
					szName = (ngoaitrang == 1 and SimCityNPCInfo:generateName()) or SimCityNPCInfo:getName(id)
				})
			end
		end


		self:taoNV(pid, forCamp, worldInfo, myPath, ngoaitrang or 0, children, nil, {
			childrenWalkMode = "random"
		})

		if i > 5 then
			forCamp = 2
		end
	end
end

function SimCityChienTranh:nv_tudo(capHP)
 
	local worldInfo = SimCityWorld:Get(self.nW)

	local forCamp = 1
	local pool = SimCityNPCInfo:getPoolByCap(capHP)
	local total = 0
	local loop = 0
	
	local rate = worldInfo.teamRatio or 0.5
	local everyoneCount = 100

	local team1Size = floor(everyoneCount * rate)
	local team2Size = everyoneCount - team1Size

	-- create team 1
	total = 0
	forCamp = 1
	while total < team1Size and loop < team1Size*3 do
		local id = pool[random(1, getn(pool))]
		local myPath = self:genWalkPath(forCamp)
		local fighter = self:taoNV(id, forCamp, worldInfo, myPath, 1, nil, capHP)
		if fighter then
			total = total + 1
		end
		loop = loop + 1
	end

	-- create team 2
	total = 0
	forCamp = 2
	loop = 0
	while total < team2Size and loop < team2Size*3 do
		local id = pool[random(1, getn(pool))]
		local myPath = self:genWalkPath(forCamp)
		local fighter = self:taoNV(id, forCamp, worldInfo, myPath, 1, nil, capHP)
		if fighter then
			total = total + 1
		end
		loop = loop + 1
	end
end

function SimCityChienTranh:nv_tudo_xe(capHP)
 
	local forCamp = 1
	local pool = SimCityNPCInfo:getPoolByCap(capHP)

	local worldInfo = SimCityWorld:Get(self.nW)

	for i = 1, 10 do
		local pid = pool[random(1, getn(pool))]
		local myPath = self:genWalkPath(forCamp)

		while SimCityNPCInfo:notFightingChar(pid) == 1 do
			pid = pool[random(1, getn(pool))]
		end

		-- 10 con theo sau
		local runSpeed = SimCityNPCInfo:getSpeed(pid) or 0

		local children = {}
		while getn(children) < 20 do
			local id = pool[random(1, getn(pool))]
			local mySpeed = SimCityNPCInfo:getSpeed(id) or 0
			if SimCityNPCInfo:notFightingChar(id) == 0 and (runSpeed == 0 or abs(mySpeed - runSpeed) <= 2) then
				tinsert(children, {
					nNpcId = id,
					szName = SimCityNPCInfo:generateName() or SimCityNPCInfo:getName(id)
				})
			end
		end


		self:taoNV(pid, forCamp, worldInfo, myPath, 1, children, capHP, {
			childrenWalkMode = "random"
		})

		if i > 5 then
			forCamp = 2
		end
	end
end

function SimCityChienTranh:phe_quanbinh()
	-- PHE TONG BINH
	local linh = 682
	local kybinh = 1080
	local camp = 1

	self:taophe(self.nW, camp, linh, linh + 1, linh + 2, linh + 3, linh + 4, linh + 5, kybinh)


	-- PHE KIM BINH
	linh = 688
	kybinh = 1090
	camp = 2

	self:taophe(self.nW, camp, linh, linh + 1, linh + 2, linh + 3, linh + 4, linh + 5, kybinh)
end

function SimCityChienTranh:removeAll(targetWorld)
	for k, world in SimCityWorld.data do
		if (not targetWorld or world.worldId == targetWorld) then
			self.nW = world.worldId
			SimCitizen:ClearMap(self.nW, "chiendau")
		end
	end
end

function SimCityChienTranh:getWorldName()
	local worldInfo = SimCityWorld:Get(self.nW)

	local counter = 0
	for k, v in SimCitizen.fighterList do
		if v.nMapId and v.nMapId == self.nW then
			counter = counter + 1
		end
	end
	return { worldInfo.name .. " ChiÕn Lo¹n<enter><color=yellow>Nh©n sè hiÖn t¹i: " .. counter }
end


function SimCityChienTranh:countMap(nW)
	local counter = 0
	for k, v in SimCitizen.fighterList do
		if v.nMapId and v.nMapId == nW then
			counter = counter + 1
		end
	end
	return counter
end


function SimCityChienTranh:goiAnhHungThiepNgoaiTrang()

	local counter = self:countMap(self.nW)
	local extra = "<enter><enter><color=yellow>Nh©n sè hiÖn t¹i: " .. counter .. "<color>"


	local tbSay = createTaskSayChienTranh(self.nW, extra)	

	tinsert(tbSay, "§Ö tö tinh anh (100 thiÕp)/#SimCityChienTranh:nv_tudo(1)")
	tinsert(tbSay, "§Ö tö tinh anh (5 nhãm)/#SimCityChienTranh:nv_tudo_xe(1)")

	tinsert(tbSay, "Cao thñ nhÊt l­u (100 thiÕp)/#SimCityChienTranh:nv_tudo(2)")
	tinsert(tbSay, "Cao thñ nhÊt l­u (5 nhãm)/#SimCityChienTranh:nv_tudo_xe(2)")


	tinsert(tbSay, "TuyÖn ®Ønh cao thñ (100 thiÕp)/#SimCityChienTranh:nv_tudo(3)")
	tinsert(tbSay, "TuyÖn ®Ønh cao thñ (5 nhãm)/#SimCityChienTranh:nv_tudo_xe(3)")

	tinsert(tbSay, "Vâ l©m chÝ t«n (100 thiÕp)/#SimCityChienTranh:nv_tudo(4)")
	tinsert(tbSay, "Vâ l©m chÝ t«n (5 nhãm)/#SimCityChienTranh:nv_tudo_xe(4)")


	tinsert(tbSay, "Quay l¹i./#SimCityChienTranh:mainMenu()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityChienTranh:goiAnhHungThiep()
	local counter = self:countMap(self.nW)
	local extra = "<enter><enter><color=yellow>Nh©n sè hiÖn t¹i: " .. counter .. "<color>"
	local tbSay = createTaskSayChienTranh(self.nW, extra)



	tinsert(tbSay, "Cao cÊp 1 (500 thiÕp)/#SimCityChienTranh:phe_tudo(1000,500,0)")
	--tinsert(tbSay, "Cao cÊp 1 (5 xe)/#SimCityChienTranh:phe_tudo_xe(1000,500,0)")

	tinsert(tbSay, "Cao cÊp 2 (500 thiÕp)/#SimCityChienTranh:phe_tudo(1500,500,0)")
	--tinsert(tbSay, "Cao cÊp 2 (5 xe)/#SimCityChienTranh:phe_tudo_xe(1500,500,0)")

	tinsert(tbSay, "Cao cÊp 3 (500 thiÕp)/#SimCityChienTranh:phe_tudo(2000,500,0)")
	--tinsert(tbSay, "Cao cÊp 3 (5 xe)/#SimCityChienTranh:phe_tudo_xe(2000,500,0)")



	tinsert(tbSay, "Trung cÊp (500 thiÕp)/#SimCityChienTranh:phe_tudo(500,500,1)")
	--tinsert(tbSay, "Trung cÊp (5 xe)/#SimCityChienTranh:phe_tudo_xe(500,500,0)")

	tinsert(tbSay, "Quay l¹i./#SimCityChienTranh:mainMenu()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end


function SimCityChienTranh:khaiChienPhongHoaLienThanh()	
	if self.nW ~= 580 and self.nW ~= 581 then
		return 1
	end
	SetMissionV(5, 89)
	Say("Qu©n ®Þch sÏ b¾t ®Çu c«ng thµnh trong 20 gi©y, c¸c T­íng sÜ h·y s½n sµng!")

	for k, v in SimCitizen.fighterList do
		if v.nMapId and v.nMapId == self.nW then
			v.tick_canWalk = 0
		end
	end

	return 1
 end

function SimCityChienTranh:khaiChienTongKim()	
	if self.nW == 580 or self.nW == 581 then
		self:khaiChienPhongHoaLienThanh()
		return 1
	end
	if GetMissionV(1) ~= 2 then			
		AddGlobalCountNews("Thêi gian b¸o danh ®· kÕt thóc. ChiÕn ®Êu chÝnh thøc b¾t ®Çu", 2);
		Msg2Map(self.nW, "Phong V©n LuËn KiÕm chÝnh thøc khai chiÕn! C¸c chiÕn sÜ! X«ng lªn!");
		SetMissionV(1,2);
		BT_SetData( 46, GetGameTime() )
		PutMessage("§Þch qu©n ®· b¾t ®Çu hµnh ®éng! C¸c chiÕn sÜ! X«ng lªn!")

		for k, v in SimCitizen.fighterList do
			if v.nMapId and v.nMapId == self.nW then
				v.tick_canWalk = 0
			end
		end
	end
end

function SimCityChienTranh:showBXH(inp)
	local worldInfo = SimCityWorld:Get(self.nW)

	worldInfo.showBXH = tonumber(inp)
	SimCityWorld:doShowBXH(self.nW)
	return SimCityChienTranh:caidat()
end

function SimCityChienTranh:showThangCap(inp)
	local worldInfo = SimCityWorld:Get(self.nW)

	worldInfo.showThangCap = inp
	return SimCityChienTranh:caidat()
end

function SimCityChienTranh:caidat()
	local worldInfo = SimCityWorld:Get(self.nW)
	local counter = self:countMap(self.nW)
	local extra = "<enter><enter><color=yellow>Nh©n sè hiÖn t¹i: " .. counter .. "<color>"
	local tbSay = createTaskSayChienTranh(self.nW, extra)



	if worldInfo.showBXH == 1 then
		tinsert(tbSay, "Th«ng b¸o xÕp h¹ng mçi phót [cã]/#SimCityChienTranh:showBXH(0)")
	else
		tinsert(tbSay, "Th«ng b¸o xÕp h¹ng mçi phót [kh«ng]/#SimCityChienTranh:showBXH(1)")
	end

	if worldInfo.showThangCap == 1 then
		tinsert(tbSay, "Th«ng b¸o th¨ng cÊp [cã]/#SimCityChienTranh:showThangCap(0)")
	else
		tinsert(tbSay, "Th«ng b¸o th¨ng cÊp [kh«ng]/#SimCityChienTranh:showThangCap(1)")
	end


	tinsert(tbSay, "Quay l¹i/#SimCityChienTranh:mainMenu()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityChienTranh:mainMenu()
	local worldInfo = SimCityWorld:Get(self.nW)
	local result = SimCityGraphToChienTranh:build(worldInfo, 32)

	if (result == 0) then
		local tbSay = createTaskSayChienTranh("<enter><enter>ChiÕn lo¹n t¹i b¶n ®å nµy ch­a ®­îc më. Chµng cã thÓ gëi <color=yellow>®Þa ®å chÝ<color> ®Õn t¸c gi¶ trªn fb héi qu¸n.")
		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbSay)
		return 1 
 	end

	worldInfo.allowFighting = 1
	worldInfo.showFightingArea = 0

	local counter = self:countMap(self.nW)
	local extra = "<enter><enter><color=yellow>Nh©n sè hiÖn t¹i: " .. counter .. "<color>"
	local tbSay = createTaskSayChienTranh(self.nW, extra)
	if SimCityThanhThi then
		SimCityThanhThi:removeAll()
	end

	if worldInfo.isTongKim == 1 then
		if GetMissionV(1) ~= 2 then
			tinsert(tbSay, "Khai chiÕn/#SimCityChienTranh:khaiChienTongKim()")
		end
	end

	tinsert(tbSay, "Ph¸t anh hïng thiÕp/#SimCityChienTranh:goiAnhHungThiepNgoaiTrang()")
	tinsert(tbSay, "Ph¸t qu¸i nh©n thiÕp/#SimCityChienTranh:goiAnhHungThiep()")
	tinsert(tbSay, "§iÒu ®éng qu©n binh/#SimCityChienTranh:phe_quanbinh()")
	tinsert(tbSay, "Xem b¶ng xÕp h¹ng/#SimCitizen:ThongBaoBXH(" .. (self.nW) .. ")")
	tinsert(tbSay, "Ban lÖnh/#SimCityChienTranh:caidat()")
	tinsert(tbSay, "Gi¶i t¸n/#SimCityChienTranh:removeAll()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)


	return 1
end


function SimCityChienTranh:countMapSpawn(nW)
	local counter = 0
	for k, v in SimCitizen.fighterList do
		if v.nMapId and v.nMapId == nW and v.baoDanhTongKim == 1 then
			counter = counter + 1
		end
	end
	return counter
end


function SimCityChienTranh:taoHauDoanh(ngoaitrang)
	if self:countMapSpawn(self.nW) > 0 then
		return 1
	end

	local worldInfo = SimCityWorld:Get(self.nW)
	if (not worldInfo.presetPaths.haudoanh1 and not worldInfo.presetPaths.haudoanh2) 
		then
		return 1
	end

	local forCamp = 1
	local capHP = 3
	local pool = SimCityNPCInfo:getPoolByCap(capHP)
	local total = 0
	local pW, pX, pY = GetWorldPos()
	local userCamp = GetCurCamp()

	local firstPoint = nil
	local firstPointX = 0
	local firstPointY = 0
	local dist1 = 0
	local secondPoint = nil
	local secondPointX = 0
	local secondPointY = 0
	local dist2 = 0
	local myPath = nil
	local id = 0
	local loop = 0
	while (total < 20 and loop < 100)  do
		loop = loop + 1
		id = pool[random(1, getn(pool))] 
		 
		myPath = nil

		if worldInfo.presetPaths.haudoanh1 and worldInfo.presetPaths.haudoanh2 then
			local myHauDoanh = "haudoanh1"			

			-- Note: sometimes preset paths are swapped around in correctly, we need to check based on user position
			firstPoint = worldInfo.presetPaths.haudoanh1[1]
			firstPointX, firstPointY = nodeNameToCoords(firstPoint)
			dist1 = GetDistanceRadius(pX, pY, firstPointX, firstPointY)

			secondPoint = worldInfo.presetPaths.haudoanh2[1]
			secondPointX, secondPointY = nodeNameToCoords(secondPoint)
			dist2 = GetDistanceRadius(pX, pY, secondPointX, secondPointY)

			-- TH 1, dang o chung camp voi user va haudoanh nao gan user nhat?
			if userCamp == forCamp then 
				if dist2 < dist1 then
					myHauDoanh = "haudoanh2"
				else
					myHauDoanh = "haudoanh1"
				end
			-- TH 2, dang o khac camp voi user va hau doanh nao xa user nhat
			elseif userCamp ~= forCamp then
				if dist2 < dist1 then
					myHauDoanh = "haudoanh1"
				else
					myHauDoanh = "haudoanh2"
				end
			end 

			myPath = { {myHauDoanh, 1} }

		elseif worldInfo.presetPaths.haudoanh1 then
			firstPoint = worldInfo.presetPaths.haudoanh1[1]
			firstPointX, firstPointY = nodeNameToCoords(firstPoint)
			dist1 = GetDistanceRadius(pX, pY, firstPointX, firstPointY)

			if (userCamp == forCamp and dist1 < 50) or 
				(userCamp ~= forCamp and dist1 > 100) then
				myPath = { {"haudoanh1", 1} }
			else
				myPath = nil
			end


		elseif worldInfo.presetPaths.haudoanh2 then
			secondPoint = worldInfo.presetPaths.haudoanh2[1]
			secondPointX, secondPointY = nodeNameToCoords(secondPoint)
			dist2 = GetDistanceRadius(pX, pY, secondPointX, secondPointY)
			
			if (userCamp == forCamp and dist2 < 50) or 
				(userCamp ~= forCamp and dist2 > 100) then
				myPath = { {"haudoanh2", 1} }
			else
				myPath = nil
			end
		end

		if myPath then
 			local fighter = self:taoNV(id, forCamp, worldInfo, myPath, ngoaitrang, nil, capHP, {
				baoDanhTongKim = 1
			})
			if fighter then 
				total = total + 1
			end
		end
		if forCamp == 1 then
			forCamp = 2
		else
			forCamp = 1
		end

	end
	
end