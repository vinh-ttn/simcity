-- movement_behavior.lua
-- A module for different movement behaviors that can be used by various sim types

function IsActive(self, simInstance,tbNpc)

    if not tbNpc.finalIndex or tbNpc.finalIndex == 0 then 
        tbNpc.isActive = 1
        return 1
    end

    -- Track player around
    tbNpc.isPlayerEnemyAround = 0
    local scanFightRadius = tbNpc.RADIUS_FIGHT_PLAYER or RADIUS_FIGHT_PLAYER

    if GetNpcAroundPlayerList then
        local allNpcs, nCount = GetNpcAroundPlayerList(tbNpc.finalIndex, 32)
        for i = 1, nCount do
            local pID = allNpcs[i]
            local camp = CallPlayerFunction(pID, GetCurCamp)
            local pW, pX, pY = CallPlayerFunction(pID, GetWorldPos)

            if tbNpc.worldInfo then
                if tbNpc.worldInfo.playerTracker[pID] and tbNpc.worldInfo.playerTracker[pID][1] ~= pX and tbNpc.worldInfo.playerTracker[pID][2] ~= pY then
                    tbNpc.worldInfo.playerTracker[pID] = {pX, pY, camp}
                end

                if not tbNpc.worldInfo.playerTracker[pID] then
                    tbNpc.worldInfo.playerTracker[pID] = {pX, pY, camp}
                    tbNpc.worldInfo.playerTrackerCount = tbNpc.worldInfo.playerTrackerCount + 1
                end
            end

            -- Is this player an enemy?
            if tbNpc.lastPos 
                and tbNpc.camp ~= 0
                and IsAttackableCamp(camp, tbNpc.camp) == 1
                and GetDistanceRadius(tbNpc.lastPos.nX32/32, tbNpc.lastPos.nY32/32, pX, pY) <= scanFightRadius
                and CallPlayerFunction(pID, GetFightState) == 1 
                 then
                tbNpc.isPlayerEnemyAround = pID
            end
        end

        if nCount == 0 then
            tbNpc.isActive = 0
            return 0
        end

        tbNpc.isActive = 1
        return 1
    end

    -- No player around
    tbNpc.isActive = 0
    return 0
end

SimMovement = {}
SimMovement.KeoXe = {
    IsActive = IsActive,

    resetPos = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nW = tbNpc.nMapId
        local pW, pX, pY = CallPlayerFunction(simInstance:GetPlayer(nListId), GetWorldPos)

        if pX and pY then
            local targetPos = randomRange({pX, pY }, tbNpc.walkVar or 2)
            tbNpc.parentAppointPos[1] = targetPos[1]
            tbNpc.parentAppointPos[2] = targetPos[2]
        elseif tbNpc.lastPos then
            local targetPos = randomRange({tbNpc.lastPos.nX32/32, tbNpc.lastPos.nY32/32 }, tbNpc.walkVar or 2)
            tbNpc.parentAppointPos[1] = targetPos[1]
            tbNpc.parentAppointPos[2] = targetPos[2]
        end
        return 1
    end,

    Move = function(self, simInstance, tbNpc)
        local nListId = tbNpc.id
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

                if tbNpc.mode ~= "tieuthiep" then
                    if isPlayerFighting == 1 then
                        SetNpcKind(tbNpc.finalIndex, tbNpc.kind or 4)
                    else
                        SetNpcKind(tbNpc.finalIndex, 0)
                    end
                end
            end

            cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)

            if (cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) then
                tbNpc.fightSys:execCastOnParent(simInstance, tbNpc, pID, pX, pY)
            end                       

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
            if (tbNpc.CHANCE_JOIN_FIGHT and random(0, tbNpc.CHANCE_JOIN_FIGHT) <= 2) then
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
                if random(1,100) < 5 then 
                    local targetPos = randomRange({pX, pY}, tbNpc.walkVar or 2)
                    NpcWalk(tbNpc.finalIndex, targetPos[1], targetPos[2]) 
                end
            else
                local targetPos = randomRange({pX, pY}, tbNpc.walkVar or 2)
                NpcWalk(tbNpc.finalIndex, targetPos[1], targetPos[2]) 
            end
        end
        return 1
    end
}
SimMovement.KeoXe.MoveInactive = SimMovement.KeoXe.Move

SimMovement.Citizen = {

    IsActive = IsActive,
    NextPathSegment = function(self, simInstance, tbNpc)
        -- Check if we have valid path names
        if not tbNpc.walkPathNames or not tbNpc.worldInfo or not tbNpc.worldInfo.presetPaths then
            return 0
        end

        -- Check if we have more segments to process
        if getn(tbNpc.walkPathNames) > tbNpc.pathSegment then
            local nextPath = tbNpc.walkPathNames[tbNpc.pathSegment + 1]
            
            -- Validate next path exists
            if not nextPath or not nextPath[1] or not nextPath[2] then
                return 0
            end
            
            local nextPathIndex = nextPath[1]
            local nextPathDirection = nextPath[2]

            -- Validate the path exists in worldInfo
            local path = tbNpc.worldInfo.presetPaths[nextPathIndex]
            if not path then
                return 0
            end
            
            local pathLength = getn(path)
            if pathLength < 1 then
                return 0
            end

            local nextPointIndex
            if nextPathDirection == 1 then
                nextPointIndex = 1
            else               
                nextPointIndex = pathLength
            end

            -- Find next node name
            local nextNodeName = path[nextPointIndex] 

            -- Get current node name from current position
            local currentPath = tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex]
            local currentNodeName = currentPath[tbNpc.currentPointIndex]
            local nodes = {}
            for k,v in tbNpc.worldInfo.nodes do
                if v.nodeType == 1 then
                    nodes[k] = {v.x, v.y, v.linkedNodes}
                end
            end
 
            -- If current node name doesn't exist in walk graph, find closest node
            if not nodes[currentNodeName] then
                local nX32, nY32, _ = GetNpcPos(tbNpc.nNpcIndex)
                local nX = floor(nX32 / 32)
                local nY = floor(nY32 / 32)
                local closestNode = getClosestNode(nodes, nX, nY)
                if closestNode ~= nil then
                    currentNodeName = closestNode
                end
            end

            
            -- Check if we have a valid walk graph
            if nodes[currentNodeName] and nodes[currentNodeName][3] then               
                local edges = nodes[currentNodeName][3]    
                -- Check if there's a direct edge between current and next node
                local hasDirectEdge = 0            
                for i=1, getn(edges) do
                    local edge = edges[i]
                    if edge == nextNodeName then
                        hasDirectEdge = 1
                        break
                    end
                end

                -- Not found edge, need to find path to next node 
                if hasDirectEdge == 0 
                    and currentNodeName ~= nextNodeName 
                    and nodes[nextNodeName] and nodes[nextNodeName][3]
                    then
                    
                    -- No direct edge, need to find path to next node 
                    --print("NEXT PATH", currentNodeName, nextNodeName)
                    local paths = SimCityGraphToChienTranh:find_all_paths(nodes, currentNodeName, nextNodeName, 0)
                    --print("FOUND PATHS 2", getn(paths))
                    if paths and getn(paths) > 0 then
                        -- Take first found path and set current point to first node
                        -- Loop through all found paths to find first matching one
                        for i = 1, getn(paths) do
                            local firstPath = paths[i]                             
                            if getn(firstPath) > 1 then
                                -- Get coordinates for first node in path
                                local firstNodeCoords = nodes[firstPath[2]]
                                -- Find closest point in current path to first node coords
                                local closestDist = 999999
                                local closestIndex = 1
                                for i = 1, getn(currentPath) do
                                    local dist = GetDistanceRadius(
                                        nodes[currentPath[i]][1], nodes[currentPath[i]][2], 
                                        firstNodeCoords[1], firstNodeCoords[2])
                                    if dist < closestDist then
                                        closestDist = dist
                                        closestIndex = i
                                    end
                                end
                                if (closestDist > 0 and closestIndex ~= tbNpc.currentPointIndex) then
                                    tbNpc.currentPointIndex = closestIndex
                                    return 0
                                end
                            end
                        end
                    end
                end
            end

            

            -- Update path indices
            tbNpc.currentPathIndex = nextPathIndex
            tbNpc.pathDirection = nextPathDirection
            tbNpc.pathSegment = tbNpc.pathSegment + 1
            tbNpc.currentPointIndex = nextPointIndex
            tbNpc.pathStart = nil
            tbNpc.pathEnd = nil 

            local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
            local nX = floor(nX32 / 32)
            local nY = floor(nY32 / 32)

            -- Handle children if they exist
            if tbNpc.children then
                for i = 1, getn(tbNpc.children) do
                    local child = simInstance:Get(tbNpc.children[i])
                    if child then
                        child.currentPathIndex = tbNpc.currentPathIndex
                        child.pathDirection = tbNpc.pathDirection
                        child.currentPointIndex = tbNpc.currentPointIndex
                        child.pathStart = nil
                        child.pathEnd = nil
                    end
                end
            end

            return 1
        end
        return 0
    end,

    GetRandomWalkPoint = function(self, simInstance, tbNpc, currentPosId)
        if not tbNpc.worldInfo or not tbNpc.worldInfo.nodes then
            return "none"
        end
        
        -- Handle preset walking mode
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.presetPaths then
            if tbNpc.currentPathIndex and tbNpc.currentPointIndex then
                local path = tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex]
                if path then
                    local pathLength = getn(path)


                    -- Van con thoi gian o lai trong spawn
                    if (tbNpc.tick_breath < tbNpc.tick_canWalk and tbNpc.tongkim == 1) or tbNpc.baoDanhTongKim then
                        
                        -- If we have walk graph edges, use them to pick next point
                        local nodes = tbNpc.worldInfo.nodes

                        if nodes then
                            -- Get current node ID from path point
                            local currentPoint = path[tbNpc.currentPointIndex]
                            if nodes[currentPoint] then
                                local currentX = nodes[currentPoint].x
                                local currentY = nodes[currentPoint].y
                                
                                -- Find matching node in walk graph
                                local edges = nodes[currentPoint] and nodes[currentPoint].linkedNodes or {}
                                if edges and getn(edges) > 0 then
                                    -- Pick random edge                                
                                    local nextNode = edges[random(1, getn(edges))]

                                    -- Find matching point in path
                                    local nextCoords = nodes[nextNode]
                                    for i = 1, pathLength do
                                        local pathPoint = path[i]
                                        if nodes[pathPoint].x == nextCoords.x and nodes[pathPoint].y == nextCoords.y then
                                            tbNpc.currentPointIndex = i
                                            return pathPoint
                                        end
                                    end
                                end
                            end
                        
                        end

                        -- Up to here mean no node found, so we just random a point
                        tbNpc.currentPointIndex = random(1, pathLength)                        
                        return path[tbNpc.currentPointIndex]


                    -- Can move as usual
                    elseif tbNpc.tick_breath > tbNpc.tick_canWalk then

                        -- Trong mode tong kim ma dang o nha thi di tiep
                        if tbNpc.tongkim == 1 
                            and tbNpc.pathDirection == 0 then
                            self:NextPathSegment(simInstance, tbNpc) 
                            return path[tbNpc.currentPointIndex]
                        end


                        if pathLength > 0 then
                            -- Move to next point based on direction
                            local nextIndex = tbNpc.currentPointIndex + tbNpc.pathDirection
                            
                            -- If reached the end of path, reverse direction
                            if nextIndex > pathLength or (tbNpc.pathEnd and nextIndex > tbNpc.pathEnd) then
                                -- Khi chien dau den cuoi duong thi random lai
                                if tbNpc.mode == "chiendau" then

                                    -- Chuyen sang duong tiep theo hoac het duong thi gioi han lai duong di va chi di nguoc 10 diem
                                    if self:NextPathSegment(simInstance, tbNpc) == 0 then
                                        if not tbNpc.pathStart then
                                            if pathLength > 10 then 
                                                tbNpc.pathStart = pathLength - 10 
                                            else 
                                                tbNpc.pathStart = 1 
                                            end
                                            tbNpc.pathEnd = pathLength
                                        end
                                        tbNpc.pathDirection = -1
                                        nextIndex = tbNpc.pathEnd - 1
                                    else
                                        nextIndex = tbNpc.currentPointIndex
                                    end

                                else
                                    tbNpc.pathDirection = -1
                                    nextIndex = pathLength - 1
                                end
                            -- If reached the start of path when going backward, reverse direction
                            elseif nextIndex < 1 or (tbNpc.pathStart and nextIndex < tbNpc.pathStart) then

                                -- Di nguoc lai vi da het duong
                                if tbNpc.mode == "chiendau" then 
                                    -- Chuyen sang duong tiep theo hoac het duong thi gioi han lai duong di va chi di nguoc 10 diem
                                    if self:NextPathSegment(simInstance, tbNpc) == 0 then
                                        if not tbNpc.pathStart then 
                                            tbNpc.pathStart = 1
                                            if pathLength > 10 then 
                                                tbNpc.pathEnd = 10
                                            else 
                                                tbNpc.pathEnd = pathLength
                                            end
                                        end
                                        tbNpc.pathDirection = 1
                                        nextIndex = tbNpc.pathStart + 1
                                    else
                                        nextIndex = tbNpc.currentPointIndex
                                    end
                                else 
                                    tbNpc.pathDirection = 1
                                    nextIndex = 2
                                end
                            end
                        
                            tbNpc.currentPointIndex = nextIndex
                            return path[tbNpc.currentPointIndex]
                        end
                    end
                end
            end
            
            -- Fallback if path data is not properly initialized
            return "none"
        end

        -- If current position ID is provided, get next node from edges
        if currentPosId ~= nil then
            local nodes = tbNpc.worldInfo.nodes
            local edges = nodes[currentPosId] and nodes[currentPosId].linkedNodes or nil
            if edges and getn(edges) > 0 then
                -- Count unvisited edges first
                local unvisitedCount = 0
                for i = 1, getn(edges) do
                    local edgeId = edges[i]
                    local isVisited = 0
                    
                    -- Check if this edge was recently visited
                    for j = 1, getn(tbNpc.last2VisitedEdges) do
                        if tbNpc.last2VisitedEdges[j] == edgeId then
                            isVisited = 1
                            break
                        end
                    end
                    
                    if isVisited == 0 then
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
                        local isVisited = 0
                        
                        -- Check if this edge was recently visited
                        for j = 1, getn(tbNpc.last2VisitedEdges) do
                            if tbNpc.last2VisitedEdges[j] == edgeId then
                                isVisited = 1
                                break
                            end
                        end
                        
                        if isVisited == 0 then
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
        for id, _ in tbNpc.worldInfo.nodes do
            nodeCount = nodeCount + 1
        end
        if nodeCount == 0 then return nil end

        local targetIndex = random(1, nodeCount)
        local currentIndex = 0
        for id, _ in tbNpc.worldInfo.nodes do
            currentIndex = currentIndex + 1
            if currentIndex == targetIndex then
                return id
            end
        end
    end,

    resetPos = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nW = tbNpc.nMapId
 

        -- If wants to walk into preset or formation but not given path name?
        if tbNpc.role == "citizen" and (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") 
            and tbNpc.worldInfo.presetPaths 
            then
            local pathNames = getObjectKeys(tbNpc.worldInfo.presetPaths)
            local pathCount = getn(pathNames)
            if pathCount > 0 then
                if tbNpc.mode == "chiendau" and tbNpc.walkPathNames then
                    tbNpc.currentPathIndex = tbNpc.walkPathNames[1][1]
                    tbNpc.pathDirection = tbNpc.walkPathNames[1][2]
                    tbNpc.pathSegment = 1

                    local pathLength = getn(tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex])

                    if pathLength > 3 then                        
                        if tbNpc.pathDirection == 1 or tbNpc.pathDirection == 0 then
                            tbNpc.currentPointIndex = random(1, 3)
                        elseif tbNpc.pathDirection == -1 then
                            tbNpc.currentPointIndex = random(pathLength - 3, pathLength)
                        end
                    else
                        tbNpc.currentPointIndex = 1
                    end

                    tbNpc.pathStart = nil
                    tbNpc.pathEnd = nil
                    tbNpc.tick_canWalk = tbNpc.tick_breath + random(TONGKIM_SPAWN_MINSTAY, TONGKIM_SPAWN_MAXSTAY)*18/REFRESH_RATE
                    if (tbNpc.tongkim == 1) then
                        tbNpc.currentPointIndex = random(1, pathLength)

                        local node = getNodeInfoByNodeName(tbNpc, tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex][tbNpc.currentPointIndex])
                        local targetPos = randomRange({node.x, node.y}, tbNpc.walkVar or 4)
                        tbNpc.goX32 = targetPos[1]*32
                        tbNpc.goY32 = targetPos[2]*32
                    end
                else
                    tbNpc.currentPathIndex = pathNames[tbNpc.hardsetPathIndex or random(1, pathCount)]
                    tbNpc.currentPointIndex = random(1, getn(tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex]))
                    tbNpc.pathDirection = 1
                end

                tbNpc.nPosId = "none" -- Just set a value for compatibility
                return 1
            end
        end

        -- Startup position
        local walkPoint = self:GetRandomWalkPoint(simInstance, tbNpc)
        if walkPoint == nil or walkPoint == "none" then
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

        if (tbNpc.walkMode and tbNpc.walkMode == "formation") then
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
        end
    end,


    HasArrived = function(self, simInstance, tbNpc)
        local nListId = tbNpc.id
        local nX32, nY32 = GetNpcPos(tbNpc.finalIndex)
        local oX = nX32 / 32;
        local oY = nY32 / 32;

        local nX
        local nY
        local checkDistance = DISTANCE_CAN_CONTINUE
 
        -- Handle preset path mode
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.presetPaths and tbNpc.currentPathIndex then
            local path = tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex]
            if path and tbNpc.currentPointIndex and tbNpc.currentPointIndex <= getn(path) then
                local node = getNodeInfoByNodeName(tbNpc, path[tbNpc.currentPointIndex])
                nX = node.x
                nY = node.y
            else
                return 0
            end
        else

            if tbNpc.nPosId == nil or tbNpc.nPosId == "none" then
                return 0
            end

            local node = getNodeInfoByNodeName(tbNpc, tbNpc.nPosId)
            nX = node.x
            nY = node.y
            
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
            if child.movementSys:HasArrived(simInstance, child) == 0 then
                return 0
            end
        end
        return 1
    end,

    -- Breath
    Move = function(self, simInstance, tbNpc)
        local nListId = tbNpc.id

        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)

        local pW = 0
        local pX = 0
        local pY = 0

        local myPosX = floor(nX32 / 32)
        local myPosY = floor(nY32 / 32)        

        tbNpc.lastPos = {
            nX32 = nX32,
            nY32 = nY32
        }

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
            
            if (tbNpc.isAttractionAround == 0)then
                -- Case 1: someone around is fighting, we join
                if (tbNpc.CHANCE_JOIN_FIGHT and random(0, tbNpc.CHANCE_JOIN_FIGHT) <= 2) then
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
                if (tbNpc.CHANCE_ATTACK_NPC and random(1, tbNpc.CHANCE_ATTACK_NPC) <= 2) then
                    -- CHo nhung dua chung quanh

                    local countFighting = tbNpc.fightSys:GetFightingNPCs(simInstance, tbNpc, myPosX, myPosY)

                    -- If someone is around or I am not crazy then I fight
                    if countFighting > 0 or tbNpc.CHANCE_ATTACK_NPC > 1 then
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
        if tbNpc.tick_checklag and tbNpc.tick_breath > tbNpc.tick_checklag and tbNpc.isAttractionAround == 0 then
            tbNpc.entitySys:Respawn(simInstance, tbNpc, 4, "dang bi lag roi")
            return 1
        end

        -- Mode 1: randomwalk
        if self:HasArrived(simInstance, tbNpc) == 1 then
            -- Keep walking no stop
            local keepWalkingRate = 90
            if tbNpc.isAttractionAround > 0 then
                keepWalkingRate = 5
            end

            if tbNpc.baoDanhTongKim then
                keepWalkingRate = 5
                if tbNpc.isAttractionAround > 0 then
                    keepWalkingRate = 2
                end
                if (random(1, 100) < keepWalkingRate) then
                    tbNpc.nPosId = tbNpc.movementSys:GetRandomWalkPoint(simInstance, tbNpc, tbNpc.nPosId)
                else
                    return 1
                end
            
            -- Tong kim dang o trong spawn?
            elseif (tbNpc.tongkim == 1 and tbNpc.tick_breath < tbNpc.tick_canWalk) then
                
                keepWalkingRate = 5
                 
                -- Walk random trong spawn
                if (random(1, 100) < keepWalkingRate) then
                    tbNpc.nPosId = tbNpc.movementSys:GetRandomWalkPoint(simInstance, tbNpc, tbNpc.nPosId)
                else
                    return 1
                end

            -- Normal walk
            elseif (tbNpc.noStop == 1 or random(1, 100) < keepWalkingRate) then
                tbNpc.nPosId = tbNpc.movementSys:GetRandomWalkPoint(simInstance, tbNpc, tbNpc.nPosId)
            
            -- Stop walking
            else
                return 1
            end


            tbNpc.tick_checklag = nil
        else
            if not tbNpc.tick_checklag then
                tbNpc.tick_checklag = tbNpc.tick_breath +
                    30*18/REFRESH_RATE -- check again in 30s, if still at same position, respawn because this is stuck
            end
        end

        local targetPos
        
        -- Handle preset path walking
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.presetPaths then
            if tbNpc.currentPathIndex and tbNpc.currentPointIndex then
                local path = tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex]
                if path and tbNpc.currentPointIndex <= getn(path) then
                    targetPos = path[tbNpc.currentPointIndex]
                end
            end
        else
            targetPos = tbNpc.nPosId
        end

        if targetPos == nil or targetPos == "none" then
            return 0
        end

        local node = getNodeInfoByNodeName(tbNpc, targetPos)
        local nX = node.x
        local nY = node.y

        if not nX or not nY then
            return 0
        end

        
        if node.isExact == 1 then
            NpcWalk(tbNpc.finalIndex, nX, nY)
        else
            local targetPos = randomRange({nX, nY}, tbNpc.walkVar or 2)
            NpcWalk(tbNpc.finalIndex, targetPos[1], targetPos[2])            
        end 
        self:CalculateChildrenPosition(simInstance, nListId, nX, nY)
        
        return 1
    end,

    -- Breath
    MoveInactive = function(self, simInstance, tbNpc)
        local nListId = tbNpc.id

        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)

        local pW = 0
        local pX = 0
        local pY = 0

        local myPosX = floor(nX32 / 32)
        local myPosY = floor(nY32 / 32)        

        tbNpc.lastPos = {
            nX32 = nX32,
            nY32 = nY32
        }

        -- Is fighting? Do nothing except leave fight if possible
        if tbNpc.isFighting == 1 then 
            return 1 
        end

        -- Mode 1: randomwalk
        tbNpc.tick_checklag = nil
        if self:HasArrived(simInstance, tbNpc) == 1 then
            -- Keep walking no stop
            local keepWalkingRate = 90
            if tbNpc.isAttractionAround > 0 then
                keepWalkingRate = 5
            end

            if tbNpc.baoDanhTongKim then
                keepWalkingRate = 5
                if tbNpc.isAttractionAround > 0 then
                    keepWalkingRate = 2
                end
                if (random(1, 100) < keepWalkingRate) then
                    tbNpc.nPosId = tbNpc.movementSys:GetRandomWalkPoint(simInstance, tbNpc, tbNpc.nPosId)
                else
                    return 1
                end
            
            -- Tong kim dang o trong spawn?
            elseif (tbNpc.tongkim == 1 and tbNpc.tick_breath < tbNpc.tick_canWalk) then
                
                keepWalkingRate = 5
                 
                -- Walk random trong spawn
                if (random(1, 100) < keepWalkingRate) then
                    tbNpc.nPosId = tbNpc.movementSys:GetRandomWalkPoint(simInstance, tbNpc, tbNpc.nPosId)
                else
                    return 1
                end

            -- Normal walk
            elseif (tbNpc.noStop == 1 or random(1, 100) < keepWalkingRate) then
                tbNpc.nPosId = tbNpc.movementSys:GetRandomWalkPoint(simInstance, tbNpc, tbNpc.nPosId)
            
            -- Stop walking
            else
                return 1
            end
        end

        local targetPos
        
        -- Handle preset path walking
        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.presetPaths then
            if tbNpc.currentPathIndex and tbNpc.currentPointIndex then
                local path = tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex]
                if path and tbNpc.currentPointIndex <= getn(path) then
                    targetPos = path[tbNpc.currentPointIndex]
                end
            end
        else
            targetPos = tbNpc.nPosId
        end

        if targetPos == nil or targetPos == "none" then
            return 0
        end

        local node = getNodeInfoByNodeName(tbNpc, targetPos)
        local nX = node.x
        local nY = node.y

        if not nX or not nY then
            return 0
        end

        
        if node.isExact == 1 then
            NpcWalk(tbNpc.finalIndex, nX, nY)
        else
            local targetPos = randomRange({nX, nY}, tbNpc.walkVar or 2)
            NpcWalk(tbNpc.finalIndex, targetPos[1], targetPos[2])            
        end 
        self:CalculateChildrenPosition(simInstance, nListId, nX, nY)
        
        return 1
    end
}


SimMovement.FormationChild = {
    IsActive = IsActive,
    GetRandomWalkPoint = function(self, simInstance, tbNpc, currentPosId)
        return "none"
    end,

    resetPos = function(self, simInstance, nListId)
        local tbNpc = simInstance.fighterList[nListId]
        local nW = tbNpc.nMapId

        -- Dang di theo sau npc khac 
        local pW, pX32, pY32 = self:GetParentPos(simInstance, nListId)
        local pX = floor(pX32 / 32)
        local pY = floor(pY32 / 32)    
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
            return nW, nX32, nY32
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

    HasArrived = function(self, simInstance, tbNpc)
        
        local nX32, nY32 = GetNpcPos(tbNpc.finalIndex)
        local oX = nX32 / 32;
        local oY = nY32 / 32;

        local nX = tbNpc.parentAppointPos[1]
        local nY = tbNpc.parentAppointPos[2] 
        local checkDistance = DISTANCE_CAN_CONTINUE
 
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
    Move = function(self, simInstance, tbNpc)
        local nListId = tbNpc.id
        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)
    
        local pW = 0
        local pX = 0
        local pY = 0
    
        local myPosX = floor(nX32 / 32)
        local myPosY = floor(nY32 / 32)
    

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
        pW, pX32, pY32 = self:GetParentPos(simInstance, nListId)
        local pX = floor(pX32 / 32)
        local pY = floor(pY32 / 32)
        local cachNguoiChoi =  GetDistanceRadius(myPosX, myPosY, pX, pY)

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
        local targetW = pW
        local targetX = myPosX
        local targetY = myPosY 
        
        if (tbNpc.childrenWalkMode == "random") then

            if (cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) then
                if random(1,100) < 5 then 
                    local randomPos = randomRange({pX, pY}, tbNpc.walkVar or 2)
                    targetX = randomPos[1]
                    targetY = randomPos[2]
                end
            else
                local randomPos = randomRange({pX, pY}, tbNpc.walkVar or 2)
                targetX = randomPos[1]
                targetY = randomPos[2]
            end
 
        else
            targetW, targetX, targetY = self:GetMyPosFromParent(simInstance, nListId)
        end

        -- Parent gave info?
        if targetW > 0 and targetX > 0 and targetY > 0 then
            tbNpc.parentAppointPos[1] = targetX
            tbNpc.parentAppointPos[2] = targetY
            NpcWalk(tbNpc.finalIndex, targetX, targetY)
        end
        return 1
    end,

    -- Move
    MoveInactive = function(self, simInstance, tbNpc)
        local nListId = tbNpc.id
        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)
    
        local pW = 0
        local pX = 0
        local pY = 0
    
        local myPosX = floor(nX32 / 32)
        local myPosY = floor(nY32 / 32)
    
 
        -- Am I fighting? Do nothing except leave fight if possible
        if tbNpc.isFighting == 1 then  
            return 1
        end

        -- Mode 2: follow parent NPC
        -- Player has gone different map? Do respawn
        local needRespawn = 0
        pW, pX32, pY32 = self:GetParentPos(simInstance, nListId)
        local pX = floor(pX32 / 32)
        local pY = floor(pY32 / 32)
        local cachNguoiChoi =  GetDistanceRadius(myPosX, myPosY, pX, pY)

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
        local targetW = pW
        local targetX = myPosX
        local targetY = myPosY 
        
        if (tbNpc.childrenWalkMode == "random") then

            if (cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) then
                if random(1,100) < 5 then 
                    local randomPos = randomRange({pX, pY}, tbNpc.walkVar or 2)
                    targetX = randomPos[1]
                    targetY = randomPos[2]
                end
            else
                local randomPos = randomRange({pX, pY}, tbNpc.walkVar or 2)
                targetX = randomPos[1]
                targetY = randomPos[2]
            end
 
        else
            targetW, targetX, targetY = self:GetMyPosFromParent(simInstance, nListId)
        end

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