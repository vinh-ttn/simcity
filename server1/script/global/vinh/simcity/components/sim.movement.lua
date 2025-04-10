-- movement_behavior.lua
-- A module for different movement behaviors that can be used by various sim types

SimMovement = {}
SimMovement.KeoXe = {
    resetPos = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nW = tbNpc.nMapId
        local pW, pX, pY = CallPlayerFunction(simInstance:GetPlayer(nListId), GetWorldPos)
        local targetPos = randomRange({pX, pY }, tbNpc.walkVar or 2)
        tbNpc.parentAppointPos[1] = targetPos[1]
        tbNpc.parentAppointPos[2] = targetPos[2]
        return 1
    end,

    Move = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)

        local pW = 0
        local pX = 0
        local pY = 0

        local myPosX = floor(nX32 / 32)
        local myPosY = floor(nY32 / 32)

        local cachNguoiChoi = 0 

        local pID = simInstance:GetPlayer(nListId)
        
        if pID > 0 then
            tbNpc.notFoundPlayerTick = nil
            pW, pX, pY = CallPlayerFunction(pID, GetWorldPos)
            local isPlayerFighting = CallPlayerFunction(pID, GetFightState)

            if isPlayerFighting ~= tbNpc.isPlayerFighting then
                tbNpc.isPlayerFighting = isPlayerFighting
                if isPlayerFighting == 1 then
                    SetNpcCurCamp(tbNpc.finalIndex, tbNpc.camp)
                    SetNpcKind(tbNpc.finalIndex, tbNpc.kind or 4)
                else
                    SetNpcCurCamp(tbNpc.finalIndex, 0)
                    SetNpcKind(tbNpc.finalIndex, 0)
                end
            end


            cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)
        else
            if not tbNpc.notFoundPlayerTick then
                tbNpc.notFoundPlayerTick = tbNpc.tick_breath
            end

            -- Tu dong xoa sau 10 giay khi khong tim thay nguoi choi
            if tbNpc.tick_breath > tbNpc.notFoundPlayerTick + 10 then
                return simInstance:Remove(nListId)
            end
        end

        -- Is fighting? Do nothing except leave fight if possible
        if tbNpc.isFighting == 1 then
            -- Case 1: toi gio chuyen doi
            if tbNpc.tick_canswitch < tbNpc.tick_breath then
                return tbNpc.fightSys:LeaveFight(simInstance, tbNpc, 0, "toi gio thay doi trang thai")
            end

            -- Case 2: tu dong thoat danh khi khong con ai
            if tbNpc.fightSys:CanLeaveFight(simInstance, tbNpc) == 1 then
                tbNpc.fightSys:LeaveFight(simInstance, tbNpc, 0, "khong tim thay quai")
                return 1
            end

            -- Case 3: qua xa nguoi choi phai chay theo ngay
            if (cachNguoiChoi > DISTANCE_FOLLOW_PLAYER) then
                tbNpc.tick_canswitch = tbNpc.tick_breath - 1
                tbNpc.fightSys:LeaveFight(simInstance, tbNpc, 0, "chay theo nguoi choi")
            else
                return 1
            end
        end


        -- Binh thuong
        if (cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) then
            
            -- Case 1: someone around is fighting, we join
            if (tbNpc.CHANCE_ATTACK_NPC and random(0, tbNpc.CHANCE_ATTACK_NPC) <= 2) then
                if tbNpc.fightSys:TriggerFightWithNPC(simInstance, tbNpc) == 1 then
                    return 1
                end
            end

            -- Case 2: some player around is fighting and different camp, we join
            local myLife = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
            local maxLife = NPCINFO_GetNpcCurrentMaxLife(tbNpc.finalIndex)

            if ((tbNpc.CHANCE_ATTACK_PLAYER and random(0, tbNpc.CHANCE_ATTACK_PLAYER) <= 2) or (myLife < maxLife))
            then
                if tbNpc.fightSys:TriggerFightWithPlayer(simInstance, tbNpc) == 1 then
                    return 1
                end
            end
        end

        -- Mode 3: follow parent player
        -- Player has gone different map? Do respawn
        local needRespawn = 0
        if tbNpc.nMapId ~= pW then
            needRespawn = 1
        else
            if cachNguoiChoi > DISTANCE_FOLLOW_PLAYER_TOOFAR then
                needRespawn = 1
            end
        end

        if needRespawn == 1 then
            tbNpc.nMapId = pW
            tbNpc.isFighting = 0
            tbNpc.tick_canswitch = tbNpc.tick_breath
            tbNpc.parentAppointPos[1] = pX
            tbNpc.parentAppointPos[2] = pY
            tbNpc.entitySys:Respawn(simInstance, tbNpc, 2, "qua xa nguoi choi")
            return 1
        end


        -- Otherwise walk toward parent
        if tbNpc.isFighting == 0 then
            if cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER then
                if random(1,100) < 10 then 
                    NpcWalk(tbNpc.finalIndex, pX + random(-2, 2), pY + random(-2, 2)) 
                end
            else
                NpcWalk(tbNpc.finalIndex, pX + random(-2, 2), pY + random(-2, 2)) 
            end
        end
        return 1
    end
}

SimMovement.Citizen = {

    GetRandomWalkPoint = function(self, tbNpc, currentPosId)
        if not tbNpc.worldInfo or not tbNpc.worldInfo.walkGraph then
            return "none"
        end
        
        -- Handle preset walking mode
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths then
            if tbNpc.currentPathIndex and tbNpc.currentPointIndex then
                local path = tbNpc.worldInfo.walkPaths[tbNpc.currentPathIndex]
                if path then
                    local pathLength = getn(path)
                    if pathLength > 0 then
                        -- Move to next point based on direction
                        local nextIndex = tbNpc.currentPointIndex + tbNpc.pathDirection
                        
                        -- If reached the end of path, reverse direction
                        if nextIndex > pathLength then
                            tbNpc.pathDirection = -1
                            nextIndex = pathLength - 1
                        -- If reached the start of path when going backward, reverse direction
                        elseif nextIndex < 1 then
                            tbNpc.pathDirection = 1
                            nextIndex = 2
                        end
                        
                        tbNpc.currentPointIndex = nextIndex
                        return tbNpc.currentPointIndex
                    end
                end
            end
            
            -- Fallback if path data is not properly initialized
            return 1
        end

        -- If current position ID is provided, get next node from edges
        if currentPosId ~= nil then
            local edges = tbNpc.worldInfo.walkGraph.edges[currentPosId]
            if edges and getn(edges) > 0 then
                -- Count unvisited edges first
                local unvisitedCount = 0
                for i = 1, getn(edges) do
                    local edgeId = edges[i]
                    local isVisited = false
                    
                    -- Check if this edge was recently visited
                    for j = 1, getn(tbNpc.last2VisitedEdges) do
                        if tbNpc.last2VisitedEdges[j] == edgeId then
                            isVisited = true
                            break
                        end
                    end
                    
                    if not isVisited then
                        unvisitedCount = unvisitedCount + 1
                    end
                end
                
                -- Choose which selection method to use
                local selectedEdge
                if unvisitedCount > 0 then
                    -- Select from unvisited edges
                    local targetUnvisited = random(1, unvisitedCount)
                    local currentUnvisited = 0
                    
                    for i = 1, getn(edges) do
                        local edgeId = edges[i]
                        local isVisited = false
                        
                        -- Check if this edge was recently visited
                        for j = 1, getn(tbNpc.last2VisitedEdges) do
                            if tbNpc.last2VisitedEdges[j] == edgeId then
                                isVisited = true
                                break
                            end
                        end
                        
                        if not isVisited then
                            currentUnvisited = currentUnvisited + 1
                            if currentUnvisited == targetUnvisited then
                                selectedEdge = edgeId
                                break
                            end
                        end
                    end
                else
                    -- All edges were visited, just pick any edge
                    selectedEdge = edges[random(1, getn(edges))]
                end
                
                -- Update the last visited edges (keep only the last 2)
                tinsert(tbNpc.last2VisitedEdges, 1, selectedEdge)
                if getn(tbNpc.last2VisitedEdges) > 2 then
                    tremove(tbNpc.last2VisitedEdges, 3)
                end
                
                return selectedEdge
            end
        end
        
        -- Otherwise pick a random node
        local nodeCount = 0
        for id, _ in tbNpc.worldInfo.walkGraph.nodes do
            nodeCount = nodeCount + 1
        end
        if nodeCount == 0 then return nil end

        local targetIndex = random(1, nodeCount)
        local currentIndex = 0
        for id, _ in tbNpc.worldInfo.walkGraph.nodes do
            currentIndex = currentIndex + 1
            if currentIndex == targetIndex then
                return id
            end
        end
    end,

    resetPos = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nW = tbNpc.nMapId
 

        -- Preset path mode - choose a random position on the already chosen path
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths then
            if tbNpc.currentPathIndex then
                local path = tbNpc.worldInfo.walkPaths[tbNpc.currentPathIndex]
                if path and getn(path) > 0 then
                    -- Select a random position along the path
                    tbNpc.currentPointIndex = random(1, getn(path))
                    tbNpc.pathDirection = random(0, 1) == 0 and -1 or 1 -- random direction
                    tbNpc.nPosId = 1 -- Just set a value for compatibility
                    return 1
                end
            end
        end

        -- Startup position
        local walkPoint = self:GetRandomWalkPoint(tbNpc)
        if walkPoint == nil then
            return 0
        end
        
        tbNpc.nPosId = walkPoint
        
        return 1
    end,

    CalculateChildrenPosition = function(self, simInstance, nListId, X, Y)
        local tbNpc = simInstance.fighterList[nListId]
        if not tbNpc.children then
            return 1
        end
        local size = getn(tbNpc.children)
        if size == 0 then
            return 1
        end

        if tbNpc.walkMode and tbNpc.walkMode == "formation" then
            local centerCharId = getCenteredCell(createFormation(size))
            local fighter = simInstance:Get(tbNpc.children[centerCharId])

            if fighter and fighter.isDead == 1 then
                for i = 1, size do
                    fighter = simInstance:Get(tbNpc.children[i])
                    if fighter and fighter.isDead ~= 1 then
                        break
                    end
                end
            end

            if fighter and fighter.isDead ~= 1 then
                local nX, nY, nMapIndex = GetNpcPos(fighter.finalIndex)
                tbNpc.childrenPath = genCoords_squareshape({ nX / 32, nY / 32 }, { X, Y }, size)
            end
        else
            local childrenPath = {}
            for i = 1, size do
                tinsert(childrenPath, { X + random(-2, 2), Y + random(-2, 2) })
            end
            tbNpc.childrenPath = childrenPath
        end
    end,


    HasArrived = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nX32, nY32 = GetNpcPos(tbNpc.finalIndex)
        local oX = nX32 / 32;
        local oY = nY32 / 32;

        local nX
        local nY
        local checkDistance = DISTANCE_CAN_CONTINUE
 
        -- Handle preset path mode
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths and tbNpc.currentPathIndex then
            local path = tbNpc.worldInfo.walkPaths[tbNpc.currentPathIndex]
            if path and tbNpc.currentPointIndex and tbNpc.currentPointIndex <= getn(path) then
                nX = path[tbNpc.currentPointIndex][1]
                nY = path[tbNpc.currentPointIndex][2]
            else
                return 0
            end
        else
            local posIndex = tbNpc.nPosId
            if posIndex ~= nil then
                nX = tbNpc.worldInfo.walkGraph.nodes[posIndex][1]
                nY = tbNpc.worldInfo.walkGraph.nodes[posIndex][2]
            else
                return 0
            end
        end 

        local distance = GetDistanceRadius(nX, nY, oX, oY)

        if distance < checkDistance then
            return self:ChildrenArrived(simInstance, nListId)
        end
        return 0
    end,

    ChildrenArrived = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        if not tbNpc.children then
            return 1
        end
        local size = getn(tbNpc.children)
        if size == 0 then
            return 1
        end

        for i = 1, size do
            local child = simInstance:Get(tbNpc.children[i])
            if child.movementSys:HasArrived(simInstance, child.id) == 0 then
                return 0
            end
        end
        return 1
    end,

    -- Breath
    Move = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId] 

        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)

        local pW = 0
        local pX = 0
        local pY = 0

        local myPosX = floor(nX32 / 32)
        local myPosY = floor(nY32 / 32)        

        -- Is fighting? Do nothing except leave fight if possible
        if tbNpc.isFighting == 1 then
            -- Case 1: toi gio chuyen doi
            if tbNpc.tick_canswitch < tbNpc.tick_breath then
                return tbNpc.fightSys:LeaveFight(simInstance, tbNpc, 0, "toi gio thay doi trang thai")
            end

            -- Case 2: tu dong thoat danh khi khong con ai
            if tbNpc.fightSys:CanLeaveFight(simInstance, tbNpc) == 1 then
                return 1
            end
 
            return 1 
        end


        -- Binh thuong
        if (tbNpc.worldInfo.allowFighting == 1 and
            (tbNpc.isFighting == 0 and tbNpc.tick_canswitch < tbNpc.tick_breath)) then
            
            if (tbNpc.isDialogNpcAround == 0)then
                -- Case 1: someone around is fighting, we join
                if (tbNpc.CHANCE_ATTACK_NPC and random(0, tbNpc.CHANCE_ATTACK_NPC) <= 2) then
                    if tbNpc.fightSys:TriggerFightWithNPC(simInstance, tbNpc) == 1 then
                        return 1
                    end
                end

                -- Case 2: some player around is fighting and different camp, we join
                local myLife = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
                local maxLife = NPCINFO_GetNpcCurrentMaxLife(tbNpc.finalIndex)

                if ((tbNpc.CHANCE_ATTACK_PLAYER and random(0, tbNpc.CHANCE_ATTACK_PLAYER) <= 2) or (myLife and maxLife and myLife < maxLife))
                then
                    if tbNpc.fightSys:TriggerFightWithPlayer(simInstance, tbNpc) == 1 then
                        return 1
                    end
                end

                -- Case 3: I auto switch to fight  mode
                if (tbNpc.attackNpcChance and random(1, tbNpc.attackNpcChance) <= 2) then
                    -- CHo nhung dua chung quanh

                    local countFighting = tbNpc.fightSys:GetFightingNPCs(simInstance, tbNpc, myPosX, myPosY)

                    -- If someone is around or I am not crazy then I fight
                    if countFighting > 0 or tbNpc.attackNpcChance > 1 then
                        countFighting = countFighting + 1
                        tbNpc.fightSys:JoinFight(simInstance, tbNpc, "I start a fight")
                    end

                    if countFighting > 0 and tbNpc.worldInfo.showFightingArea == 1 then
                        Msg2Map(nW,
                            "C„ " .. countFighting .. " nh©n s‹ Æang Æ∏nh nhau tπi " .. tbNpc.worldInfo.name ..
                            " <color=yellow>" .. floor(myPosX / 8) .. " " .. floor(myPosY / 16) .. "<color>")
                    end

                    if (countFighting > 0) then
                        return 1
                    end
                end
            end

            
        end

        -- Khong phai dang keo xe 
        if tbNpc.tick_checklag and tbNpc.tick_breath > tbNpc.tick_checklag and tbNpc.isDialogNpcAround == 0 then
            tbNpc.entitySys:Respawn(simInstance, tbNpc, 4, "dang bi lag roi")
            return 1
        end

        -- Mode 1: randomwalk
        if self:HasArrived(simInstance, nListId) == 1 then
            -- Keep walking no stop
            local keepWalkingRate = 90
            if tbNpc.isDialogNpcAround > 0 then
                keepWalkingRate = 5
            end

            if (tbNpc.noStop == 1 or random(1, 100) < keepWalkingRate) then
                local nNextPosId = tbNpc.movementSys:GetRandomWalkPoint(tbNpc, tbNpc.nPosId)
                tbNpc.nPosId = nNextPosId 
            else
                return 1
            end


            tbNpc.tick_checklag = nil
        else
            if not tbNpc.tick_checklag then
                tbNpc.tick_checklag = tbNpc.tick_breath +
                    20 -- check again in 20s, if still at same position, respawn because this is stuck
            end
        end

        local targetPos
        
        -- Handle preset path walking
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths then
            if tbNpc.currentPathIndex and tbNpc.currentPointIndex then
                local path = tbNpc.worldInfo.walkPaths[tbNpc.currentPathIndex]
                if path and tbNpc.currentPointIndex <= getn(path) then
                    targetPos = path[tbNpc.currentPointIndex]
                end
            end
        else
            -- Default graph-based walking
            targetPos = tbNpc.worldInfo.walkGraph.nodes[tbNpc.nPosId]
        end

        if targetPos == nil then
            return 0
        end

        local nX = targetPos[1]
        local nY = targetPos[2]

        if targetPos[3] == 1 then
            NpcWalk(tbNpc.finalIndex, nX, nY)
        else
            NpcWalk(tbNpc.finalIndex, nX + random(-2, 2), nY + random(-2, 2))            
        end
        self:CalculateChildrenPosition(simInstance, nListId, nX, nY)
        
        return 1
    end
}


SimMovement.FormationChild = {
    GetRandomWalkPoint = function(self, tbNpc, currentPosId)
        return "none"
    end,

    resetPos = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nW = tbNpc.nMapId

        -- Dang di theo sau npc khac 
        local pW, pX, pY = self:GetParentPos(simInstance, nListId)
        local targetPos = randomRange({pX, pY }, tbNpc.walkVar or 2)
        tbNpc.parentAppointPos[1] = targetPos[1]
        tbNpc.parentAppointPos[2] = targetPos[2]
        return 1
        
    end,


    -- For child
    GiveChildPos = function(self, simInstance, nListId, i)
        local tbNpc = simInstance.fighterList[nListId]
        if tbNpc == nil then
            return 0, 0, 0
        end
        if tbNpc.childrenPath and getn(tbNpc.childrenPath) >= i then
            return tbNpc.nMapId, tbNpc.childrenPath[i][1], tbNpc.childrenPath[i][2]
        end
        return 0, 0, 0
    end,

    GetParentPos = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local foundParent = simInstance:Get(tbNpc.parentID)
        if foundParent then
            local nX32, nY32, nW32 = GetNpcPos(foundParent.finalIndex)
            local nW = SubWorldIdx2ID(nW32)
            return nW, nX32 / 32, nY32 / 32
        end

        return 0, 0, 0
    end,

    GetMyPosFromParent = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local foundParent = simInstance:Get(tbNpc.parentID)
        if foundParent then
            return self:GiveChildPos(simInstance, tbNpc.parentID, tbNpc.childID)
        end

        return 0, 0, 0
    end,

    HasArrived = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nX32, nY32 = GetNpcPos(tbNpc.finalIndex)
        local oX = nX32 / 32;
        local oY = nY32 / 32;

        local nX
        local nY
        local checkDistance = DISTANCE_CAN_CONTINUE

        nX = tbNpc.parentAppointPos and tbNpc.parentAppointPos[1] or 0
        nY = tbNpc.parentAppointPos and tbNpc.parentAppointPos[2] or 0

        if not nX or not nY or nX == 0 or nY == 0 then
            return 0
        end  

        local distance = GetDistanceRadius(nX, nY, oX, oY)
        if tbNpc and tbNpc.isDead == 1 then
            return 1
        end
        if distance < checkDistance then
            return 1
        end
        return 0
    end,
    
    -- Move
    Move = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)
    
        local pW = 0
        local pX = 0
        local pY = 0
    
        local myPosX = floor(nX32 / 32)
        local myPosY = floor(nY32 / 32)
    
        local cachNguoiChoi = 0
       
        pW, pX, pY = tbNpc.movementSys:GetParentPos(simInstance, nListId)
        cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)

        -- Is parent fighting? Join fight or keep fighting
        if tbNpc.fightSys:IsParentFighting(simInstance, tbNpc) == 1 and tbNpc.isFighting == 0 then
            return tbNpc.fightSys:JoinFight(simInstance, tbNpc, "parent dang danh nhau")
        end

        -- Am I fighting? Do nothing except leave fight if possible
        if tbNpc.isFighting == 1 then
            -- Case 1: toi gio chuyen doi
            if tbNpc.tick_canswitch < tbNpc.tick_breath then
                return tbNpc.fightSys:LeaveFight(simInstance, tbNpc, 0, "toi gio thay doi trang thai")
            end

            -- Case 2: tu dong thoat danh khi khong con ai
            if tbNpc.fightSys:CanLeaveFight(simInstance, tbNpc) == 1 then
                return 1
            end

            return 1
        end

        -- Mode 2: follow parent NPC
        -- Player has gone different map? Do respawn
        local needRespawn = 0
        pW, pX, pY = self:GetParentPos(simInstance, nListId)

        -- Parent pos available?
        if pW > 0 and pX > 0 and pY > 0 then
            if tbNpc.nMapId ~= pW then
                needRespawn = 1
            else
                if cachNguoiChoi > DISTANCE_FOLLOW_PLAYER_TOOFAR then
                    needRespawn = 1
                end
            end

            if needRespawn == 1 then
                tbNpc.nMapId = pW
                tbNpc.isFighting = 0
                tbNpc.tick_canswitch = tbNpc.tick_breath
                tbNpc.parentAppointPos[1] = pX
                tbNpc.parentAppointPos[2] = pY
                tbNpc.entitySys:Respawn(simInstance, tbNpc, 2, "qua xa nguoi choi")
                return 1
            end
        else
            return 1
        end


        -- Otherwise walk toward parent
        local targetW, targetX, targetY = self:GetMyPosFromParent(simInstance, nListId)

        -- Parent gave info?
        if targetW > 0 and targetX > 0 and targetY > 0 then
            tbNpc.parentAppointPos[1] = targetX
            tbNpc.parentAppointPos[2] = targetY
            NpcWalk(tbNpc.finalIndex, targetX, targetY)
        end
        return 1
    end
}

-- Helper function to create a movement behavior by name
function SimMovementSys(tbNpc)
    if tbNpc.role == "keoxe" then
        return SimMovement.KeoXe
    end
    if tbNpc.role == "child" then
        return SimMovement.FormationChild
    end
    return SimMovement.Citizen
end