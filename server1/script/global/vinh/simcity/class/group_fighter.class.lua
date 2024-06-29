IncludeLib("NPCINFO")
GroupFighter = {}
GroupFighter.npcByWorld = {}
GroupFighter.tbNpcList = {}
GroupFighter.counter = 1
GroupFighter.PARAM_LIST_ID = 1
GroupFighter.PARAM_CHILD_ID = 2
GroupFighter.ATICK_TIME = 9	-- refresh rate


GroupFighter.MAX_DIS = 5	-- start next position if within 3 points from destination
GroupFighter.MAX_DIS_SPINNING = 2	-- when spinning make sure the check is tighter
GroupFighter.SPINNING_WAIT_TIME = 0 -- wait time to correct position
GroupFighter.CHAR_SPACING = 1	-- spacing between group characters


GroupFighter.player_distance = 12 -- chay theo nguoi choi neu cach xa
GroupFighter.player_fight_distance = 8 -- neu gan nguoi choi khoang cach 12 thi chuyen sang chien dau
GroupFighter.player_distance_respawn = 30 -- neu qua xa nguoi choi vi chay nhanh thi phai bien hinh theo
GroupFighter.player_vision = 15 -- qua 15 = phai respawn vi no se quay ve cho cu

function GroupFighter:_randomNgoaiTrang(tbNpc, nNpcIndex)

	local newNgoaiTrang = SimCityNgoaiTrang:doRandom()

	tbNpc.nSettingsIdx = tbNpc.nSettingsIdx or newNgoaiTrang.nSettingsIdx
	tbNpc.nNewHelmType = tbNpc.nNewHelmType or newNgoaiTrang.nNewHelmType
	tbNpc.nNewArmorType = tbNpc.nNewArmorType or newNgoaiTrang.nNewArmorType
	tbNpc.nNewWeaponType = tbNpc.nNewWeaponType or newNgoaiTrang.nNewWeaponType
	tbNpc.nNewHorseType = tbNpc.nNewHorseType or newNgoaiTrang.nNewHorseType

	ChangeNpcFeature(nNpcIndex, 0, 0, tbNpc.nSettingsIdx, tbNpc.nNewHelmType, tbNpc.nNewArmorType, tbNpc.nNewWeaponType, tbNpc.nNewHorseType)


end

function GroupFighter:_makeDiagonal(points)
    local n = getn(points)

    if n < 3 then
        -- Not enough points to form a line
        return points
    end

    local results = {points[1]}

    -- Iterate through the points starting from the second point
    for i = 2, n - 1 do
        local A = points[i - 1]
        local B = points[i]
        local C = points[i + 1]

        -- Calculate the angles between line segments AB and BC
        local angleAB = atan2(B[2] - A[2], B[1] - A[1])
        local angleBC = atan2(C[2] - B[2], C[1] - B[1])

        -- Calculate the difference in angles
        local angleDiff = abs(angleBC - angleAB)


        if (B[3] and B[3] == 1) or angleDiff >= 20 then
        	tinsert(results, B)

        else

    		local distance = GetDistanceRadius(A[1], A[2], C[1], C[2])

    		-- Too close, we get rid of point B
    		if distance < 20 then
    			i = i + 1	-- jump
			else
				-- Adjust the position of point B to make the angle closer to 180 degrees
	            --B[1] = (A[1] + C[1]) / 2
	            --B[2] = (A[2] + C[2]) / 2
	            tinsert(results, B)
            end
    	end


    end

    tinsert(results, points[getn(points)])

    -- Return the corrected points
    return results
end
  

function GroupFighter:_genFormation(N)
    local bestX = 1
	local bestY = N

	local stop = 0
	local closestDifference = 1000

    for x = 1, N do
    	if stop == 0 then
	        local y = N / x
	        if mod(N,x) == 0 and mod(N,y) == 0 and y <= x and y ~= 1 then
	            bestX = x
	            bestY = y
	            stop = 1
            elseif (y < x) and (x - y < closestDifference) then
            	bestX = x
	            bestY = ceil(y)
	            closestDifference = x - y
	        end
        end
    end

    return {bestX, bestY}
end
 



function GroupFighter:_arrived(nNpcIndex, tbNpc)

	
	local posIndex = tbNpc.nPosId
	local parentPos = tbNpc.walkPath[posIndex]	


	local nX32, nY32 = GetNpcPos(nNpcIndex)	
	local oX = nX32/32;
	local oY = nY32/32;

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
			tbNpc.arriveTick = tbNpc.tick + 5	-- wait 10s for children to arrive
		end

		if tbNpc.arriveTick < tbNpc.tick or self:_arrived_children(tbNpc) == 1 then
			return 1
		end
	end
end

 
function GroupFighter:_checkRank(tbNpc)


	local newRank = 1
	if tbNpc.fightingScore > 2000 then
		newRank = 2
	end
	if tbNpc.fightingScore > 5000 then
		newRank = 3
	end
	if tbNpc.fightingScore > 10000 then
		newRank = 4
	end
	if tbNpc.fightingScore > 15000 then
		newRank = 5
	end
	if tbNpc.fightingScore > 20000 then
		newRank = 6
	end

	if (tbNpc.rank ~= newRank) then
		if newRank > tbNpc.rank and tbNpc.playerID == 0 then 
			local worldInfo = SimCityWorld:Get(tbNpc.nMapId)
			if worldInfo.showThangCap == 1 then
				SimCityTongKim:announceRank(tbNpc.nMapId, tbNpc.hardsetName or SimCityNPCInfo:getName(tbNpc.nNpcId), newRank)			
			end
		end
		tbNpc.rank = newRank

	end

end
 
function GroupFighter:_addNpcGo(tbNpc, isNew, goX, goY)	

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
			name = name .." "..SimCityTongKim.RANKS[tbNpc.rank]

		end


		if (tbNpc.hardsetName) then
			name = tbNpc.hardsetName
		end

		nNpcIndex = AddNpcEx(tbNpc.nNpcId, 95, tbNpc.series, nMapIndex,tX * 32, tY * 32, 1, name , 0)


		if nNpcIndex > 0 then
			local kind = GetNpcKind(nNpcIndex)
			if kind ~= 0 then 
				DelNpcSafe(nNpcIndex)
			else
				tbNpc.szName = GetNpcName(nNpcIndex)
				tbNpc.finalIndex = nNpcIndex
				tbNpc.isDead = 0
				tbNpc.lastPos = {
					nX32 = tX*32,
					nY32 = tY*32,
					nPosId = nPosId
				}

				local nNpcListIndex = self.counter + 0

				-- Save to DB
				if (isNew == 1) then
					self.counter = self.counter + 1
					tbNpc.nNpcListIndex = nNpcListIndex					
				else
					nNpcListIndex = tbNpc.nNpcListIndex
				end


				self.tbNpcList["n"..tbNpc.nNpcListIndex] = tbNpc


				if (not self.npcByWorld["w"..tbNpc.nMapId]) then
					self.npcByWorld["w"..tbNpc.nMapId] = {}
				end
				self.npcByWorld["w"..tbNpc.nMapId]["n"..tbNpc.nNpcListIndex] = tbNpc.nNpcListIndex
				
				
				-- Otherwise choose side
				SetNpcCurCamp(nNpcIndex, tbNpc.camp)

				local nPosCount = getn(tbPos)
				if nPosCount >= 1 then
					SetNpcActiveRegion(nNpcIndex, 1)				
					tbNpc.nPosId = nPosId
				end
				if nPosCount >= 1 or tbNpc.nSkillId then	
					SetNpcParam(nNpcIndex, self.PARAM_LIST_ID, nNpcListIndex)
					SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\group_fighter.timer.lua")
					SetNpcTimer(nNpcIndex, self.ATICK_TIME)
					
				end

				-- Ngoai trang?
				if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) then
					self:_randomNgoaiTrang(tbNpc, nNpcIndex)
				end
				

				self:_addNpcGo_chilren(nNpcListIndex, tbNpc.nMapId)


				-- Disable fighting?
				if (tbNpc.isFighting == 0) then
					SetNpcKind(nNpcIndex, tbNpc.kind or 4)
					self:_changeAI(tbNpc, 0)
				end
				

				return nNpcListIndex
			end
		end

		return 0
	end
	return 0

end




function GroupFighter:_respawn(nListId, isAllDead, reason)

	--CallPlayerFunction(1, Msg2Player, "Respawn: "..reason)

	local tbNpc = self.tbNpcList["n"..nListId] 

	isAllDead = isAllDead or 0

	local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)

	-- Do calculation
	nX = nX/32
	nY = nY/32

	if isAllDead == 1 and tbNpc.playerID > 0 then
		nX = tbNpc.walkPath[1][1]
		nY = tbNpc.walkPath[1][2]
		tbNpc.nPosId = 1
	elseif (isAllDead == 1 and tbNpc.resetPosWhenRevive and tbNpc.resetPosWhenRevive >= 1) then
		nX = tbNpc.walkPath[tbNpc.resetPosWhenRevive][1]
		nY = tbNpc.walkPath[tbNpc.resetPosWhenRevive][2]
		tbNpc.nPosId = tbNpc.resetPosWhenRevive
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

	-- Retrieve position of each
	if tbNpc.children then		
		for i=1,getn(tbNpc.children) do
			local child = tbNpc.children[i]
			
			if (isAllDead == 1 and ((tbNpc.resetPosWhenRevive and tbNpc.resetPosWhenRevive >= 1) or (tbNpc.playerID > 0))) then
				child.lastPos = nil
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

	self.tbNpcList["n"..nListId] = tbNpc
	self:DelNpcSafe_children(nListId)
	self:_addNpcGo(tbNpc, 0, nX, nY)

end

function GroupFighter:_getNpcAroundNpcList(nNpcIndex, radius)
	local allNpcs = {}
	local nCount = 0

	-- 8.0: has GetNpcAroundNpcList function 
	if GetNpcAroundNpcList then 
		return GetNpcAroundNpcList(nNpcIndex, radius)
		
	-- 6.0: do the long route  

    else
		local myListId = GetNpcParam(nNpcIndex, self.PARAM_LIST_ID)
    	local nX32, nY32, nW32 = GetNpcPos(nNpcIndex)
		local areaX = nX32/32
		local areaY = nY32/32
		local nW = SubWorldIdx2ID(nW32)

		-- Get info for npc in this world
		for key, nListId in self.npcByWorld["w"..nW] do
			if nListId ~= myListId then 
	    		local tbNpc = self.tbNpcList["n"..nListId]
				if tbNpc then
					if (tbNpc.isDead == 0) then
						local oX32, oY32 = GetNpcPos(tbNpc.finalIndex)
						local oX = oX32/32
						local oY = oY32/32
						if GetDistanceRadius(oX,oY,areaX,areaY) < radius then
							tinsert(allNpcs, tbNpc.finalIndex)
							nCount = nCount + 1
						end
					end
				end
			end
		end

	end
	
	return allNpcs, nCount
end

function GroupFighter:_isNpcEnemyAround(tbNpc, nNpcIndex, radius)

	local allNpcs = {}
	local nCount = 0

	if tbNpc.playerID > 0 then
		allNpcs, nCount = CallPlayerFunction(tbNpc.playerID, GetAroundNpcList, radius)
		for i = 1, nCount do
			local tbNpc2Kind = GetNpcKind(allNpcs[i])
			local tbNpc2Camp = GetNpcCurCamp(allNpcs[i])
	    	if (tbNpc2Kind == 0) then			
				if (tbNpc2Camp ~= tbNpc.camp) then
					if (not tbNpc.targetCamp) or tbNpc.targetCamp == tbNpc2Camp then
						return 1
					end
				end
			end
	    end   
	end

	allNpcs, nCount = self:_getNpcAroundNpcList(nNpcIndex, radius)
    for i = 1, nCount do
		local tbNpc2Kind = GetNpcKind(allNpcs[i])
		local tbNpc2Camp = GetNpcCurCamp(allNpcs[i])
    	if (tbNpc2Kind == 0) then			
			if (tbNpc2Camp ~= tbNpc.camp) then
				if (not tbNpc.targetCamp) or tbNpc.targetCamp == tbNpc2Camp then
					return 1
				end
			end
		end
    end   


    if tbNpc.children then
    	for j=1,getn(tbNpc.children) do
    		if (tbNpc.children[j] and tbNpc.children[j].finalIndex and tbNpc.children[j].finalIndex > 0 and tbNpc.children[j].isDead == 0) then
				local allNpcs, nCount = self:_getNpcAroundNpcList(tbNpc.children[j].finalIndex, radius)
				for i = 1, nCount do
					local tbNpc2Kind = GetNpcKind(allNpcs[i])
					local tbNpc2Camp = GetNpcCurCamp(allNpcs[i])
					if (tbNpc2Kind == 0) then			
						if (tbNpc2Camp ~= tbNpc.camp) then
							if (not tbNpc.targetCamp) or tbNpc.targetCamp == tbNpc2Camp then
								return 1
							end
						end
					end
				end
			end
		end

	end

    return 0
end




function GroupFighter:_isPlayerEnemyAround(nListId, nNpcIndex)

	local tbNpc = self.tbNpcList["n"..nListId]

	if not tbNpc then
		return 0
	end

    -- FIGHT other player
	if GetNpcAroundPlayerList then 
		local allNpcs, nCount = GetNpcAroundPlayerList(nNpcIndex, tbNpc.fightPlayerRadius or fightPlayerRadius)
	    for i = 1, nCount do
			if (CallPlayerFunction(allNpcs[i], GetFightState) == 1 and CallPlayerFunction(allNpcs[i], GetCurCamp) ~= tbNpc.camp) and tbNpc.camp ~= 0 then
				return 1
			end
	    end  

		-- Check children
		if tbNpc.children then
	    	for j=1,getn(tbNpc.children) do
	    		if (tbNpc.children[j] and tbNpc.children[j].finalIndex and tbNpc.children[j].finalIndex > 0 and tbNpc.children[j].isDead == 0) then
					local allNpcs, nCount = GetNpcAroundPlayerList(tbNpc.children[j].finalIndex, tbNpc.fightPlayerRadius or fightPlayerRadius)
					for i = 1, nCount do
						if (CallPlayerFunction(allNpcs[i], GetFightState) == 1 and CallPlayerFunction(allNpcs[i], GetCurCamp) ~= tbNpc.camp) and tbNpc.camp ~= 0 then
							return 1
						end
				    end  
				end
			end

		end
	end
	return 0
end



function GroupFighter:_joinFight(nListId, reason)
	local tbNpc = self.tbNpcList["n"..nListId]
	if not tbNpc then
		return 0
	end
	tbNpc.isFighting = 1
	tbNpc.canSwitchTick = tbNpc.tick + random(tbNpc.tg_danhnhau_minTs or tg_danhnhau.minTs,tbNpc.tg_danhnhau_maxTs or tg_danhnhau.maxTs)	-- trong trang thai pk 1 toi 2ph
	self.tbNpcList["n"..nListId] = tbNpc

	reason = reason or "no reason"

	local currX, currY, currW = GetNpcPos(tbNpc.finalIndex)
	currX = floor(currX/32)
	currY = floor(currY/32)

	-- If already having last fight pos, we may simply chance AI to 1
	if tbNpc.lastFightPos then
		local lastPos = tbNpc.lastFightPos
		if lastPos.W == currW then
			if (GetDistanceRadius(lastPos.X, lastPos.Y, currX, currY) < self.player_vision) then
				self:_changeAI(tbNpc, 9)
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
	
	self:_respawn(nListId, 0, "_joinFight ".. reason)

	return 1
end




function GroupFighter:_joinFightCheck(nListId, nNpcIndex)

	local tbNpc = self.tbNpcList["n"..nListId]

	if not tbNpc then
		return 0
	end

	if (self:_isNpcEnemyAround(tbNpc, nNpcIndex, tbNpc.fightScanRadius or fightScanRadius) == 1) then	
		return self:_joinFight(nListId, "enemy around")
    end  
	return 0
end


function GroupFighter:_joinFightPlayerCheck(nListId, nNpcIndex)

	local tbNpc = self.tbNpcList["n"..nListId]

	if not tbNpc then
		return 0
	end

    -- FIGHT other player
	if GetNpcAroundPlayerList then 
		if self:_isPlayerEnemyAround(nListId, nNpcIndex) == 1 then

			local nW = tbNpc.nMapId


			if tbNpc.playerID == 0 then
				local worldInfo = SimCityWorld:Get(nW)
				if worldInfo.showFightingArea == 1 then 
					local name = GetNpcName(nNpcIndex)
					local lastPos = tbNpc.tbPos[tbNpc.nPosId]
					Msg2Map(tbNpc.nMapId, "<color=white>"..name.."<color> Æ∏nh ng≠Íi tπi "..worldInfo.name.." "..floor(lastPos[1]/8).." "..floor(lastPos[2]/16).."")
				end
			end
			return self:_joinFight(nListId, "player around")
	    end 
	end

	return 0
end



	


function GroupFighter:_leaveFight(nListId, isAllDead, reason)

	isAllDead = isAllDead or 0
	local tbNpc = self.tbNpcList["n"..nListId]
	if not tbNpc then
		return 0
	end
	tbNpc.isFighting = 0
	tbNpc.canSwitchTick = tbNpc.tick + random(tbNpc.tg_nghingoi_minTs or tg_nghingoi.minTs, tbNpc.tg_nghingoi_maxTs or tg_nghingoi.maxTs)	-- trong trang thai di bo 30s-1ph
	self.tbNpcList["n"..nListId] = tbNpc
	reason = reason or "no reason"

	-- Do not need to respawn just disable fighting
	if (isAllDead ~= 1 and tbNpc.kind ~= 4) then
		self:_changeAI(tbNpc, 0)
	else
		self:_respawn(nListId, isAllDead, reason)	
	end
end

function GroupFighter:_leaveFightCheck(nListId, nNpcIndex)

	local tbNpc = self.tbNpcList["n"..nListId]
	if not tbNpc then
		return 0
	end

	if tbNpc.isDead == 1 then
		return 0
	end

	-- No attacker around including NPC and Player ? Stop
	if (self:_isNpcEnemyAround(tbNpc, nNpcIndex, tbNpc.fightScanRadius or fightScanRadius) == 0 
		and self:_isPlayerEnemyAround(nListId, nNpcIndex) == 0) then 

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


 
function GroupFighter:_debug(msg)
	print(msg)	
end


function GroupFighter:_generateWalkPath(tbNpc)

	-- Generate walkpath for myself
	-- & Repeat for children
	local WalkSize = getn(tbNpc.tbPos)	
	tbNpc.walkPath = {}
	
	local childrenSize = 0
	if tbNpc.children then
		childrenSize = getn(tbNpc.children)
	end

	if childrenSize > 0 then
		for j=1,childrenSize do
			tbNpc.children[j].walkPath = {}
		end
	end


	for i=1,WalkSize do
		local point = tbNpc.tbPos[i]
		-- Having children?
		if childrenSize > 0 then
			
			-- RANDOM walk for everyone?
			if tbNpc.walkMode == "random" or tbNpc.walkMode == "keoxe" then
				tinsert(tbNpc.walkPath, self:_randomRange(point, tbNpc.walkVar or 2))
				for j=1,childrenSize do
					tinsert(tbNpc.children[j].walkPath, self:_randomRange(point, tbNpc.walkVar or 2))
				end

			-- FORMATION walk?
			else


				-- For children				
				local formation = self:_genCoords_squareshape(tbNpc, childrenSize, i)				
				for j=1,childrenSize do
					tinsert(tbNpc.children[j].walkPath, formation[j])
				end

				-- For myself
				local firstPointLastRow = formation[childrenSize+1]
				local lastPointLastRow 
				for k=childrenSize+1,getn(formation) do
					lastPointLastRow = formation[k]
				end

				tinsert(tbNpc.walkPath, {
					(firstPointLastRow[1] + lastPointLastRow[1])/2,
					(firstPointLastRow[2] + lastPointLastRow[2])/2,
					(firstPointLastRow[3] + lastPointLastRow[3])/2,
					(firstPointLastRow[4] + lastPointLastRow[4])/2
				})	
			end			


		-- No children = random path for myself
		else
			tinsert(tbNpc.walkPath, self:_randomRange(point, tbNpc.walkVar or 2))
		end

	end
end



function GroupFighter:Get(nListId)
	return self.tbNpcList["n"..nListId]
end


function GroupFighter:_isValid(id)

 	if SimCityNPCInfo:notValidChar(id) == 1 
 		or SimCityNPCInfo:isBlacklisted(id) == 1
		or SimCityNPCInfo:notFightingChar(id) == 1 then
		return 0
	end	

	return 1
end

function GroupFighter:New(tbNpc)

	local result = {}
	local nW = tbNpc.nMapId
	local worldInfo = {}
	
	local walkAreas = {}

	local id = tbNpc.nNpcId
	tbNpc.playerID = tbNpc.playerID or 0

	if tbNpc.playerID > 0 then
		local pW, pX, pY = CallPlayerFunction(tbNpc.playerID, GetWorldPos)
		worldInfo.showName = 1
		tbNpc.tbPos = {
			{pX, pY}
		}
		tbNpc.nPosId = 1
		walkAreas =  {{
			{pX, pY}
		}}
	else
		worldInfo = SimCityWorld:Get(nW)
		walkAreas = worldInfo.walkAreas		
	end
	

	if walkAreas == nil then
		return 0
	end

	-- No path to walk?
	if getn(walkAreas) < 1 then 
		return 0
	end

	--Not a valid char ?
	if self:_isValid(id) == 0 then
		return 0
	end

	-- Not having valid children char?
	if tbNpc.children then
		local validChildren = {}
		for i=1,getn(tbNpc.children) do
			local child = tbNpc.children[i]
			if self:_isValid(child.nNpcId) == 1 then
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
	tbNpc.series = tbNpc.series or random(0,4)
	tbNpc.camp = tbNpc.camp or random(1,3)
	tbNpc.walkMode = tbNpc.walkMode or 1
	tbNpc.isSpinning = 0
	tbNpc.lastOffSetAngle = 0
	tbNpc.noRevive = tbNpc.noRevive or 0
	tbNpc.fightingScore = 0
	tbNpc.rank = 1

	if (tbNpc.camp ==3) then
		tbNpc.camp = 5
	end

	-- Setup walk paths
	if tbNpc.playerID == 0 then
		local walkIndex = random(1,getn(walkAreas))
		tbNpc.tbPos = tbNpc.tbPos or walkAreas[walkIndex]
		if tbNpc.walkMode ~= "random" and tbNpc.walkMode ~= "keoxe" and tbNpc.children then
			tbNpc.tbPos = self:_makeDiagonal(tbNpc.tbPos)
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
	self:_generateWalkPath(tbNpc)

	-- Add to store and create everyone on screen 
	return self:_addNpcGo(tbNpc, 1)

end

 
function GroupFighter:_randomRange(point, walkVar)
	return {point[1] +random(-walkVar,walkVar), point[2] +random(-walkVar,walkVar)}
end

 
function GroupFighter:_genCoords_squareshape(tbNpc, N, targetPointer) 
    local f = self:_genFormation(N)
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
	for i=0,rows do
		for j=0,cols-1 do
			total = total + 1
			
			local newX = x + j*spacing
			local newY = y + j*spacing

			local newXF = xF + j*spacing
			local newYF = yF + j*spacing

			if (mostLeft > newX or mostLeft == 0) then mostLeft = newX end
			if (mostTop > newY or mostTop == 0) then mostTop = newY end
			if (mostRight < newX or mostRight == 0) then mostRight = newX end
			if (mostBottom < newY or mostBottom == 0) then mostBottom = newY end
			tinsert(rhombus, {newX, newY, newXF, newYF})
		end
		y = y - spacing
		x = x + spacing

		yF = yF - spacing
		xF = xF + spacing
	end


	-- And we need to shift it back to centre of the original path
	local centreX = (mostRight + mostLeft)/2
	local centreY = (mostBottom + mostTop)/2
	local offSetX = centreX - toPos[1]
	local offSetY = centreY - toPos[2]
	for i=1,total do
		rhombus[i] = self:_transform(tbNpc,{
			rhombus[i][1] - offSetX, 
			rhombus[i][2] - offSetY, 
			rhombus[i][3] - offSetX, 
			rhombus[i][4] - offSetY
		}, toPos, fromPos, toPos)
	end

	-- DONE
    return rhombus


end


function GroupFighter:_transform(tbNpc, point, centrePoint, fromPos, toPos)
	
	local deltaX = toPos[1] - fromPos[1]
	local deltaY = toPos[2] - fromPos[2]

	local offsetAngle = atan2(deltaY, deltaX) + 45


	offsetAngle = floor(offsetAngle/45 + 0.5) * 45

	-- Input coordinates
	local x = centrePoint[1]  -- x-coordinate of point O
	local y = centrePoint[2]  -- y-coordinate of point O
	local x1 = point[1] -- x-coordinate of point A
	local y1 = point[2] -- y-coordinate of point A
	local xF = fromPos[1] -- x-coordinate of point A
	local yF = fromPos[2] -- y-coordinate of point A

	-- Calculate the angle OA makes with the x-axis
	local angle_OA = atan2(y1 - y, x1 - x)

	-- Calculate the new angle for OA' (45 degrees more than angle_OA)
	local angle_OA_prime = angle_OA + offsetAngle

	-- Calculate the distance from O to A'
	local distance_OA_prime = sqrt((x1 - x)^2 + (y1 - y)^2)

	-- Calculate the new coordinates for A'
	local x_prime = x + distance_OA_prime * cos(angle_OA_prime)
	local y_prime = y + distance_OA_prime * sin(angle_OA_prime)

	local xF_prime = xF + distance_OA_prime * cos(angle_OA_prime)
	local yF_prime = yF + distance_OA_prime * sin(angle_OA_prime)

	-- New toPos and fromPos
	return {x_prime, y_prime, xF_prime, yF_prime}


end

 
function GroupFighter:ClearMap(nW, targetListId)
	if (self.npcByWorld["w"..nW]) then
		for key, nListId in self.npcByWorld["w"..nW] do		

			if (not targetListId) or (targetListId == nListId) then
				local tbNpc = self.tbNpcList["n"..nListId]
				if tbNpc then
					DelNpcSafe(tbNpc.finalIndex)
					self:DelNpcSafe_children(nListId)
					self.tbNpcList["n"..nListId] = nil
					self.npcByWorld["w"..nW][key] = nil
				end
			end
		end
	end
end




 


function GroupFighter:_addNpcGo_chilren(nListId, nW)	
	local tbNpc = self.tbNpcList["n"..nListId]
	local worldInfo = {}


	local nMapIndex = SubWorldID2Idx(nW)

	if not tbNpc.children then 
		return
	end
 
	local N = getn(tbNpc.children)

	local pX, pY, pW = GetNpcPos(tbNpc.finalIndex)
	pX = pX/32
	pY = pY/32

 
 	if tbNpc.playerID == 0 then
		worldInfo = SimCityWorld:Get(nW)
	else
		worldInfo.showName = 1
	end	
 
	for i=1,N do

		local child = tbNpc.children[i]
		local targetPos = child.walkPath[tbNpc.nPosId]
		local nNpcIndex

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
			local lastPos = {child.lastPos.nX32/32, child.lastPos.nY32/32}
			local distance = GetDistanceRadius(lastPos[1], lastPos[2], pX, pY)

			-- Within 10 radius to parent or not fighting, ok can respawn to last known location
			if tbNpc.isFighting == 0 or distance < 10 then
				targetPos = lastPos
			end
		end


		nNpcIndex = AddNpcEx(child.nNpcId, 95, child.series or random(0,4), nMapIndex, targetPos[1] * 32, targetPos[2] * 32, 1, child.szName, 0)

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
				SetNpcParam(nNpcIndex, self.PARAM_CHILD_ID, i)
				SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\group_fighter.timer.child.lua")
				SetNpcTimer(nNpcIndex, self.ATICK_TIME)
				
				-- Ngoai trang?
				if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) then
					self:_randomNgoaiTrang(child, nNpcIndex)
				end

				-- Store it
				child.finalIndex = nNpcIndex
				child.isDead = 0
				child.tick = tbNpc.tick
				child.canSwitchTick = tbNpc.canSwitchTick
				child.isFighting = tbNpc.isFighting
				tbNpc.children[i] = child				
			end
		end
	end
	self.tbNpcList["n"..nListId] = tbNpc
 
end


function GroupFighter:_changeAI(tbNpc, mode)
	SetNpcAI(tbNpc.finalIndex, mode)
	if tbNpc.children then
		for i=1,getn(tbNpc.children) do
			local child = tbNpc.children[i]
			if child.finalIndex then
				SetNpcAI(child.finalIndex, mode)
			end
		end
	end
end

function GroupFighter:_arrived_children(tbNpc)

	if not tbNpc.children then 
		return 1
	end
 
	local N = getn(tbNpc.children)
	local N = getn(tbNpc.children)
	local posIndex = tbNpc.nPosId
	local isExact = tbNpc.tbPos[posIndex][3]

	
	for i=1,N do
		local child = tbNpc.children[i]

		if (child.finalIndex) then
			local nX32, nY32 = GetNpcPos(child.finalIndex)
			local oX = nX32/32;
			local oY = nY32/32;

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

			local distance = GetDistanceRadius(nX,nY,oX,oY)

			if distance > checkDistance then
				return 0
			end

		end
	end
 

	return 1
	
end

 



function GroupFighter:_walk_children(tbNpc, posIndex)
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
		pX = pX/32
		pY = pY/32
	end


	for i=1,N do
		local child = tbNpc.children[i]
		if (child.finalIndex) then

			if isExact==1 then				
				NpcWalk(child.finalIndex, tX, tY)
			else

				if (tbNpc.walkMode == "keoxe" and pX > 0 and pY > 0 and pW > 0) then
					NpcWalk(child.finalIndex, pX + random(-2,2), pY + random(-2,2)) 
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


function GroupFighter:DelNpcSafe_children(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]
	if not tbNpc.children then 
		return 1
	end
 
	local N = getn(tbNpc.children)
	for i=1,N do
		local child = tbNpc.children[i]
		if (child.finalIndex) then
		 	DelNpcSafe(child.finalIndex)
		 	child.finalIndex = nil
		 	tbNpc.children[i] = child
		end
	end
	self.tbNpcList["n"..nListId] = tbNpc
	
end


function GroupFighter:_calculateFightingScore(tbNpc, nNpcIndex, currRank)	
	local allNpcs, nCount = self:_getNpcAroundNpcList(nNpcIndex, 15)
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
	    	for i=1,N do
	    		local tbNpc2 = self.tbNpcList["n"..foundTbNpcs[i]]
	    		if tbNpc2 and tbNpc2.isFighting == 1 then
	    			tbNpc2.fightingScore = ceil(tbNpc2.fightingScore + (scoreTotal/N) + (scoreTotal/N)*tbNpc2.rank/10)
	    			self:_checkRank(tbNpc2)
				end
			end
		end
	end

    return 0
end

function GroupFighter:ChildrenDead(childrenIndex, playerAttacker)	
	if childrenIndex > 0 then
		local nListId = GetNpcParam(childrenIndex, self.PARAM_LIST_ID)
		local childID = GetNpcParam(childrenIndex, self.PARAM_CHILD_ID)
		local tbNpc = self.tbNpcList["n"..nListId]
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
		else

			local oPlayerIndex = PlayerIndex
			if playerAttacker > 0 then			

				if oPlayerIndex ~= playerAttacker then
					PlayerIndex = playerAttacker
				end

				tbAwardTemplet:GiveAwardByList(tbAwardgive, "KillBossExp")
				local nseries = NPCINFO_GetSeries(childrenIndex)
				ITEM_DropRateItem(childrenIndex, 8,"\\settings\\droprate\\npcdroprate90.ini", 0, 10, nseries);

				PlayerIndex = oPlayerIndex
			end
		end

		self:_check_full_death(nListId)
	end
end




function GroupFighter:OnNpcDeath(nNpcIndex, playerAttacker)	
	if nNpcIndex > 0 then
		local nListId = GetNpcParam(nNpcIndex, self.PARAM_LIST_ID)
		local tbNpc = self.tbNpcList["n"..nListId]	
		if not tbNpc then
			return
		end
		tbNpc.isDead = 1
		tbNpc.finalIndex = nil


		self:_calculateFightingScore(tbNpc, nNpcIndex, tbNpc.rank or 1)

		if tbNpc.tongkim == 1 then
			SimCityTongKim:OnDeath(nNpcIndex, tbNpc.rank or 1)
		else
			if playerAttacker > 0 then

				local oPlayerIndex = PlayerIndex
				if oPlayerIndex ~= playerAttacker then
					PlayerIndex = playerAttacker
				end
				tbAwardTemplet:GiveAwardByList(tbAwardgive, "KillBossExp")
				local nseries = NPCINFO_GetSeries(nNpcIndex)
				ITEM_DropRateItem(nNpcIndex, 8,"\\settings\\droprate\\npcdroprate90.ini", 0, 10, nseries)
				PlayerIndex = oPlayerIndex
			end
		end

		self:_check_full_death(nListId)
	end
end

function GroupFighter:_check_full_death(nListId)

	local tbNpc = self.tbNpcList["n"..nListId]	
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
			for i=1,N do
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
		


		if tbNpc.playerID == 0 then
			local worldInfo = SimCityWorld:Get(nW)
			if tbNpc.children and worldInfo.showFightingArea == 1 then
				Msg2Map(nW, "<color=white>"..tbNpc.szName.."<color> toµn Æoµn bπi trÀn <color=yellow>"..floor(lastPos[1]/8).." "..floor(lastPos[2]/16).."<color>")
			end
		end

		-- No revive? Do nothing
		if tbNpc.noRevive == 1 then
			return
		end


    
    	tbNpc.fightingScore = ceil(tbNpc.fightingScore*0.7)
    	self:_checkRank(tbNpc)

		-- Do revive? Reset and leave fight
		self:_leaveFight(nListId, 1, "die toan bo")
	end
end





function GroupFighter:ChildrenTick(childrenIndex)

	if childrenIndex > 0 then

		local nListId = GetNpcParam(childrenIndex, self.PARAM_LIST_ID)
		local childID = GetNpcParam(childrenIndex, self.PARAM_CHILD_ID)
		local tbNpc = self.tbNpcList["n"..nListId]

		if not tbNpc then
			return 1
		end
		local child = tbNpc.children[childID]



		if (tbNpc and child) then
			child.tick = child.tick + self.ATICK_TIME/18
			tbNpc.children[childID] = child
			if tbNpc.tick + 2 < child.tick then
				tbNpc.tick = child.tick
			end
			self.tbNpcList["n"..nListId] = tbNpc


			-- Check distance to parent
			if tbNpc.playerID == 0 then
				if child.isDead == 0 and tbNpc.isDead == 0 then
					local pX32, pY32, pW32 = GetNpcPos(tbNpc.finalIndex)
					local nX32, nY32, nW32 = GetNpcPos(child.finalIndex)

					-- Too far from each other
					if GetDistanceRadius(nX32/32,nY32/32, pX32/32, pY32/32) > 30 then
						if (not tbNpc.tooFarStick) then
							tbNpc.tooFarStick = tbNpc.tick + 5
						elseif tbNpc.tooFarStick < tbNpc.tick then
							tbNpc.tooFarStick = nil
							self:_respawn(nListId, 1, "Too far for 5 seconds")
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


function GroupFighter:ParentTick(nNpcIndex)
	if nNpcIndex > 0 then
		local nListId = GetNpcParam(nNpcIndex, self.PARAM_LIST_ID)
		local tbNpc = self.tbNpcList["n"..nListId]
		if not tbNpc then
			return 1
		end
		tbNpc.tick = tbNpc.tick + self.ATICK_TIME/18
		tbNpc.finalIndex = nNpcIndex

		if tbNpc.isFighting == 1 then
			tbNpc.fightingScore = tbNpc.fightingScore + 10
		end
		self.tbNpcList["n"..nListId] = tbNpc
		self:_doParentTick(nListId)

		if tbNpc.isDead == 1 then
			return 0
		end
		return 1
	end
	return 1
end


 

function GroupFighter:_doParentTick(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]

	local nNpcIndex = tbNpc.finalIndex


	local nX32, nY32, nW32 = GetNpcPos(nNpcIndex)
	local nW = SubWorldIdx2ID(nW32)
	local worldInfo = {}



	local pW = 0
	local pX = 0
	local pY = 0

	
	local myPosX = floor(nX32/32)
	local myPosY = floor(nY32/32)

	local cachNguoiChoi = 0	


	if tbNpc.playerID == 0 then
		worldInfo = SimCityWorld:Get(nW)

		-- Otherwise just Random chat
		if worldInfo.allowChat == 1 then
			if tbNpc.isFighting == 1 then
				if random(1,talkChance/2) <= 2 then
					NpcChat(nNpcIndex,  SimCityChat:getChatFight())
				end
			else
				if random(1,talkChance) <= 2 then
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
		pW, pX, pY = CallPlayerFunction(tbNpc.playerID, GetWorldPos)
		cachNguoiChoi = GetDistanceRadius(myPosX,myPosY, pX, pY)
	end

	
	-- Is fighting? Do nothing except leave fight if possible
	if tbNpc.isFighting == 1 then

		-- Case 1: toi gio chuyen doi 
		if tbNpc.canSwitchTick < tbNpc.tick then
			return self:_leaveFight(nListId, 0, "toi gio thay doi trang thai")
		end

		-- Case 2: tu dong thoat danh khi khong con ai
		if self:_leaveFightCheck(nListId, nNpcIndex) == 1 then
			--self:_leaveFight(nListId, 0, "khong tim thay quai")
			return 1
		end

		-- Case 3: qua xa nguoi choi phai chay theo ngay
		if (tbNpc.playerID > 0 and  cachNguoiChoi > self.player_distance) then
			tbNpc.canSwitchTick = tbNpc.tick - 1
			self:_leaveFight(nListId, 0, "chay theo nguoi choi")
		else
			return 1	
		end
	end
	
	-- Up to here means walking
	local nNextPosId = tbNpc.nPosId
	local tbPos = tbNpc.tbPos	
	local WalkSize = getn(tbPos)
	if tbNpc.playerID == 0 and (nNextPosId == 0 or WalkSize < 2) then
		return 0
	end

	if ((tbNpc.playerID > 0 and cachNguoiChoi <= self.player_fight_distance) or tbNpc.playerID == 0) 
		and (worldInfo.allowFighting == 1) and (tbNpc.isFighting == 0 and tbNpc.canSwitchTick < tbNpc.tick) 
	then

		-- Case 1: someone around is fighting, we join		
		if (tbNpc.joinFightChance and random(0, tbNpc.joinFightChance) <= 2) then			
			if self:_joinFightCheck(nListId, nNpcIndex) == 1 then
				return 1
			end
		end


		-- Case 2: some player around is fighting and different camp, we join
		if (tbNpc.attackPlayerChance and random(0, tbNpc.attackPlayerChance) <= 2)
			then
			if self:_joinFightPlayerCheck(nListId, nNpcIndex) == 1 then
				return 1
			end
		end

		-- Case 3: I auto switch to fight  mode
		if (tbNpc.playerID == 0 and tbNpc.attackNpcChance and random(1,tbNpc.attackNpcChance) <= 2) then			
			-- CHo nhung dua chung quanh 
			
			local countFighting = 0
			if self.npcByWorld["w"..tbNpc.nMapId] then 
				for key, nListId2 in self.npcByWorld["w"..tbNpc.nMapId] do

					-- Myself = I start 
					if nListId2 ~= nListId then

						local tbNpc2 = self.tbNpcList["n"..nListId2]
						
						if (tbNpc2.isFighting == 0 and tbNpc2.camp ~= tbNpc.camp) then

							if (not tbNpc.targetCamp) or tbNpc.targetCamp == tbNpc2.camp then
								local otherPosX, otherPosY, otherPosW = GetNpcPos(tbNpc2.finalIndex)
								otherPosX = floor(otherPosX / 32)
								otherPosY = floor(otherPosY / 32)

								local distance = floor(GetDistanceRadius(otherPosX,otherPosY,myPosX,myPosY))
								local checkDistance = tbNpc.attackNpcRadius or attackNpcRadius
								if distance < checkDistance then
									countFighting = countFighting + 1
									if (tbNpc2.children) then
										countFighting = countFighting + getn(tbNpc2.children)
									end
									self:_joinFight(nListId2, "caused by others "..distance.." ("..otherPosX.." "..otherPosY..") ("..myPosX.." "..myPosY..")")
								end
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
				self:_joinFight(nListId, "I start a fight")

			end


			if tbNpc.playerID == 0 and countFighting > 0 and worldInfo.showFightingArea == 1 then 
				Msg2Map(nW, "C„ "..countFighting.." nh©n s‹ Æang Æ∏nh nhau tπi "..worldInfo.name.." <color=yellow>"..floor(myPosX/8).." "..floor(myPosY/16).."<color>")
			end

			if (countFighting > 0) then
				return 1
			end
		end


	end
	

	-- Otherwise just walk peacefully
	if tbNpc.playerID == 0 then

		-- Mode 1: random
		if tbNpc.walkMode == "random" or tbNpc.walkMode == "keoxe" or (not tbNpc.children) then
			if self:_arrived(nNpcIndex, tbNpc) then
				-- Keep walking no stop
				if (tbNpc.noStop == 1 or random(1,100)<90) then
					nNextPosId = nNextPosId + 1

					-- End of the array
					if nNextPosId > WalkSize then
						if tbNpc.noBackward == 1 then
							return 1
						end

						tbNpc.tbPos = arrFlip(tbNpc.tbPos)
						nNextPosId = 1
						tbNpc.nPosId = nNextPosId

						self:_generateWalkPath(tbNpc)

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

			if tbNpc.isSpinning == 0 and self:_arrived(nNpcIndex, tbNpc) then
				-- Keep walking no stop
				if (tbNpc.noStop == 1 or random(1,100)<90) then
					
					nNextPosId = nNextPosId + 1

					-- End of the array
					if nNextPosId > WalkSize then
						if tbNpc.noBackward == 1 then
							return 1
						end
						local newFlipArr = {}
						for i=1,WalkSize do 		
							tinsert(newFlipArr, tbNpc.tbPos[WalkSize-i+1])
						end

						tbNpc.tbPos = newFlipArr
						self:_generateWalkPath(tbNpc)

						nNextPosId = 2
						tbNpc.nPosId = nNextPosId

						self:_generateWalkPath(tbNpc)

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
			elseif tbNpc.isSpinning == 1 and self:_arrived(nNpcIndex, tbNpc) then


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

		-- Otherwise keep walking
		local targetPos = tbNpc.walkPath[nNextPosId]
		local nX = targetPos[1]
		local nY = targetPos[2]
		if tbNpc.isSpinning == 1 then
			nX = targetPos[3]
			nY = targetPos[4]
		end

		NpcWalk(nNpcIndex, nX, nY)	

		self:_walk_children(tbNpc, nNextPosId)

	else

		-- Walk toward parent

		-- Player has gone different map? Do respawn
		local needRespawn = 0
		if tbNpc.nMapId ~= pW then
			needRespawn = 1

			-- Remove the list from this world
			self.npcByWorld["w"..tbNpc.nMapId]["n"..tbNpc.nNpcListIndex] = nil

		else

			if cachNguoiChoi > self.player_distance_respawn then
				needRespawn = 1
			end
		end

		if needRespawn == 1 then
			tbNpc.nMapId = pW
			tbNpc.isFighting = 0
			tbNpc.canSwitchTick = tbNpc.tick
			tbNpc.tbPos ={
				{pX, pY}
			}
			tbNpc.nPosId = 1
			self:_generateWalkPath(tbNpc)
			self:_respawn(tbNpc.nNpcListIndex, 1, "keo xe qua map khac")
			return 1
		end
		

		-- Otherwise walk toward parent
		NpcWalk(nNpcIndex, pX+random(-2,2), pY+random(-2,2))

		-- Walk children as 
		if tbNpc.children then 
			local N = getn(tbNpc.children)

			-- Exact param of parent is given
			for i=1,N do
				local child = tbNpc.children[i]
				if (child.finalIndex) then
					NpcWalk(child.finalIndex, pX+random(-2,2), pY+random(-2,2))
				end
			end
		end
	end
	return 1
end





function _sortByScore(tb1, tb2)
	return tb1[2] > tb2[2]
end

function GroupFighter:ThongBaoBXH(nW)
	
	-- Collect all data
	local allPlayers = {}
	for i,tbNpc in self.tbNpcList do
		if tbNpc.nMapId == nW then 
			tinsert(allPlayers, {
				i, tbNpc.fightingScore
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
			local tbNpc = self.tbNpcList[allPlayers[j][1]]
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

				local msg = "<color=white>"..j.." <color=yellow>["..phe.."] "..SimCityTongKim.RANKS[tbNpc.rank].." <color>"..(tbNpc.hardsetName or SimCityNPCInfo:getName(tbNpc.nNpcId)).."<color=white> ("..allPlayers[j][2]..")<color>"
				Msg2Map(nW, msg)
			end
		end
		Msg2Map(nW, "<color=yellow>=================================<color>")			
	end 


end