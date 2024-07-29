Helpers = {}


function Helpers:isValidChar(id)
    if SimCityNPCInfo:notValidChar(id) == 1 or SimCityNPCInfo:isBlacklisted(id) == 1 or
        SimCityNPCInfo:notFightingChar(id) == 1 then
        return 0
    end

    return 1
end

function Helpers:setFightState(group, mode)
    SetNpcAI(group.finalIndex, mode)
    if group.children then
        for i = 1, getn(group.children) do
            local child = group.children[i]
            if child.finalIndex then
                SetNpcAI(child.finalIndex, mode)
            end
        end
    end
end

function Helpers:initChar(config)
    config.playerID = config.playerID or "" -- dang theo sau ai do
    config.ownerID = config.ownerID or ""   -- dang van tieu cua ai d

    -- Not having valid children char?
    if config.children then
        local validChildren = {}
        for i = 1, getn(config.children) do
            local child = config.children[i]
            if self:isValidChar(child.nNpcId) == 1 then
                child.rank = 1
                child.rebel = 0
                tinsert(validChildren, child)
            end
        end
        config.children = validChildren
    end

    if config.children and getn(config.children) == 0 then
        config.children = nil
    end

    -- Init stats
    config.playerID = config.playerID or "simcityplayerhaha"
    config.isFighting = 0
    config.tick = 0
    config.canSwitchTick = 0
    config.series = config.series or random(0, 4)
    config.camp = config.camp or random(1, 3)
    config.walkMode = config.walkMode or 1
    config.isSpinning = 0
    config.lastOffSetAngle = 0
    config.noRevive = config.noRevive or 0
    config.fightingScore = 0
    config.rank = 1
    local randomPos = 1
    if config.tbPos ~= nil then
        randomPos = getn(config.tbPos)
        if randomPos < 1 then
            randomPos = 1
        end
    end
    config.hardsetPos = config.hardsetPos or random(1, randomPos)
    config.rebelActivated = config.rebelActivated or 0
end

function Helpers:createGroup(group, isNew, goX, goY)
    local tbPos = group.tbPos
    local nPosId = group.hardsetPos

    if (not nPosId) or (not tbPos[nPosId]) then
        nPosId = random(1, getn(tbPos))
    end

    local nMapIndex = SubWorldID2Idx(group.nMapId)

    if nMapIndex >= 0 then
        local nNpcIndex

        local tX = group.walkPath[nPosId][1]
        local tY = group.walkPath[nPosId][2]

        if goX and goY and goX > 0 and goY > 0 then
            tX = goX
            tY = goY
        end

        local name = group.szName or SimCityNPCInfo:getName(group.nNpcId)

        if (group.tongkim == 1) then
            if (group.tongkim_name) then
                name = group.tongkim_name
            else
                name = "Kim"
                if group.camp == 1 then
                    name = "Tèng"
                end
            end
            name = name .. " " .. SimCityTongKim.RANKS[group.rank]
        end

        if (group.hardsetName) then
            name = group.hardsetName
        end

        nNpcIndex = AddNpcEx(group.nNpcId, 95, group.series, nMapIndex, tX * 32, tY * 32, 1, name, 0)

        if nNpcIndex > 0 then
            local kind = GetNpcKind(nNpcIndex)
            if kind ~= 0 then
                DelNpcSafe(nNpcIndex)
            else
                group.szName = GetNpcName(nNpcIndex)
                group.finalIndex = nNpcIndex
                group.isDead = 0
                group.lastPos = {
                    nX32 = tX * 32,
                    nY32 = tY * 32,
                    nPosId = nPosId
                }

                -- Otherwise choose side
                SetNpcCurCamp(nNpcIndex, group.camp)

                local nPosCount = getn(tbPos)
                if nPosCount >= 1 then
                    SetNpcActiveRegion(nNpcIndex, 1)
                    group.nPosId = nPosId
                end
                if nPosCount >= 1 or group.nSkillId then
                    SetNpcParam(nNpcIndex, PARAM_LIST_ID, group.groupID)
                    SetNpcParam(nNpcIndex, PARAM_PLAYER_ID, SearchPlayer(group.playerID))
                    SetNpcParam(nNpcIndex, PARAM_NPC_TYPE, 1)
                    SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\timer.lua")
                    SetNpcTimer(nNpcIndex, REFRESH_RATE)
                end

                -- Ngoai trang?
                if (group.ngoaitrang and group.ngoaitrang == 1) then
                    SimCityNgoaiTrang:makeup(group, nNpcIndex)
                end

                self:createChildren(group)

                -- Disable fighting?
                if (group.isFighting == 0) then
                    SetNpcKind(nNpcIndex, group.kind or 4)
                    self:setFightState(group, 0)
                end

                -- Set NPC life
                if group.cap and group.cap < 2 and NPCINFO_SetNpcCurrentLife then
                    local maxHP = SimCityNPCInfo:getHPByCap(group.cap)
                    NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, maxHP)
                    NPCINFO_SetNpcCurrentLife(nNpcIndex, maxHP)
                end

                -- Life?
                if (group.lastHP ~= nil) then
                    NPCINFO_SetNpcCurrentLife(nNpcIndex, group.lastHP)
                    group.lastHP = nil
                end
                return group.groupID
            end
        end

        return 0
    end
    return 0
end

function Helpers:createChildren(group)
    if not group.children then
        return
    end

    local N = getn(group.children)
    for i = 1, N do
        self:createChild(group, i)
    end
end

function Helpers:createChild(group, childID)
    local worldInfo = {}
    local nW = group.nMapId

    if not group.children then
        return
    end

    local pX, pY, pW = GetNpcPos(group.finalIndex)
    pX = pX / 32
    pY = pY / 32

    if SearchPlayer(group.playerID) == 0 then
        worldInfo = SimCityWorld:Get(nW)
    else
        worldInfo.showName = 1
    end

    local child = group.children[childID]
    local targetPos = child.walkPath[group.nPosId]
    local nNpcIndex

    if not (child.isDead == 1 and group.noRevive == 1) then
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
            if group.isFighting == 0 or distance < 20 then
                targetPos = lastPos
            end
        end

        nNpcIndex = AddNpcEx(child.nNpcId, 95, child.series or random(0, 4), pW, targetPos[1] * 32, targetPos[2] * 32,
            1, child.szName, 0)

        if nNpcIndex > 0 then
            local kind = GetNpcKind(nNpcIndex)
            if kind ~= 0 then
                DelNpcSafe(nNpcIndex)
            else
                -- Do magic on this NPC
                if (group.isFighting == 0) then
                    SetNpcKind(nNpcIndex, group.kind or 4)
                end

                -- Choose side
                SetNpcCurCamp(nNpcIndex, child.camp or group.camp)
                SetNpcActiveRegion(nNpcIndex, 1)

                -- Ngoai trang?
                if (group.ngoaitrang and group.ngoaitrang == 1) then
                    SimCityNgoaiTrang:makeup(child, nNpcIndex)
                end

                if group.cap and group.cap < 2 and NPCINFO_SetNpcCurrentLife then
                    local maxHP = SimCityNPCInfo:getHPByCap(group.cap)
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
                child.tick = group.tick
                child.canSwitchTick = group.canSwitchTick
                child.isFighting = group.isFighting

                if child.rebel == 2 and group.rebelActivated == 2 then
                    group.rebelActivated = 0
                    SetNpcCurCamp(nNpcIndex, 5)
                    child.isDead = 1
                else
                    -- Set param to link to parent
                    SetNpcParam(nNpcIndex, PARAM_LIST_ID, group.groupID)
                    SetNpcParam(nNpcIndex, PARAM_CHILD_ID, childID)
                    SetNpcParam(nNpcIndex, PARAM_PLAYER_ID, SearchPlayer(group.playerID))
                    SetNpcParam(nNpcIndex, PARAM_NPC_TYPE, 2)
                    SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\class\\timer.lua")
                    SetNpcTimer(nNpcIndex, REFRESH_RATE)
                end
            end
        end
    end
end
