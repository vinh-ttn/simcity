Include("\\script\\global\\vinh\\simcity\\config.lua")
IncludeLib("NPCINFO")
NpcFighter = {}



function NpcFighter:New(fighter)
    fighter.children = nil
    fighter.originalConfig = objCopy(fighter)


    -- Copy over the method to be used
    for k, v in self do
        fighter[k] = v
    end

    -- Setup walk paths
    if fighter:HardResetPos() == 0 then
        return nil
    end

    -- Bugfix series
    fighter.series = SimCityNPCInfo:GetSeries(fighter.nNpcId)

    -- Create the character on screen
    fighter:Show(1, fighter.goX, fighter.goY)


    -- What about childrenSetup?
    fighter:SetupChildren()
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

        if self.role == "child" then
            local pW, pX, pY = self:GetParentPos()
            tX = pX
            tY = pY
        end

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

        nNpcIndex = AddNpcEx(self.nNpcId, self.level, self.series, nMapIndex, tX * 32, tY * 32, 1, name, 0)

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
                    SetNpcParam(nNpcIndex, PARAM_LIST_ID, self.id)
                    SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\fighter.timer.lua")
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
    -- code: 0: con nv con song 1: da chet toan bo 2: keo xe qua map khac 3: chuyen sang chien dau 4: bi lag dung 1 cho nay gio ko di duoc
    -- print(self.role .. ": respawn " .. code .. " " .. reason)


    local isAllDead = code == 1 and 1 or 0

    local nX, nY, nMapIndex = GetNpcPos(self.finalIndex)

    -- Do calculation
    nX = nX / 32
    nY = nY / 32

    -- 3 = bi lag? tim cho khac hien len nao
    if code == 4 then
        nX = 0
        nY = 0
        self.nPosId = random(1, getn(self.originalWalkPath))
        self:HardResetPos()

        -- 2 = qua map khac?
    elseif code == 2 then
        nX = 0
        nY = 0
        self.nPosId = 1
        self:HardResetPos()

        -- otherwise reset
    elseif isAllDead == 1 and (self.role == "keoxe" or self.role == "child") then
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
    self.tick_checklag = nil
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
    if self.role == "keoxe" then
        allNpcs, nCount = CallPlayerFunction(self:GetPlayer(), GetAroundNpcList, radius)
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
            if (CallPlayerFunction(allNpcs[i], GetFightState) == 1 and
                    IsAttackableCamp(CallPlayerFunction(allNpcs[i], GetCurCamp), self.camp) == 1 and
                    self.camp ~= 0) then
                return 1
            end
        end
    end
    return 0
end

function NpcFighter:JoinFight(reason)
    self:ChildrenJoinFight(reason)
    self.isFighting = 1
    self.tick_canswitch = self.tick_breath +
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
    self:ChildrenLeaveFight(isAllDead, reason)

    isAllDead = isAllDead or 0

    self.isFighting = 0
    self.tick_canswitch = self.tick_breath +
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
            local realCanSwitchTick = self.tick_breath + self.leaveFightWhenNoEnemy - 1

            if self.tick_canswitch > realCanSwitchTick then
                self.tick_canswitch = realCanSwitchTick
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
            if self.role == "citizen" then
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
    local nX32, nY32 = GetNpcPos(self.finalIndex)
    local oX = nX32 / 32;
    local oY = nY32 / 32;

    local nX
    local nY
    local checkDistance = DISTANCE_CAN_CONTINUE

    if self.role == "child" then
        nX = self.parentAppointPos and self.parentAppointPos[1] or 0
        nY = self.parentAppointPos and self.parentAppointPos[2] or 0

        if not nX or not nY or nX == 0 or nY == 0 then
            return 0
        end
    else
        local posIndex = self.nPosId
        local parentPos = self.walkPath[posIndex]

        local isExact = self.originalWalkPath[posIndex][3]
        nX = parentPos[1]
        nY = parentPos[2]
        if isExact == 1 then
            nX = self.originalWalkPath[posIndex][1]
            nY = self.originalWalkPath[posIndex][2]
        end
    end

    local distance = GetDistanceRadius(nX, nY, oX, oY)

    if distance < checkDistance then
        return self:ChildrenArrived()
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
            tinsert(self.walkPath, randomRange(point, self.walkVar or 2))
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
        -- Dang di theo sau npc khac
        if self.role == "child" then
            local pW, pX, pY = self:GetParentPos()
            self.originalWalkPath = { { pX, pY } }
            self.nPosId = 1
            walkAreas = { { { pX, pY } } }

            -- Dang theo sau thi lay dia diem cua nguoi choi
        elseif self.role == "keoxe" then
            local pW, pX, pY = CallPlayerFunction(self:GetPlayer(), GetWorldPos)
            worldInfo.showName = 1
            self.originalWalkPath = { { pX, pY } }
            self.nPosId = 1
            walkAreas = { { { pX, pY } } }

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

    -- Di 1 minh
    if self.role == "citizen" then
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
            NpcChat(self.finalIndex, self.id .. " " .. self.nNpcId)
        end
    elseif self.role == "child" then
        pW, pX, pY = self:GetParentPos()
        cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)
        if self:IsParentFighting() == 1 and self.isFighting == 0 then
            return self:JoinFight("parent dang danh nhau")
        end
    elseif self.role == "keoxe" then
        worldInfo.allowFighting = 1
        worldInfo.showFightingArea = 0
        pW, pX, pY = CallPlayerFunction(self:GetPlayer(), GetWorldPos)
        cachNguoiChoi = GetDistanceRadius(myPosX, myPosY, pX, pY)
    end

    -- Is fighting? Do nothing except leave fight if possible
    if self.isFighting == 1 then
        -- Case 1: toi gio chuyen doi
        if self.tick_canswitch < self.tick_breath then
            return self:LeaveFight(0, "toi gio thay doi trang thai")
        end

        -- Case 2: tu dong thoat danh khi khong con ai
        if self:CanLeaveFight() == 1 then
            -- self:LeaveFight(0, "khong tim thay quai")
            return 1
        end

        -- Case 3: qua xa nguoi choi phai chay theo ngay
        if (self.role == "keoxe" and cachNguoiChoi > DISTANCE_FOLLOW_PLAYER) then
            self.tick_canswitch = self.tick_breath - 1
            self:LeaveFight(0, "chay theo nguoi choi")
        elseif (self.role == "child" and cachNguoiChoi > DISTANCE_FOLLOW_PLAYER) then
            --self.tick_canswitch = self.tick_breath - 1
            --self:LeaveFight(0, "chay theo parent")
            return 1
        else
            return 1
        end
    end

    -- Up to here means walking
    local nNextPosId = self.nPosId
    local originalWalkPath = self.originalWalkPath
    local WalkSize = getn(originalWalkPath)
    if self.role == "citizen" and (nNextPosId == 0 or WalkSize < 2) then
        return 0
    end

    if ((self.role == "keoxe" and cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) or
            (self.role == "child" and cachNguoiChoi <= DISTANCE_SUPPORT_PLAYER) or
            self.role == "citizen") and worldInfo.allowFighting == 1 and
        (self.isFighting == 0 and self.tick_canswitch < self.tick_breath) then
        if self.role == "citizen" or self.role == "keoxe" then
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
        end

        -- Case 3: I auto switch to fight  mode
        if (self.role == "citizen" and self.attackNpcChance and random(1, self.attackNpcChance) <= 2) then
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

            if countFighting > 0 and worldInfo.showFightingArea == 1 then
                Msg2Map(nW,
                    "C„ " .. countFighting .. " nh©n s‹ Æang Æ∏nh nhau tπi " .. worldInfo.name ..
                    " <color=yellow>" .. floor(myPosX / 8) .. " " .. floor(myPosY / 16) .. "<color>")
            end

            if (countFighting > 0) then
                return 1
            end
        end
    end

    -- Khong phai dang keo xe
    if self.role == "citizen" then
        if self.tick_checklag and self.tick_breath > self.tick_checklag then
            self:Respawn(4, "dang bi lag roi")
            return 1
        end

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
            else
                return 1
            end


            self.tick_checklag = nil
        else
            if not self.tick_checklag then
                self.tick_checklag = self.tick_breath +
                    20 -- check again in 20s, if still at same position, respawn because this is stuck
            end
        end

        local targetPos = self.walkPath[nNextPosId]
        local nX = targetPos[1]
        local nY = targetPos[2]

        NpcWalk(self.finalIndex, nX, nY)
        self:CalculateChildrenPosition(nX, nY)
    elseif self.role == "child" then
        -- Mode 2: follow parent NPC
        -- Player has gone different map? Do respawn
        local needRespawn = 0
        pW, pX, pY = self:GetParentPos()

        -- Parent pos available?
        if pW > 0 and pX > 0 and pY > 0 then
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
                self.tick_canswitch = self.tick_breath
                self.originalWalkPath = { { pX, pY } }
                self.nPosId = 1
                self:GenWalkPath(0)
                self:Respawn(2, "qua xa parent")
                return 1
            end
        else
            return 1
        end


        -- Otherwise walk toward parent
        local targetW, targetX, targetY = self:GetMyPosFromParent()

        -- Parent gave info?
        if targetW > 0 and targetX > 0 and targetY > 0 then
            self.parentAppointPos = { targetX, targetY }
            NpcWalk(self.finalIndex, targetX, targetY)

            -- No info we would work by ourself
        else
            local targetPos = self.walkPath[nNextPosId]
            local nX = targetPos[1]
            local nY = targetPos[2]
            NpcWalk(self.finalIndex, nX, nY)
        end
    elseif self.role == "keoxe" then
        -- Mode 3: follow parent player
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
            self.tick_canswitch = self.tick_breath
            self.originalWalkPath = { { pX, pY } }
            self.nPosId = 1
            self:GenWalkPath(0)
            self:Respawn(2, "qua xa nguoi choi")
            return 1
        end


        -- Otherwise walk toward parent
        if self.parentAppointPos then
            NpcWalk(self.finalIndex, self.parentAppointPos[1], self.parentAppointPos[2])
        else
            NpcWalk(self.finalIndex, pX + random(-2, 2), pY + random(-2, 2))
        end
    end
    return 1
end

function NpcFighter:OnTimer()
    if self.killTimer == 1 then
        return 0
    end
    self.tick_breath = self.tick_breath + REFRESH_RATE / 18
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
    if self.role == "citizen" and self.children then
        local child

        for i = 1, getn(self.children) do
            local each = FighterManager:Get(self.children[i])
            if each and each.isDead ~= 1 then
                child = each

                local tmp = {
                    finalIndex = self.finalIndex,
                    szName = self.szName,
                    nNpcId = self.nNpcId,
                    series = self.series,
                    lastHP = self.lastHP,
                    isFighting = self.isFighting,
                }

                self.finalIndex = child.finalIndex
                self.szName = child.szName
                self.nNpcId = child.nNpcId
                self.series = child.series
                self.lastHP = child.lastHP
                self.isFighting = child.isFighting


                child.finalIndex = tmp.finalIndex
                child.szName = tmp.szName
                child.series = tmp.series
                child.lastHP = tmp.lastHP
                child.isFighting = tmp.isFighting

                SetNpcParam(self.finalIndex, PARAM_LIST_ID, self.id)
                SetNpcParam(child.finalIndex, PARAM_LIST_ID, child.id)

                child.isDead = 1

                --print("Doi chu PT sang nv " .. self.szName)
                return 1
            end
        end
    end

    self.isDead = 1
    self.finalIndex = nil

    -- If child dead do nothing, let parent do it
    if self.role == "child" then
        return 1
    end

    local doRespawn = 0

    if self.isFighting == 1 and self.tick_breath > self.tick_canswitch then
        doRespawn = 1
    end


    -- Is every one dead?
    if (doRespawn == 1 or self.isDead == 1) then
        self.fightingScore = ceil(self.fightingScore * 0.7)
        SimCityTongKim:updateRank(self)


        -- No revive? Do removal
        if self.noRevive == 1 then
            if self.role == "citizen" then
                FighterManager:Remove(self.id)
            end
            return 1
        end
        -- Do revive? Reset and leave fight
        self:LeaveFight(1, "die toan bo")
    end
end

function NpcFighter:KillTimer()
    self.killTimer = 1
end

-- For keo xe
function NpcFighter:GetPlayer()
    if self.playerID == "" then
        return 0
    end
    return SearchPlayer(self.playerID)
end

-- For parent
function NpcFighter:SetupChildren()
    if self.childrenSetup and getn(self.childrenSetup) > 0 then
        local createdChildren = {}

        local nX32, nY32, nW32 = GetNpcPos(self.finalIndex)
        local nW = SubWorldIdx2ID(nW32)
        local nX = nX32 / 32
        local nY = nY32 / 32

        -- Create children
        for i = 1, getn(self.childrenSetup) do
            local childConfig = objCopy(self.originalConfig)
            childConfig.parentID = self.id
            childConfig.childID = i
            childConfig.role = "child"
            childConfig.hardsetName = nil
            childConfig.childrenSetup = nil
            for k, v in self.childrenSetup[i] do
                childConfig[k] = v
            end
            childConfig.goX = nX
            childConfig.goY = nY
            local childId = FighterManager:Add(childConfig)
            tinsert(createdChildren, childId)
        end

        self.children = createdChildren
    end
end

function NpcFighter:GiveChildPos(i)
    if self.childrenPath and getn(self.childrenPath) >= i then
        return self.nMapId, self.childrenPath[i][1], self.childrenPath[i][2]
    end
    return 0, 0, 0
end

function NpcFighter:CalculateChildrenPosition(X, Y)
    if not self.children then
        return 1
    end
    local size = getn(self.children)
    if size == 0 then
        return 1
    end

    if self.walkMode and self.walkMode == "formation" then
        local centerCharId = getCenteredCell(createFormation(size))
        local fighter = FighterManager:Get(self.children[centerCharId])

        if fighter and fighter.isDead == 1 then
            for i = 1, size do
                fighter = FighterManager:Get(self.children[i])
                if fighter and fighter.isDead ~= 1 then
                    break
                end
            end
        end

        if fighter and fighter.isDead ~= 1 then
            local nX, nY, nMapIndex = GetNpcPos(fighter.finalIndex)
            self.childrenPath = genCoords_squareshape({ nX / 32, nY / 32 }, { X, Y }, size)
        end
    else
        local childrenPath = {}
        for i = 1, size do
            tinsert(childrenPath, { X + random(-2, 2), Y + random(-2, 2) })
        end
        self.childrenPath = childrenPath
    end
end

function NpcFighter:ChildrenArrived()
    if not self.children then
        return 1
    end
    local size = getn(self.children)
    if size == 0 then
        return 1
    end

    for i = 1, size do
        local child = FighterManager:Get(self.children[i])
        if child and child.isDead ~= 1 and child:HasArrived() == 0 then
            return 0
        end
    end
    return 1
end

function NpcFighter:ChildrenJoinFight(code)
    if not self.children then
        return 1
    end
    local size = getn(self.children)
    if size == 0 then
        return 1
    end

    for i = 1, size do
        local child = FighterManager:Get(self.children[i])
        if child then
            child:JoinFight(code)
        end
    end
    return 1
end

function NpcFighter:ChildrenLeaveFight(code, reason)
    if not self.children then
        return 1
    end
    local size = getn(self.children)
    if size == 0 then
        return 1
    end

    for i = 1, size do
        local child = FighterManager:Get(self.children[i])
        if child then
            child:LeaveFight(code, reason)
        end
    end
    return 1
end

-- For child
function NpcFighter:GetParentPos()
    local foundParent = FighterManager:Get(self.parentID)
    if foundParent then
        local nX32, nY32, nW32 = GetNpcPos(foundParent.finalIndex)
        local nW = SubWorldIdx2ID(nW32)
        return nW, nX32 / 32, nY32 / 32
    end

    return 0, 0, 0
end

function NpcFighter:GetMyPosFromParent()
    local foundParent = FighterManager:Get(self.parentID)
    if foundParent then
        return foundParent:GiveChildPos(self.childID)
    end

    return 0, 0, 0
end

function NpcFighter:IsParentFighting()
    local foundParent = FighterManager:Get(self.parentID)
    if foundParent and foundParent.isFighting == 1 then
        return 1
    end
    return 0
end
