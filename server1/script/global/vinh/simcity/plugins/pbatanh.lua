Include("\\script\\lib\\timerlist.lua")

-- Data structure
-- hello1 = {
--     	children = { id1, id2, id3 },
-- 		player_location = {nW, nX, nY},
--      nW, nX, nY,
-- 		finished, finishedReason
-- }

SimCityBaTanh = {
	player2TieuXa = {

	}
}
function SimCityBaTanh:CreateChar(config)
	local finalChar = {

		walkMode = "formation", -- optional: random, keoxe, or 1 for formation
		walkVar = 2,         -- random walk of radius of 4*2

		noStop = 1,          -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5, -- optional: leave fight instantly after no enemy, otherwise there's waiting period

		noRevive = 1,        -- optional: 0: keep reviving, 1: dead

		CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
		attackNpcChance = 1, -- co hoi bat chien dau khi thay NPC khac phe
		CHANCE_ATTACK_NPC = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		RADIUS_FIGHT_PLAYER = 8, -- scan for player around and randomly attack
		RADIUS_FIGHT_NPC = 8, -- scan for NPC around and start randomly attack,
		RADIUS_FIGHT_SCAN = 8, -- scan for fight around and join/leave fight it

		noBackward = 1,      -- do not walk backward
		kind = 4,            -- quai mode
		TIME_FIGHTING_minTs = 1800,
		TIME_FIGHTING_maxTs = 3000,
		TIME_RESTING_minTs = 0,
		TIME_RESTING_maxTs = 1,

		role = "vantieu"

	}

	for k, v in config do
		finalChar[k] = v
	end


	return FighterManager:Add(finalChar)
end

function SimCityBaTanh:NewJob()
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()
	local name = GetName()

	local children5 = {
		{ 43,   3, { szName = "Heo n¸i", CHANCE_ATTACK_NPC = 1000, CHANCE_ATTACK_PLAYER = 1000 } },
		{ 43,   3, { szName = "Heo näc", CHANCE_ATTACK_NPC = 1000, CHANCE_ATTACK_PLAYER = 1000 } },
		{ 42,   2, { szName = "H­u sao", CHANCE_ATTACK_NPC = 1000, CHANCE_ATTACK_PLAYER = 1000 } },
		{ 13,   2, { szName = "Voi b¶n ®«n", CHANCE_ATTACK_NPC = 1000, CHANCE_ATTACK_PLAYER = 1000 } },

		{ 2146, 1, { szName = "Xe l­¬ng thùc", CHANCE_ATTACK_NPC = 1000, CHANCE_ATTACK_PLAYER = 1000 } },
		--{ 2147, 1, { szName = "Xe quÇn ¸o" } },
		--{ 2148, 1, { szName = "Xe cña c¶i" } },

		{ 682,  4, { szName = "Gia nh©n", CHANCE_ATTACK_NPC = 1, CHANCE_ATTACK_PLAYER = 1 } }
	}
	local children = {}
	for i = 1, getn(children5) do
		children = spawnN(children, children5[i][1], children5[i][2], children5[i][3])
	end

	local collections = {}
	for i = 1, getn(children) do
		local nNpc = children[i]
		nNpc.camp = forCamp
		nNpc.nMapId = pW
		nNpc.goX = pX
		nNpc.goY = pY
		nNpc.playerID = name
		local id = self:CreateChar(nNpc)
		if id and id > 0 then
			tinsert(collections, id)
		end
	end

	local tieuxa = self:Get()
	tieuxa.children = arrJoin({ tieuxa.children, collections })
end

function SimCityBaTanh:Get()
	local name = GetName()
	local nListId = self.player2TieuXa[name] or 0
	if nListId == 0 then
		self.player2TieuXa[name] = {
			children = {},
			testLoc = ""
		}
		return self.player2TieuXa[name]
	end
	return nListId
end

function SimCityBaTanh:GoToJob()
	local tieuxa = self:Get()
	if not tieuxa then
		Msg2Player("Kh«ng t×m thÊy b¸ t¸nh")
	end
	NewWorld(tieuxa.nW, tieuxa.nX, tieuxa.nY)
end

function SimCityBaTanh:FinishJob(force)
	local tieuxa = self:Get()

	if force == 0 and tieuxa.finished == nil then
		return Talk(1, "", "Tiªu xa vÉn ®ang trªn ®­êng di chuyÓn")
	end

	if tieuxa.finishedReason == 1 then
		Talk(2, "", "Hoµn thµnh nhiÖm vô", "Xin h·y nhËn phÇn th­ëng, h·y cè g¾ng lªn!")
		Earn(100000)
		AddSkillState(509, 1, 0, 180);
	else
		Talk(1, "", "NhiÖm vô thÊt b¹i")
	end

	self:Remove()
end

function SimCityBaTanh:Remove()
	local tieuxa = self:Get()
	for i = 1, getn(tieuxa.children) do
		FighterManager:Remove(tieuxa.children[i])
	end
	self.player2TieuXa[GetName()] = nil
end

function SimCityBaTanh:WalkAllTieu()
	-- Get info for npc in this world
	for name, tieuxa in self.player2TieuXa do
		local parentID = SearchPlayer(name)
		if parentID > 0 then
			local pW, pX, pY = CallPlayerFunction(parentID, GetWorldPos)
			local rW, rX, rY = CallPlayerFunction(parentID, GetPos)
			local newLoc = "" .. rW .. rX .. rY
			tieuxa.testLoc = newLoc
			tieuxa.player_location = { nW = pW, nX = pX, nY = pY }
			local children = tieuxa.children

			-- Filter out deleted children
			local newList = {}
			for i = 1, getn(children) do
				local id = children[i]
				if id then
					local v = FighterManager:Get(id)
					if v then
						tinsert(newList, v.id)
					end
				end
			end
			if getn(newList) > 0 then
				children = newList
				tieuxa.children = newList

				-- Find the centerChar
				local size = getn(children)
				local centerCharId = getCenteredCell(createFormation(size))
				local fighter = FighterManager:Get(children[centerCharId])
				if not fighter or fighter.isDead == 1 or fighter.nMapId ~= pW then
					for i = 1, getn(children) do
						local child = FighterManager:Get(children[i])
						if child and child.isDead ~= 1 and child.nMapId == pW then
							fighter = child
							break
						end
					end
				end

				-- If found then can draw
				if fighter then
					local nX, nY, nW = GetNpcPos(fighter.finalIndex)
					nX = nX / 32
					nY = nY / 32
					nW = SubWorldIdx2ID(nW)
					local newPath = genCoords_squareshape({ nX, nY }, { pX, pY }, size)
					local cachNguoiChoi = GetDistanceRadius(nX, nY, pX, pY)

					if pW == nW and cachNguoiChoi <= DISTANCE_FOLLOW_PLAYER_TOOFAR then
						local newIds = {}
						for i = 1, size do
							local child = FighterManager:Get(children[i])
							if child and child.nMapId == pW then
								child.parentAppointPos = newPath[i]
								tinsert(newIds, child.id)
							end
						end
						tieuxa.children = newIds
					end
				end
			end
		end
	end
end

---------- EVENTS
function SimCityBaTanh:init()
	if self.m_TimerId then
		TimerList:DelTimer(self.m_TimerId)
	end
	-- Bo dong sau day neu muon di theo doi hinh
	self.m_TimerId = TimerList:AddTimer(self, 18)
end

function SimCityBaTanh:OnTime()
	self:WalkAllTieu()
	self.m_TimerId = TimerList:AddTimer(self, 18)
end
