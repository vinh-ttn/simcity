IncludeLib("NPCINFO")
GroupFighter = {}
GroupFighter.fighterList = {}
GroupFighter.counter = 1
GroupFighter.PARAM_LIST_ID = 1
GroupFighter.PARAM_CHILD_ID = 2
GroupFighter.PARAM_PLAYER_ID = 3
GroupFighter.PARAM_NPC_TYPE = 4
GroupFighter.ATICK_TIME = 9 -- refresh rate


GroupFighter.MAX_DIS = 5            -- start next position if within 3 points from destination
GroupFighter.MAX_DIS_SPINNING = 2   -- when spinning make sure the check is tighter
GroupFighter.SPINNING_WAIT_TIME = 0 -- wait time to correct position
GroupFighter.CHAR_SPACING = 1       -- spacing between group characters


GroupFighter.player_distance = 12        -- chay theo nguoi choi neu cach xa
GroupFighter.player_fight_distance = 8   -- neu gan nguoi choi khoang cach 12 thi chuyen sang chien dau
GroupFighter.player_distanceRespawn = 30 -- neu qua xa nguoi choi vi chay nhanh thi phai bien hinh theo
GroupFighter.player_vision = 15          -- qua 15 = phai respawn vi no se quay ve cho cu

function GroupFighter:Add(tbNpc)
	local result = {}
	local nW = tbNpc.nMapId
	local worldInfo = {}

	local walkAreas = {}

	local id = tbNpc.nNpcId
	tbNpc.playerID = tbNpc.playerID or ""

	if (tbNpc.originalWalkPath) then
		walkAreas = arrCopy(tbNpc.originalWalkPath)
	else
		if SearchPlayer(tbNpc.playerID) > 0 then
			local pW, pX, pY = CallPlayerFunction(SearchPlayer(tbNpc.playerID), GetWorldPos)
			worldInfo.showName = 1
			tbNpc.tbPos = {
				{ pX, pY }
			}
			tbNpc.nPosId = 1
			walkAreas = {
				{ pX, pY }
			}
		else
			worldInfo = SimCityWorld:Get(nW)
			local worldPaths = worldInfo.walkAreas
			local walkIndex = random(1, getn(worldPaths))
			walkAreas = worldPaths[walkIndex]
		end
	end

	if walkAreas == nil then
		return nil
	end

	-- No path to walk?
	if getn(walkAreas) < 1 then
		return nil
	end

	--Not a valid char ?
	if SimCityNPCInfo:IsValidFighter(id) == 0 then
		return nil
	end

	-- Not having valid children char?
	if tbNpc.childrenSetup then
		local validChildren = {}
		for i = 1, getn(tbNpc.childrenSetup) do
			local child = tbNpc.childrenSetup[i]
			if SimCityNPCInfo:IsValidFighter(child.nNpcId) == 1 then
				child.rank = 1
				tinsert(validChildren, child)
			end
		end
		tbNpc.children = validChildren
	end

	if tbNpc.children and getn(tbNpc.children) == 0 then
		tbNpc.children = nil
	end


	-- Init stats
	tbNpc.isFighting = 0
	tbNpc.tick = 0
	tbNpc.canSwitchTick = 0
	tbNpc.series = tbNpc.series or random(0, 4)
	tbNpc.camp = tbNpc.camp or random(1, 3)
	tbNpc.walkMode = tbNpc.walkMode or 1
	tbNpc.isSpinning = 0
	tbNpc.lastOffSetAngle = 0
	tbNpc.noRevive = tbNpc.noRevive or 0
	tbNpc.fightingScore = 0
	tbNpc.rank = 1

	--if (tbNpc.camp ==3) then
	--	tbNpc.camp = 5
	--end

	-- Setup walk paths
	if SearchPlayer(tbNpc.playerID) == 0 then
		tbNpc.tbPos = tbNpc.tbPos or arrCopy(walkAreas)

		if tbNpc.thanhthi ~= nil and tbNpc.thanhthi == 1 and random(1, 2) < 2 then
			tbNpc.tbPos = arrFlip(tbNpc.tbPos)
		end

		if tbNpc.walkMode ~= "random" and tbNpc.walkMode ~= "keoxe" and tbNpc.children then
			tbNpc.tbPos = createDiagonalFormPath(tbNpc.tbPos)
		end
	else

	end

	-- Startup position
	tbNpc.hardsetPos = tbNpc.hardsetPos or random(1, getn(tbNpc.tbPos))

	-- Name for it?

	if worldInfo.showName == 1 then
		if (not tbNpc.szName) or tbNpc.szName == "" then
			tbNpc.szName = SimCityNPCInfo:getName(id)
		end
	else
		tbNpc.szName = " "
	end

	-- Calculate walk path for main + children
	self:GenWalkPath(tbNpc, 0)

	-- Add to store and create everyone on screen
	local nListId = self:Show(tbNpc, 1)
	if not nListId or nListId == 0 then
		return nil
	end

	return self.fighterList["n" .. nListId]
end

function GroupFighter:Remove(nListId)
	local tbNpc = self.fighterList["n" .. nListId]
	if tbNpc then
		DelNpcSafe(tbNpc.finalIndex)
		self:ChildrenRemove(nListId)
		self.fighterList["n" .. nListId] = nil
	end
end

function GroupFighter:Show(tbNpc, isNew, goX, goY)
	local tbPos = tbNpc.tbPos
	local nPosId = tbNpc.hardsetPos

	if (not nPosId) or (not tbPos[nPosId]) then
		nPosId = random(1, getn(tbPos))
	end

	local nMapIndex = SubWorldID2Idx(tbNpc.nMapId)
	if nMapIndex >= 0 then
		local nNpcIndex


		local tX = tbNpc.walkPath[nPosId][1]
		local tY = tbNpc.walkPath[nPosId][2]

		if goX and goY then
			tX = goX
			tY = goY
		end

		local name = tbNpc.szName or SimCityNPCInfo:getName(tbNpc.nNpcId)

		if (tbNpc.tongkim == 1) then
			if (tbNpc.tongkim_name) then
				name = tbNpc.tongkim_name
			else
				name = "Kim"
				if tbNpc.camp == 1 then
					name = "TËng"
				end
			end
			name = name .. " " .. SimCityTongKim.RANKS[tbNpc.rank]
		end


		if (tbNpc.hardsetName) then
			name = tbNpc.hardsetName
		end

		nNpcIndex = AddNpcEx(tbNpc.nNpcId, tbNpc.level or 95, tbNpc.series, nMapIndex, tX * 32, tY * 32, 1, name, 0)


		if nNpcIndex > 0 then
			local kind = GetNpcKind(nNpcIndex)
			if kind ~= 0 then
				DelNpcSafe(nNpcIndex)
			else
				tbNpc.szName = GetNpcName(nNpcIndex)
				tbNpc.finalIndex = nNpcIndex
				tbNpc.isDead = 0
				tbNpc.lastPos = {
					nX32 = tX * 32,
					nY32 = tY * 32,
					nPosId = nPosId
				}

				local id = self.counter + 0

				-- Save to DB
				if (isNew == 1) then
					self.counter = self.counter + 1
					tbNpc.id = id
				else
					id = tbNpc.id
				end


				self.fighterList["n" .. tbNpc.id] = tbNpc

				-- Otherwise choose side
				SetNpcCurCamp(nNpcIndex, tbNpc.camp)

				local nPosCount = getn(tbPos)
				if nPosCount >= 1 then
					SetNpcActiveRegion(nNpcIndex, 1)
					tbNpc.nPosId = nPosId
				end
				if nPosCount >= 1 or tbNpc.nSkillId then
					SetNpcParam(nNpcIndex, self.PARAM_LIST_ID, id)
					SetNpcParam(nNpcIndex, self.PARAM_PLAYER_ID, SearchPlayer(tbNpc.playerID))
					SetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE, 1)
					SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\group_fighter.timer.lua")
					SetNpcTimer(nNpcIndex, self.ATICK_TIME)
				end

				-- Ngoai trang?
				if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) then
					SimCityNgoaiTrang:makeup(tbNpc, nNpcIndex)
				end


				self:ChildrenShow(id)


				-- Disable fighting?
				if (tbNpc.isFighting == 0) then
					SetNpcKind(nNpcIndex, tbNpc.kind or 4)
					self:SetFightState(tbNpc, 0)
				end


				-- Set NPC life
				if tbNpc.cap and tbNpc.cap < 2 and NPCINFO_SetNpcCurrentLife then
					local maxHP = SimCityNPCInfo:getHPByCap(tbNpc.cap)
					NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, maxHP)
					NPCINFO_SetNpcCurrentLife(nNpcIndex, maxHP)
				end

				-- Life?
				if (tbNpc.lastHP ~= nil) then
					NPCINFO_SetNpcCurrentLife(nNpcIndex, tbNpc.lastHP)
					tbNpc.lastHP = nil
				end
				return id
			end
		end

		return 0
	end
	return 0
end

function GroupFighter:Respawn(nListId, isAllDead, reason)
	--CallPlayerFunction(1, Msg2Player, "Respawn: "..reason)

	local tbNpc = self.fighterList["n" .. nListId]

	isAllDead = isAllDead or 0

	local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)

	-- Do calculation
	nX = nX / 32
	nY = nY / 32

	-- 2 = qua map khac?
	if (isAllDead == 2) then
		nX = 0
		nY = 0
		tbNpc.nPosId = 1
		self:HardResetPos(tbNpc)

		-- otherwise reset
	elseif isAllDead == 1 and SearchPlayer(tbNpc.playerID) > 0 then
		nX = tbNpc.walkPath[1][1]
		nY = tbNpc.walkPath[1][2]
		tbNpc.nPosId = 1
	elseif (isAllDead == 1 and tbNpc.resetPosWhenRevive and tbNpc.resetPosWhenRevive >= 1) then
		nX = tbNpc.walkPath[tbNpc.resetPosWhenRevive][1]
		nY = tbNpc.walkPath[tbNpc.resetPosWhenRevive][2]
		tbNpc.nPosId = tbNpc.resetPosWhenRevive
		self:HardResetPos(tbNpc)
	elseif (isAllDead == 1 and tbNpc.lastPos ~= nil) then
		nX = tbNpc.lastPos.nX32
		nY = tbNpc.lastPos.nY32
		tbNpc.nPosId = tbNpc.lastPos.nPosId
	else
		tbNpc.lastPos = {
			nX32 = nX,
			nY32 = nY,
			nPosId = tbNpc.nPosId
		}
	end

	tbNpc.hardsetPos = tbNpc.nPosId
	tbNpc.arriveTick = nil
	tbNpc.lastHP = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
	if (isAllDead == 1) then
		tbNpc.lastHP = nil
	end

	-- Retrieve position of each
	if tbNpc.children then
		for i = 1, getn(tbNpc.children) do
			local child = tbNpc.children[i]
			if child.isDead ~= 1 then
				child.lastHP = NPCINFO_GetNpcCurrentLife(child.finalIndex)
			end

			if (isAllDead == 1) then
				child.lastHP = nil
			end

			if (isAllDead == 1 and ((tbNpc.resetPosWhenRevive and tbNpc.resetPosWhenRevive >= 1) or (SearchPlayer(tbNpc.playerID) > 0))) then
				child.lastPos = nil

				-- Children bi lag
			elseif isAllDead == 3 then
				if child.isDead ~= 1 then
					if child.walkPath ~= nil then
						local targetPos = child.walkPath[tbNpc.nPosId]
						local cX = targetPos[1]
						local cY = targetPos[2]
						child.lastPos = {
							nX32 = cX * 32,
							nY32 = cY * 32
						}
					else
						child.lastPos = {
							nX32 = (nX + random(-2, 2)) * 32,
							nY32 = (nY + random(-2, 2)) * 32
						}
					end
				end
			else
				if child.isDead ~= 1 then
					local nX32, nY32 = GetNpcPos(child.finalIndex)
					child.lastPos = {
						nX32 = nX32,
						nY32 = nY32
					}
				end
			end
		end
	end



	-- Normal respawn ? Can del NPC
	DelNpcSafe(tbNpc.finalIndex)

	self.fighterList["n" .. nListId] = tbNpc
	self:ChildrenRemove(nListId)
	self:Show(tbNpc, 0, nX, nY)
end

function GroupFighter:IsNpcEnemyAround(tbNpc, nNpcIndex, radius)
	local allNpcs = {}
	local nCount = 0
	-- Keo xe?
	if self.role == "keoxe" then
		allNpcs, nCount = CallPlayerFunction(SearchPlayer(tbNpc.playerID), GetAroundNpcList, radius)
		for i = 1, nCount do
			local fighter2Kind = GetNpcKind(allNpcs[i])
			local fighter2Camp = GetNpcCurCamp(allNpcs[i])
			if fighter2Kind == 0 and (IsAttackableCamp(tbNpc.camp, fighter2Camp) == 1) then
				return 1
			end
		end
		return 0
	end

	-- Thanh thi / tong kim / chien loan
	allNpcs, nCount = Simcity_GetNpcAroundNpcList(nNpcIndex, radius)
	for i = 1, nCount do
		local fighter2Kind = GetNpcKind(allNpcs[i])
		local fighter2Camp = GetNpcCurCamp(allNpcs[i])
		if fighter2Kind == 0 and (IsAttackableCamp(tbNpc.camp, fighter2Camp) == 1) then
			return 1
		end
	end

	return 0
end

function GroupFighter:IsPlayerEnemyAround(nListId, nNpcIndex)
	local tbNpc = self.fighterList["n" .. nListId]

	if not tbNpc then
		return 0
	end

	-- FIGHT other player
	if GetNpcAroundPlayerList then
		local allNpcs, nCount = GetNpcAroundPlayerList(nNpcIndex, tbNpc.RADIUS_FIGHT_PLAYER or RADIUS_FIGHT_PLAYER)
		for i = 1, nCount do
			if (CallPlayerFunction(allNpcs[i], GetFightState) == 1 and IsAttackableCamp(CallPlayerFunction(allNpcs[i], GetCurCamp), tbNpc.camp) == 1) then
				return 1
			end
		end

		-- Check children
		if tbNpc.children then
			for j = 1, getn(tbNpc.children) do
				if (tbNpc.children[j] and tbNpc.children[j].finalIndex and tbNpc.children[j].finalIndex > 0 and tbNpc.children[j].isDead == 0) then
					local allNpcs, nCount = GetNpcAroundPlayerList(tbNpc.children[j].finalIndex,
						tbNpc.RADIUS_FIGHT_PLAYER or RADIUS_FIGHT_PLAYER)
					for i = 1, nCount do
						if (CallPlayerFunction(allNpcs[i], GetFightState) == 1 and IsAttackableCamp(CallPlayerFunction(allNpcs[i], GetCurCamp), tbNpc.camp) == 1) then
							return 1
						end
					end
				end
			end
		end
	end
	return 0
end

function GroupFighter:JoinFight(nListId, reason)
	local tbNpc = self.fighterList["n" .. nListId]
	if not tbNpc then
		return 0
	end
	tbNpc.isFighting = 1
	tbNpc.canSwitchTick = tbNpc.tick +
		random(tbNpc.TIME_FIGHTING_minTs or TIME_FIGHTING.minTs, tbNpc.TIME_FIGHTING_maxTs or TIME_FIGHTING.maxTs) -- trong trang thai pk 1 toi 2ph
	self.fighterList["n" .. nListId] = tbNpc

	reason = reason or "no reason"

	local currX, currY, currW = GetNpcPos(tbNpc.finalIndex)
	currX = floor(currX / 32)
	currY = floor(currY / 32)

	-- If already having last fight pos, we may simply chance AI to 1
	if tbNpc.lastFightPos then
		local lastPos = tbNpc.lastFightPos
		if lastPos.W == currW then
			if (GetDistanceRadius(lastPos.X, lastPos.Y, currX, currY) < self.player_vision) then
				self:SetFightState(tbNpc, 9)
				return 1
			end
		end
	end

	-- Otherwise save it and respawn
	tbNpc.lastFightPos = {
		X = currX,
		Y = currY,
		W = currW
	}

	self:Respawn(nListId, 0, "JoinFight " .. reason)

	return 1
end

function GroupFighter:JoinFightCheck(nListId, nNpcIndex)
	local tbNpc = self.fighterList["n" .. nListId]

	if not tbNpc then
		return 0
	end

	if (self:IsNpcEnemyAround(tbNpc, nNpcIndex, tbNpc.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN) == 1) then
		return self:JoinFight(nListId, "enemy around")
	end
	return 0
end

function GroupFighter:JoinFightPlayerCheck(nListId, nNpcIndex)
	local tbNpc = self.fighterList["n" .. nListId]

	if not tbNpc then
		return 0
	end

	-- FIGHT other player
	if GetNpcAroundPlayerList then
		if self:IsPlayerEnemyAround(nListId, nNpcIndex) == 1 then
			local nW = tbNpc.nMapId
			if SearchPlayer(tbNpc.playerID) == 0 then
				local worldInfo = SimCityWorld:Get(nW)
				if worldInfo.showFightingArea == 1 then
					local name = GetNpcName(nNpcIndex)
					local lastPos = tbNpc.tbPos[tbNpc.nPosId]
					Msg2Map(tbNpc.nMapId,
						"<color=white>" ..
						name ..
						"<color> Æ∏nh ng≠Íi tπi " ..
						worldInfo.name .. " " .. floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "")
				end
			end
			return self:JoinFight(nListId, "player around")
		end
	end

	return 0
end

function GroupFighter:LeaveFight(nListId, isAllDead, reason)
	isAllDead = isAllDead or 0
	local tbNpc = self.fighterList["n" .. nListId]
	if not tbNpc then
		return 0
	end
	tbNpc.isFighting = 0
	tbNpc.canSwitchTick = tbNpc.tick +
		random(tbNpc.TIME_RESTING_minTs or TIME_RESTING.minTs, tbNpc.TIME_RESTING_maxTs or TIME_RESTING.maxTs) -- trong trang thai di bo 30s-1ph
	self.fighterList["n" .. nListId] = tbNpc
	reason = reason or "no reason"

	-- Do not need to respawn just disable fighting
	if (isAllDead ~= 1 and tbNpc.kind ~= 4) then
		self:SetFightState(tbNpc, 0)
	else
		self:Respawn(nListId, isAllDead, reason)
	end
end

function GroupFighter:LeaveFightCheck(nListId, nNpcIndex)
	local tbNpc = self.fighterList["n" .. nListId]
	if not tbNpc then
		return 0
	end

	if tbNpc.isDead == 1 then
		return 0
	end

	-- No attacker around including NPC and Player ? Stop
	if (self:IsNpcEnemyAround(tbNpc, nNpcIndex, tbNpc.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN) == 0
			and self:IsPlayerEnemyAround(nListId, nNpcIndex) == 0) then
		if (tbNpc.leaveFightWhenNoEnemy and tbNpc.leaveFightWhenNoEnemy > 0) then
			local targetTick = tbNpc.tick + tbNpc.leaveFightWhenNoEnemy - 1

			if tbNpc.canSwitchTick > targetTick then
				tbNpc.canSwitchTick = targetTick
			end
		end

		return 1
	end
	return 0
end

function GroupFighter:HasArrived(nNpcIndex, tbNpc)
	local posIndex = tbNpc.nPosId
	local parentPos = tbNpc.walkPath[posIndex]


	local nX32, nY32 = GetNpcPos(nNpcIndex)
	local oX = nX32 / 32;
	local oY = nY32 / 32;

	local isExact = tbNpc.tbPos[posIndex][3]
	local nX = parentPos[1]
	local nY = parentPos[2]


	local checkDistance = self.MAX_DIS

	if tbNpc.isSpinning == 1 then
		nX = parentPos[3]
		nY = parentPos[4]
		checkDistance = self.MAX_DIS_SPINNING
	end

	if isExact == 1 then
		nX = tbNpc.tbPos[posIndex][1]
		nY = tbNpc.tbPos[posIndex][2]
	end


	local distance = GetDistanceRadius(nX, nY, oX, oY)

	if distance < checkDistance then
		if not tbNpc.arriveTick then
			tbNpc.arriveTick = tbNpc.tick + 15 -- wait 15s for children to arrive
		end

		-- Day du children?
		if self:ChildrenArrived(tbNpc) == 1 then
			return 1
		end

		-- Qua thoi gian cho doi
		if tbNpc.arriveTick < tbNpc.tick and tbNpc.isFighting ~= 1 then
			return 0
		end
	end
	return 0
end

function GroupFighter:GenWalkPath(tbNpc, hasJustBeenFlipped)
	-- Generate walkpath for myself
	-- & Repeat for children
	local WalkSize = getn(tbNpc.tbPos)
	tbNpc.walkPath = {}

	local childrenSize = 0
	if tbNpc.children then
		childrenSize = getn(tbNpc.children)
	end

	if childrenSize > 0 then
		for j = 1, childrenSize do
			tbNpc.children[j].walkPath = {}
		end
	end


	for i = 1, WalkSize do
		local point = tbNpc.tbPos[i]
		-- Having children?
		if childrenSize > 0 then
			-- RANDOM walk for everyone?
			if tbNpc.walkMode == "random" or tbNpc.walkMode == "keoxe" then
				if hasJustBeenFlipped == 0 then
					tinsert(tbNpc.walkPath, randomRange(point, tbNpc.walkVar or 2))
				else
					tinsert(tbNpc.walkPath, randomRange(point, 0))
				end
				for j = 1, childrenSize do
					if hasJustBeenFlipped == 0 then
						tinsert(tbNpc.children[j].walkPath, randomRange(point, tbNpc.walkVar or 2))
					else
						tinsert(tbNpc.children[j].walkPath, randomRange(point, 0))
					end
				end

				-- FORMATION walk?
			else
				-- For children
				local formation = self:_genCoords_squareshape(tbNpc, childrenSize, i)
				for j = 1, childrenSize do
					tinsert(tbNpc.children[j].walkPath, formation[j])
				end

				-- For myself
				local firstPointLastRow = formation[childrenSize + 1]
				local lastPointLastRow
				for k = childrenSize + 1, getn(formation) do
					lastPointLastRow = formation[k]
				end

				tinsert(tbNpc.walkPath, {
					(firstPointLastRow[1] + lastPointLastRow[1]) / 2,
					(firstPointLastRow[2] + lastPointLastRow[2]) / 2,
					(firstPointLastRow[3] + lastPointLastRow[3]) / 2,
					(firstPointLastRow[4] + lastPointLastRow[4]) / 2
				})
			end


			-- No children = random path for myself
		else
			if hasJustBeenFlipped == 0 then
				tinsert(tbNpc.walkPath, randomRange(point, tbNpc.walkVar or 2))
			else
				tinsert(tbNpc.walkPath, randomRange(point, 0))
			end
		end
	end
end

function GroupFighter:Get(nListId)
	return self.fighterList["n" .. nListId]
end

function GroupFighter:HardResetPos(tbNpc)
	local result = {}
	local nW = tbNpc.nMapId
	local worldInfo = {}

	local walkAreas = {}

	local id = tbNpc.nNpcId

	if (tbNpc.originalWalkPath) then
		walkAreas = arrCopy(tbNpc.originalWalkPath)
	else
		if SearchPlayer(tbNpc.playerID) > 0 then
			local pW, pX, pY = CallPlayerFunction(SearchPlayer(tbNpc.playerID), GetWorldPos)
			worldInfo.showName = 1
			tbNpc.tbPos = {
				{ pX, pY }
			}
			tbNpc.nPosId = 1
			walkAreas = {
				{ pX, pY }
			}
		else
			worldInfo = SimCityWorld:Get(nW)
			local worldPaths = worldInfo.walkAreas
			local walkIndex = random(1, getn(worldPaths))
			walkAreas = worldPaths[walkIndex]
		end
	end

	if walkAreas == nil then
		return nil
	end


	if walkAreas == nil then
		return 0
	end

	-- No path to walk?
	if getn(walkAreas) < 1 then
		return 0
	end

	--Not a valid char ?
	if SimCityNPCInfo:IsValidFighter(id) == 0 then
		return 0
	end



	-- Init stats
	tbNpc.isSpinning = 0
	tbNpc.lastOffSetAngle = 0

	-- Setup walk paths
	if SearchPlayer(tbNpc.playerID) == 0 then
		tbNpc.tbPos = tbNpc.tbPos or arrCopy(walkAreas)
		if tbNpc.walkMode ~= "random" and tbNpc.walkMode ~= "keoxe" and tbNpc.children then
			tbNpc.tbPos = createDiagonalFormPath(tbNpc.tbPos)
		end
	else

	end

	-- Startup position
	tbNpc.hardsetPos = tbNpc.hardsetPos or random(1, getn(tbNpc.tbPos))


	-- Calculate walk path for main + children
	self:GenWalkPath(tbNpc, 0)

	-- Add to store and create everyone on screen
	return tbNpc
end

function GroupFighter:_genCoords_squareshape(tbNpc, N, targetPointer)
	local f = createFormation(N)
	local rows = f[1] > f[2] and f[1] or f[2]
	local cols = f[1] > f[2] and f[2] or f[1]
	local spacing = tbNpc.char_spacing or self.CHAR_SPACING
	local pathLength = getn(tbNpc.tbPos)

	-- Variables
	local toPos = tbNpc.tbPos[targetPointer]

	local fromPos
	if (targetPointer == 1) then
		fromPos = tbNpc.tbPos[2]
	else
		fromPos = tbNpc.tbPos[targetPointer - 1]
	end

	-- Given a target X and Y
	local x = toPos[1]
	local y = toPos[2]
	local xF = fromPos[1]
	local yF = fromPos[2]

	local mostLeft = 0
	local mostRight = 0
	local mostTop = 0
	local mostBottom = 0


	local rhombus = {}
	local total = 0
	for i = 0, rows do
		for j = 0, cols - 1 do
			total = total + 1

			local newX = x + j * spacing
			local newY = y + j * spacing

			local newXF = xF + j * spacing
			local newYF = yF + j * spacing

			if (mostLeft > newX or mostLeft == 0) then mostLeft = newX end
			if (mostTop > newY or mostTop == 0) then mostTop = newY end
			if (mostRight < newX or mostRight == 0) then mostRight = newX end
			if (mostBottom < newY or mostBottom == 0) then mostBottom = newY end
			tinsert(rhombus, { newX, newY, newXF, newYF })
		end
		y = y - spacing
		x = x + spacing

		yF = yF - spacing
		xF = xF + spacing
	end


	-- And we need to shift it back to centre of the original path
	local centreX = (mostRight + mostLeft) / 2
	local centreY = (mostBottom + mostTop) / 2
	local offSetX = centreX - toPos[1]
	local offSetY = centreY - toPos[2]
	for i = 1, total do
		rhombus[i] = transformRhombus({
			rhombus[i][1] - offSetX,
			rhombus[i][2] - offSetY,
			rhombus[i][3] - offSetX,
			rhombus[i][4] - offSetY
		}, toPos, fromPos, toPos)
	end

	-- DONE
	return rhombus
end

function GroupFighter:ClearMap(nW, targetListId)
	-- Get info for npc in this world
	for key, tbNpc in self.fighterList do
		if tbNpc.nMapId == nW then
			if (not targetListId) or (targetListId == tbNpc.id) then
				self:Remove(tbNpc.id)
			end
		end
	end
end

function GroupFighter:SetFightState(tbNpc, mode)
	SetNpcAI(tbNpc.finalIndex, mode)
	if tbNpc.children then
		for i = 1, getn(tbNpc.children) do
			local child = tbNpc.children[i]
			if child.finalIndex then
				SetNpcAI(child.finalIndex, mode)
			end
		end
	end
end

function GroupFighter:OnNpcDeath(nNpcIndex, playerAttacker)
	local npcType = GetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE)
	if (npcType == 1) then
		self:ParentDead(nNpcIndex, playerAttacker)
	else
		self:ChildrenDead(nNpcIndex, playerAttacker)
	end
end

function GroupFighter:ParentDead(nNpcIndex, playerAttacker)
	if nNpcIndex > 0 then
		local nListId = GetNpcParam(nNpcIndex, self.PARAM_LIST_ID)
		local tbNpc = self.fighterList["n" .. nListId]
		if not tbNpc then
			return
		end


		self:_calculateFightingScore(tbNpc, nNpcIndex, tbNpc.rank or 1)
		if tbNpc.tongkim == 1 then
			SimCityTongKim:OnDeath(nNpcIndex, tbNpc.rank or 1)
		end

		local foundAlive = 0
		if tbNpc.children then
			for i = 1, getn(tbNpc.children) do
				local child = tbNpc.children[i]
				if child.isDead ~= 1 then
					foundAlive = i
					break
				end
			end
		end

		-- No revive and found children alive? That child become parent
		if tbNpc.noRevive == 1 then
			if foundAlive > 0 then
				local child = tbNpc.children[foundAlive]
				tbNpc.finalIndex = child.finalIndex
				tbNpc.szName = child.szName
				tbNpc.nNpcId = child.nNpcId
				tbNpc.series = child.series
				tbNpc.children[foundAlive].isDead = 1
				SetNpcParam(tbNpc.finalIndex, self.PARAM_NPC_TYPE, 1)
				return 1
			else
				tbNpc.isDead = 1
				tbNpc.finalIndex = nil
			end
		else
			tbNpc.isDead = 1
			tbNpc.finalIndex = nil
		end

		self:OnDeath(nListId)
	end
end

function GroupFighter:OnDeath(nListId)
	local tbNpc = self.fighterList["n" .. nListId]
	if (not tbNpc) then
		return
	end


	local doRespawn = 0

	if tbNpc.isFighting == 1 and tbNpc.tick > tbNpc.canSwitchTick then
		doRespawn = 1
	end

	local allChildrenDead = 1
	local alive = 0

	if doRespawn == 0 then
		if tbNpc.children then
			local N = getn(tbNpc.children)
			for i = 1, N do
				if doRespawn == 0 then
					local child = tbNpc.children[i]
					if child.tick > child.canSwitchTick then
						doRespawn = 1
					else
						if child.isFighting == 1 and child.finalIndex and child.isDead ~= 1 then
							allChildrenDead = 0
							alive = alive + 1
						end
					end
				end
			end
		end
	end

	-- Is every one dead?
	if (doRespawn == 1 or (tbNpc.isDead == 1 and allChildrenDead == 1)) then
		local nW = tbNpc.nMapId
		local lastPos = tbNpc.tbPos[tbNpc.nPosId]



		if SearchPlayer(tbNpc.playerID) == 0 then
			local worldInfo = SimCityWorld:Get(nW)
			if tbNpc.children and worldInfo.showFightingArea == 1 then
				Msg2Map(nW,
					"<color=white>" ..
					tbNpc.szName ..
					"<color> toµn Æoµn bπi trÀn <color=yellow>" ..
					floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "<color>")
			end
		end

		-- No revive? Do nothing
		if tbNpc.noRevive == 1 then
			return
		end



		tbNpc.fightingScore = ceil(tbNpc.fightingScore * 0.7)
		SimCityTongKim:updateRank(tbNpc)
		-- Do revive? Reset and leave fight
		self:LeaveFight(nListId, 1, "die toan bo")
	end
end

function GroupFighter:ATick(nNpcIndex)
	local npcType = GetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE)
	-- Parent
	if (npcType == 1) then
		return self:ParentTick(nNpcIndex)
	else
		return self:ChildrenTick(nNpcIndex)
	end
end

function GroupFighter:ParentTick(nNpcIndex)
	if nNpcIndex > 0 then
		local nListId = GetNpcParam(nNpcIndex, self.PARAM_LIST_ID)
		local tbNpc = self.fighterList["n" .. nListId]
		if not tbNpc then
			return 1
		end
		tbNpc.tick = tbNpc.tick + self.ATICK_TIME / 18
		tbNpc.finalIndex = nNpcIndex

		if tbNpc.isFighting == 1 then
			tbNpc.fightingScore = tbNpc.fightingScore + 10
		end
		self.fighterList["n" .. nListId] = tbNpc
		self:Breath(nListId)

		if tbNpc.isDead == 1 then
			return 0
		end
		return 1
	end
	return 1
end

function GroupFighter:Breath(nListId)
	local tbNpc = self.fighterList["n" .. nListId]

	local nNpcIndex = tbNpc.finalIndex


	local nX32, nY32, nW32 = GetNpcPos(nNpcIndex)
	local nW = SubWorldIdx2ID(nW32)
	local worldInfo = {}



	local pW = 0
	local pX = 0
	local pY = 0


	local myPosX = floor(nX32 / 32)
	local myPosY = floor(nY32 / 32)

	local cachNguoiChoi = 0


	if SearchPlayer(tbNpc.playerID) == 0 then
		worldInfo = SimCityWorld:Get(nW)

		-- Otherwise just Random chat
		if worldInfo.allowChat == 1 then
			if tbNpc.isFighting == 1 then
				if random(1, CHANCE_CHAT / 2) <= 2 then
					NpcChat(nNpcIndex, SimCityChat:getChatFight())
				end
			else
				if random(1, CHANCE_CHAT) <= 2 then
					NpcChat(nNpcIndex, SimCityChat:getChat())
				end
			end
		end

		-- Show my ID
		if (worldInfo.showingId == 1) then
			local dbMsg = tbNpc.debugMsg or ""
			NpcChat(nNpcIndex, tbNpc.nNpcId)
		end
	else
		worldInfo.allowFighting = 1
		worldInfo.showFightingArea = 0
		pW, pX, pY = CallPlayerFunction(SearchPlayer(tbNpc.playerID), GetWorldPos)
		cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)
	end


	-- Is fighting? Do nothing except leave fight if possible
	if tbNpc.isFighting == 1 then
		-- Case 1: toi gio chuyen doi
		if tbNpc.canSwitchTick < tbNpc.tick then
			return self:LeaveFight(nListId, 0, "toi gio thay doi trang thai")
		end

		-- Case 2: tu dong thoat danh khi khong con ai
		if self:LeaveFightCheck(nListId, nNpcIndex) == 1 then
			--self:LeaveFight(nListId, 0, "khong tim thay quai")
			return 1
		end

		-- Case 3: qua xa nguoi choi phai chay theo ngay
		if (SearchPlayer(tbNpc.playerID) > 0 and cachNguoiChoi > self.player_distance) then
			tbNpc.canSwitchTick = tbNpc.tick - 1
			self:LeaveFight(nListId, 0, "chay theo nguoi choi")
		else
			return 1
		end
	end

	-- Up to here means walking
	local nNextPosId = tbNpc.nPosId
	local tbPos = tbNpc.tbPos
	local WalkSize = getn(tbPos)
	if SearchPlayer(tbNpc.playerID) == 0 and (nNextPosId == 0 or WalkSize < 2) then
		return 0
	end

	if ((SearchPlayer(tbNpc.playerID) > 0 and cachNguoiChoi <= self.player_fight_distance) or SearchPlayer(tbNpc.playerID) == 0)
		and (worldInfo.allowFighting == 1) and (tbNpc.isFighting == 0 and tbNpc.canSwitchTick < tbNpc.tick)
	then
		-- Case 1: someone around is fighting, we join
		if (tbNpc.joinFightChance and random(0, tbNpc.joinFightChance) <= 2) then
			if self:JoinFightCheck(nListId, nNpcIndex) == 1 then
				return 1
			end
		end


		-- Case 2: some player around is fighting and different camp, we join
		if (tbNpc.CHANCE_ATTACK_PLAYER and random(0, tbNpc.CHANCE_ATTACK_PLAYER) <= 2)
		then
			if self:JoinFightPlayerCheck(nListId, nNpcIndex) == 1 then
				return 1
			end
		end

		-- Case 3: I auto switch to fight  mode
		if (SearchPlayer(tbNpc.playerID) == 0 and tbNpc.attackNpcChance and random(1, tbNpc.attackNpcChance) <= 2) then
			-- CHo nhung dua chung quanh

			local countFighting = 0

			for key, tbNpc2 in self.fighterList do
				if tbNpc2.id ~= nListId and tbNpc2.nMapId == tbNpc.nMapId then
					if (tbNpc2.isFighting == 0 and tbNpc2.camp ~= tbNpc.camp) then
						if (not tbNpc.targetCamp) or tbNpc.targetCamp == tbNpc2.camp then
							local otherPosX, otherPosY, otherPosW = GetNpcPos(tbNpc2.finalIndex)
							otherPosX = floor(otherPosX / 32)
							otherPosY = floor(otherPosY / 32)

							local distance = floor(GetDistanceRadius(otherPosX, otherPosY, myPosX, myPosY))
							local checkDistance = tbNpc.RADIUS_FIGHT_NPC or RADIUS_FIGHT_NPC
							if distance < checkDistance then
								countFighting = countFighting + 1
								if (tbNpc2.children) then
									countFighting = countFighting + getn(tbNpc2.children)
								end
								self:JoinFight(tbNpc2.id,
									"caused by others " ..
									distance .. " (" .. otherPosX .. " " .. otherPosY .. ") (" ..
									myPosX .. " " .. myPosY .. ")")
							end
						end
					end
				end
			end

			-- If someone is around or I am not crazy then I fight
			if countFighting > 0 or tbNpc.attackNpcChance > 1 then
				countFighting = countFighting + 1
				if (tbNpc.children) then
					countFighting = countFighting + getn(tbNpc.children)
				end
				self:JoinFight(nListId, "I start a fight")
			end


			if SearchPlayer(tbNpc.playerID) == 0 and countFighting > 0 and worldInfo.showFightingArea == 1 then
				Msg2Map(nW,
					"C„ " ..
					countFighting ..
					" nh©n s‹ Æang Æ∏nh nhau tπi " ..
					worldInfo.name .. " <color=yellow>" .. floor(myPosX / 8) .. " " .. floor(myPosY / 16) .. "<color>")
			end

			if (countFighting > 0) then
				return 1
			end
		end
	end


	-- Otherwise just walk peacefully
	if SearchPlayer(tbNpc.playerID) == 0 then
		-- Mode 1: random
		if tbNpc.walkMode == "random" or tbNpc.walkMode == "keoxe" or (not tbNpc.children) then
			if self:HasArrived(nNpcIndex, tbNpc) == 1 then
				-- Keep walking no stop
				if (tbNpc.noStop == 1 or random(1, 100) < 90) then
					nNextPosId = nNextPosId + 1

					-- End of the array
					if nNextPosId > WalkSize then
						if tbNpc.noBackward == 1 then
							return 1
						end

						tbNpc.tbPos = arrFlip(tbNpc.tbPos)
						nNextPosId = 1
						tbNpc.nPosId = nNextPosId

						self:GenWalkPath(tbNpc, 1)
					else
						tbNpc.nPosId = nNextPosId
					end

					tbNpc.arriveTick = nil
				else
					return 1
				end
			end

			-- Mode 2: formation
		else
			local arrivedRes = self:HasArrived(nNpcIndex, tbNpc)
			if arrivedRes == 1 then
				if tbNpc.isSpinning == 0 then
					-- Keep walking no stop
					if (tbNpc.noStop == 1 or random(1, 100) < 90) then
						nNextPosId = nNextPosId + 1

						-- End of the array
						if nNextPosId > WalkSize then
							if tbNpc.noBackward == 1 then
								return 1
							end
							local newFlipArr = {}
							for i = 1, WalkSize do
								tinsert(newFlipArr, tbNpc.tbPos[WalkSize - i + 1])
							end

							tbNpc.tbPos = newFlipArr
							self:GenWalkPath(tbNpc, 1)

							nNextPosId = 2
							tbNpc.nPosId = nNextPosId

							self:GenWalkPath(tbNpc, 1)
						else
							tbNpc.nPosId = nNextPosId
						end
						tbNpc.isSpinning = 1
						tbNpc.canStartWalking = 0

						tbNpc.arriveTick = nil
					else
						return 1
					end

					-- Is Spinning?
				elseif tbNpc.isSpinning == 1 then
					-- Has finish spinning
					if tbNpc.canStartWalking == 0 then
						tbNpc.canStartWalking = tbNpc.tick + self.SPINNING_WAIT_TIME
					elseif tbNpc.canStartWalking < tbNpc.tick then
						tbNpc.canStartWalking = 0
						tbNpc.isSpinning = 0
					end

					tbNpc.arriveTick = nil
				end
			end
		end

		-- Otherwise keep walking
		local targetPos = tbNpc.walkPath[nNextPosId]
		local nX = targetPos[1]
		local nY = targetPos[2]
		if tbNpc.isSpinning == 1 then
			nX = targetPos[3]
			nY = targetPos[4]
		end

		NpcWalk(nNpcIndex, nX, nY)

		self:ChildrenWalk(tbNpc, nNextPosId)
	else
		-- Walk toward parent

		-- Player has gone different map? Do respawn
		local needRespawn = 0
		if tbNpc.nMapId ~= pW then
			needRespawn = 1
		else
			if cachNguoiChoi > self.player_distanceRespawn then
				needRespawn = 1
			end
		end

		if needRespawn == 1 then
			tbNpc.nMapId = pW
			tbNpc.isFighting = 0
			tbNpc.canSwitchTick = tbNpc.tick
			tbNpc.tbPos = {
				{ pX, pY }
			}
			tbNpc.nPosId = 1
			self:GenWalkPath(tbNpc, 0)
			self:Respawn(tbNpc.id, 1, "keo xe qua map khac")
			return 1
		end


		-- Otherwise walk toward parent
		NpcWalk(nNpcIndex, pX + random(-2, 2), pY + random(-2, 2))

		-- Walk children as
		if tbNpc.children then
			local N = getn(tbNpc.children)

			-- Exact param of parent is given
			for i = 1, N do
				local child = tbNpc.children[i]
				if (child.finalIndex) then
					NpcWalk(child.finalIndex, pX + random(-2, 2), pY + random(-2, 2))
				end
			end
		end
	end
	return 1
end

--- For children

function GroupFighter:ChildrenTick(childrenIndex)
	if childrenIndex > 0 then
		local nListId = GetNpcParam(childrenIndex, self.PARAM_LIST_ID)
		local childID = GetNpcParam(childrenIndex, self.PARAM_CHILD_ID)
		local tbNpc = self.fighterList["n" .. nListId]

		if not tbNpc then
			return 1
		end
		local child = tbNpc.children[childID]



		if (tbNpc and child) then
			child.tick = child.tick + self.ATICK_TIME / 18
			tbNpc.children[childID] = child
			if tbNpc.tick + 2 < child.tick then
				tbNpc.tick = child.tick
			end
			self.fighterList["n" .. nListId] = tbNpc


			-- Check distance to parent
			if SearchPlayer(tbNpc.playerID) == 0 then
				if child.isDead == 0 and tbNpc.isDead == 0 then
					local pX32, pY32, pW32 = GetNpcPos(tbNpc.finalIndex)
					local nX32, nY32, nW32 = GetNpcPos(child.finalIndex)

					-- Too far from each other
					if GetDistanceRadius(nX32 / 32, nY32 / 32, pX32 / 32, pY32 / 32) > 30 then
						if (not tbNpc.tooFarStick) then
							tbNpc.tooFarStick = tbNpc.tick + 5
						elseif tbNpc.tooFarStick < tbNpc.tick then
							tbNpc.tooFarStick = nil
							self:ChildrenRespawn(nListId, childID, "Too far for 10 seconds")
						end
						return 0
					end
				end
			else

			end


			if child.isDead == 1 then
				return 0
			end
			return 1
		end
		return 1
	end
	return 0
end

function GroupFighter:ChildrenShow(nListId)
	local tbNpc = self.fighterList["n" .. nListId]

	if not tbNpc.children then
		return
	end

	local N = getn(tbNpc.children)
	for i = 1, N do
		self:ChildrenAdd(nListId, i)
	end
end

function GroupFighter:ChildrenAdd(nListId, childID)
	local tbNpc = self.fighterList["n" .. nListId]
	local worldInfo = {}
	local nW = tbNpc.nMapId

	local nMapIndex = SubWorldID2Idx(nW)

	if not tbNpc.children then
		return
	end

	local pX, pY, pW = GetNpcPos(tbNpc.finalIndex)
	pX = pX / 32
	pY = pY / 32


	if SearchPlayer(tbNpc.playerID) == 0 then
		worldInfo = SimCityWorld:Get(nW)
	else
		worldInfo.showName = 1
	end

	local child = tbNpc.children[childID]
	local targetPos = child.walkPath[tbNpc.nPosId]
	local nNpcIndex

	if not (child.isDead == 1 and tbNpc.noRevive == 1) then
		if not child.szName then
			local id = child.nNpcId
			if worldInfo.showName == 1 then
				child.szName = SimCityNPCInfo:getName(id)
			else
				child.szName = " "
			end
		end

		-- Are we closed to parent?
		if child.lastPos ~= nil then
			local lastPos = { child.lastPos.nX32 / 32, child.lastPos.nY32 / 32 }
			local distance = GetDistanceRadius(lastPos[1], lastPos[2], pX, pY)

			-- Within 10 radius to parent or not fighting, ok can respawn to last known location
			if tbNpc.isFighting == 0 or distance < 10 then
				targetPos = lastPos
			end
		end


		nNpcIndex = AddNpcEx(child.nNpcId, child.level or 95, child.series or random(0, 4), nMapIndex, targetPos[1] * 32,
			targetPos[2] * 32, 1, child.szName, 0)

		if nNpcIndex > 0 then
			local kind = GetNpcKind(nNpcIndex)
			if kind ~= 0 then
				DelNpcSafe(nNpcIndex)
			else
				-- Do magic on this NPC
				if (tbNpc.isFighting == 0) then
					SetNpcKind(nNpcIndex, tbNpc.kind or 4)
				end

				-- Choose side
				SetNpcCurCamp(nNpcIndex, tbNpc.camp)
				SetNpcActiveRegion(nNpcIndex, 1)


				-- Set param to link to parent
				SetNpcParam(nNpcIndex, self.PARAM_LIST_ID, nListId)
				SetNpcParam(nNpcIndex, self.PARAM_CHILD_ID, childID)
				SetNpcParam(nNpcIndex, self.PARAM_PLAYER_ID, SearchPlayer(tbNpc.playerID))
				SetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE, 2)
				SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\group_fighter.timer.lua")
				SetNpcTimer(nNpcIndex, self.ATICK_TIME)

				-- Ngoai trang?
				if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) then
					SimCityNgoaiTrang:makeup(child, nNpcIndex)
				end

				if tbNpc.cap and tbNpc.cap < 2 and NPCINFO_SetNpcCurrentLife then
					local maxHP = SimCityNPCInfo:getHPByCap(tbNpc.cap)
					NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, maxHP)
					NPCINFO_SetNpcCurrentLife(nNpcIndex, maxHP)
				end

				-- Life?
				if (child.lastHP ~= nil) then
					NPCINFO_SetNpcCurrentLife(nNpcIndex, child.lastHP)
					child.lastHP = nil
				end

				-- Store it
				child.finalIndex = nNpcIndex
				child.isDead = 0
				child.tick = tbNpc.tick
				child.canSwitchTick = tbNpc.canSwitchTick
				child.isFighting = tbNpc.isFighting
				tbNpc.children[childID] = child
			end
		end
	end
end

function GroupFighter:ChildrenRespawn(nListId, childID, reason)
	local tbNpc = self.fighterList["n" .. nListId]
	if not tbNpc then
		return 0
	end

	if tbNpc.children then
		local child = tbNpc.children[childID]

		if child.isDead ~= 1 and child.finalIndex ~= nil then
			child.lastHP = NPCINFO_GetNpcCurrentLife(child.finalIndex)
		end


		if child.finalIndex ~= nil then
			DelNpcSafe(child.finalIndex)
		end

		if child.isDead ~= 1 then
			if child.walkPath ~= nil then
				local targetPos = child.walkPath[tbNpc.nPosId]
				local cX = targetPos[1]
				local cY = targetPos[2]
				child.lastPos = {
					nX32 = cX * 32,
					nY32 = cY * 32
				}
			else
				local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)

				-- Do calculation
				nX = nX / 32
				nY = nY / 32
				child.lastPos = {
					nX32 = (nX + random(-2, 2)) * 32,
					nY32 = (nY + random(-2, 2)) * 32
				}
			end

			self:ChildrenAdd(nListId, childID)
		end
	end
end

function GroupFighter:ChildrenArrived(tbNpc)
	if not tbNpc.children then
		return 1
	end

	local N = getn(tbNpc.children)
	local N = getn(tbNpc.children)
	local posIndex = tbNpc.nPosId
	local isExact = tbNpc.tbPos[posIndex][3]


	for i = 1, N do
		local child = tbNpc.children[i]

		if (child.finalIndex) then
			local nX32, nY32 = GetNpcPos(child.finalIndex)
			local oX = nX32 / 32;
			local oY = nY32 / 32;

			local nX = child.walkPath[posIndex][1]
			local nY = child.walkPath[posIndex][2]

			local checkDistance = self.MAX_DIS

			if (tbNpc.isSpinning == 1) then
				nX = child.walkPath[posIndex][3]
				nY = child.walkPath[posIndex][4]
				checkDistance = self.MAX_DIS_SPINNING
			end

			if tbNpc.childrenCheckDistance then
				checkDistance = tbNpc.childrenCheckDistance
			end

			if isExact == 1 then
				nX = tbNpc.tbPos[posIndex][1]
				nY = tbNpc.tbPos[posIndex][2]
			end

			local distance = GetDistanceRadius(nX, nY, oX, oY)

			-- Con qua xa
			if distance > checkDistance then
				-- Qua thoi gian cho doi, keu con den ben canh
				if tbNpc.arriveTick < tbNpc.tick and tbNpc.isFighting ~= 1 then
					self:ChildrenRespawn(tbNpc.id, i, "Too far for 15 seconds")
					return 0
				end

				return 0
			end
		end
	end


	return 1
end

function GroupFighter:ChildrenWalk(tbNpc, posIndex)
	if not tbNpc.children then
		return
	end

	local N = getn(tbNpc.children)

	local tX = tbNpc.tbPos[posIndex][1]
	local tY = tbNpc.tbPos[posIndex][2]
	local isExact = tbNpc.tbPos[posIndex][3]

	local pX = 0
	local pY = 0
	local pW = 0

	if (tbNpc.isDead == 0 and tbNpc.finalIndex) then
		pX, pY, pW = GetNpcPos(tbNpc.finalIndex)
		pX = pX / 32
		pY = pY / 32
	end


	for i = 1, N do
		local child = tbNpc.children[i]
		if (child.finalIndex) then
			if isExact == 1 then
				NpcWalk(child.finalIndex, tX, tY)
			else
				if (tbNpc.walkMode == "keoxe" and pX > 0 and pY > 0 and pW > 0) then
					NpcWalk(child.finalIndex, pX + random(-2, 2), pY + random(-2, 2))
				else
					local targetPos = child.walkPath[posIndex]
					local nX = targetPos[1]
					local nY = targetPos[2]
					if tbNpc.isSpinning == 1 then
						nX = targetPos[3]
						nY = targetPos[4]
					end

					NpcWalk(child.finalIndex, nX, nY)
				end
			end
		end
	end
end

function GroupFighter:ChildrenRemove(nListId)
	local tbNpc = self.fighterList["n" .. nListId]

	if not tbNpc then
		return 1
	end

	if not tbNpc.children then
		return 1
	end

	local N = getn(tbNpc.children)
	for i = 1, N do
		local child = tbNpc.children[i]
		if (child.finalIndex) then
			DelNpcSafe(child.finalIndex)
			child.finalIndex = nil
			tbNpc.children[i] = child
		end
	end
	self.fighterList["n" .. nListId] = tbNpc
end

function GroupFighter:ChildrenDead(childrenIndex, playerAttacker)
	if childrenIndex > 0 then
		local nListId = GetNpcParam(childrenIndex, self.PARAM_LIST_ID)
		local childID = GetNpcParam(childrenIndex, self.PARAM_CHILD_ID)
		local tbNpc = self.fighterList["n" .. nListId]
		if not tbNpc then
			return
		end

		local child = tbNpc.children[childID]
		if (child) then
			local nX32, nY32 = GetNpcPos(childrenIndex)
			child.lastPos = {
				nX32 = nX32,
				nY32 = nY32
			}
			child.isDead = 1
			child.finalIndex = nil
		end

		self:_calculateFightingScore(child or tbNpc, childrenIndex, child.rank or 1)

		if tbNpc.tongkim == 1 then
			SimCityTongKim:OnDeath(childrenIndex, child.rank or 1)
			--else

			--	local oPlayerIndex = PlayerIndex
			--	if playerAttacker > 0 then

			--		if oPlayerIndex ~= playerAttacker then
			--			PlayerIndex = playerAttacker
			--		end

			--		tbAwardTemplet:GiveAwardByList(tbAwardgive, "KillBossExp")
			--		local nseries = NPCINFO_GetSeries(childrenIndex)
			--		ITEM_DropRateItem(childrenIndex, 8,"\\settings\\droprate\\npcdroprate90.ini", 0, 10, nseries);

			--		PlayerIndex = oPlayerIndex
			--	end
		end

		self:OnDeath(nListId)
	end
end

-- TONG KIM

function _sortByScore(tb1, tb2)
	return tb1[2] > tb2[2]
end

function GroupFighter:_calculateFightingScore(tbNpc, nNpcIndex, currRank)
	local allNpcs, nCount = Simcity_GetNpcAroundNpcList(nNpcIndex, 15)
	local foundTbNpcs = {}

	if nCount > 0 then
		for i = 1, nCount do
			local tbNpc2Kind = GetNpcKind(allNpcs[i])
			local tbNpc2Camp = GetNpcCurCamp(allNpcs[i])
			if (tbNpc2Kind == 0) then
				if (tbNpc2Camp ~= tbNpc.camp) then
					if (not tbNpc.targetCamp) or tbNpc.targetCamp == tbNpc2Camp then
						local nListId2 = GetNpcParam(allNpcs[i], self.PARAM_LIST_ID) or 0
						if (nListId2 > 0) then
							tinsert(foundTbNpcs, nListId2)
						end
					end
				end
			end
		end

		local N = getn(foundTbNpcs)
		if N > 0 then
			local scoreTotal = currRank * 1000
			for i = 1, N do
				local tbNpc2 = self.fighterList["n" .. foundTbNpcs[i]]
				if tbNpc2 and tbNpc2.isFighting == 1 then
					tbNpc2.fightingScore = ceil(tbNpc2.fightingScore + (scoreTotal / N) +
						(scoreTotal / N) * tbNpc2.rank /
						10)
					SimCityTongKim:updateRank(tbNpc2)
				end
			end
		end
	end

	return 0
end

function GroupFighter:ThongBaoBXH(nW)
	-- Collect all data
	local allPlayers = {}
	for i, tbNpc in self.fighterList do
		if tbNpc.nMapId == nW then
			tinsert(allPlayers, {
				i, tbNpc.fightingScore, "npc"
			})
		end
	end

	if (SimCityTongKim.playerInTK and SimCityTongKim.playerInTK[nW]) then
		for pId, data in SimCityTongKim.playerInTK[nW] do
			tinsert(allPlayers, {
				pId, data.score, "player"
			})
		end
	end

	if getn(allPlayers) > 1 then
		local maxIndex = getn(allPlayers)
		if maxIndex > 10 then
			maxIndex = 10
		end

		sort(allPlayers, _sortByScore)

		Msg2Map(nW, "<color=yellow>========= B∂NG X’P HπNG =========<color>")
		Msg2Map(nW, "<color=yellow>=================================<color>")

		for j = 1, maxIndex do
			local info = allPlayers[j]

			if info[3] == "npc" then
				local tbNpc = self.fighterList[info[1]]
				if tbNpc then
					local phe = ""

					if (tbNpc.tongkim == 1) then
						if (tbNpc.tongkim_name) then
							phe = tbNpc.tongkim_name
						else
							phe = "Kim"
							if tbNpc.camp == 1 then
								phe = "TËng"
							end
						end
					end

					if phe == "Kim" then
						phe = "K"
					else
						phe = "T"
					end

					local msg = "<color=white>" ..
						j ..
						" <color=yellow>[" ..
						phe ..
						"] " ..
						SimCityTongKim.RANKS[tbNpc.rank] ..
						" <color>" ..
						(tbNpc.hardsetName or SimCityNPCInfo:getName(tbNpc.nNpcId)) ..
						"<color=white> (" .. allPlayers[j][2] .. ")<color>"
					Msg2Map(nW, msg)
				end
			else
				local tbPlayer = SimCityTongKim.playerInTK[nW][info[1]]
				local msg = "<color=white>" ..
					j ..
					" <color=red>[" ..
					(tbPlayer.phe) ..
					"] " .. (tbPlayer.rank) .. " <color>" .. (tbPlayer.name) ..
					"<color=white> (" .. (tbPlayer.score) .. ")<color>"
				Msg2Map(nW, msg)
			end
		end
		Msg2Map(nW, "<color=yellow>=================================<color>")
	end
end
