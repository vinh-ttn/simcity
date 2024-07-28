--Include("\\script\\global\\vinh\\simcity\\head.lua")
Include("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua")
SimCityMainVanTieu = {
	player2TieuXa = {}
}

function SimCityMainVanTieu:InitWorld()
	for nW,routeMap in VT_ROUTES do
	 	local worldInfo = SimCityWorld:Get(nW)
		if not worldInfo.name then
			SimCityWorld:New({
				worldId = nW, 
				name = "VÀn ti™u", 
				walkAreas = routeMap, 				
				allowChat = 0,
				showFightingArea = 1,
				allowFighting = 1
			})
		end
	end
end
function SimCityMainVanTieu:tao1xe()
	local nW = "vt_test"

	--
	-- [1] = {nId=2146, nLevel=95}, 
	-- [2] = {nId=2147, nLevel=95}, 
	-- [3] = {nId=2148, nLevel=95}, 
	local npcXeTieu = 681 
 	local mapID = nW
 	local children5 = {		
		{43, 2, {szName = "Heo n∏i"}},
		{43, 2, {szName = "Heo n‰c"}},
		{42, 2, {szName = "H≠u sao"}},
		{13, 2, {szName = "Voi b∂n Æ´n"}},

		{2146, 1, {szName = "Xe l≠¨ng th˘c"}},
		{2147, 1, {szName = "Xe qu«n ∏o"}},
		{2148, 1, {szName = "Xe cÒa c∂i"}},
		
		{682,  4, {szName = "Gia nh©n"}}
	}
	local mapData = VT_ROUTES[nW]

	
	local name = "Qu∂n gia"
	local realCamp = GetCurCamp()
		
 	-- Theo sau
 	local children = {}
	for i=1,getn(children5) do
		children = spawnN(children, children5[i][1], children5[i][2], children5[i][3])
	end

	-- Attackers
	local attackCounts = random(0,4) -- toi da 4 lan bi tan cong
	local attackTypes = {}
	for i=1,attackCounts do
		tinsert(attackTypes, random(0,2)) -- 0: theo sau choi 1: theo sau va cuop 2: cuop truc tiep
		--if random(1,2) > 1 then
		--	tinsert(attackTypes, 3)			-- 3: bay duong mon
		--end
		--tinsert(attackTypes, random(1,2))
	end
	

	local nListId = XeTieu:New({
		szName = name,

		nNpcId = npcXeTieu,						-- required, main char ID
		nMapId = mapData[1][1],		-- required, map
		camp = realCamp,			-- optional, camp 0 trang 1 cp 2 tp 3 tl 4 sat thu 5 quai 
		children = children, -- optional, children
		childrenCheckDistance = 8,   -- force distance check for child


		walkMode = 1,	-- optional: random or 1 for formation
		tbPos = {},
		mapData = mapData,
		walkPath={},
		noStop = 1,				-- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 1,	-- optional: leave fight instantly after no enemy, otherwise there's waiting period
		
		noRevive = 1,			-- optional: 0: keep reviving, 1: dead

		hardsetPos = 1,

		attackPlayerChance = 1,	-- co hoi tan cong nguoi choi neu di ngang qua
		attackNpcChance = 1,	-- co hoi bat chien dau khi thay NPC khac phe
		joinFightChance = 1,	-- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		fightPlayerRadius = 15,	-- scan for player around and randomly attack
		attackNpcRadius = 1,	-- scan for NPC around and start randomly attack,
		fightScanRadius = 15,	-- scan for fight around and join/leave fight it

		noBackward = 1,			-- do not walk backward
		kind = 0,				-- quai mode
		tg_danhnhau_minTs = 5,
		tg_danhnhau_maxTs = 5*60,
		tg_nghingoi_minTs = 1,
		tg_nghingoi_maxTs = 3,

		resetPosWhenRevive = 0,

		ownerID = GetName(),

		underAttack = {
			types = attackTypes,
			pointer = 0,
			locations = {},
			isConfirmation = 0,
			rebelChance  = 100,  -- 1/100 every tick

			attackerIds = {1786,1787,1788,1789, 1790, 1791,1792,1793,1794,1795}
		}
	})
	if nListId > 0 then
		self.player2TieuXa[GetName()] = nListId
	end

	
end 
 
function SimCityMainVanTieu:getTieuXa()
	local nListId = self.player2TieuXa[GetName()] or 0

	if nListId == 0 then
		return nil
	end
	return XeTieu:Get(nListId)

end

function SimCityMainVanTieu:gotoTieuXa()
 	local tbNpc = self:getTieuXa()
	local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
	local areaX = nX32/32
	local areaY = nY32/32
	local nW = SubWorldIdx2ID(nW32)

	NewWorld(nW, areaX, areaY)

end
 
function SimCityMainVanTieu:hoanthanhTieuXa(force)
 	local tbNpc = self:getTieuXa()

	if force == 0 and tbNpc.finished == nil then
		return Talk(1, "", "Ti™u xa v…n Æang tr™n Æ≠Íng di chuy”n")
	end

	if tbNpc.finishedReason == 1 then 
		Talk(2, "", "Hoµn thµnh nhi÷m vÙ", "Xin h∑y nhÀn ph«n th≠Îng, h∑y cË gæng l™n!")
		Earn(100000)
		AddSkillState( 509, 1, 0, 180);
	else 
		Talk(1, "", "Nhi÷m vÙ th t bπi")
	end

	XeTieu:Remove(tbNpc.nNpcListIndex)
	self.player2TieuXa[GetName()] = 0
end

function SimCityMainVanTieu:mainMenu()
	self:InitWorld() 
 
	SetFightState(0)

 	local tbSay = {"Nhi÷m vÙ hÈ tËng"}
 	local tbNpc = self:getTieuXa()

 	if tbNpc == nil then
		tinsert(tbSay, "B∂o v÷ b∏ t∏nh/#SimCityMainVanTieu:tao1xe()")
	else
 		tinsert(tbSay, "Di chuy”n tÌi vﬁ tr› ti™u xa/#SimCityMainVanTieu:gotoTieuXa()")
 		tinsert(tbSay, "Hoµn thµnh nhi÷m vÙ/#SimCityMainVanTieu:hoanthanhTieuXa(0)") 	
 		tinsert(tbSay, "HÒy b· nhi÷m vÙ/#SimCityMainVanTieu:hoanthanhTieuXa(1)") 	
		end

    tinsert(tbSay, "K’t thÛc ÆËi thoπi./no")
    CreateTaskSay(tbSay)  
	return 1 
end


function SimCityMainVanTieu:addNpcs()
	add_dialognpc({ 
		{1617,78,1610,3235,"\\script\\global\\vinh\\simcity\\controllers\\vantieu.lua","Tri÷u M…n"}, -- TD
		{1617,37,1719,3091,"\\script\\global\\vinh\\simcity\\controllers\\vantieu.lua","Tri÷u M…n"}, -- BK
		{1617,11,3158,5082,"\\script\\global\\vinh\\simcity\\controllers\\vantieu.lua","Tri÷u M…n"}, -- TD
		{1617,1,1569,3198,"\\script\\global\\vinh\\simcity\\controllers\\vantieu.lua","Tri÷u M…n"}, -- PT
		{1617,162,1603,3157,"\\script\\global\\vinh\\simcity\\controllers\\vantieu.lua","Tri÷u M…n"}, -- DL
		{1617,80,1785,3034,"\\script\\global\\vinh\\simcity\\controllers\\vantieu.lua","Tri÷u M…n"}, -- DC
		{1617,176,1585,2932,"\\script\\global\\vinh\\simcity\\controllers\\vantieu.lua","Tri÷u M…n"}, -- LA
	})
end


function main()
	return SimCityMainVanTieu:mainMenu()
end
