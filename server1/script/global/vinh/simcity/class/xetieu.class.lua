Include("\\script\\misc\\eventsys\\type\\player.lua")
Include("\\script\\misc\\eventsys\\type\\map.lua")

IncludeLib("NPCINFO")
XeTieu = {}
XeTieu.tbNpcList = {}
XeTieu.ownerID2List = {}
XeTieu.counter = 1
XeTieu.PARAM_LIST_ID = 1
XeTieu.PARAM_CHILD_ID = 2
XeTieu.PARAM_PLAYER_ID = 3
XeTieu.PARAM_NPC_TYPE = 4
XeTieu.ATICK_TIME = 9	-- refresh rate


XeTieu.MAX_DIS = 5	-- start next position if within 3 points from destination
XeTieu.MAX_DIS_SPINNING = 2	-- when spinning make sure the check is tighter
XeTieu.SPINNING_WAIT_TIME = 0 -- wait time to correct position
XeTieu.CHAR_SPACING = 1	-- spacing between group characters


XeTieu.player_distance = 12 -- chay theo nguoi choi neu cach xa
XeTieu.player_fight_distance = 8 -- neu gan nguoi choi khoang cach 12 thi chuyen sang chien dau
XeTieu.player_distance_respawn = 30 -- neu qua xa nguoi choi vi chay nhanh thi phai bien hinh theo
XeTieu.player_vision = 15 -- qua 15 = phai respawn vi no se quay ve cho cu

function XeTieu:New(tbNpc)

	local result = {}
	local nW = tbNpc.nMapId
 	
 
	local id = tbNpc.nNpcId
	tbNpc.playerID = tbNpc.playerID or ""
	tbNpc.ownerID = tbNpc.ownerID or ""

 
	-- Not having valid children char?
	if tbNpc.children then
		local validChildren = {}
		for i=1,getn(tbNpc.children) do
			local child = tbNpc.children[i]
			child.rank = 1
			child.rebel = 0
			tinsert(validChildren, child) 
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
	tbNpc.hardsetPos = 1

	tbNpc.rebelActivated = tbNpc.rebelActivated or 0

	-- Setup walk paths	 
	if self:HardResetPos(tbNpc) == 0 then
		return 1
	end
  
  	-- Setup attacked location 
  	if tbNpc.underAttack and tbNpc.underAttack.types then 
		local attackLocations = {}
		local attackTypes = tbNpc.underAttack.types 
		for i=1,getn(attackTypes) do
			local nPoint = random(1, getn(tbNpc.tbPos))
			attackLocations["n"..nPoint] = attackTypes[i]
			print(nPoint .. " -> " .. attackTypes[i])
		end

		-- DEV 
		tbNpc.underAttack.locations = {n2 = 1, n5 = 1}
	end

	-- Add to store and create everyone on screen 
	local npcIndex = self:_addNpcGo(tbNpc, 1) 
	return npcIndex
end

function XeTieu:_randomNgoaiTrang(tbNpc, nNpcIndex)

	local newNgoaiTrang = SimCityNgoaiTrang:doRandom()

	tbNpc.nSettingsIdx = tbNpc.nSettingsIdx or newNgoaiTrang.nSettingsIdx
	tbNpc.nNewHelmType = tbNpc.nNewHelmType or newNgoaiTrang.nNewHelmType
	tbNpc.nNewArmorType = tbNpc.nNewArmorType or newNgoaiTrang.nNewArmorType
	tbNpc.nNewWeaponType = tbNpc.nNewWeaponType or newNgoaiTrang.nNewWeaponType
	tbNpc.nNewHorseType = tbNpc.nNewHorseType or newNgoaiTrang.nNewHorseType

	ChangeNpcFeature(nNpcIndex, 0, 0, tbNpc.nSettingsIdx, tbNpc.nNewHelmType, tbNpc.nNewArmorType, tbNpc.nNewWeaponType, tbNpc.nNewHorseType)


end

function XeTieu:_makeDiagonal(points)
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
    		if distance < 10 then
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
  

function XeTieu:_genFormation(N)
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
 



function XeTieu:_arrived(nNpcIndex, tbNpc)

	
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
			tbNpc.arriveTick = tbNpc.tick + 15	-- wait 15s for children to arrive
		end

		-- Day du children?
		if self:_arrived_children(tbNpc) == 1 then
			return 1
		end

		-- Qua thoi gian cho doi 
		if tbNpc.arriveTick < tbNpc.tick and tbNpc.isFighting ~= 1 then
			return 0
		end
	end

	return 0
end

  
function XeTieu:_addNpcGo(tbNpc, isNew, goX, goY)	

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

		if goX and goY and goX > 0 and goY > 0 then		
			tX = goX
			tY = goY
		end

		local name = tbNpc.szName or SimCityNPCInfo:getName(tbNpc.nNpcId)

	 


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
				self.ownerID2List[tbNpc.ownerID] = nNpcListIndex
 
				
				
				-- Otherwise choose side
				SetNpcCurCamp(nNpcIndex, tbNpc.camp)

				local nPosCount = getn(tbPos)
				if nPosCount >= 1 then
					SetNpcActiveRegion(nNpcIndex, 1)				
					tbNpc.nPosId = nPosId
				end
				if nPosCount >= 1 or tbNpc.nSkillId then	
					SetNpcParam(nNpcIndex, self.PARAM_LIST_ID, nNpcListIndex)
					SetNpcParam(nNpcIndex, self.PARAM_PLAYER_ID, SearchPlayer(tbNpc.playerID))
					SetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE, 3)
					SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\timer.lua")
					SetNpcTimer(nNpcIndex, self.ATICK_TIME)
					
				end

				-- Ngoai trang?
				if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) then
					self:_randomNgoaiTrang(tbNpc, nNpcIndex)
				end
				

				self:_addNpcGo_chilren(nNpcListIndex)


				-- Disable fighting?
				if (tbNpc.isFighting == 0) then
					SetNpcKind(nNpcIndex, tbNpc.kind or 4)
					self:_changeAI(tbNpc, 0)
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
				return nNpcListIndex
			end
		end

		return 0
	end
	return 0

end


function XeTieu:_respawnChild(nListId, childID, reason)
	local tbNpc = self.tbNpcList["n"..nListId] 
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
					nX32 = cX*32,
					nY32 = cY*32
				}
			else

				local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)

				-- Do calculation
				nX = nX/32
				nY = nY/32
				child.lastPos = {
					nX32 = (nX + random(-2,2))*32,
					nY32 = (nY + random(-2,2))*32
				}
			end

		 	self:_createChild(nListId, childID)
		end
	end
end


function XeTieu:_respawn(nListId, isAllDead, reason)

	--CallPlayerFunction(1, Msg2Player, "Respawn: "..reason)

	local tbNpc = self.tbNpcList["n"..nListId] 

	isAllDead = isAllDead or 0

	local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)

	-- Do calculation
	nX = nX/32
	nY = nY/32

	-- Next map
	if (isAllDead == 2) then
		nX = 0
		nY = 0
		tbNpc.nPosId = 1
		self:HardResetPos(tbNpc)

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
		for i=1,getn(tbNpc.children) do
			local child = tbNpc.children[i]
			
			if child.isDead ~= 1 then
				child.lastHP = NPCINFO_GetNpcCurrentLife(child.finalIndex)
			end

			if (isAllDead == 1) then
				child.lastHP = nil
			end
			

			if ((isAllDead == 1 and ((tbNpc.resetPosWhenRevive and tbNpc.resetPosWhenRevive >= 1) or (SearchPlayer(tbNpc.playerID) > 0))) or (isAllDead == 2)) then
				child.lastPos = nil

			-- Children bi lag
			elseif isAllDead == 3 then
				if child.isDead ~= 1 then 

					if child.walkPath ~= nil then 
						local targetPos = child.walkPath[tbNpc.nPosId]
						local cX = targetPos[1]
						local cY = targetPos[2]
						child.lastPos = {
							nX32 = cX*32,
							nY32 = cY*32
						}
					else
						child.lastPos = {
							nX32 = (nX + random(-2,2))*32,
							nY32 = (nY + random(-2,2))*32
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

	self.tbNpcList["n"..nListId] = tbNpc
	self:DelNpcSafe_children(nListId)

	-- Children bi lag
	if isAllDead == 3 then
		tbNpc.lastPos = nil
		self:_addNpcGo(tbNpc, 0)
	-- Binh thuong
	else
		self:_addNpcGo(tbNpc, 0, nX, nY)
	end

end

function XeTieu:_getNpcAroundNpcList(nNpcIndex, radius)
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
		for key, tbNpc in self.tbNpcList do
			if tbNpc.nNpcListIndex ~= myListId then 
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
	
	return allNpcs, nCount
end

function XeTieu:_isNpcEnemyAround(tbNpc, nNpcIndex, radius)

	local allNpcs = {}
	local nCount = 0

	if SearchPlayer(tbNpc.playerID) > 0 then
		allNpcs, nCount = CallPlayerFunction(SearchPlayer(tbNpc.playerID), GetAroundNpcList, radius)
		for i = 1, nCount do
			if IsNpcAttackable(allNpcs[i], tbNpc.targetCamp or nil, tbNpc.camp or nil) == 1 then
				return 1
			end
	    end   
	end

	allNpcs, nCount = self:_getNpcAroundNpcList(nNpcIndex, radius)
    for i = 1, nCount do
		if IsNpcAttackable(allNpcs[i], tbNpc.targetCamp or nil, tbNpc.camp or nil) == 1 then
			return 1
		end
    end   


    if tbNpc.children then
    	for j=1,getn(tbNpc.children) do
    		if (tbNpc.children[j] and tbNpc.children[j].finalIndex and tbNpc.children[j].finalIndex > 0 and tbNpc.children[j].isDead == 0) then
				local allNpcs, nCount = self:_getNpcAroundNpcList(tbNpc.children[j].finalIndex, radius)
				for i = 1, nCount do
					if IsNpcAttackable(allNpcs[i], tbNpc.targetCamp or nil, tbNpc.camp or nil) == 1 then
						return 1
					end
				end
			end
		end

	end

    return 0
end




function XeTieu:_isPlayerEnemyAround(nListId, nNpcIndex)

	local tbNpc = self.tbNpcList["n"..nListId]

	if not tbNpc then
		return 0
	end

    -- FIGHT other player
	if GetNpcAroundPlayerList then 
		local allNpcs, nCount = GetNpcAroundPlayerList(nNpcIndex, tbNpc.fightPlayerRadius or fightPlayerRadius)
	    for i = 1, nCount do
			if (allNpcs[i] ~= SearchPlayer(tbNpc.ownerID) and CallPlayerFunction(allNpcs[i], GetFightState) == 1 and CallPlayerFunction(allNpcs[i], GetCurCamp) ~= tbNpc.camp) and tbNpc.camp ~= 0 then
				return 1
			end
	    end  

		-- Check children
		if tbNpc.children then
	    	for j=1,getn(tbNpc.children) do
	    		if (tbNpc.children[j] and tbNpc.children[j].finalIndex and tbNpc.children[j].finalIndex > 0 and tbNpc.children[j].isDead == 0) then
					local allNpcs, nCount = GetNpcAroundPlayerList(tbNpc.children[j].finalIndex, tbNpc.fightPlayerRadius or fightPlayerRadius)
					for i = 1, nCount do
						if (allNpcs[i] ~= SearchPlayer(tbNpc.ownerID) and CallPlayerFunction(allNpcs[i], GetFightState) == 1 and CallPlayerFunction(allNpcs[i], GetCurCamp) ~= tbNpc.camp) and tbNpc.camp ~= 0 then
							return 1
						end
				    end  
				end
			end

		end
	end
	return 0
end



function XeTieu:_joinFight(nListId, reason)
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




function XeTieu:_joinFightCheck(nListId, nNpcIndex)

	local tbNpc = self.tbNpcList["n"..nListId]

	if not tbNpc then
		return 0
	end

	if (self:_isNpcEnemyAround(tbNpc, nNpcIndex, tbNpc.fightScanRadius or fightScanRadius) == 1) then	
		return self:_joinFight(nListId, "enemy around")
    end  
	return 0
end


function XeTieu:_joinFightPlayerCheck(nListId, nNpcIndex)

	local tbNpc = self.tbNpcList["n"..nListId]

	if not tbNpc then
		return 0
	end

    -- FIGHT other player
	if GetNpcAroundPlayerList then 
		if self:_isPlayerEnemyAround(nListId, nNpcIndex) == 1 then

			local nW = tbNpc.nMapId


			if SearchPlayer(tbNpc.playerID) == 0 then
				local name = GetNpcName(nNpcIndex)
				local lastPos = tbNpc.tbPos[tbNpc.nPosId]
				Msg2Map(tbNpc.nMapId, "<color=white>"..name.."<color> bﬁ t n c´ng tπi "..floor(lastPos[1]/8).." "..floor(lastPos[2]/16).."")
				
			end
			return self:_joinFight(nListId, "player around")
	    end 
	end

	return 0
end



	


function XeTieu:_leaveFight(nListId, isAllDead, reason)

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

function XeTieu:_leaveFightCheck(nListId, nNpcIndex)

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

 

function XeTieu:_generateWalkPath(tbNpc, hasJustBeenFlipped)

	-- Generate walkpath for myself
	-- & Repeat for children
	local WalkSize = getn(tbNpc.tbPos)	
	tbNpc.walkPath = {}
	

	local aliveChildren = {}
	if tbNpc.children then
		for j=1,getn(tbNpc.children) do
			if tbNpc.children[j].isDead ~= 1 then 
				tinsert(aliveChildren, j)
			end
		end
	end

	local childrenSize = getn(aliveChildren)
	if childrenSize > 0 then
		for j=1,childrenSize do
			tbNpc.children[aliveChildren[j]].walkPath = {}
		end
	end


	for i=1,WalkSize do
		local point = tbNpc.tbPos[i]
		-- Having children?
		if childrenSize > 0 then
			
			-- RANDOM walk for everyone?
			if tbNpc.walkMode == "random" or tbNpc.walkMode == "keoxe" then

				if hasJustBeenFlipped == 0 then
					tinsert(tbNpc.walkPath, self:_randomRange(point, tbNpc.walkVar or 2))
					
				else
					tinsert(tbNpc.walkPath, self:_randomRange(point, 0))
				end
				for j=1,childrenSize do

					if hasJustBeenFlipped == 0 then
						tinsert(tbNpc.children[aliveChildren[j]].walkPath, self:_randomRange(point, tbNpc.walkVar or 2))
					else
						tinsert(tbNpc.children[aliveChildren[j]].walkPath, self:_randomRange(point, 0))
					end
				end

			-- FORMATION walk?
			else


				-- For children				
				local formation = self:_genCoords_squareshape(tbNpc, childrenSize, i)				
				for j=1,childrenSize do
					tinsert(tbNpc.children[aliveChildren[j]].walkPath, formation[j])
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
			if hasJustBeenFlipped == 0 then
				tinsert(tbNpc.walkPath, self:_randomRange(point, tbNpc.walkVar or 2))
			else
				tinsert(tbNpc.walkPath, self:_randomRange(point, 0))
			end
		end

	end
end



function XeTieu:Get(nListId)
	return self.tbNpcList["n"..nListId]
end

 


function XeTieu:HardResetPos(tbNpc)

	local result = {}
	local nW = tbNpc.nMapId

	local mapData = tbNpc.mapData
	local walkAreas = {}

	local id = tbNpc.nNpcId
  
 	if mapData == nil then
	
		return 0
	end


 
	for i=1,getn(mapData) do
		local dataPoint = mapData[i]
		if (dataPoint[1] == nW) then
			if dataPoint[4] ~= nil then
				tbNpc.mapName = dataPoint[4]
			end
			tinsert(walkAreas, {dataPoint[2], dataPoint[3]})
		end
	end

	-- No path to walk?
	if getn(walkAreas) < 1 then 
		return 0
	end
 
	-- Init stats 
	tbNpc.isSpinning = 0
	tbNpc.lastOffSetAngle = 0  

	-- Startup position
	tbNpc.hardsetPos = tbNpc.hardsetPos or 1

	-- Setup walk paths
	tbNpc.tbPos = arrCopy(walkAreas)
	if tbNpc.walkMode ~= "random" and tbNpc.walkMode ~= "keoxe" and tbNpc.children then
		tbNpc.tbPos = self:_makeDiagonal(tbNpc.tbPos)
	end

 

	-- Calculate walk path for main + children
	self:_generateWalkPath(tbNpc, 0)

	-- Add to store and create everyone on screen 
	return tbNpc

end
 
function XeTieu:_randomRange(point, walkVar)
	if walkVar == 0 then
		return {point[1], point[2]}
	end
	return {point[1] +random(-walkVar,walkVar), point[2] +random(-walkVar,walkVar)}
end

 
function XeTieu:_genCoords_squareshape(tbNpc, N, targetPointer) 
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


function XeTieu:_transform(tbNpc, point, centrePoint, fromPos, toPos)
	
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

 
function XeTieu:Remove(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]
	if tbNpc then
		DelNpcSafe(tbNpc.finalIndex)
		self:DelNpcSafe_children(nListId)
		self.tbNpcList["n"..nListId] = nil
	

		local nOwnerIndex = SearchPlayer(tbNpc.ownerID)
		tbNpc.nState_town = nil
		KhoaTHP(nOwnerIndex, 0)
	end 
end


function XeTieu:_createChild(nListId, childID)
	local tbNpc = self.tbNpcList["n"..nListId]

	local pX, pY, pW = GetNpcPos(tbNpc.finalIndex)
	pX = pX/32
	pY = pY/32


	local child = tbNpc.children[childID]
	local targetPos = child.walkPath[tbNpc.nPosId]
	local nNpcIndex

	if not (child.isDead == 1 and tbNpc.noRevive == 1) then			
		
		if not child.szName then
			local id = child.nNpcId
 			child.szName = SimCityNPCInfo:getName(id)
			
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


		nNpcIndex = AddNpcEx(child.nNpcId, 95, child.series or random(0,4), pW, targetPos[1] * 32, targetPos[2] * 32, 1, child.szName, 0)

		if nNpcIndex > 0 then
			local kind = GetNpcKind(nNpcIndex)
			if kind ~= 0 then 
				DelNpcSafe(nNpcIndex)
			else

				-- Do magic on this NPC
				if (tbNpc.isFighting == 0) then
					SetNpcKind(nNpcIndex, child.kind or tbNpc.kind or 4)
				end

				-- Choose side
				local targetCamp = child.camp or tbNpc.camp
				SetNpcCurCamp(nNpcIndex, targetCamp)
				SetNpcActiveRegion(nNpcIndex, 1)

				
				-- Ngoai trang?
				if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) or (child.ngoaitrang and child.ngoaitrang == 1) then
					self:_randomNgoaiTrang(child, nNpcIndex)
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
									
				if child.rebel == 2 and tbNpc.rebelActivated == 2 then
					tbNpc.rebelActivated = 0
					SetNpcCurCamp(nNpcIndex, 5)
					child.isDead = 1
				else
					-- Set param to link to parent
					SetNpcParam(nNpcIndex, self.PARAM_LIST_ID, nListId)
					SetNpcParam(nNpcIndex, self.PARAM_CHILD_ID, childID)
					SetNpcParam(nNpcIndex, self.PARAM_PLAYER_ID, SearchPlayer(tbNpc.playerID))
					SetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE, 4)
					SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\timer.lua")
					SetNpcTimer(nNpcIndex, self.ATICK_TIME)
				end
				tbNpc.children[childID] = child				
			end
		end
	end
end
function XeTieu:_addNpcGo_chilren(nListId)	
	local tbNpc = self.tbNpcList["n"..nListId]
 

	local nMapIndex = SubWorldID2Idx(nW)

	if not tbNpc.children then 
		return
	end
 
	local N = getn(tbNpc.children)
	for i=1,N do
		self:_createChild(nListId, i)		
	end
 
end


function XeTieu:_changeAI(tbNpc, mode)
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

function XeTieu:_arrived_children(tbNpc)

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
				-- Qua thoi gian cho doi, keu con den ben canh 
				if tbNpc.arriveTick < tbNpc.tick and tbNpc.isFighting ~= 1 then
					self:_respawnChild(tbNpc.nNpcListIndex, i, "Too far for 15 seconds")
					return 0
				end
				return 0
			end

		end
	end
 

	return 1
	
end

 



function XeTieu:_walk_children(tbNpc, posIndex)
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


function XeTieu:DelNpcSafe_children(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]

	if not tbNpc then 
		return 1
	end

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

function XeTieu:OnNpcDeath(nNpcIndex, playerAttacker)	
 	local npcType = GetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE)
 	if (npcType == 3) then
 		self:ParentDead(nNpcIndex, playerAttacker)
 	else
		self:ChildrenDead(nNpcIndex, playerAttacker)
	end	

end

function XeTieu:ChildrenDead(childrenIndex, playerAttacker)	
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

		self:_check_full_death(nListId)
	end
end




function XeTieu:ParentDead(nNpcIndex, playerAttacker)	
	if nNpcIndex > 0 then
		local nListId = GetNpcParam(nNpcIndex, self.PARAM_LIST_ID)
		local tbNpc = self.tbNpcList["n"..nListId]	
		if not tbNpc then
			return
		end

		local foundAlive = 0
		if tbNpc.children then		
			for i=1,getn(tbNpc.children) do
				local child = tbNpc.children[i]
				if child.isDead ~= 1 and child.rebel == 0 then
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
				tbNpc.children[foundAlive].isDead =	1 
				SetNpcParam(tbNpc.finalIndex, self.PARAM_NPC_TYPE, 3)
				return 1
			else
				tbNpc.isDead = 1
				tbNpc.finalIndex = nil 
			end
		else
			tbNpc.isDead = 1
			tbNpc.finalIndex = nil 
		end
		self:_check_full_death(nListId)
	end
end

function XeTieu:FINISH(tbNpc, code, reason)
	-- code 0:failed 1:success
	tbNpc.finished = 1
	tbNpc.finishedReason = code
end

function XeTieu:_check_full_death(nListId)

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
						if child.isFighting == 1 and child.finalIndex and child.isDead ~= 1 and child.rebel == 0 then
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
		
	 	self:FINISH(tbNpc, 0, "allDead")
		
		Msg2Map(nW, "<color=white>"..tbNpc.szName.."<color> hoµn toµn bﬁ c≠Ìp tπi <color=green>"..tbNpc.mapName.." <color=yellow>"..floor(lastPos[1]/8).." "..floor(lastPos[2]/16).."<color>")
		

		-- No revive? Do nothing
		if tbNpc.noRevive == 1 then
			DelNpcSafe(tbNpc.finalIndex)
			self:DelNpcSafe_children(nListId)
			return
		end


    
    	tbNpc.fightingScore = ceil(tbNpc.fightingScore*0.7)
 
		-- Do revive? Reset and leave fight
		self:_leaveFight(nListId, 1, "die toan bo")
	end
end


function XeTieu:ATick(nNpcIndex)
	local npcType = GetNpcParam(nNpcIndex, self.PARAM_NPC_TYPE)
	
	-- Parent
	if (npcType == 3) then
		return self:ParentTick(nNpcIndex)
	else
		return self:ChildrenTick(nNpcIndex)
	end
end

function XeTieu:ChildrenTick(childrenIndex)

	if childrenIndex > 0 then

		local nListId = GetNpcParam(childrenIndex, self.PARAM_LIST_ID)
		local childID = GetNpcParam(childrenIndex, self.PARAM_CHILD_ID)
		local tbNpc = self.tbNpcList["n"..nListId]

		if not tbNpc then
			return 1
		end

		if (tbNpc.finished == 1) then
			return 0
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
			if SearchPlayer(tbNpc.playerID) == 0 then
				if child.isDead == 0 and tbNpc.isDead == 0 then
					local pX32, pY32, pW32 = GetNpcPos(tbNpc.finalIndex)
					local nX32, nY32, nW32 = GetNpcPos(child.finalIndex)

					-- Too far from each other
					if GetDistanceRadius(nX32/32,nY32/32, pX32/32, pY32/32) > 30 then
						if (not tbNpc.tooFarStick) then
							tbNpc.tooFarStick = tbNpc.tick + 10
						elseif tbNpc.tooFarStick < tbNpc.tick then
							tbNpc.tooFarStick = nil
							self:_respawnChild(nListId, childID, "Too far for 10 seconds")
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


function XeTieu:ParentTick(nNpcIndex)
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
		self:moveParent(nListId)

		if tbNpc.isDead == 1 then
			return 0
		end
		self:CheckOwnerPos(nListId)

		return 1

	end
	return 1
end


function XeTieu:CheckOwnerPos(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]
	local nOwnerIndex = SearchPlayer(tbNpc.ownerID)
	if not (nOwnerIndex > 0) then
		return not self:OwnerFarAway(nListId)
	end
	
	local nOwnerX32, nOwnerY32, nOwnerMapIndex = CallPlayerFunction(nOwnerIndex, GetPos)
	if not nOwnerX32 then
		return not self:OwnerFarAway(nListId)
	end
	
	local nSelfX32, nSelfY32, nSelfMapIndex = GetNpcPos(tbNpc.finalIndex)
	local nDis = ((nOwnerX32 - nSelfX32)^2) + ((nOwnerY32 - nSelfY32)^2)
	if nOwnerMapIndex ~= nSelfMapIndex or nDis >= 750*750 then
		return not self:OwnerFarAway(nListId)
	end
	
	self:OwnerNear(nListId, nOwnerIndex, nOwnerX32/32, nOwnerY32/32)
end

function XeTieu:OwnerNear(nListId, nOwnerIndex, nX, nY)
	local tbNpc = self.tbNpcList["n"..nListId]
	local nOwnerIndex = SearchPlayer(tbNpc.ownerID)
	CallPlayerFunction(nOwnerIndex, SetFightState, 1)
	if not tbNpc.bOwnerHere then
 		self:OnOwnerEnter(nListId)
		tbNpc.bOwnerHere = 1
	end
end


function XeTieu:OnOwnerEnter(nListId)

	local tbNpc = self.tbNpcList["n"..nListId]
	local nOwnerIndex = SearchPlayer(tbNpc.ownerID)

	-- Save current state then lock 
	tbNpc.nState_town = CallPlayerFunction(nOwnerIndex, IsDisabledUseTownP)
	KhoaTHP(nOwnerIndex, 1)

end


function XeTieu:OwnerFarAway(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]

	if tbNpc.bOwnerHere then
		tbNpc.bOwnerHere = nil
		self:OnOwnerLeave(nListId)
	--else
		--if GetCurServerTime() - tbNpc.nPlayerLeaveTime >= 5 * 60 then
		--	local _, _, nMapIndex = GetNpcPos(self.nNpcIndex)
		--	-- do someting when owner leave for 5 minutes here
		--	return 1
		--end
	end
end

function XeTieu:OnOwnerLeave(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]
	local nOwnerIndex = SearchPlayer(tbNpc.ownerID)

	local nCurTime = GetCurServerTime()
	tbNpc.nPlayerLeaveTime = nCurTime
	if nOwnerIndex > 0 then 
		if tbNpc.nState_town ~= nil then
			KhoaTHP(nOwnerIndex, tbNpc.nState_town)
			tbNpc.nState_town = nil
		end
	end
end



function XeTieu:moveParent(nListId)
	local tbNpc = self.tbNpcList["n"..nListId]

	local nNpcIndex = tbNpc.finalIndex

	if (tbNpc.finished == 1) then
		return 0
	end

	local nX32, nY32, nW32 = GetNpcPos(nNpcIndex)
	local nW = SubWorldIdx2ID(nW32)
 


	local pW = 0
	local pX = 0
	local pY = 0

	
	local myPosX = floor(nX32/32)
	local myPosY = floor(nY32/32)

	local cachNguoiChoi = 0	

 	-- Waiting for parent action
	if tbNpc.underAttack.isConfirmation ~= 0 then
		return 1
	end
	
	-- Is fighting? Do nothing except leave fight if possible
	if tbNpc.isFighting == 1 then

		-- Case 1: toi gio chuyen doi 
		if tbNpc.canSwitchTick < tbNpc.tick then
			return self:_leaveFight(nListId, 0, "toi gio thay  doi trang thai")
		end

		-- Case 2: tu dong thoat danh khi khong con ai
		if self:_leaveFightCheck(nListId, nNpcIndex) == 1 then
			--self:_leaveFight(nListId, 0, "khong tim thay quai")
			return 1
		end

		-- Case 3: qua xa nguoi choi phai chay theo ngay
		if (SearchPlayer(tbNpc.playerID) > 0 and  cachNguoiChoi > self.player_distance) then
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
	if SearchPlayer(tbNpc.playerID) == 0 and (nNextPosId == 0 or WalkSize < 2) then
		return 0
	end

	if ((SearchPlayer(tbNpc.playerID) > 0 and cachNguoiChoi <= self.player_fight_distance) or SearchPlayer(tbNpc.playerID) == 0) 
		and (tbNpc.isFighting == 0 and tbNpc.canSwitchTick < tbNpc.tick) 
	then

		-- Case 1: someone around is fighting, we join		
		if (tbNpc.rebelActivated == 1 and random(0, tbNpc.underAttack.rebelChance) <= 2) then -- 1% bi tan cong moi giay
			tbNpc.rebelActivated = 2

			if tbNpc.bOwnerHere == 1 then
				CallPlayerFunction(SearchPlayer(tbNpc.ownerID), Talk, 1, "", "...!!! Ph∏t hi÷n Æπo t∆c trµ trÈn!")
			end
			self:_joinFight(nListId, "fight rebel")
			return 1
		end
		

		

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
		if (SearchPlayer(tbNpc.playerID) == 0 and tbNpc.attackNpcChance and random(1,tbNpc.attackNpcChance) <= 2) then			
			-- CHo nhung dua chung quanh 
			
			local countFighting = 0
			for key, tbNpc2 in self.tbNpcList do

				-- Myself = I start 
				if tbNpc2.nNpcListIndex ~= nListId then 
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
			 

			-- If someone is around or I am not crazy then I fight
			if countFighting > 0 or tbNpc.attackNpcChance > 1 then
				countFighting = countFighting + 1
				if (tbNpc.children) then
					countFighting = countFighting + getn(tbNpc.children)
				end
				self:_joinFight(nListId, "I start a fight")

			end


			if SearchPlayer(tbNpc.playerID) == 0 and countFighting > 0 then 
				Msg2Map(nW, "C„ "..countFighting.." Æang Æ∏nh nhau tπi <color=yellow>"..floor(myPosX/8).." "..floor(myPosY/16).."<color>")
			end

			if (countFighting > 0) then
				return 1
			end
		end


	end


	local arriveRes = self:_arrived(nNpcIndex, tbNpc)
	-- Mode 1: random
	if tbNpc.walkMode == "random" or tbNpc.walkMode == "keoxe" or (not tbNpc.children) then
		if  arriveRes == 1 then
			-- Keep walking no stop
			if (tbNpc.noStop == 1 or random(1,100)<90) then
				nNextPosId = nNextPosId + 1

				-- End of the array
				if nNextPosId > WalkSize then
					if tbNpc.noBackward == 1 then
						self:NextMap(tbNpc)
						return 1
					end

					tbNpc.tbPos = arrFlip(tbNpc.tbPos)
					nNextPosId = 1
					tbNpc.nPosId = nNextPosId

					self:_generateWalkPath(tbNpc, 1)

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
		-- Da toi noi, tiep tuc di
		if (arriveRes == 1) then
			if tbNpc.isSpinning == 0 then
				-- Keep walking no stop
				if (tbNpc.noStop == 1 or random(1,100)<90) then
					
					nNextPosId = nNextPosId + 1

					-- End of the array
					if nNextPosId > WalkSize then
						if tbNpc.noBackward == 1 then
							self:NextMap(tbNpc)
							return 1
						end
						local newFlipArr = {}
						for i=1,WalkSize do 		
							tinsert(newFlipArr, tbNpc.tbPos[WalkSize-i+1])
						end

						tbNpc.tbPos = newFlipArr
						self:_generateWalkPath(tbNpc, 1)

						nNextPosId = 2
						tbNpc.nPosId = nNextPosId

						self:_generateWalkPath(tbNpc, 1)

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

	self:spawnAttack(tbNpc, nNextPosId)

	NpcWalk(nNpcIndex, nX, nY)	

	if mod(tbNpc.tick, 10) == 0 then
		CallPlayerFunction(SearchPlayer(tbNpc.ownerID), Msg2Player, "T‰a ÆÈ hi÷n tπi cÒa xe ti™u lµ <color=green>"..tbNpc.mapName.." <color=yellow>"..floor(nX/8)..","..floor(nY/16))
	end

	self:_walk_children(tbNpc, nNextPosId)

	return 1
end


function XeTieu:spawnAttack(tbNpc, nNextPosId)
	-- By locations
	if tbNpc.underAttack and tbNpc.underAttack.locations and tbNpc.underAttack.locations["n"..nNextPosId] then
		self:triggerUnderAttack(tbNpc, tbNpc.underAttack.locations["n"..nNextPosId])
		tbNpc.underAttack.locations["n"..nNextPosId] = nil
	end
end

function XeTieu:triggerUnderAttack(tbNpc, attackType)
	tbNpc.underAttack.isConfirmation = attackType

	-- 0: theo sau choi 1: theo sau va cuop 2: cuop truc tiep
	local tbSay = {}
	if attackType == 0 or attackType == 1 then
		tinsert(tbSay, "(Nh„m ng≠Íi lπ)\n\n\nCÚng lµ bÃo n≠Ìc g∆p nhau n¨i nguy hi”m nµy. ¢u cÚng lµ duy™n phÀn, xin cho chÛng ta cÔng theo c∏c hπ!")
		CallPlayerFunction(SearchPlayer(tbNpc.ownerID), Msg2Player, "C„ 1 vµi nh©n vÀt kh∂ nghi Æang Æi theo chÛng ta")
	end

	if attackType == 2 then
		tinsert(tbSay, "(Nh„m ng≠Íi lπ)\n\n\nß≠Íng nµy do ta mÎ! Ai cho c∏c ng≠¨i vµo?")
	end

	if attackType == 3 then
		tinsert(tbSay, "...\n\n\nXung quanh Æ©y thÀt kh∂ nghi...")
	end
	
	tinsert(tbSay, "K’t thÛc ÆËi thoπi/#XeTieu:confirmAttack("..tbNpc.nNpcListIndex ..")") 

	if tbNpc.bOwnerHere == 1 then
		CallPlayerFunction(SearchPlayer(tbNpc.ownerID), CreateTaskSay, tbSay)
	end
end

function XeTieu:confirmAttack(nListId)
	local tbNpc = self.tbNpcList["n"..nListId] 

	if not tbNpc then
		return 1
	end

	local attackType = tbNpc.underAttack.isConfirmation
	tbNpc.underAttack.isConfirmation = 0

	-- Add attackers?
	if attackType == 0 or attackType == 1 or attackType == 2 then
		local attackers = {}
		local totalN = random(1,6)
		local pool = tbNpc.underAttack.attackerIds
		local current = getn(tbNpc.children)
		local tobeCreated = {}
		for i=1,totalN do
			local attacker = {}
			attacker.szName = SimCityPlayerName:getName()
			attacker.rebel = attackType + 1
			if attackType == 0 then
				attacker.nNpcId = 682
			else
				attacker.nNpcId = pool[random(1,getn(pool))]
			end
			attacker.ngoaitrang = 1
			tinsert(tbNpc.children, attacker)
			current = current + 1
			tinsert(tobeCreated, current)			
		end

		-- Has attacker enabled
		if attackType == 1 then
			tbNpc.rebelActivated = 1 -- fight randomly
		end
		if attackType == 2 then
			tbNpc.rebelActivated = 2 -- fight instantly			
		end

		-- Reset pos
		self:HardResetPos(tbNpc)
		--tbNpc.nPosId = tbNpc.nPosId - 1

		-- Create new char
		for i=1,getn(tobeCreated) do
			self:_respawnChild(nListId, tobeCreated[i], "them nhan vat theo sau")
		end
	end
  
	print("TRIGGER ATTACK: "..attackType)
end

function XeTieu:NextMap(tbNpc)

	local pW = 0
	local found = 0
	local mapData = tbNpc.mapData
	for i=1,getn(mapData) do
		local dataPoint = mapData[i]
		if (dataPoint[1] == tbNpc.nMapId) then
			found = 1
		end
		if (found == 1 and pW == 0 and dataPoint[1] ~= tbNpc.nMapId) then
			pW = dataPoint[1]
		end
	end

	if pW == 0 then
	 	self:FINISH(tbNpc, 1, "success")
		CallPlayerFunction(SearchPlayer(tbNpc.ownerID), Msg2Player, "Ti™u xa Æ∑ Æ’n Æ›ch")
		return 1
	end

	-- Player has gone different map? Do respawn
	local needRespawn = 1
 

	
	tbNpc.nMapId = pW
	tbNpc.isFighting = 0
	tbNpc.canSwitchTick = tbNpc.tick
 	CallPlayerFunction(SearchPlayer(tbNpc.ownerID), Msg2Player, "Ti™u xa Æ∑ chuy”n qua map")
	self:_respawn(tbNpc.nNpcListIndex, 2, "keo xe qua map khac")
	return 1
	

	
end

function XeTieu:OnPlayerLeaveMap()
	local szName = GetName()
	if not szName then
		return
	end
	local nNpcListIndex = self.ownerID2List[szName]
	if nNpcListIndex > 0 then
		self:OwnerFarAway(nNpcListIndex)
	end
end


EventSys:GetType("LeaveMap"):Reg("ALL", XeTieu.OnPlayerLeaveMap, XeTieu)
--EventSys:GetType("EnterMap"):Reg("ALL", XeTieu.OnPlayerEnterMap, XeTieu)