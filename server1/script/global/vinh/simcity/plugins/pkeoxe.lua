Include("\\script\\lib\\timerlist.lua")

SimCityKeoXe = {
	ALLXE = {

		{ 1355, 1356, 523,  1358, 513,  1360, 1361, 1362, 511,  1364, },
		{ 566,  739,  567,  568,  741,  1366, 742,  582,  743,  1365, 740, },
		{ 744,  745,  583,  565,  563,  748,  746,  562,  1367, 1368, 747, },
		{ 1194, 1193, 1195, 1196, 1197, 1198, 1199, 1200, 1201, 1202, 1231, },
		{ 1875, 1874, 1873, },
		{ 1466, 1437, 1479, 1438, },
	},

	collections = {},
	collections_knownPoint = {}

}


function createTaskSayKeoxe()
	local tbOpt = {}
	local nSettingIdx = 103
	local nActionId = 1
	tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">V« Kþ ca:<link> Nh©n sinh nh­ méng, tr­êng l­u v« tËn, gÆp gì chØ lµ tho¸ng qua");
	return tbOpt
end

function SimCityKeoXe:taoNV(id, camp, mapID, map, nt, theosau, capHP, extraConfig)
	local name = GetName()
	local rank = 1

	local tbNpc = {

		szName = SimCityNPCInfo:generateName(),

		nNpcId = id,   -- required, main char ID
		nMapId = mapID, -- required, map
		camp = camp,   -- optional, camp

		walkMode = "random", -- optional: random, keoxe, or 1 for formation
		walkVar = 2,   -- random walk of radius of 4*2
		

		noStop = 1,          -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5, -- optional: leave fight instantly after no enemy, otherwise there's waiting period

		noRevive = 0,        -- optional: 0: keep reviving, 1: dead

		CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = 1, -- co hoi bat chien dau khi thay NPC khac phe
		CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		RADIUS_FIGHT_PLAYER = 15, -- scan for player around and randomly attack
		RADIUS_FIGHT_NPC = 10, -- scan for NPC around and start randomly attack,
		RADIUS_FIGHT_SCAN = 10, -- scan for fight around and join/leave fight it
 
		kind = 0,            -- quai mode
		TIME_FIGHTING_minTs = 1800,
		TIME_FIGHTING_maxTs = 3000,
		TIME_RESTING_minTs = 0,
		TIME_RESTING_maxTs = 1,


		ngoaitrang = nt or 0,

		childrenSetup = theosau or nil,
		childrenCheckDistance = (theosau and 8) or nil, -- force distance check for child

		playerID = name,
		capHP = capHP,
		role = "keoxe"

	};
	if extraConfig then
		for k, v in extraConfig do
			tbNpc[k] = v
		end
	end
	local nListId = SimTheoSau:New(tbNpc);

	if not self.collections[name] then
		self.collections[name] = {}
	end

	if nListId > 0 then
		tinsert(self.collections[name], nListId)
	end

	return nListId
end

function SimCityKeoXe:nv_tudo_xe(capHP)
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()
	local pool = SimCityNPCInfo:getPoolByCap(capHP)

	-- 10 con theo sau
	for i = 1, 10 do
		local pid = pool[random(1, getn(pool))]


		while SimCityNPCInfo:notFightingChar(pid) == 1 do
			pid = pool[random(1, getn(pool))]
		end

		local children = {}
		self:taoNV(pid, forCamp, pW, {}, 1, children, capHP)
	end
end

function SimCityKeoXe:goiAnhHungThiepNgoaiTrang()
	local tbSay = createTaskSayKeoxe()


	tinsert(tbSay, "§Ö tö tinh anh/#SimCityKeoXe:nv_tudo_xe(1)")
	tinsert(tbSay, "Cao thñ nhÊt l­u/#SimCityKeoXe:nv_tudo_xe(2)")
	tinsert(tbSay, "TuyÖn ®Ønh cao thñ/#SimCityKeoXe:nv_tudo_xe(3)")
	tinsert(tbSay, "Vâ l©m chÝ t«n/#SimCityKeoXe:nv_tudo_xe(4)")

	tinsert(tbSay, "Quay l¹i./#SimCityKeoXe:mainMenu()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityKeoXe:goiAnhHungThiep()
	local tbSay = createTaskSayKeoxe()

	-- Chon xe nao
	tinsert(tbSay, "Më tÊt c¶/#SimCityKeoXe:taonhanhnhom_confirm(0)")

	for i = 1, getn(self.ALLXE) do
		tinsert(tbSay, format("Më nhãm %d/#SimCityKeoXe:taonhanhnhom_confirm(%d)", i, i))
	end

	tinsert(tbSay, "Quay l¹i./#SimCityKeoXe:mainMenu()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityKeoXe:taonhanhnhom_confirm(mode)
	local ALLXE = self.ALLXE
	-- 0 = all in
	if (mode == 0) then
		for i = 1, getn(ALLXE) do
			self:tao1xe(ALLXE[i], ngoaitrang)
		end
		-- Mode 0: full 5 xe
	elseif (mode > 0 and mode <= getn(ALLXE)) then
		self:tao1xe(ALLXE[mode], ngoaitrang)
	end
end

function SimCityKeoXe:tao1xe(data)
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()

	-- 10 con theo sau
	for i = 1, getn(data) do
		local pid = data[i]
		local children = {}
		self:taoNV(pid, forCamp, pW, {}, 0, children, 0)
	end
end

function SimCityKeoXe:ketgiaoNgauNhien()
	local tbSay = createTaskSayKeoxe()
	local phai = random(1, 10)
	local ten = SimCityNPCInfo:generateName()
	local gen = random(1,2)
	if phai == 2 then 
		gen = 1
	elseif	phai == 7 or phai == 8 then
		gen = 2
	end 
	self.randomName = {ten}
	SimCityKeoXe:taoBangHuu(phai, gen, 1)
	return 1
end

function SimCityKeoXe:ketgiaoPhai(phai)
	local tbSay = createTaskSayKeoxe()	
	if phai == 0 then
		tinsert(tbSay, "Giang hå l·ng tö/#SimCityKeoXe:ketgiaoNgauNhien()")
		tinsert(tbSay, "Thiªn V­¬ng Bang/#SimCityKeoXe:ketgiaoPhai(1)")
		tinsert(tbSay, "ThiÕu L©m/#SimCityKeoXe:ketgiaoPhai(2)")
		tinsert(tbSay, "Vâ §ang/#SimCityKeoXe:ketgiaoPhai(3)")
		tinsert(tbSay, "C«n L«n/#SimCityKeoXe:ketgiaoPhai(4)")
		tinsert(tbSay, "§­êng M«n/#SimCityKeoXe:ketgiaoPhai(5)")
		tinsert(tbSay, "Ngò §éc/#SimCityKeoXe:ketgiaoPhai(6)")
		tinsert(tbSay, "Nga Mi/#SimCityKeoXe:ketgiaoPhai(7)")
		tinsert(tbSay, "Thóy Yªn/#SimCityKeoXe:ketgiaoPhai(8)")
		tinsert(tbSay, "C¸i Bang/#SimCityKeoXe:ketgiaoPhai(9)")
		tinsert(tbSay, "Thiªn NhÉn/#SimCityKeoXe:ketgiaoPhai(10)")				
		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	else
		self.randomName = {}
		for i=1, 5 do
			self.randomName[i] = SimCityNPCInfo:generateName()
			local gen = random(1,2)
			if phai == 2 then 
				gen = 1
			elseif	phai == 7 or phai == 8 then
				gen = 2
			end

			local gioiTinh = "Nam"
			if gen == 2 then
				gioiTinh = "N÷"
			end

			
			local ten = self.randomName[i]

			tinsert(tbSay, format("%s (%s)/#SimCityKeoXe:taoBangHuu(%s, %d, %s)", ten, gioiTinh, phai, gen, i))
		end
		tinsert(tbSay, format("T×m thªm/#SimCityKeoXe:ketgiaoPhai(%d)", phai))
		tinsert(tbSay, format("Quay l¹i/#SimCityKeoXe:ketgiaoPhai(%d)", 0))
		tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")

	end
	
	CreateTaskSay(tbSay)
	return 1
end 

function SimCityKeoXe:taoBangHuu(phai, gen, tenIndex)
	local ten = self.randomName[tenIndex]
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()
	local tenPhai = "thienvuongbang"
	if phai == 2 then
		tenPhai = "thieulam"
	elseif phai == 3 then
		tenPhai = "vodang"
	elseif phai == 4 then
		tenPhai = "conlon"
	elseif phai == 5 then
		tenPhai = "duongmon"
	elseif phai == 6 then
		tenPhai = "ngudoc"
	elseif phai == 7 then
		tenPhai = "ngami"
	elseif phai == 8 then
		tenPhai = "thuyyen"
	elseif phai == 9 then
		tenPhai = "caibang"
	elseif phai == 10 then
		tenPhai = "thiennhan"				
	end
	-- 1193, 1786, 1481, 1765: thienvuongbang
	-- 1194, 1787, 1766: thieulam
	-- 1196, 1788, 1488, 1767: ngudoc
	-- 1195, 1789, 1485, 1768: duongmon
	-- 1197, 1790, 1483, 1769: ngami
	-- 1198, 1791, 1482, 1770: thuyyen
	-- 1201, 1792, 1480 (thien ngoai), 1484 (van long kich), 1771 (thien ngoai): thiennhan 
	-- 1199, 1793, 1489, 1772: caibang
	-- 1200, 1794, 1486, 1773: vodang
	-- 1202, 1795, 1487, 1774: conlon

	local id = 1193
	local pool = {1193}
	local series = 0
	if tenPhai == "thienvuongbang" then
		pool = {1193, 1481, 1484, 1765, 1786}
	elseif tenPhai == "thieulam" then
		pool = {1194, 1787, 1766}
	elseif tenPhai == "ngudoc" then
		series = 1
		pool = {1196, 1788, 1488, 1767}
	elseif tenPhai == "duongmon" then
		series = 1
		pool = {1195, 1789, 1485, 1768}
	elseif tenPhai == "ngami" then
		series = 2
		pool = {1197, 1790, 1483, 1769}
	elseif tenPhai == "thuyyen" then
		series = 2
		pool = {1198, 1791, 1482, 1770}
	elseif tenPhai == "thiennhan" then
		series = 3
		pool = {1200, 1792, 1480, 1771}
	elseif tenPhai == "caibang" then
		series = 3
		pool = {1199, 1793, 1489, 1772}
	elseif tenPhai == "vodang" then
		series = 4
		pool = {1201, 1794, 1486, 1773}
	elseif tenPhai == "conlon" then
		series = 4
		pool = {1202, 1795, 1487, 1774}
	end

	id = pool[random(1, getn(pool))]
	local realGen = -2
	if gen == 1 then
		realGen = -1
	end
	
	self:taoNV(id, forCamp, pW, 1, 1, {}, 1, {
		szName = ten,
		nSettingsIdx = realGen,
		series = series
	})
	
end

function SimCityKeoXe:mainMenu()
	local tbSay = createTaskSayKeoxe()

	tinsert(tbSay, "KÕt giao b»ng h÷u/#SimCityKeoXe:ketgiaoPhai(0)")
	tinsert(tbSay, "KÕt giao nhãm anh hïng/#SimCityKeoXe:goiAnhHungThiepNgoaiTrang()")
	tinsert(tbSay, "KÕt giao nhãm qu¸i nh©n/#SimCityKeoXe:goiAnhHungThiep()")
	--tinsert(tbSay, "ThiÕt lËp/#SimCityKeoXe:caidat()")
	tinsert(tbSay, "T¹o b·i luyÖn c«ng/#SimCityKeoXe:luyencong()")
	tinsert(tbSay, "Gi¶i t¸n/#SimTheoSau:RemoveAll()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)

	return 1
end

function SimCityKeoXe:askBaiLevel()
	g_AskClientNumberEx(0, 110, "CÊp qu¸i", { self.askBaiLevel_confirm , {self}})
end
function SimCityKeoXe:askBaiLevel_confirm(inp)
	local level = tonumber(inp)
	level = floor(level/10) * 10
	self:TaoBai(level)
end
function SimCityKeoXe:luyencong()
	local tab_Content = {
		
		"Tù ®éng/#SimCityKeoXe:TaoBai(999)",
		"Chän cÊp/#SimCityKeoXe:askBaiLevel()",
		"Xãa qu¸i xung quanh/#SimCityKeoXe:XoaBai()",
		"Tho¸t/no",
	}
	Say("Chän nhãm qu¸i", getn(tab_Content), tab_Content);
end

function SimCityKeoXe:XoaBai()
	local fighterList = GetAroundNpcList(30)
	local pW, pX, pY = GetWorldPos()

	local tmpFound = {}
	local nNpcIdx
	for i = 1, getn(fighterList) do
		nNpcIdx = fighterList[i]
		local kind = GetNpcKind(nNpcIdx)
		local nSettingIdx = GetNpcSettingIdx(nNpcIdx)
		if nSettingIdx > 0 and kind == 0 then
			DelNpc(nNpcIdx)
		end
	end
	return 0
end

function SimCityKeoXe:TaoBai(forceLevel)
	-- Tam thoi xoa xe de tao NPC tu dong neu khong se copy NPC tu xe vao luon
	if (forceLevel == 999) then
		SimTheoSau:RemoveAll()
	end

	local fighterList = GetAroundNpcList(60)
	local pW, pX, pY = GetWorldPos()

	local tmpFound = {}
	local nNpcIdx
	for i = 1, getn(fighterList) do
		nNpcIdx = fighterList[i]
		local nSettingIdx = GetNpcSettingIdx(nNpcIdx)
		local name = GetNpcName(nNpcIdx)
		local level = NPCINFO_GetLevel(nNpcIdx)
		local kind = GetNpcKind(nNpcIdx)
		if nSettingIdx > 0 and kind == 0 then
			tinsert(tmpFound, { nSettingIdx, name, level })
		end
	end
	local total = getn(tmpFound)

	if total == 0 then
		return 0
	end
	local j = 0
	while j < 20 do
		local data = tmpFound[random(1, total)]
		local isBoss = 0
		if (j == 10) then
			isBoss = 2
		end
		local targetLevel = data[3]
		if (forceLevel < 999 and ((targetLevel > forceLevel) or (targetLevel > 90))) then
			targetLevel = forceLevel
		end
		local nNpcIndex = AddNpcEx(data[1], targetLevel, random(0, 4), SubWorldID2Idx(pW), (pX + random(-5, 5)) * 32,
			(pY + random(-5, 5)) * 32, 0, data[2], isBoss)
		if nNpcIndex > 0 then
			j = j + 1
		end
	end
	return 0
end

function SimCityKeoXe:ATick()
	-- Get info for npc in this world
	for name, children in self.collections do
		local parentID = SearchPlayer(name)

		if parentID > 0 then
			local pW, pX, pY = CallPlayerFunction(parentID, GetWorldPos)
			local newLoc = "" .. pW .. pY .. pX
			if not self.collections_knownPoint[name] or self.collections_knownPoint[name] ~= newLoc then
				self.collections_knownPoint[name] = newLoc
				local size = getn(children)
				local centerCharId = getCenteredCell(createFormation(size))
				local fighter = SimTheoSau:Get(children[centerCharId])
				local nX, nY, nMapIndex = GetNpcPos(fighter.finalIndex)
				local newPath = genCoords_squareshape({ nX / 32, nY / 32 }, { pX, pY }, size)
				for i = 1, size do
					SimTheoSau:Get(children[i]).parentAppointPos = newPath[i]
				end
			end
		end
	end

end
