--Include("\\script\\global\\vinh\\simcity\\head.lua")
Include("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua")
SimCityMainVanTieu = {
	player2TieuXa = {}
}

function SimCityMainVanTieu:InitWorld()
	for nW, routeMap in VT_ROUTES do
		local worldInfo = SimCityWorld:Get(nW)
		if not worldInfo.name then
			SimCityWorld:New({
				worldId = nW,
				name = "VËn tiªu",
				walkPaths = routeMap,
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
	local npcXeTieu = 682
	local mapID = nW
	local children5 = {
		{ 43,   3, { szName = "Heo n¸i" } },
		{ 43,   3, { szName = "Heo näc" } },
		--{42, 2, {szName = "H­u sao"}},
		--{13, 2, {szName = "Voi b¶n ®«n"}},

		--{2146, 1, {szName = "Xe l­¬ng thùc"}},
		--{2147, 1, {szName = "Xe quÇn ¸o"}},
		{ 2148, 1, { szName = "Xe cña c¶i" } },

		--{682,  4, {szName = "Gia nh©n"}}
	}
	local mapData = VT_ROUTES[nW]


	local name = "Qu¶n gia"
	local realCamp = GetCurCamp()

	-- Theo sau
	local children = {}
	for i = 1, getn(children5) do
		children = spawnN(children, children5[i][1], children5[i][2], children5[i][3])
	end

	-- Attackers
	local attackCounts = random(0, 4) -- toi da 4 lan bi tan cong
	local attackTypes = {}
	for i = 1, attackCounts do
		tinsert(attackTypes, random(0, 2)) -- 0: theo sau choi 1: theo sau va cuop 2: cuop truc tiep
		--if random(1,2) > 1 then
		--	tinsert(attackTypes, 3)			-- 3: bay duong mon
		--end
		--tinsert(attackTypes, random(1,2))
	end


	local nListId = SimCitizen:New({
		mode = "vantieu",
		szName = name,

		nNpcId = npcXeTieu,  -- required, main char ID
		nMapId = mapData[1][1], -- required, map
		camp = realCamp,     -- optional, camp 0 trang 1 cp 2 tp 3 tl 4 sat thu 5 quai
		children = children, -- optional, children
		childrenCheckDistance = 8, -- force distance check for child


		walkMode = "formation", -- optional: random or 1 for formation
		originalWalkPath = {},
		mapData = mapData,
		walkPath = {},
		noStop = 1,          -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 1, -- optional: leave fight instantly after no enemy, otherwise there's waiting period

		noRevive = 1,        -- optional: 0: keep reviving, 1: dead

		hardsetPos = 1,

		CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = 1, -- co hoi bat chien dau khi thay NPC khac phe
		CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		RADIUS_FIGHT_PLAYER = 15, -- scan for player around and randomly attack
		RADIUS_FIGHT_NPC = 1, -- scan for NPC around and start randomly attack,
		RADIUS_FIGHT_SCAN = 15, -- scan for fight around and join/leave fight it
 
		kind = 0,           -- quai mode
		TIME_FIGHTING_minTs = 5,
		TIME_FIGHTING_maxTs = 5 * 60,
		TIME_RESTING_minTs = 1,
		TIME_RESTING_maxTs = 3,

		resetPosWhenRevive = 0,


		underAttack = {
			types          = attackTypes,
			pointer        = 0,
			locations      = {},
			isConfirmation = 0,
			rebelChance    = 100, -- 1/100 every tick

			attackerIds    = { 1786, 1787, 1788, 1789, 1790, 1791, 1792, 1793, 1794, 1795 }
		}
	})
	if nListId > 0 then
		self.player2TieuXa[GetName()] = nListId
	end
end
