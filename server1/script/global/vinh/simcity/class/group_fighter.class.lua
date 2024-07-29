Include("\\script\\misc\\eventsys\\type\\player.lua")
Include("\\script\\misc\\eventsys\\type\\map.lua")
Include("\\script\\global\\vinh\\simcity\\config.lua")
Include("\\script\\global\\vinh\\simcity\\class\\group_fighter.helper.lua")
IncludeLib("NPCINFO")
GroupFighter = {
    groupList = {},
    ownerID2List = {},
    counter = 0,
}

for k, v in Helpers do
    Helpers[k] = v
end

function GroupFighter:New(group)
    local id = group.nNpcId

    -- Not a valid char ?
    if Helpers:isValidChar(id) == 0 then
        return 0
    end

    -- Initialise this char config
    Helpers:initChar(group)

    -- Setup walk paths
    if self:HardResetPos(group) == 0 then
        return 1
    end

    -- All good generate name for Thanh Thi
    if group.mode == nil or group.mode == "thanhthi" then
        local worldInfo = SimCityWorld:Get(group.nMapId)

        if worldInfo.showName == 1 then
            if (not group.szName) or group.szName == "" then
                group.szName = SimCityNPCInfo:getName(id)
            end
        else
            group.szName = " "
        end
    end

    -- Setup attacked position (vantieu)
    if group.underAttack and group.underAttack.types then
        local attackLocations = {}
        local attackTypes = group.underAttack.types
        for i = 1, getn(attackTypes) do
            local nPoint = random(1, getn(group.tbPos))
            attackLocations["n" .. nPoint] = attackTypes[i]
            --------print(nPoint .. " -> " .. attackTypes[i])
        end

        -- DEV
        group.underAttack.locations = {} -- attackLocations
    end

    -- Setup GROUP ID and keep a record of it
    self.counter = self.counter + 1

    local groupID = self.counter
    group.groupID = groupID
    self.groupList["n" .. group.groupID] = group
    self.ownerID2List[group.ownerID] = groupID

    local npcIndex = Helpers:createGroup(group, 1)
    return npcIndex
end

function GroupFighter:_arrived(nNpcIndex, group)
    local posIndex = group.nPosId
    local parentPos = group.walkPath[posIndex]

    local nX32, nY32 = GetNpcPos(nNpcIndex)
    local oX = nX32 / 32;
    local oY = nY32 / 32;

    local isExact = group.tbPos[posIndex][3]
    local nX = parentPos[1]
    local nY = parentPos[2]

    local checkDistance = DISTANCE_CAN_CONTINUE

    if group.isSpinning == 1 then
        nX = parentPos[3]
        nY = parentPos[4]
        checkDistance = DISTANCE_CAN_SPIN
    end

    if isExact == 1 then
        nX = group.tbPos[posIndex][1]
        nY = group.tbPos[posIndex][2]
    end

    local distance = GetDistanceRadius(nX, nY, oX, oY)

    if distance < checkDistance then
        if not group.arriveTick then
            group.arriveTick = group.tick + 15 -- wait 15s for children to arrive
        end

        -- Day du children?
        if self:_arrived_children(group) == 1 then
            return 1
        end

        -- Qua thoi gian cho doi
        if group.arriveTick < group.tick and group.isFighting ~= 1 then
            return 0
        end
    end
    return 0
end

function GroupFighter:_checkRank(group)
    local newRank = 1
    if group.fightingScore > 2000 then
        newRank = 2
    end
    if group.fightingScore > 5000 then
        newRank = 3
    end
    if group.fightingScore > 10000 then
        newRank = 4
    end
    if group.fightingScore > 15000 then
        newRank = 5
    end
    if group.fightingScore > 20000 then
        newRank = 6
    end

    if (group.rank ~= newRank) then
        if newRank > group.rank and SearchPlayer(group.playerID) == 0 then
            local worldInfo = SimCityWorld:Get(group.nMapId)
            if worldInfo.showThangCap == 1 then
                SimCityTongKim:announceRank(group.nMapId, group.hardsetName or SimCityNPCInfo:getName(group.nNpcId),
                    newRank)
            end
        end
        group.rank = newRank
    end
end

function GroupFighter:_respawnChild(nListId, childID, code, reason)
    -- code: 0: qua xa parent, 2: them quai chien dau

    local group = self.groupList["n" .. nListId]
    if not group then
        return 0
    end

    if group.children then
        local child = group.children[childID]

        if child.isDead ~= 1 and child.finalIndex ~= nil then
            child.lastHP = NPCINFO_GetNpcCurrentLife(child.finalIndex)
        end

        if child.finalIndex ~= nil then
            DelNpcSafe(child.finalIndex)
        end

        if child.isDead ~= 1 then
            if code == 0 or code == 2 or child.walkPath == nil then
                local nX, nY, nMapIndex = GetNpcPos(group.finalIndex)

                -- Do calculation
                nX = nX / 32
                nY = nY / 32
                child.lastPos = {
                    nX32 = (nX + random(-2, 2)) * 32,
                    nY32 = (nY + random(-2, 2)) * 32
                }
            elseif child.walkPath ~= nil then
                local targetPos = child.walkPath[group.nPosId]
                local cX = targetPos[1]
                local cY = targetPos[2]
                child.lastPos = {
                    nX32 = cX * 32,
                    nY32 = cY * 32
                }
            end

            Helpers:createChild(group, childID)
        end
    end
end

function GroupFighter:_respawn(nListId, code, reason)
    -- code: 0: con nv con song 1: da chet toan bo 2: keo xe qua map khac 3: chuyen sang chien dau
    --print("RESPAWN " .. code .. " " .. reason)
    -- CallPlayerFunction(1, Msg2Player, "Respawn: "..reason)

    local group = self.groupList["n" .. nListId]

    isAllDead = code == 1 and 1 or 0

    local nX, nY, nMapIndex = GetNpcPos(group.finalIndex)

    -- Do calculation
    nX = nX / 32
    nY = nY / 32

    -- 2 = qua map khac?
    if (code == 2) then
        nX = 0
        nY = 0
        group.nPosId = 1
        self:HardResetPos(group)

        -- otherwise reset
    elseif isAllDead == 1 and SearchPlayer(group.playerID) > 0 then
        nX = group.walkPath[1][1]
        nY = group.walkPath[1][2]
        group.nPosId = 1
    elseif (isAllDead == 1 and group.resetPosWhenRevive and group.resetPosWhenRevive >= 1) then
        nX = group.walkPath[group.resetPosWhenRevive][1]
        nY = group.walkPath[group.resetPosWhenRevive][2]
        group.nPosId = group.resetPosWhenRevive
        self:HardResetPos(group)
    elseif (isAllDead == 1 and group.lastPos ~= nil) then
        nX = group.lastPos.nX32
        nY = group.lastPos.nY32
        group.nPosId = group.lastPos.nPosId
    else
        group.lastPos = {
            nX32 = nX,
            nY32 = nY,
            nPosId = group.nPosId
        }
    end

    group.hardsetPos = group.nPosId
    group.arriveTick = nil
    group.lastHP = NPCINFO_GetNpcCurrentLife(group.finalIndex)
    if (isAllDead == 1) then
        group.lastHP = nil
    end

    -- Retrieve position of each
    if group.children then
        for i = 1, getn(group.children) do
            local child = group.children[i]
            if child.isDead ~= 1 then
                child.lastHP = NPCINFO_GetNpcCurrentLife(child.finalIndex)
            end

            if (isAllDead == 1) then
                child.lastHP = nil
            end

            if ((isAllDead == 1 and
                        ((group.resetPosWhenRevive and group.resetPosWhenRevive >= 1) or (SearchPlayer(group.playerID) > 0))) or
                    (isAllDead == 2)) then
                child.lastPos = nil
                -- Children bi lag
            elseif isAllDead == 3 then
                if child.isDead ~= 1 then
                    if child.walkPath ~= nil then
                        local targetPos = child.walkPath[group.nPosId]
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
    DelNpcSafe(group.finalIndex)

    self.groupList["n" .. nListId] = group
    self:DelNpcSafe_children(nListId)

    -- Children bi lag
    if isAllDead == 3 then
        group.lastPos = nil
        Helpers:createGroup(group, 0)
        -- Binh thuong
    else
        Helpers:createGroup(group, 0, nX, nY)
    end
end

function GroupFighter:_getNpcAroundNpcList(nNpcIndex, radius)
    local allNpcs = {}
    local nCount = 0

    -- 8.0: has GetNpcAroundNpcList function
    if GetNpcAroundNpcList then
        return GetNpcAroundNpcList(nNpcIndex, radius)

        -- 6.0: do the long route
    else
        local myListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
        local nX32, nY32, nW32 = GetNpcPos(nNpcIndex)
        local areaX = nX32 / 32
        local areaY = nY32 / 32
        local nW = SubWorldIdx2ID(nW32)

        -- Get info for npc in this world
        for key, group in self.groupList do
            if group.isDead == 0 and group.nMapId == nW and group.groupID ~= myListId then
                local oX32, oY32 = GetNpcPos(group.finalIndex)
                local oX = oX32 / 32
                local oY = oY32 / 32
                if GetDistanceRadius(oX, oY, areaX, areaY) < radius then
                    tinsert(allNpcs, group.finalIndex)
                    nCount = nCount + 1
                end
            end
        end
    end

    return allNpcs, nCount
end

function GroupFighter:_isNpcEnemyAround(group, nNpcIndex, radius)
    local allNpcs = {}
    local nCount = 0

    -- Keo xe?
    if SearchPlayer(group.playerID) > 0 then
        allNpcs, nCount = CallPlayerFunction(SearchPlayer(group.playerID), GetAroundNpcList, radius)
        for i = 1, nCount do
            local group2Kind = GetNpcKind(allNpcs[i])
            local group2Camp = GetNpcCurCamp(allNpcs[i])
            if group2Kind == 0 and (IsAttackableCamp(group.camp, group2Camp) == 1) then
                --print("SIM" .. group2Camp .. group.camp)
                return 1
            end
        end
        return 0
    end

    -- Thanh thi / tong kim / chien loan
    allNpcs, nCount = self:_getNpcAroundNpcList(nNpcIndex, radius)
    for i = 1, nCount do
        local group2Kind = GetNpcKind(allNpcs[i])
        local group2Camp = GetNpcCurCamp(allNpcs[i])
        if group2Kind == 0 and (IsAttackableCamp(group.camp, group2Camp) == 1) then
            --print("USER" .. group2Camp .. group.camp)
            return 1
        end
    end

    if group.children then
        for j = 1, getn(group.children) do
            if (group.children[j] and group.children[j].finalIndex and group.children[j].finalIndex > 0 and group.children[j].isDead == 0) then
                local allNpcs, nCount = self:_getNpcAroundNpcList(group.children[j].finalIndex, radius)
                for i = 1, nCount do
                    local group2Kind = GetNpcKind(allNpcs[i])
                    local group2Camp = GetNpcCurCamp(allNpcs[i])
                    if group2Kind == 0 and (IsAttackableCamp(group.camp, group2Camp) == 1) then
                        return 1
                    end
                end
            end
        end
    end

    return 0
end

function GroupFighter:_isPlayerEnemyAround(nListId, nNpcIndex)
    local group = self.groupList["n" .. nListId]

    if not group then
        return 0
    end

    -- FIGHT other player
    if GetNpcAroundPlayerList then
        local allNpcs, nCount = GetNpcAroundPlayerList(nNpcIndex, group.RADIUS_FIGHT_PLAYER or RADIUS_FIGHT_PLAYER)
        for i = 1, nCount do
            if ((group.ownerID == nil or allNpcs[i] ~= SearchPlayer(group.ownerID)) and
                    CallPlayerFunction(allNpcs[i], GetFightState) == 1 and
                    IsAttackableCamp(CallPlayerFunction(allNpcs[i], GetCurCamp), group.camp) and
                    group.camp ~= 0) then
                return 1
            end
        end

        -- Check children
        if group.children then
            for j = 1, getn(group.children) do
                if (group.children[j] and group.children[j].finalIndex and group.children[j].finalIndex > 0 and
                        group.children[j].isDead == 0) then
                    local allNpcs, nCount = GetNpcAroundPlayerList(group.children[j].finalIndex,
                        group.RADIUS_FIGHT_PLAYER or RADIUS_FIGHT_PLAYER)
                    for i = 1, nCount do
                        if ((group.ownerID == nil or allNpcs[i] ~= SearchPlayer(group.ownerID)) and
                                CallPlayerFunction(allNpcs[i], GetFightState) == 1 and
                                IsAttackableCamp(CallPlayerFunction(allNpcs[i], GetCurCamp), group.camp) == 1 and
                                group.camp ~= 0) then
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
    local group = self.groupList["n" .. nListId]
    if not group then
        return 0
    end
    group.isFighting = 1
    group.canSwitchTick = group.tick +
        random(group.TIME_FIGHTING_minTs or TIME_FIGHTING.minTs,
            group.TIME_FIGHTING_maxTs or TIME_FIGHTING.maxTs) -- trong trang thai pk 1 toi 2ph
    self.groupList["n" .. nListId] = group

    reason = reason or "no reason"

    local currX, currY, currW = GetNpcPos(group.finalIndex)
    currX = floor(currX / 32)
    currY = floor(currY / 32)

    -- If already having last fight pos, we may simply chance AI to 1
    if group.lastFightPos then
        local lastPos = group.lastFightPos
        if lastPos.W == currW then
            if (GetDistanceRadius(lastPos.X, lastPos.Y, currX, currY) < DISTANCE_VISION) then
                Helpers:setFightState(group, 9)
                return 1
            end
        end
    end

    -- Otherwise save it and respawn
    group.lastFightPos = {
        X = currX,
        Y = currY,
        W = currW
    }

    self:_respawn(nListId, 3, "_joinFight " .. reason)

    return 1
end

function GroupFighter:_joinFightCheck(nListId, nNpcIndex)
    local group = self.groupList["n" .. nListId]

    if not group then
        return 0
    end

    if (self:_isNpcEnemyAround(group, nNpcIndex, group.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN) == 1) then
        return self:_joinFight(nListId, "enemy around")
    end
    return 0
end

function GroupFighter:_joinFightPlayerCheck(nListId, nNpcIndex)
    local group = self.groupList["n" .. nListId]

    if not group then
        return 0
    end

    -- FIGHT other player
    if GetNpcAroundPlayerList then
        if self:_isPlayerEnemyAround(nListId, nNpcIndex) == 1 then
            local nW = group.nMapId
            if SearchPlayer(group.playerID) == 0 then
                local worldInfo = SimCityWorld:Get(nW)
                if group.mode == "vantieu" or worldInfo.showFightingArea == 1 then
                    local name = GetNpcName(nNpcIndex)
                    local lastPos = group.tbPos[group.nPosId]

                    if group.mode == "vantieu" then
                        Msg2Map(group.nMapId,
                            "<color=white>" .. name .. "<color> bÞ tÊn c«ng t¹i " .. worldInfo.name .. " " ..
                            floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "")
                    else
                        Msg2Map(group.nMapId,
                            "<color=white>" .. name .. "<color> ®¸nh ng­êi t¹i " .. worldInfo.name .. " " ..
                            floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "")
                    end
                end
            end
            return self:_joinFight(nListId, "player around")
        end
    end

    return 0
end

function GroupFighter:walk2ClosestPoint(nListId)
    local group = self.groupList["n" .. nListId]
    if not group then
        return 0
    end

    local currPointer = group.nPosId
    local closestPointer = -1
    local closestDistance = 99999
    local maxPointer = getn(group.tbPos)
    local pX, pY, _ = GetNpcPos(group.finalIndex)
    pX = pX / 32
    pY = pY / 32

    local tmp
    for i = currPointer - 5, currPointer + 5 do
        if (i > 0 and i <= maxPointer) then
            tmp = GetDistanceRadius(pX, pY, group.tbPos[i][1], group.tbPos[i][2])
            if (tmp < closestDistance) then
                closestDistance = tmp
                closestPointer = i
            end
        end
    end

    if closestPointer ~= -1 then
        group.nPosId = closestPointer
    end
end

function GroupFighter:_leaveFight(nListId, isAllDead, reason)
    isAllDead = isAllDead or 0
    local group = self.groupList["n" .. nListId]
    if not group then
        return 0
    end
    group.isFighting = 0
    group.canSwitchTick = group.tick +
        random(group.TIME_RESTING_minTs or TIME_RESTING.minTs,
            group.TIME_RESTING_maxTs or TIME_RESTING.maxTs) -- trong trang thai di bo 30s-1ph
    self.groupList["n" .. nListId] = group
    reason = reason or "no reason"

    -- Do not need to respawn just disable fighting
    if (isAllDead ~= 1 and group.kind ~= 4) then
        self:walk2ClosestPoint(nListId)
        Helpers:setFightState(group, 0)
    else
        self:_respawn(nListId, isAllDead, reason)
    end
end

function GroupFighter:_leaveFightCheck(nListId, nNpcIndex)
    local group = self.groupList["n" .. nListId]
    if not group then
        return 0
    end

    if group.isDead == 1 then
        return 0
    end

    -- No attacker around including NPC and Player ? Stop
    if (self:_isNpcEnemyAround(group, nNpcIndex, group.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN) == 0 and
            self:_isPlayerEnemyAround(nListId, nNpcIndex) == 0) then
        if (group.leaveFightWhenNoEnemy and group.leaveFightWhenNoEnemy > 0) then
            local targetTick = group.tick + group.leaveFightWhenNoEnemy - 1

            if group.canSwitchTick > targetTick then
                group.canSwitchTick = targetTick
            end
        end

        return 1
    end
    return 0
end

function GroupFighter:_generateWalkPath(group, hasJustBeenFlipped)
    -- Generate walkpath for myself
    -- & Repeat for children
    local WalkSize = getn(group.tbPos)
    group.walkPath = {}

    local aliveChildren = {}
    if group.children then
        for j = 1, getn(group.children) do
            if group.children[j].isDead ~= 1 then
                tinsert(aliveChildren, j)
            end
        end
    end

    local childrenSize = getn(aliveChildren)
    if childrenSize > 0 then
        for j = 1, childrenSize do
            group.children[aliveChildren[j]].walkPath = {}
        end
    end

    for i = 1, WalkSize do
        local point = group.tbPos[i]
        -- Having children?
        if childrenSize > 0 then
            -- RANDOM walk for everyone?
            if group.walkMode == "random" or group.walkMode == "keoxe" then
                if hasJustBeenFlipped == 0 then
                    tinsert(group.walkPath, randomRange(point, group.walkVar or 2))
                else
                    tinsert(group.walkPath, randomRange(point, 0))
                end
                for j = 1, childrenSize do
                    if hasJustBeenFlipped == 0 then
                        tinsert(group.children[aliveChildren[j]].walkPath, randomRange(point, group.walkVar or 2))
                    else
                        tinsert(group.children[aliveChildren[j]].walkPath, randomRange(point, 0))
                    end
                end

                -- FORMATION walk?
            else
                -- For children
                local formation = self:_genCoords_squareshape(group, childrenSize, i)
                for j = 1, childrenSize do
                    tinsert(group.children[aliveChildren[j]].walkPath, formation[j])
                end

                -- For myself
                local firstPointLastRow = formation[childrenSize + 1]
                local lastPointLastRow
                for k = childrenSize + 1, getn(formation) do
                    lastPointLastRow = formation[k]
                end

                tinsert(group.walkPath,
                    { (firstPointLastRow[1] + lastPointLastRow[1]) / 2, (firstPointLastRow[2] + lastPointLastRow[2]) / 2,
                        (firstPointLastRow[3] + lastPointLastRow[3]) / 2, (firstPointLastRow[4] + lastPointLastRow[4]) /
                    2 })
            end

            -- No children = random path for myself
        else
            if hasJustBeenFlipped == 0 then
                tinsert(group.walkPath, randomRange(point, group.walkVar or 2))
            else
                tinsert(group.walkPath, randomRange(point, 0))
            end
        end
    end
end

function GroupFighter:Get(nListId)
    return self.groupList["n" .. nListId]
end

function GroupFighter:HardResetPos(group)
    local nW = group.nMapId
    local worldInfo = {}
    local walkAreas = {}

    -- Co duong di bao gom map
    if group.mapData then
        local mapData = group.mapData
        for i = 1, getn(mapData) do
            local dataPoint = mapData[i]
            if (dataPoint[1] == nW) then
                tinsert(walkAreas, { dataPoint[2], dataPoint[3] })
            end
        end
        group.tbPos = arrCopy(walkAreas)
        if group.walkMode ~= "random" and group.walkMode ~= "keoxe" and group.children then
            group.tbPos = createDiagonalFormPath(group.tbPos)
        end

        -- Di tu do
    else
        -- Dang theo sau thi lay dia diem cua nguoi choi
        if SearchPlayer(group.playerID) > 0 then
            local pW, pX, pY = CallPlayerFunction(SearchPlayer(group.playerID), GetWorldPos)
            worldInfo.showName = 1
            group.tbPos = { { pX, pY } }
            group.nPosId = 1
            walkAreas = { { { pX, pY } } }
            -- --print("DONE "..pX.." "..pY)
            -- hoac la sim thanh thi di tum lum
        else
            if not group.tbPos then
                worldInfo = SimCityWorld:Get(nW)
                walkAreas = worldInfo.walkAreas
                if not walkAreas then 
                    return 0
                end
                local walkIndex = random(1, getn(walkAreas))
                group.tbPos = arrCopy(walkAreas[walkIndex])

                -- Trong thanh thi co the random di nguoc chieu
                if group.mode == "thanhthi" and random(1, 2) < 2 then
                    group.tbPos = arrFlip(group.tbPos)
                end

                -- Neu di theo doi quan ma ko phai random
                if group.walkMode ~= "random" and group.walkMode ~= "keoxe" and group.children then
                    group.tbPos = createDiagonalFormPath(group.tbPos)
                end

                group.hardsetPos = random(1, getn(group.tbPos))
            end
        end
    end

    -- No path to walk?
    if not group.tbPos or getn(group.tbPos) < 1 then
        return 0
    end

    -- Init stats
    group.isSpinning = 0
    group.lastOffSetAngle = 0

    -- Startup position
    group.hardsetPos = group.hardsetPos or random(1, getn(group.tbPos))

    -- Calculate walk path for main + children
    self:_generateWalkPath(group, 0)

    -- Add to store and create everyone on screen
    return group
end

function GroupFighter:_genCoords_squareshape(group, N, targetPointer)
    local f = createFormation(N)
    local rows = f[1] > f[2] and f[1] or f[2]
    local cols = f[1] > f[2] and f[2] or f[1]
    local spacing = group.char_spacing or CHAR_SPACING
    local pathLength = getn(group.tbPos)

    -- Variables
    local toPos = group.tbPos[targetPointer]

    local fromPos
    if (targetPointer == 1) then
        fromPos = group.tbPos[2]
    else
        fromPos = group.tbPos[targetPointer - 1]
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

            if (mostLeft > newX or mostLeft == 0) then
                mostLeft = newX
            end
            if (mostTop > newY or mostTop == 0) then
                mostTop = newY
            end
            if (mostRight < newX or mostRight == 0) then
                mostRight = newX
            end
            if (mostBottom < newY or mostBottom == 0) then
                mostBottom = newY
            end
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
        rhombus[i] = self:_transform(group, { rhombus[i][1] - offSetX, rhombus[i][2] - offSetY, rhombus[i][3] - offSetX,
            rhombus[i][4] - offSetY }, toPos, fromPos, toPos)
    end

    -- DONE
    return rhombus
end

function GroupFighter:_transform(group, point, centrePoint, fromPos, toPos)
    local deltaX = toPos[1] - fromPos[1]
    local deltaY = toPos[2] - fromPos[2]

    local offsetAngle = atan2(deltaY, deltaX) + 45

    offsetAngle = floor(offsetAngle / 45 + 0.5) * 45

    -- Input coordinates
    local x = centrePoint[1] -- x-coordinate of point O
    local y = centrePoint[2] -- y-coordinate of point O
    local x1 = point[1]      -- x-coordinate of point A
    local y1 = point[2]      -- y-coordinate of point A
    local xF = fromPos[1]    -- x-coordinate of point A
    local yF = fromPos[2]    -- y-coordinate of point A

    -- Calculate the angle OA makes with the x-axis
    local angle_OA = atan2(y1 - y, x1 - x)

    -- Calculate the new angle for OA' (45 degrees more than angle_OA)
    local angle_OA_prime = angle_OA + offsetAngle

    -- Calculate the distance from O to A'
    local distance_OA_prime = sqrt((x1 - x) ^ 2 + (y1 - y) ^ 2)

    -- Calculate the new coordinates for A'
    local x_prime = x + distance_OA_prime * cos(angle_OA_prime)
    local y_prime = y + distance_OA_prime * sin(angle_OA_prime)

    local xF_prime = xF + distance_OA_prime * cos(angle_OA_prime)
    local yF_prime = yF + distance_OA_prime * sin(angle_OA_prime)

    -- New toPos and fromPos
    return { x_prime, y_prime, xF_prime, yF_prime }
end

function GroupFighter:ClearMap(nW, targetListId)
    -- Get info for npc in this world
    for key, group in self.groupList do
        if group.nMapId == nW then
            if (not targetListId) or (targetListId == group.groupID) then
                self:Remove(group.groupID)
            end
        end
    end
end

function GroupFighter:Remove(nListId)
    local group = self.groupList["n" .. nListId]
    if group then
        DelNpcSafe(group.finalIndex)
        self:DelNpcSafe_children(nListId)
        self:OwnerFarAway(nListId, "Remove")
        self.groupList["n" .. nListId] = nil
    end
end

function GroupFighter:_arrived_children(group)
    if not group.children then
        return 1
    end

    local N = getn(group.children)
    local N = getn(group.children)
    local posIndex = group.nPosId
    local isExact = group.tbPos[posIndex][3]

    for i = 1, N do
        local child = group.children[i]

        if (child.finalIndex) then
            local nX32, nY32 = GetNpcPos(child.finalIndex)
            local oX = nX32 / 32;
            local oY = nY32 / 32;

            local nX = child.walkPath[posIndex][1]
            local nY = child.walkPath[posIndex][2]

            local checkDistance = DISTANCE_CAN_CONTINUE

            if (group.isSpinning == 1) then
                nX = child.walkPath[posIndex][3]
                nY = child.walkPath[posIndex][4]
                checkDistance = DISTANCE_CAN_SPIN
            end

            if group.childrenCheckDistance then
                checkDistance = group.childrenCheckDistance
            end

            if isExact == 1 then
                nX = group.tbPos[posIndex][1]
                nY = group.tbPos[posIndex][2]
            end

            local distance = GetDistanceRadius(nX, nY, oX, oY)

            -- Con qua xa
            if distance > checkDistance then
                -- Qua thoi gian cho doi, keu con den ben canh
                if group.arriveTick < group.tick and group.isFighting ~= 1 then
                    self:_respawnChild(group.groupID, i, 0, "Too far for 15 seconds")
                    return 0
                end

                return 0
            end
        end
    end

    return 1
end

function GroupFighter:_walk_children(group, posIndex)
    if not group.children then
        return
    end

    local N = getn(group.children)

    local tX = group.tbPos[posIndex][1]
    local tY = group.tbPos[posIndex][2]
    local isExact = group.tbPos[posIndex][3]

    local pX = 0
    local pY = 0
    local pW = 0

    if (group.isDead == 0 and group.finalIndex) then
        pX, pY, pW = GetNpcPos(group.finalIndex)
        pX = pX / 32
        pY = pY / 32
    end

    for i = 1, N do
        local child = group.children[i]
        if (child.finalIndex) then
            if isExact == 1 then
                NpcWalk(child.finalIndex, tX, tY)
            else
                if (group.walkMode == "keoxe" and pX > 0 and pY > 0 and pW > 0) then
                    NpcWalk(child.finalIndex, pX + random(-2, 2), pY + random(-2, 2))
                else
                    local targetPos = child.walkPath[posIndex]
                    local nX = targetPos[1]
                    local nY = targetPos[2]
                    if group.isSpinning == 1 then
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
    local group = self.groupList["n" .. nListId]

    if not group then
        return 1
    end

    if not group.children then
        return 1
    end

    local N = getn(group.children)
    for i = 1, N do
        local child = group.children[i]
        if (child.finalIndex) then
            DelNpcSafe(child.finalIndex)
            child.finalIndex = nil
            group.children[i] = child
        end
    end
    self.groupList["n" .. nListId] = group
end

function GroupFighter:_calculateFightingScore(group, nNpcIndex, currRank)
    local allNpcs, nCount = self:_getNpcAroundNpcList(nNpcIndex, 15)
    local foundgroups = {}

    if nCount > 0 then
        for i = 1, nCount do
            local group2Kind = GetNpcKind(allNpcs[i])
            local group2Camp = GetNpcCurCamp(allNpcs[i])
            if (group2Kind == 0) then
                if (group2Camp ~= group.camp) then
                    local nListId2 = GetNpcParam(allNpcs[i], PARAM_LIST_ID) or 0
                    if (nListId2 > 0) then
                        tinsert(foundgroups, nListId2)
                    end
                end
            end
        end

        local N = getn(foundgroups)
        if N > 0 then
            local scoreTotal = currRank * 1000
            for i = 1, N do
                local group2 = self.groupList["n" .. foundgroups[i]]
                if group2 and group2.isFighting == 1 then
                    group2.fightingScore = ceil(
                        group2.fightingScore + (scoreTotal / N) + (scoreTotal / N) * group2.rank / 10)
                    self:_checkRank(group2)
                end
            end
        end
    end

    return 0
end

function GroupFighter:OnNpcDeath(nNpcIndex, playerAttacker)
    local npcType = GetNpcParam(nNpcIndex, PARAM_NPC_TYPE)
    if (npcType == 1) then
        self:ParentDead(nNpcIndex, playerAttacker)
    else
        self:ChildrenDead(nNpcIndex, playerAttacker)
    end
end

function GroupFighter:ChildrenDead(childrenIndex, playerAttacker)
    if childrenIndex > 0 then
        local nListId = GetNpcParam(childrenIndex, PARAM_LIST_ID)
        local childID = GetNpcParam(childrenIndex, PARAM_CHILD_ID)
        local group = self.groupList["n" .. nListId]
        if not group then
            return
        end

        local child = group.children[childID]
        if (child) then
            local nX32, nY32 = GetNpcPos(childrenIndex)
            child.lastPos = {
                nX32 = nX32,
                nY32 = nY32
            }
            child.isDead = 1
            child.finalIndex = nil
        end

        self:_calculateFightingScore(child or group, childrenIndex, child.rank or 1)

        if group.tongkim == 1 then
            SimCityTongKim:OnDeath(childrenIndex, child.rank or 1)
            -- else

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

        self:_check_full_death(nListId)
    end
end

function GroupFighter:ParentDead(nNpcIndex, playerAttacker)
    if nNpcIndex > 0 then
        local nListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
        local group = self.groupList["n" .. nListId]
        if not group then
            return
        end

        self:_calculateFightingScore(group, nNpcIndex, group.rank or 1)
        if group.tongkim == 1 then
            SimCityTongKim:OnDeath(nNpcIndex, group.rank or 1)
        end

        local foundAlive = 0
        if group.children then
            for i = 1, getn(group.children) do
                local child = group.children[i]
                if child.isDead ~= 1 and child.rebel == 0 then
                    foundAlive = i
                    break
                end
            end
        end

        -- No revive and found children alive? That child become parent
        if foundAlive > 0 then
            local child = group.children[foundAlive]
            local tmp = {
                finalIndex = group.finalIndex,
                szName = group.szName,
                nNpcId = group.nNpcId,
                series = group.series
            }

            group.finalIndex = child.finalIndex
            group.szName = child.szName
            group.nNpcId = child.nNpcId
            group.series = child.series

            child.isDead = tmp.isDead
            child.finalIndex = tmp.finalIndex
            child.szName = tmp.szName
            child.series = tmp.series

            SetNpcParam(group.finalIndex, PARAM_NPC_TYPE, 1)
            SetNpcParam(group.finalIndex, PARAM_CHILD_ID, nil)
            --------print("Doi chu pt sang nv "..group.szName)
            return 1
        else
            group.isDead = 1
            group.finalIndex = nil
        end

        self:_check_full_death(nListId)
    end
end

function GroupFighter:FINISH(group, code, reason)
    -- code 0:failed 1:success
    group.finished = 1
    group.finishedReason = code
end

function GroupFighter:_check_full_death(nListId)
    local group = self.groupList["n" .. nListId]
    if (not group) then
        return
    end

    local doRespawn = 0

    if group.isFighting == 1 and group.tick > group.canSwitchTick then
        doRespawn = 1
    end

    local allChildrenDead = 1
    local alive = 0

    if doRespawn == 0 then
        if group.children then
            local N = getn(group.children)
            for i = 1, N do
                if doRespawn == 0 then
                    local child = group.children[i]
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
    if (doRespawn == 1 or (group.isDead == 1 and allChildrenDead == 1)) then
        local nW = group.nMapId
        local lastPos = group.tbPos[group.nPosId]

        self:FINISH(group, 0, "allDead")
        local worldInfo = SimCityWorld:Get(nW)

        if group.mode == "vantieu" and worldInfo.name then
            Msg2Map(nW,
                "<color=white>" .. group.szName .. "<color> hoµn toµn bÞ c­íp t¹i <color=green>" .. worldInfo.name ..
                " <color=yellow>" .. floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "<color>")
        elseif SearchPlayer(group.playerID) == 0 then
            if group.children and worldInfo.showFightingArea == 1 then
                Msg2Map(nW,
                    "<color=white>" .. group.szName .. "<color> toµn ®oµn b¹i trËn <color=green>" .. worldInfo.name ..
                    " <color=yellow>" .. floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "<color>")
            end
        end

        -- No revive? Do nothing
        if group.noRevive == 1 then
            self:Remove(nListId)
            return
        end

        group.fightingScore = ceil(group.fightingScore * 0.7)
        self:_checkRank(group)

        -- Do revive? Reset and leave fight
        self:_leaveFight(nListId, 1, "die toan bo")
    end
end

function GroupFighter:ATick(nNpcIndex)
    local npcType = GetNpcParam(nNpcIndex, PARAM_NPC_TYPE)
    -- Parent
    if (npcType == 1) then
        return self:ParentTick(nNpcIndex)
    else
        return self:ChildrenTick(nNpcIndex)
    end
end

function GroupFighter:ChildrenTick(childrenIndex)
    if childrenIndex > 0 then
        local nListId = GetNpcParam(childrenIndex, PARAM_LIST_ID)
        local childID = GetNpcParam(childrenIndex, PARAM_CHILD_ID)
        local group = self.groupList["n" .. nListId]

        if not group then
            return 1
        end

        if (group.finished == 1) then
            return 0
        end

        local child = group.children[childID]

        if (group and child) then
            child.tick = child.tick + REFRESH_RATE / 18
            group.children[childID] = child
            if group.tick + 2 < child.tick then
                group.tick = child.tick
            end
            self.groupList["n" .. nListId] = group

            -- Check distance to parent
            if SearchPlayer(group.playerID) == 0 then
                if child.isDead == 0 and group.isDead == 0 then
                    local pX32, pY32, pW32 = GetNpcPos(group.finalIndex)
                    local nX32, nY32, nW32 = GetNpcPos(child.finalIndex)

                    -- Too far from each other
                    if GetDistanceRadius(nX32 / 32, nY32 / 32, pX32 / 32, pY32 / 32) > 30 then
                        if (not group.tooFarStick) then
                            group.tooFarStick = group.tick + 10
                        elseif group.tooFarStick < group.tick then
                            group.tooFarStick = nil
                            self:_respawnChild(nListId, childID, 0, "Too far for 10 seconds")
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
        local nListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
        local group = self.groupList["n" .. nListId]
        if not group then
            return 1
        end
        group.tick = group.tick + REFRESH_RATE / 18
        group.finalIndex = nNpcIndex

        if group.isFighting == 1 then
            group.fightingScore = group.fightingScore + 10
        end

        if group.isDead == 1 then
            return 0
        end

        self:moveParent(nListId)
        if group.mode == "vantieu" then
            self:CheckOwnerPos(nListId)
        end

        return 1
    end
    return 1
end

function GroupFighter:CheckOwnerPos(nListId)
    local group = self.groupList["n" .. nListId]

    local nOwnerIndex = SearchPlayer(group.ownerID)
    if not (nOwnerIndex > 0) then
        return not self:OwnerFarAway(nListId, "CheckOwnerPos1")
    end

    local nOwnerX32, nOwnerY32, nOwnerMapIndex = CallPlayerFunction(nOwnerIndex, GetPos)
    if not nOwnerX32 then
        return not self:OwnerFarAway(nListId, "CheckOwnerPos2")
    end

    local nSelfX32, nSelfY32, nSelfMapIndex = GetNpcPos(group.finalIndex)
    local nDis = ((nOwnerX32 - nSelfX32) ^ 2) + ((nOwnerY32 - nSelfY32) ^ 2)
    if nOwnerMapIndex ~= nSelfMapIndex or nDis >= 750 * 750 then
        return not self:OwnerFarAway(nListId, "CheckOwnerPos3")
    end

    self:OwnerNear(nListId, nOwnerIndex, nOwnerX32 / 32, nOwnerY32 / 32)
end

function GroupFighter:OwnerNear(nListId, nOwnerIndex, nX, nY)
    local group = self.groupList["n" .. nListId]
    local nOwnerIndex = SearchPlayer(group.ownerID)
    CallPlayerFunction(nOwnerIndex, SetFightState, 1)
    if not group.bOwnerHere then
        self:OnOwnerEnter(nListId)
        group.bOwnerHere = 1
    end
end

function GroupFighter:OnOwnerEnter(nListId)
    local group = self.groupList["n" .. nListId]
    local nOwnerIndex = SearchPlayer(group.ownerID)

    -- Save current state then lock
    group.nState_town = CallPlayerFunction(nOwnerIndex, IsDisabledUseTownP)
    KhoaTHP(nOwnerIndex, 1)
end

function GroupFighter:OwnerFarAway(nListId, reason)
    local group = self.groupList["n" .. nListId]
    if not group then
        return 1
    end
    if group.bOwnerHere then
        group.bOwnerHere = nil
        self:OnOwnerLeave(nListId)
        -- else
        -- if GetCurServerTime() - group.nPlayerLeaveTime >= 5 * 60 then
        --	local _, _, nMapIndex = GetNpcPos(self.nNpcIndex)
        --	-- do someting when owner leave for 5 minutes here
        --	return 1
        -- end
    end
end

function GroupFighter:OnOwnerLeave(nListId)
    local group = self.groupList["n" .. nListId]
    local nOwnerIndex = SearchPlayer(group.ownerID)

    local nCurTime = GetCurServerTime()
    group.nPlayerLeaveTime = nCurTime
    if nOwnerIndex > 0 then
        if group.nState_town ~= nil then
            KhoaTHP(nOwnerIndex, group.nState_town)
            group.nState_town = nil
        end
    end
end

function GroupFighter:moveParent(nListId)
    local group = self.groupList["n" .. nListId]

    local nNpcIndex = group.finalIndex

    local nX32, nY32, nW32 = GetNpcPos(nNpcIndex)
    local nW = SubWorldIdx2ID(nW32)
    local worldInfo = {}

    local pW = 0
    local pX = 0
    local pY = 0

    local myPosX = floor(nX32 / 32)
    local myPosY = floor(nY32 / 32)

    local cachNguoiChoi = 0

    -- Waiting for parent action
    if group.underAttack and group.underAttack.isConfirmation > 0 then
        return 1
    end

    -- CHAT FEATRUE - Khong dang theo sau ai het
    local worldInfo = SimCityWorld:Get(nW)
    if SearchPlayer(group.playerID) == 0 then
        -- Otherwise just Random chat
        if worldInfo.allowChat == 1 then
            if group.isFighting == 1 then
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
            local dbMsg = group.debugMsg or ""
            NpcChat(nNpcIndex, group.nNpcId)
        end
    else
        worldInfo.allowFighting = 1
        worldInfo.showFightingArea = 0
        pW, pX, pY = CallPlayerFunction(SearchPlayer(group.playerID), GetWorldPos)
        cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)
    end

    -- Is fighting? Do nothing except leave fight if possible
    if group.isFighting == 1 then
        -- Case 1: toi gio chuyen doi
        if group.canSwitchTick < group.tick then
            return self:_leaveFight(nListId, 0, "toi gio thay doi trang thai")
        end

        -- Case 2: tu dong thoat danh khi khong con ai
        if self:_leaveFightCheck(nListId, nNpcIndex) == 1 then
            -- self:_leaveFight(nListId, 0, "khong tim thay quai")
            return 1
        end

        -- Case 3: qua xa nguoi choi phai chay theo ngay
        if (SearchPlayer(group.playerID) > 0 and cachNguoiChoi > DISTANCE_FOLLOW_PLAYER) then
            group.canSwitchTick = group.tick - 1
            self:_leaveFight(nListId, 0, "chay theo nguoi choi")
        else
            return 1
        end
    end

    -- Up to here means walking
    local nNextPosId = group.nPosId
    local tbPos = group.tbPos
    local WalkSize = getn(tbPos)
    if SearchPlayer(group.playerID) == 0 and (nNextPosId == 0 or WalkSize < 2) then
        return 0
    end

    if ((SearchPlayer(group.playerID) > 0 and cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) or
            SearchPlayer(group.playerID) == 0) and (worldInfo.allowFighting == 1 or group.mode == "vantieu") and
        (group.isFighting == 0 and group.canSwitchTick < group.tick) then
        -- Case 1: someone around is fighting, we join
        if (group.underAttack and group.rebelActivated == 1 and random(0, group.underAttack.rebelChance) <= 2) then -- 1% bi tan cong moi giay
            group.rebelActivated = 2

            if group.bOwnerHere == 1 then
                CallPlayerFunction(SearchPlayer(group.ownerID), Talk, 1, "", "...!!! Ph¸t hiÖn ®¹o tÆc trµ trén!")
            end
            self:_joinFight(nListId, "fight rebel")
            return 1
        end

        -- Case 1: someone around is fighting, we join
        if (group.CHANCE_ATTACK_NPC and random(0, group.CHANCE_ATTACK_NPC) <= 2) then
            if self:_joinFightCheck(nListId, nNpcIndex) == 1 then
                return 1
            end
        end

        -- Case 2: some player around is fighting and different camp, we join
        if (group.CHANCE_ATTACK_PLAYER and random(0, group.CHANCE_ATTACK_PLAYER) <= 2) then
            if self:_joinFightPlayerCheck(nListId, nNpcIndex) == 1 then
                return 1
            end
        end

        -- Case 3: I auto switch to fight  mode
        if (SearchPlayer(group.playerID) == 0 and group.attackNpcChance and random(1, group.attackNpcChance) <= 2) then
            -- CHo nhung dua chung quanh

            local countFighting = 0

            for key, group2 in self.groupList do
                if group2.groupID ~= nListId and group2.nMapId == group.nMapId and
                    (group2.isFighting == 0 and IsAttackableCamp(group2.camp, group.camp) == 1) then
                    local otherPosX, otherPosY, otherPosW = GetNpcPos(group2.finalIndex)
                    otherPosX = floor(otherPosX / 32)
                    otherPosY = floor(otherPosY / 32)

                    local distance = floor(GetDistanceRadius(otherPosX, otherPosY, myPosX, myPosY))
                    local checkDistance = group.RADIUS_FIGHT_NPC or RADIUS_FIGHT_NPC
                    if distance < checkDistance then
                        countFighting = countFighting + 1
                        if (group2.children) then
                            countFighting = countFighting + getn(group2.children)
                        end
                        self:_joinFight(group2.groupID, "caused by others " .. distance .. " (" .. otherPosX ..
                            " " .. otherPosY .. ") (" .. myPosX .. " " .. myPosY .. ")")
                    end
                end
            end

            -- If someone is around or I am not crazy then I fight
            if countFighting > 0 or group.attackNpcChance > 1 then
                countFighting = countFighting + 1
                if (group.children) then
                    countFighting = countFighting + getn(group.children)
                end
                self:_joinFight(nListId, "I start a fight")
            end

            if SearchPlayer(group.playerID) == 0 and countFighting > 0 and
                (worldInfo.showFightingArea == 1 or group.mode == "vantieu") then
                Msg2Map(nW,
                    "Cã " .. countFighting .. " nh©n sÜ ®ang ®¸nh nhau t¹i " .. worldInfo.name ..
                    " <color=yellow>" .. floor(myPosX / 8) .. " " .. floor(myPosY / 16) .. "<color>")
            end

            if (countFighting > 0) then
                return 1
            end
        end
    end

    local arriveRes = self:_arrived(nNpcIndex, group)
    ------print(arriveRes.." "..nNextPosId)
    -- Otherwise just walk peacefully
    if SearchPlayer(group.playerID) == 0 then
        -- Mode 1: random
        if group.walkMode == "random" or group.walkMode == "keoxe" or (not group.children) then
            if arriveRes == 1 then
                -- Keep walking no stop
                if (group.noStop == 1 or random(1, 100) < 90) then
                    nNextPosId = nNextPosId + 1

                    -- End of the array
                    if nNextPosId > WalkSize then
                        if group.noBackward == 1 then
                            self:NextMap(group)
                            return 1
                        end

                        group.tbPos = arrFlip(group.tbPos)
                        nNextPosId = 1
                        group.nPosId = nNextPosId

                        self:_generateWalkPath(group, 1)
                    else
                        group.nPosId = nNextPosId
                    end

                    group.arriveTick = nil
                else
                    return 1
                end
            end

            -- Mode 2: formation
        else
            if arriveRes == 1 then
                if group.isSpinning == 0 then
                    -- Keep walking no stop
                    if (group.noStop == 1 or random(1, 100) < 90) then
                        nNextPosId = nNextPosId + 1

                        -- End of the array
                        if nNextPosId > WalkSize then
                            if group.noBackward == 1 then
                                self:NextMap(group)
                                return 1
                            end
                            local newFlipArr = {}
                            for i = 1, WalkSize do
                                tinsert(newFlipArr, group.tbPos[WalkSize - i + 1])
                            end

                            group.tbPos = newFlipArr
                            self:_generateWalkPath(group, 1)

                            nNextPosId = 2
                            group.nPosId = nNextPosId

                            self:_generateWalkPath(group, 1)
                        else
                            group.nPosId = nNextPosId
                        end
                        group.isSpinning = 1
                        group.canStartWalking = 0

                        group.arriveTick = nil
                    else
                        return 1
                    end

                    -- Is Spinning?
                elseif group.isSpinning == 1 then
                    -- Has finish spinning
                    if group.canStartWalking == 0 then
                        group.canStartWalking = group.tick + SPINNING_WAIT_TIME
                    elseif group.canStartWalking < group.tick then
                        group.canStartWalking = 0
                        group.isSpinning = 0
                    end

                    group.arriveTick = nil
                end
            end
        end

        -- Otherwise keep walking
        local targetPos = group.walkPath[nNextPosId]
        local nX = targetPos[1]
        local nY = targetPos[2]
        if group.isSpinning == 1 then
            nX = targetPos[3]
            nY = targetPos[4]
        end

        self:spawnAttack(group, nNextPosId)

        NpcWalk(nNpcIndex, nX, nY)
        local worldInfo = SimCityWorld:Get(nW)

        ------print(floor(nX/8)..","..floor(nY/16))

        if group.mode == "vantieu" and mod(group.tick, 10) == 0 and worldInfo.name then
            CallPlayerFunction(SearchPlayer(group.ownerID), Msg2Player,
                "Täa ®é hiÖn t¹i cña xe tiªu lµ <color=green>" .. worldInfo.name .. " <color=yellow>" ..
                floor(nX / 8) .. "," .. floor(nY / 16))
        end

        self:_walk_children(group, nNextPosId)
    else
        -- Walk toward parent

        -- Player has gone different map? Do respawn
        local needRespawn = 0
        if group.nMapId ~= pW then
            needRespawn = 1
        else
            if cachNguoiChoi > DISTANCE_FOLLOW_PLAYER_TOOFAR then
                needRespawn = 1
            end
        end

        if needRespawn == 1 then
            group.nMapId = pW
            group.isFighting = 0
            group.canSwitchTick = group.tick
            group.tbPos = { { pX, pY } }
            group.nPosId = 1
            self:_generateWalkPath(group, 0)
            self:_respawn(group.groupID, 2, "keo xe qua map khac")
            return 1
        end

        self:spawnAttack(group, nNextPosId)

        -- Otherwise walk toward parent
        NpcWalk(nNpcIndex, pX + random(-2, 2), pY + random(-2, 2))

        local nX32, nY32 = GetNpcPos(nNpcIndex)
        local nX = nX32 / 32;
        local nY = nY32 / 32;

        local worldInfo = SimCityWorld:Get(nW)
        if group.mode == "vantieu" and mod(group.tick, 10) == 0 and worldInfo.name then
            CallPlayerFunction(SearchPlayer(group.ownerID), Msg2Player,
                "Täa ®é hiÖn t¹i cña xe tiªu lµ <color=green>" .. worldInfo.name .. " <color=yellow>" ..
                floor(nX / 8) .. "," .. floor(nY / 16))
        end

        -- Walk children as
        if group.children then
            local N = getn(group.children)

            -- Exact param of parent is given
            for i = 1, N do
                local child = group.children[i]
                if (child.finalIndex) then
                    NpcWalk(child.finalIndex, pX + random(-2, 2), pY + random(-2, 2))
                end
            end
        end
    end
    return 1
end

function GroupFighter:spawnAttack(group, nNextPosId)
    -- By locations
    if group.underAttack and group.underAttack.locations and group.underAttack.locations["n" .. nNextPosId] then
        self:triggerUnderAttack(group, group.underAttack.locations["n" .. nNextPosId])
        group.underAttack.locations["n" .. nNextPosId] = nil
    end
end

function GroupFighter:triggerUnderAttack(group, attackType)
    group.underAttack.isConfirmation = attackType

    -- 0: theo sau choi 1: theo sau va cuop 2: cuop truc tiep
    local tbSay = {}
    if attackType == 0 or attackType == 1 then
        tinsert(tbSay,
            "(Nhãm ng­êi l¹)\n\n\nCòng lµ bÌo n­íc gÆp nhau n¬i nguy hiÓm nµy. ¢u còng lµ duyªn phËn, xin cho chóng ta cïng theo c¸c h¹!")
        CallPlayerFunction(SearchPlayer(group.ownerID), Msg2Player,
            "Cã 1 vµi nh©n vËt kh¶ nghi ®ang ®i theo chóng ta")
    end

    if attackType == 2 then
        tinsert(tbSay, "(Nhãm ng­êi l¹)\n\n\n§­êng nµy do ta më! Ai cho c¸c ng­¬i vµo?")
    end

    if attackType == 3 then
        tinsert(tbSay, "...\n\n\nXung quanh ®©y thËt kh¶ nghi...")
    end

    tinsert(tbSay, "KÕt thóc ®èi tho¹i/#GroupFighter:confirmAttack(" .. group.groupID .. ")")

    if group.bOwnerHere == 1 then
        CallPlayerFunction(SearchPlayer(group.ownerID), CreateTaskSay, tbSay)
    end
end

function GroupFighter:confirmAttack(nListId)
    local group = self.groupList["n" .. nListId]

    if not group then
        return 1
    end

    local attackType = group.underAttack.isConfirmation
    group.underAttack.isConfirmation = 0

    -- Add attackers?
    if attackType == 0 or attackType == 1 or attackType == 2 then
        local attackers = {}
        local totalN = random(1, 6)
        local pool = group.underAttack.attackerIds
        local current = getn(group.children)
        local tobeCreated = {}
        for i = 1, totalN do
            local attacker = {}
            attacker.szName = SimCityPlayerName:getName()
            attacker.rebel = attackType + 1
            if attackType == 0 then
                attacker.nNpcId = 682
            else
                attacker.nNpcId = pool[random(1, getn(pool))]
            end
            attacker.ngoaitrang = 1
            tinsert(group.children, attacker)
            current = current + 1
            tinsert(tobeCreated, current)
        end

        -- Has attacker enabled
        if attackType == 1 then
            group.rebelActivated = 1 -- fight randomly
        end
        if attackType == 2 then
            group.rebelActivated = 2 -- fight instantly
        end

        -- Reset pos
        self:HardResetPos(group)
        -- group.nPosId = group.nPosId - 1

        -- Create new char
        for i = 1, getn(tobeCreated) do
            self:_respawnChild(nListId, tobeCreated[i], 2, "them nhan vat theo sau")
        end
    end

    ------print("TRIGGER ATTACK: "..attackType)
end

function GroupFighter:NextMap(group)
    if group.mode ~= "vantieu" then
        return 1
    end

    local pW = 0
    local found = 0
    local mapData = group.mapData
    for i = 1, getn(mapData) do
        local dataPoint = mapData[i]
        if (dataPoint[1] == group.nMapId) then
            found = 1
        end
        if (found == 1 and pW == 0 and dataPoint[1] ~= group.nMapId) then
            pW = dataPoint[1]
        end
    end

    if pW == 0 then
        self:FINISH(group, 1, "success")
        CallPlayerFunction(SearchPlayer(group.ownerID), Msg2Player, "Tiªu xa ®· ®Õn ®Ých")
        return 1
    end

    -- Player has gone different map? Do respawn
    local needRespawn = 1
    group.nMapId = pW
    group.isFighting = 0
    group.canSwitchTick = group.tick
    CallPlayerFunction(SearchPlayer(group.ownerID), Msg2Player, "Tiªu xa ®· chuyÓn qua map")
    self:_respawn(group.groupID, 2, "keo xe qua map khac")
    return 1
end

function GroupFighter:OnPlayerLeaveMap()
    local szName = GetName()
    if not szName then
        return
    end
    local groupID = self.ownerID2List[szName]
    if groupID ~= nil and groupID > 0 then
        self:OwnerFarAway(groupID, "onPlayerLeaveMap")
    end
end

function _sortByScore(tb1, tb2)
    return tb1[2] > tb2[2]
end

function GroupFighter:ThongBaoBXH(nW)
    -- Collect all data
    local allPlayers = {}
    for i, group in self.groupList do
        if group.nMapId == nW then
            tinsert(allPlayers, { i, group.fightingScore, "npc" })
        end
    end

    if (SimCityTongKim.playerInTK and SimCityTongKim.playerInTK[nW]) then
        for pId, data in SimCityTongKim.playerInTK[nW] do
            tinsert(allPlayers, { pId, data.score, "player" })
        end
    end

    if getn(allPlayers) > 1 then
        local maxIndex = getn(allPlayers)
        if maxIndex > 10 then
            maxIndex = 10
        end

        sort(allPlayers, _sortByScore)

        Msg2Map(nW, "<color=yellow>========= B¶NG XÕP H¹NG =========<color>")
        Msg2Map(nW, "<color=yellow>=================================<color>")

        for j = 1, maxIndex do
            local info = allPlayers[j]

            if info[3] == "npc" then
                local group = self.groupList[info[1]]
                if group then
                    local phe = ""

                    if (group.tongkim == 1) then
                        if (group.tongkim_name) then
                            phe = group.tongkim_name
                        else
                            phe = "Kim"
                            if group.camp == 1 then
                                phe = "Tèng"
                            end
                        end
                    end

                    if phe == "Kim" then
                        phe = "K"
                    else
                        phe = "T"
                    end

                    local msg = "<color=white>" .. j .. " <color=yellow>[" .. phe .. "] " ..
                        SimCityTongKim.RANKS[group.rank] .. " <color>" ..
                        (group.hardsetName or SimCityNPCInfo:getName(group.nNpcId)) .. "<color=white> (" ..
                        allPlayers[j][2] .. ")<color>"
                    Msg2Map(nW, msg)
                end
            else
                local tbPlayer = SimCityTongKim.playerInTK[nW][info[1]]
                local msg = "<color=white>" .. j .. " <color=red>[" .. (tbPlayer.phe) .. "] " .. (tbPlayer.rank) ..
                    " <color>" .. (tbPlayer.name) .. "<color=white> (" .. (tbPlayer.score) .. ")<color>"
                Msg2Map(nW, msg)
            end
        end
        Msg2Map(nW, "<color=yellow>=================================<color>")
    end
end

EventSys:GetType("LeaveMap"):Reg("ALL", GroupFighter.OnPlayerLeaveMap, GroupFighter)
-- EventSys:GetType("EnterMap"):Reg("ALL", GroupFighter.OnPlayerEnterMap, GroupFighter)
