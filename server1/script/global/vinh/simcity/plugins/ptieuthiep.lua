SimCityTieuThiep = { 
	collections = {},
	collections_knownPoint = {} 
}


function createTaskSayTieuThiep()
	local tbOpt = {}

	local name = GetName()

	local foundId
	for key, fighter in SimTheoSau.fighterList do
        if fighter.playerID == name and fighter.mode == "tieuthiep" then
            foundId = fighter.nNpcId
        end
    end

	local nSettingIdx = foundId or 103


	local nActionId = 1
	tinsert(tbOpt, 1, "<dec><link=image[0,10]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">V« Kþ:<link> Nh©n sinh nh­ méng, tr­êng l­u v« tËn, gÆp gì chØ lµ tho¸ng qua");
	return tbOpt
end

function SimCityTieuThiep:taoNV(id, camp, mapID, map, nt, theosau, capHP, extraConfig)
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
		leaveFightWhenNoEnemy = 1, -- optional: leave fight instantly after no enemy, otherwise there's waiting period

		noRevive = 0,        -- optional: 0: keep reviving, 1: dead

		CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = 1, -- co hoi bat chien dau khi thay NPC khac phe
		CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		RADIUS_FIGHT_PLAYER = 15, -- scan for player around and randomly attack
		RADIUS_FIGHT_NPC = 10, -- scan for NPC around and start randomly attack,
		RADIUS_FIGHT_SCAN = 10, -- scan for fight around and join/leave fight it
 
		kind = 3,            -- quai mode
		TIME_FIGHTING_minTs = 1800*18/REFRESH_RATE,
		TIME_FIGHTING_maxTs = 3000*18/REFRESH_RATE,
		TIME_RESTING_minTs = 60*18/REFRESH_RATE,
		TIME_RESTING_maxTs = 120*18/REFRESH_RATE,


		ngoaitrang = nt or 0,

		childrenSetup = theosau or nil,
		childrenCheckDistance = (theosau and 8) or nil, -- force distance check for child

		playerID = name,
		capHP = capHP,
		role = "keoxe",
		mode = "tieuthiep"
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



function SimCityTieuThiep:nhanTieuThiep(id)

	local xemNpcIds = { 
		{1198, "TriÖu MÉn"},
		{1309, "TÇn Hång Miªn"},
		{1332, "Cam B¶o B¶o"},
		{1360, "A Ch©u"},
		{1439, "Lam Ph­îng Hoµng"},
		{1504, "NhËm Doanh Doanh"},
		{1678, "Chu ChØ Nh­îc"},
		{1679, "§ao B¹ch Ph­îng"},
		{1770, "Hoµng Dung"},
		{2424, "¢n Ly"},
	}

	if id < 1 then
		id = 1
	end
	if id > getn(xemNpcIds) then
		id = 1
	end

	local tbOpt = {}
	local nSettingIdx = xemNpcIds[id][1]
	local nName = xemNpcIds[id][2]
	local nActionId = 1
	tinsert(tbOpt, 1, "<dec><link=image[0,108]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">V« Kþ:<link><enter><enter>Ng­¬i cã muèn nµng <color=yellow>"..nName.."<color> hµnh tÈu giang hå cïng ng­¬i?");

	tinsert(tbOpt, format("Chän %s/#SimCityTieuThiep:nhanTieuThiepConfirm('%s', %s)", nName, nName, nSettingIdx))	
	tinsert(tbOpt, "Xem kÕ tiÕp/#SimCityTieuThiep:nhanTieuThiep("..(id+1)..")")
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)

	return 1
end

function SimCityTieuThiep:nhanTieuThiepConfirm(name, id)
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()
	self:RemoveAll()
	self:taoNV(id, forCamp, pW, 1, 0, {}, 1, {
		szName = name .. " cña ".. GetName(),
		nSettingsIdx = id,
		series = 2,
		kind = 3,
		faction = "ngami",
		skillHoTro = 5,
		skillTranPhai = {109, 20},
		skillCastBua = {93, 20}
	})
end
 

function SimCityTieuThiep:GoiPTToiNoi()
    local nW, nX, nY = GetWorldPos();
    local nFightMode = GetFightState();

    local nPreservedPlayerIndex = PlayerIndex;
    local nMemCount = GetTeamSize(); 

    if (nMemCount == 0) then
		Msg2Player("Kh«ng cã ai trong PT ®Ó gäi")
        return 0
    end


    for i = 1, nMemCount do
        PlayerIndex = GetTeamMember(i); 
        SetFightState(nFightMode)
        NewWorld(nW, nX, nY);
    end;

    PlayerIndex = nPreservedPlayerIndex;
    return 0
end

function SimCityTieuThiep:DenNoiTeXe()
    local nW = GetTask(801)
    local nX = GetTask(802)
    local nY = GetTask(803)
    if (nW ~= nil and nX ~= nil and nY ~= nil and nW > 0 and nY > 0 and nX > 0) then
        NewWorld(nW, nX, nY)
        SetFightState(1)
        SetTask(801, 0)
    else
        ReturnFromPortal()
    end
end

function SimCityTieuThiep:GoiBangToiNoi()
    local szTongName, nTongID   = GetTongName()
    local nMemberID             = TONG_GetFirstMember(nTongID, -1);
    local nPreservedPlayerIndex = PlayerIndex;
    local nW, nX, nY            = GetWorldPos();
    local nFightMode            = GetFightState();

    while (nMemberID > 0) do
        local pName = TONGM_GetName(nTongID, nMemberID)
        local index = SearchPlayer(pName)
        if index ~= nPreservedPlayerIndex and index > 0 then
            PlayerIndex = index
            SetFightState(nFightMode)
            NewWorld(nW, nX, nY) 
        end

        nMemberID = TONG_GetNextMember(nTongID, nMemberID, -1)
    end

    PlayerIndex = nPreservedPlayerIndex
end

function SimCityTieuThiep:trieuhoi()
	local tbOpt = createTaskSayTieuThiep()
	tinsert(tbOpt, "Gäi PT ®Õn ®©y/SimCityTieuThiep:GoiPTToiNoi()")
	tinsert(tbOpt, "Gäi bang ®Õn ®©y/SimCityTieuThiep:GoiBangToiNoi()")
	tinsert(tbOpt, "§Õn n¬i tÐ xe/SimCityTieuThiep:DenNoiTeXe()")
	tinsert(tbOpt, "Quay l¹i/#SimCityTieuThiep:mainMenu()")
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)
end

function SimCityTieuThiep:muathuoc()
	local tbOpt = createTaskSayTieuThiep()

	tinsert(tbOpt, "Mau cho ta xin Ýt thuèc/#SimCityTieuThiep:nhan5hoa()")
	tinsert(tbOpt, "Mau cho ta xin TDP/#SimCityTieuThiep:nhanTDP()")
 
	tinsert(tbOpt, "Quay l¹i/#SimCityTieuThiep:mainMenu()")
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)
end

function SimCityTieuThiep:nhan5hoa()
	local nW, nX, nY = GetWorldPos()
	for i=1, 25 do
		DropItem(SubWorldID2Idx(nW), nX*32, nY*32, -1, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	end
end

function SimCityTieuThiep:nhanTDP()
	local nW, nX, nY = GetWorldPos()
	for i=1, 3 do
		DropItem(SubWorldID2Idx(nW), nX*32, nY*32, -1, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	end
end

function SimCityTieuThiep:mainMenu()

	local tbOpt = createTaskSayTieuThiep()
	local name = GetName()
	local isStanding = 0
	for key, fighter in SimTheoSau.fighterList do        
        if fighter.playerID == name and fighter.mode == "tieuthiep" and fighter.isStanding == 1 then
            isStanding = 1
        end
    end
	if isStanding == 1 then
		tinsert(tbOpt, "H·y ®i theo ta/#SimCityTieuThiep:SetStanding(0)")
	else
		tinsert(tbOpt, "H·y ®øng l¹i ®©y chê ta/#SimCityTieuThiep:SetStanding(1)")
	end

	tinsert(tbOpt, "LÊy thuèc, thæ ®Þa phï/#SimCityTieuThiep:muathuoc()")
	tinsert(tbOpt, "Gäi thµnh viªn PT, bang héi/#SimCityTieuThiep:trieuhoi()")
	tinsert(tbOpt, "T¹o b·i luyÖn c«ng/#SimCityTieuThiep:luyencong()")
	tinsert(tbOpt, "T×m V« Kþ, TriÖu MÉn vµ L·o §éng VËt/#SimCityTieuThiep:simcityMenu()")	
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)
	return 1
end

function SimCityTieuThiep:SetStanding(isStanding)
	local name = GetName()
	for key, fighter in SimTheoSau.fighterList do
		if fighter.playerID == name and fighter.mode == "tieuthiep" then
			fighter.isStanding = isStanding
		end
	end
end

function SimCityTieuThiep:simcityMenu()	
	local tbOpt = createTaskSayTieuThiep()
	tinsert(tbOpt, "GÆp TriÖu MÉn (thµnh thÞ)/#SimCityThanhThi:mainMenu()")
	tinsert(tbOpt, "GÆp V« Kþ (kÐo xe)/#SimCityKeoXe:mainMenu()")
	tinsert(tbOpt, "GÆp L·o §éng VËt (thó c­ng)/#SimCityVatNuoi:mainMenu()")
	tinsert(tbOpt, "Quay l¹i/#SimCityTieuThiep:mainMenu()")
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)
	return 1
end


function SimCityTieuThiep:RemoveAll()
	local name = GetName()

	if self.collections[name] then
		self.collections[name] = nil
	end
	
	for key, fighter in SimTheoSau.fighterList do
        if fighter.playerID == name and fighter.mode == "tieuthiep" then
            SimTheoSau:Remove(fighter.id)
        end
    end
end

function SimCityTieuThiep:askBaiLevel()
	g_AskClientNumberEx(0, 110, "CÊp qu¸i", { self.askBaiLevel_confirm , {self}})
end
function SimCityTieuThiep:askBaiLevel_confirm(inp)
	local level = tonumber(inp)
	level = floor(level/10) * 10
	self:TaoBai(level)
end
function SimCityTieuThiep:luyencong()
	local tbOpt = createTaskSayTieuThiep()
	tinsert(tbOpt, "Tù ®éng/#SimCityTieuThiep:TaoBai(999)")
	tinsert(tbOpt, "Chän cÊp/#SimCityTieuThiep:askBaiLevel()")
	tinsert(tbOpt, "Xãa qu¸i xung quanh/#SimCityTieuThiep:XoaBai()")
	tinsert(tbOpt, "Quay l¹i/#SimCityTieuThiep:mainMenu()")
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)
end

function SimCityTieuThiep:XoaBai()
	local fighterList = GetAroundNpcList(30)
	local pW, pX, pY = GetWorldPos()

	local tmpFound = {}
	local nNpcIdx
	for i = 1, getn(fighterList) do
		nNpcIdx = fighterList[i]
		local kind = GetNpcKind(nNpcIdx)
		local nSettingIdx = GetNpcSettingIdx(nNpcIdx)
		if nSettingIdx > 0 and kind == 0 then
			DelNpcSafe(nNpcIdx)
		end
	end
	return 0
end

function SimCityTieuThiep:TaoBai(forceLevel)
	-- Tam thoi xoa xe de tao NPC tu dong neu khong se copy NPC tu xe vao luon
	 

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