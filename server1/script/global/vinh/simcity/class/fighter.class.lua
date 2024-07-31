Include("\\script\\global\\vinh\\simcity\\config.lua")
IncludeLib("NPCINFO")
NpcFighter = {}



function NpcFighter:New(fighter)
    -- Copy over the method to be used
    for k, v in self do
        fighter[k] = v
    end

    -- Setup walk paths
    if fighter:HardResetPos() == 0 then
        return nil
    end

    -- Set NPC life
    if self.cap and self.cap < 2 and not self.lastHP then
        self.maxHP = SimCityNPCInfo:getHPByCap(self.cap)
    end

    -- Create the character on screen
    fighter:Show(1)
    return fighter
end

function NpcFighter:Remove()
    DelNpcSafe(self.finalIndex)
end

function NpcFighter:Show(isNew, goX, goY)
    local originalWalkPath = self.originalWalkPath
    local nPosId = self.hardsetPos

    if (not nPosId) or (not originalWalkPath[nPosId]) then
        nPosId = random(1, getn(originalWalkPath))
    end

    local nMapIndex = SubWorldID2Idx(self.nMapId)

    if nMapIndex >= 0 then
        local nNpcIndex

        local tX = self.walkPath[nPosId][1]
        local tY = self.walkPath[nPosId][2]

        if goX and goY and goX > 0 and goY > 0 then
            tX = goX
            tY = goY
        end

        local name = self.szName or SimCityNPCInfo:getName(self.nNpcId)

        if (self.tongkim == 1) then
            if (self.tongkim_name) then
                name = self.tongkim_name
            else
                name = "Kim"
                if self.camp == 1 then
                    name = "TËng"
                end
            end
            name = name .. " " .. SimCityTongKim.RANKS[self.rank]
        end

        if (self.hardsetName) then
            name = self.hardsetName
        end

        nNpcIndex = AddNpcEx(self.nNpcId, 95, self.series, nMapIndex, tX * 32, tY * 32, 1, name, 0)

        if nNpcIndex > 0 then
            local kind = GetNpcKind(nNpcIndex)
            if kind ~= 0 then
                DelNpcSafe(nNpcIndex)
            else
                self.szName = GetNpcName(nNpcIndex)
                self.finalIndex = nNpcIndex
                self.isDead = 0
                self.lastPos = {
                    nX32 = tX * 32,
                    nY32 = tY * 32,
                    nPosId = nPosId
                }

                -- Otherwise choose side
                SetNpcCurCamp(nNpcIndex, self.camp)

                local nPosCount = getn(originalWalkPath)
                if nPosCount >= 1 then
                    SetNpcActiveRegion(nNpcIndex, 1)
                    self.nPosId = nPosId
                end
                if nPosCount >= 1 or self.nSkillId then
                    SetNpcParam(nNpcIndex, PARAM_LIST_ID, self.id)
                    SetNpcParam(nNpcIndex, PARAM_PLAYER_ID, SearchPlayer(self.playerID))
                    SetNpcParam(nNpcIndex, PARAM_NPC_TYPE, 1)
                    SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\timer.lua")
                    SetNpcTimer(nNpcIndex, REFRESH_RATE)
                end

                -- Ngoai trang?
                if (self.ngoaitrang and self.ngoaitrang == 1) then
                    SimCityNgoaiTrang:makeup(self, nNpcIndex)
                end


                -- Disable fighting?
                if (self.isFighting == 0) then
                    SetNpcKind(nNpcIndex, self.kind or 4)
                    self:SetFightState(0)
                end

                -- Set NPC MAX life
                if self.maxHP then
                    NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, self.maxHP)
                end

                -- Life?
                if self.lastHP then
                    NPCINFO_SetNpcCurrentLife(nNpcIndex, self.lastHP)
                elseif self.maxHP then
                    NPCINFO_SetNpcCurrentLife(nNpcIndex, self.maxHP)
                end
                return self.id
            end
        end

        return 0
    end
    return 0
end

function NpcFighter:Respawn(code, reason)
    -- code: 0: con nv con song 1: da chet toan bo 2: keo xe qua map khac 3: chuyen sang chien dau
    --print("RESPAWN " .. code .. " " .. reason)
    -- CallPlayerFunction(1, Msg2Player, "Respawn: "..reason)


    local isAllDead = code == 1 and 1 or 0

    local nX, nY, nMapIndex = GetNpcPos(self.finalIndex)

    -- Do calculation
    nX = nX / 32
    nY = nY / 32

    -- 2 = qua map khac?
    if (code == 2) then
        nX = 0
        nY = 0
        self.nPosId = 1
        self:HardResetPos()

        -- otherwise reset
    elseif isAllDead == 1 and SearchPlayer(self.playerID) > 0 then
        nX = self.walkPath[1][1]
        nY = self.walkPath[1][2]
        self.nPosId = 1
    elseif (isAllDead == 1 and self.resetPosWhenRevive and self.resetPosWhenRevive >= 1) then
        nX = self.walkPath[self.resetPosWhenRevive][1]
        nY = self.walkPath[self.resetPosWhenRevive][2]
        self.nPosId = self.resetPosWhenRevive
        self:HardResetPos()
    elseif (isAllDead == 1 and self.lastPos ~= nil) then
        nX = self.lastPos.nX32 / 32
        nY = self.lastPos.nY32 / 32
        self.nPosId = self.lastPos.nPosId
    else
        self.lastPos = {
            nX32 = nX,
            nY32 = nY,
            nPosId = self.nPosId
        }
    end

    self.hardsetPos = self.nPosId
    self.arriveTick = nil
    self.lastHP = NPCINFO_GetNpcCurrentLife(self.finalIndex)
    if (isAllDead == 1) then
        self.lastHP = nil
    end


    -- Normal respawn ? Can del NPC
    DelNpcSafe(self.finalIndex)

    self:Show(0, nX, nY)
end

function NpcFighter:IsNpcEnemyAround()
    local allNpcs = {}
    local nCount = 0
    local radius = self.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN
    -- Keo xe?
    if SearchPlayer(self.playerID) > 0 then
        allNpcs, nCount = CallPlayerFunction(SearchPlayer(self.playerID), GetAroundNpcList, radius)
        for i = 1, nCount do
            local fighter2Kind = GetNpcKind(allNpcs[i])
            local fighter2Camp = GetNpcCurCamp(allNpcs[i])
            if fighter2Kind == 0 and (IsAttackableCamp(self.camp, fighter2Camp) == 1) then
                return 1
            end
        end
        return 0
    end

    -- Thanh thi / tong kim / chien loan
    allNpcs, nCount = Simcity_GetNpcAroundNpcList(self.finalIndex, radius)
    for i = 1, nCount do
        local fighter2Kind = GetNpcKind(allNpcs[i])
        local fighter2Camp = GetNpcCurCamp(allNpcs[i])
        if fighter2Kind == 0 and (IsAttackableCamp(self.camp, fighter2Camp) == 1) then
            return 1
        end
    end

    return 0
end

function NpcFighter:IsPlayerEnemyAround()
    -- FIGHT other player
    if GetNpcAroundPlayerList then
        local allNpcs, nCount = GetNpcAroundPlayerList(self.finalIndex, self.RADIUS_FIGHT_PLAYER or RADIUS_FIGHT_PLAYER)
        for i = 1, nCount do
            if ((self.ownerID == nil or allNpcs[i] ~= SearchPlayer(self.ownerID)) and
                    CallPlayerFunction(allNpcs[i], GetFightState) == 1 and
                    IsAttackableCamp(CallPlayerFunction(allNpcs[i], GetCurCamp), self.camp) == 1 and
                    self.camp ~= 0) then
                return 1
            end
        end
    end
    return 0
end

function NpcFighter:JoinFight(reason)
    self.isFighting = 1
    self.canSwitchTick = self.tick +
        random(self.TIME_FIGHTING_minTs or TIME_FIGHTING.minTs,
            self.TIME_FIGHTING_maxTs or TIME_FIGHTING.maxTs) -- trong trang thai pk 1 toi 2ph

    reason = reason or "no reason"

    local currX, currY, currW = GetNpcPos(self.finalIndex)
    currX = floor(currX / 32)
    currY = floor(currY / 32)

    -- If already having last fight pos, we may simply chance AI to 1
    if self.lastFightPos then
        local lastPos = self.lastFightPos
        if lastPos.W == currW then
            if (GetDistanceRadius(lastPos.X, lastPos.Y, currX, currY) < DISTANCE_VISION) then
                self:SetFightState(9)
                return 1
            end
        end
    end

    -- Otherwise save it and respawn
    self.lastFightPos = {
        X = currX,
        Y = currY,
        W = currW
    }

    self:Respawn(3, "JoinFight " .. reason)

    return 1
end

function NpcFighter:LeaveFight(isAllDead, reason)
    isAllDead = isAllDead or 0

    self.isFighting = 0
    self.canSwitchTick = self.tick +
        random(self.TIME_RESTING_minTs or TIME_RESTING.minTs,
            self.TIME_RESTING_maxTs or TIME_RESTING.maxTs) -- trong trang thai di bo 30s-1ph
    reason = reason or "no reason"

    -- Do not need to respawn just disable fighting
    if (isAllDead ~= 1 and self.kind ~= 4) then
        self:Walk2ClosestPoint()
        self:SetFightState(0)
    else
        self:Respawn(isAllDead, reason)
    end
end

function NpcFighter:CanLeaveFight()
    if self.isDead == 1 then
        return 0
    end

    -- No attacker around including NPC and Player ? Stop
    if (self:IsNpcEnemyAround() == 0 and
            self:IsPlayerEnemyAround() == 0) then
        if (self.leaveFightWhenNoEnemy and self.leaveFightWhenNoEnemy > 0) then
            local targetTick = self.tick + self.leaveFightWhenNoEnemy - 1

            if self.canSwitchTick > targetTick then
                self.canSwitchTick = targetTick
            end
        end

        return 1
    end
    return 0
end

function NpcFighter:SetFightState(mode)
    SetNpcAI(self.finalIndex, mode)
end

function NpcFighter:TriggerFightWithNPC()
    if (self:IsNpcEnemyAround() == 1) then
        return self:JoinFight("enemy around")
    end
    return 0
end

function NpcFighter:TriggerFightWithPlayer()
    -- FIGHT other player
    if GetNpcAroundPlayerList then
        if self:IsPlayerEnemyAround() == 1 then
            local nW = self.nMapId
            if SearchPlayer(self.playerID) == 0 then
                local worldInfo = SimCityWorld:Get(nW)
                if worldInfo.showFightingArea == 1 then
                    local name = GetNpcName(self.finalIndex)
                    local lastPos = self.originalWalkPath[self.nPosId]


                    Msg2Map(self.nMapId,
                        "<color=white>" .. name .. "<color> Æ∏nh ng≠Íi tπi " .. worldInfo.name .. " " ..
                        floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "")
                end
            end
            return self:JoinFight("player around")
        end
    end

    return 0
end

function NpcFighter:HasArrived()
    local posIndex = self.nPosId
    local parentPos = self.walkPath[posIndex]

    local nX32, nY32 = GetNpcPos(self.finalIndex)
    local oX = nX32 / 32;
    local oY = nY32 / 32;

    local isExact = self.originalWalkPath[posIndex][3]
    local nX = parentPos[1]
    local nY = parentPos[2]

    local checkDistance = DISTANCE_CAN_CONTINUE

    if self.isSpinning == 1 then
        nX = parentPos[3]
        nY = parentPos[4]
        checkDistance = DISTANCE_CAN_SPIN
    end

    if isExact == 1 then
        nX = self.originalWalkPath[posIndex][1]
        nY = self.originalWalkPath[posIndex][2]
    end

    local distance = GetDistanceRadius(nX, nY, oX, oY)

    if distance < checkDistance then
        return 1
    end
    return 0
end

function NpcFighter:Walk2ClosestPoint()
    local currPointer = self.nPosId
    local closestPointer = -1
    local closestDistance = 99999
    local maxPointer = getn(self.originalWalkPath)
    local pX, pY, _ = GetNpcPos(self.finalIndex)
    pX = pX / 32
    pY = pY / 32

    local tmp
    for i = currPointer - 5, currPointer + 5 do
        if (i > 0 and i <= maxPointer) then
            tmp = GetDistanceRadius(pX, pY, self.originalWalkPath[i][1], self.originalWalkPath[i][2])
            if (tmp < closestDistance) then
                closestDistance = tmp
                closestPointer = i
            end
        end
    end

    if closestPointer ~= -1 then
        self.nPosId = closestPointer
    end
end

function NpcFighter:GenWalkPath(hasJustBeenFlipped)
    -- Generate walkpath for myself
    local WalkSize = getn(self.originalWalkPath)
    self.walkPath = {}
    for i = 1, WalkSize do
        local point = self.originalWalkPath[i]
        if hasJustBeenFlipped == 0 then
            tinsert(self.walkPath, randomRange(point, self.walkVar or 2))
        else
            tinsert(self.walkPath, randomRange(point, 0))
        end
    end
end

function NpcFighter:HardResetPos()
    local nW = self.nMapId
    local worldInfo = {}
    local walkAreas = {}

    -- Co duong di bao gom map
    if self.mapData then
        local mapData = self.mapData
        for i = 1, getn(mapData) do
            local dataPoint = mapData[i]
            if (dataPoint[1] == nW) then
                tinsert(walkAreas, { dataPoint[2], dataPoint[3] })
            end
        end
        self.originalWalkPath = arrCopy(walkAreas)
    else
        -- Dang theo sau thi lay dia diem cua nguoi choi
        if SearchPlayer(self.playerID) > 0 then
            local pW, pX, pY = CallPlayerFunction(SearchPlayer(self.playerID), GetWorldPos)
            worldInfo.showName = 1
            self.originalWalkPath = { { pX, pY } }
            self.nPosId = 1
            walkAreas = { { { pX, pY } } }
            -- --print("DONE "..pX.." "..pY)
            -- hoac la sim thanh thi di tum lum
        else
            if not self.originalWalkPath then
                worldInfo = SimCityWorld:Get(nW)
                walkAreas = worldInfo.walkAreas
                if not walkAreas then
                    return 0
                end
                local walkIndex = random(1, getn(walkAreas))
                self.originalWalkPath = arrCopy(walkAreas[walkIndex])

                -- Trong thanh thi co the random di nguoc chieu
                if self.mode == "thanhthi" and random(1, 2) < 2 then
                    self.originalWalkPath = arrFlip(self.originalWalkPath)
                end


                self.hardsetPos = random(1, getn(self.originalWalkPath))
            end
        end
    end

    -- No path to walk?
    if not self.originalWalkPath or getn(self.originalWalkPath) < 1 then
        return 0
    end

    -- Init stats
    self.isSpinning = 0
    self.lastOffSetAngle = 0

    -- Startup position
    self.hardsetPos = self.hardsetPos or random(1, getn(self.originalWalkPath))

    -- Calculate walk path for main
    self:GenWalkPath(0)
end

function NpcFighter:NextMap()
    return 1
end

function NpcFighter:Breath()
    local nX32, nY32, nW32 = GetNpcPos(self.finalIndex)
    local nW = SubWorldIdx2ID(nW32)
    local worldInfo = {}

    local pW = 0
    local pX = 0
    local pY = 0

    local myPosX = floor(nX32 / 32)
    local myPosY = floor(nY32 / 32)

    local cachNguoiChoi = 0


    -- CHAT FEATRUE - Khong dang theo sau ai het
    worldInfo = SimCityWorld:Get(nW)
    if SearchPlayer(self.playerID) == 0 then
        -- Otherwise just Random chat
        if worldInfo.allowChat == 1 then
            if self.isFighting == 1 then
                if random(1, CHANCE_CHAT / 2) <= 2 then
                    NpcChat(self.finalIndex, SimCityChat:getChatFight())
                end
            else
                if random(1, CHANCE_CHAT) <= 2 then
                    NpcChat(self.finalIndex, SimCityChat:getChat())
                end
            end
        end

        -- Show my ID
        if (worldInfo.showingId == 1) then
            local dbMsg = self.debugMsg or ""
            NpcChat(self.finalIndex, self.nNpcId)
        end
    else
        worldInfo.allowFighting = 1
        worldInfo.showFightingArea = 0
        pW, pX, pY = CallPlayerFunction(SearchPlayer(self.playerID), GetWorldPos)
        cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)
    end

    -- Is fighting? Do nothing except leave fight if possible
    if self.isFighting == 1 then
        -- Case 1: toi gio chuyen doi
        if self.canSwitchTick < self.tick then
            return self:LeaveFight(0, "toi gio thay doi trang thai")
        end

        -- Case 2: tu dong thoat danh khi khong con ai
        if self:CanLeaveFight() == 1 then
            -- self:LeaveFight(0, "khong tim thay quai")
            return 1
        end

        -- Case 3: qua xa nguoi choi phai chay theo ngay
        if (SearchPlayer(self.playerID) > 0 and cachNguoiChoi > DISTANCE_FOLLOW_PLAYER) then
            self.canSwitchTick = self.tick - 1
            self:LeaveFight(0, "chay theo nguoi choi")
        else
            return 1
        end
    end

    -- Up to here means walking
    local nNextPosId = self.nPosId
    local originalWalkPath = self.originalWalkPath
    local WalkSize = getn(originalWalkPath)
    if SearchPlayer(self.playerID) == 0 and (nNextPosId == 0 or WalkSize < 2) then
        return 0
    end

    if ((SearchPlayer(self.playerID) > 0 and cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) or
            SearchPlayer(self.playerID) == 0) and (worldInfo.allowFighting == 1 or self.mode == "vantieu") and
        (self.isFighting == 0 and self.canSwitchTick < self.tick) then
        -- Case 1: someone around is fighting, we join
        if (self.CHANCE_ATTACK_NPC and random(0, self.CHANCE_ATTACK_NPC) <= 2) then
            if self:TriggerFightWithNPC() == 1 then
                return 1
            end
        end

        -- Case 2: some player around is fighting and different camp, we join
        if (self.CHANCE_ATTACK_PLAYER and random(0, self.CHANCE_ATTACK_PLAYER) <= 2) then
            if self:TriggerFightWithPlayer() == 1 then
                return 1
            end
        end

        -- Case 3: I auto switch to fight  mode
        if (SearchPlayer(self.playerID) == 0 and self.attackNpcChance and random(1, self.attackNpcChance) <= 2) then
            -- CHo nhung dua chung quanh

            local countFighting = 0

            for key, fighter2 in FighterManager.fighterList do
                if fighter2.id ~= self.id and fighter2.nMapId == self.nMapId and
                    (fighter2.isFighting == 0 and IsAttackableCamp(fighter2.camp, self.camp) == 1) then
                    local otherPosX, otherPosY, otherPosW = GetNpcPos(fighter2.finalIndex)
                    otherPosX = floor(otherPosX / 32)
                    otherPosY = floor(otherPosY / 32)

                    local distance = floor(GetDistanceRadius(otherPosX, otherPosY, myPosX, myPosY))
                    local checkDistance = self.RADIUS_FIGHT_NPC or RADIUS_FIGHT_NPC
                    if distance < checkDistance then
                        countFighting = countFighting + 1
                        FighterManager:Get(fighter2.id):JoinFight("caused by others " ..
                            distance .. " (" .. otherPosX ..
                            " " .. otherPosY .. ") (" .. myPosX .. " " .. myPosY .. ")")
                    end
                end
            end

            -- If someone is around or I am not crazy then I fight
            if countFighting > 0 or self.attackNpcChance > 1 then
                countFighting = countFighting + 1
                self:JoinFight("I start a fight")
            end

            if SearchPlayer(self.playerID) == 0 and countFighting > 0 and
                (worldInfo.showFightingArea == 1 or self.mode == "vantieu") then
                Msg2Map(nW,
                    "C„ " .. countFighting .. " nh©n s‹ Æang Æ∏nh nhau tπi " .. worldInfo.name ..
                    " <color=yellow>" .. floor(myPosX / 8) .. " " .. floor(myPosY / 16) .. "<color>")
            end

            if (countFighting > 0) then
                return 1
            end
        end
    end


    if SearchPlayer(self.playerID) == 0 then
        -- Mode 1: randomwork

        if self:HasArrived() == 1 then
            -- Keep walking no stop
            if (self.noStop == 1 or random(1, 100) < 90) then
                nNextPosId = nNextPosId + 1

                -- End of the array
                if nNextPosId > WalkSize then
                    if self.noBackward == 1 then
                        self:NextMap()
                        return 1
                    end

                    self.originalWalkPath = arrFlip(self.originalWalkPath)
                    nNextPosId = 1
                    self.nPosId = nNextPosId

                    self:GenWalkPath(1)
                else
                    self.nPosId = nNextPosId
                end

                self.arriveTick = nil
            else
                return 1
            end
        end

        local targetPos = self.walkPath[nNextPosId]
        local nX = targetPos[1]
        local nY = targetPos[2]
        if self.isSpinning == 1 then
            nX = targetPos[3]
            nY = targetPos[4]
        end

        NpcWalk(self.finalIndex, nX, nY)
    else
        -- Mode 2: follow parent player
        -- Player has gone different map? Do respawn
        local needRespawn = 0
        if self.nMapId ~= pW then
            needRespawn = 1
        else
            if cachNguoiChoi > DISTANCE_FOLLOW_PLAYER_TOOFAR then
                needRespawn = 1
            end
        end

        if needRespawn == 1 then
            self.nMapId = pW
            self.isFighting = 0
            self.canSwitchTick = self.tick
            self.originalWalkPath = { { pX, pY } }
            self.nPosId = 1
            self:GenWalkPath(0)
            self:Respawn(2, "keo xe qua map khac")
            return 1
        end


        -- Otherwise walk toward parent
        NpcWalk(self.finalIndex, pX + random(-2, 2), pY + random(-2, 2))
    end
    return 1
end

function NpcFighter:OnTimer()
    self.tick = self.tick + REFRESH_RATE / 18
    if self.isFighting == 1 then
        self.fightingScore = self.fightingScore + 10
    end

    if self.isDead == 1 then
        return 0
    end

    self:Breath()

    return 1
end

function NpcFighter:OnDeath()
    self.isDead = 1
    self.finalIndex = nil

    local doRespawn = 0

    if self.isFighting == 1 and self.tick > self.canSwitchTick then
        doRespawn = 1
    end

    -- Is every one dead?
    if (doRespawn == 1 or self.isDead == 1) then
        local nW = self.nMapId
        local lastPos = self.originalWalkPath[self.nPosId]

        local worldInfo = SimCityWorld:Get(nW)

        if self.mode == "vantieu" and worldInfo.name then
            Msg2Map(nW,
                "<color=white>" ..
                self.szName .. "<color> hoµn toµn bﬁ c≠Ìp tπi <color=green>" .. worldInfo.name ..
                " <color=yellow>" .. floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "<color>")
        end


        self.fightingScore = ceil(self.fightingScore * 0.7)
        SimCityTongKim:updateRank(self)


        -- No revive? Do removal
        if self.noRevive == 1 then
            FighterManager:Remove(self.id)
            return
        end

        -- Do revive? Reset and leave fight
        self:LeaveFight(1, "die toan bo")
    end
end
