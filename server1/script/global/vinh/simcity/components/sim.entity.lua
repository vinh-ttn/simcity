/*
    Public functions
*/
SimEntity = {}

SimEntity.Base = {
}

SimEntity.Citizen = {
    CreateChar = function(self, simInstance, tbNpc, isNew, goX, goY)
        local nListId = tbNpc.id
        local nMapIndex = SubWorldID2Idx(tbNpc.nMapId)

        if nMapIndex >= 0 then
            local nNpcIndex

            local tX, tY
            if tbNpc.role == "child" then
                local pW, pX, pY = tbNpc.movementSys:GetParentPos(simInstance, nListId)
                tX = pX
                tY = pY
            elseif tbNpc.role == "citizen" then
                if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths and tbNpc.currentPathIndex then
                    local path = tbNpc.worldInfo.walkPaths[tbNpc.currentPathIndex]
                    if path and tbNpc.currentPointIndex and tbNpc.currentPointIndex <= getn(path) then
                        tX = path[tbNpc.currentPointIndex][1]
                        tY = path[tbNpc.currentPointIndex][2]
                    end
                else
                    tX = tbNpc.worldInfo.walkGraph.nodes[tbNpc.nPosId][1]
                    tY = tbNpc.worldInfo.walkGraph.nodes[tbNpc.nPosId][2]
                end
            end

            if not tX or not tY then            
                return 0
            end

            if goX and goY and goX > 0 and goY > 0 then
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
                        name = "Tèng"
                    end
                end
                name = name .. " " .. SimCityTongKim.RANKS[tbNpc.rank]
            end

            if (tbNpc.hardsetName) then
                name = tbNpc.hardsetName
            end

            nNpcIndex = AddNpcEx(tbNpc.nNpcId, tbNpc.level, tbNpc.series, nMapIndex, tX * 32, tY * 32, 1, name, 0)

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
                        nY32 = tY * 32
                    }

                    -- Otherwise choose side
                    SetNpcCurCamp(nNpcIndex, tbNpc.camp)

                    local nPosCount = tbNpc.movementSys:GetRandomWalkPoint(tbNpc)
                    if nPosCount ~= nil then
                        SetNpcActiveRegion(nNpcIndex, 1)
                        SetNpcParam(nNpcIndex, PARAM_LIST_ID, tbNpc.id)
                        SetNpcParam(nNpcIndex, 4, 1)
                        SetNpcParam(nNpcIndex, PARAM_TYPE, 1)
                        SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\components\\sim.timer.lua")
                    end

                    -- Ngoai trang?
                    if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) then
                        SimCityNgoaiTrang:makeup(tbNpc, nNpcIndex)
                    end


                    -- Disable fighting?
                    if (tbNpc.isFighting == 0) then
                        -- TODO An hien
                        -- if (tbNpc.isAttackable == 1) then
                        --     SetNpcKind(nNpcIndex, 0)
                        -- else
                        --     SetNpcKind(nNpcIndex, tbNpc.kind or 4)
                        -- end
                        SetNpcKind(nNpcIndex, 0)
                        tbNpc.fightSys:SetFightState(tbNpc, 0)
                    end

                    -- Set NPC MAX life
                    if tbNpc.maxHP then
                        NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, tbNpc.maxHP)
                    end

                    -- Life?
                    if tbNpc.lastHP then
                        NPCINFO_SetNpcCurrentLife(nNpcIndex, tbNpc.lastHP)
                    elseif tbNpc.maxHP then
                        NPCINFO_SetNpcCurrentLife(nNpcIndex, tbNpc.maxHP)
                    end
                    return tbNpc.id
                end
            end

            return 0
        end
        return 0
    end,


    Respawn = function(self, simInstance, tbNpc, code, reason)
        local nListId = tbNpc.id
        -- code: 0: con nv con song 1: da chet toan bo 2: keo xe qua map khac 3: chuyen sang chien dau 4: bi lag dung 1 cho nay gio ko di duoc
        --print(tbNpc.role .. " " .. tbNpc.szName .. ": respawn " .. code .. " " .. reason)


        local isAllDead = code == 1 and 1 or 0

        local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)

        -- Do calculation
        nX = nX / 32
        nY = nY / 32

        -- 4 = bi lag or 2 = qua map khac tim cho khac hien len nao
        if code == 4 or code == 2 then
            nX = 0
            nY = 0
            if code == 4 then
                tbNpc.nPosId = tbNpc.movementSys:GetRandomWalkPoint(tbNpc)
            end
            tbNpc.movementSys:resetPos(simInstance, nListId)

            -- otherwise reset
        elseif isAllDead == 1 and tbNpc.role == "child" then
            nX = tbNpc.parentAppointPos[1]
            nY = tbNpc.parentAppointPos[2]
        elseif (isAllDead == 1 and tbNpc.resetPosWhenRevive and tbNpc.resetPosWhenRevive >= 1) then
            if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths and tbNpc.currentPathIndex then
                -- For preset path, select a random point on the path
                local path = tbNpc.worldInfo.walkPaths[tbNpc.currentPathIndex]
                if path and getn(path) > 0 then
                    tbNpc.currentPointIndex = random(1, getn(path))
                    nX = path[tbNpc.currentPointIndex][1]
                    nY = path[tbNpc.currentPointIndex][2]
                end
            else
                local newPosId = tbNpc.movementSys:GetRandomWalkPoint(tbNpc)
                nX = tbNpc.worldInfo.walkGraph.nodes[newPosId][1]
                nY = tbNpc.worldInfo.walkGraph.nodes[newPosId][2]
                tbNpc.nPosId = newPosId
            end
        elseif (isAllDead == 1 and tbNpc.lastPos ~= nil) then
            nX = tbNpc.lastPos.nX32 / 32
            nY = tbNpc.lastPos.nY32 / 32
        else
            tbNpc.lastPos = {
                nX32 = nX,
                nY32 = nY
            }
        end

        tbNpc.tick_checklag = nil
        tbNpc.lastHP = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
        if (isAllDead == 1) then
            tbNpc.lastHP = nil
        end


        -- Normal respawn ? Can del NPC
        DelNpcSafe(tbNpc.finalIndex)

        self:CreateChar(simInstance, tbNpc, 0, nX, nY)
    end,
    
    OnDeath = function(self, simInstance, tbNpc, nNpcIndex)        
        if tbNpc == nil then
            return 0
        end

        tbNpc.funSys:OnDeath(tbNpc, nNpcIndex)    

        if tbNpc.role == "citizen" and tbNpc.children then
            local child

            for i = 1, getn(tbNpc.children) do
                local each = simInstance:Get(tbNpc.children[i])
                if each and each.isDead ~= 1 then
                    child = each

                    local tmp = {
                        finalIndex = tbNpc.finalIndex,
                        szName = tbNpc.szName,
                        nNpcId = tbNpc.nNpcId,
                        series = tbNpc.series,
                        lastHP = tbNpc.lastHP,
                        isFighting = tbNpc.isFighting,
                    }

                    tbNpc.finalIndex = child.finalIndex
                    tbNpc.szName = child.szName
                    tbNpc.nNpcId = child.nNpcId
                    tbNpc.series = child.series
                    tbNpc.lastHP = child.lastHP
                    tbNpc.isFighting = child.isFighting


                    child.finalIndex = tmp.finalIndex
                    child.szName = tmp.szName
                    child.series = tmp.series
                    child.lastHP = tmp.lastHP
                    child.isFighting = tmp.isFighting

                    SetNpcParam(tbNpc.finalIndex, PARAM_LIST_ID, tbNpc.id)
                    SetNpcParam(child.finalIndex, PARAM_LIST_ID, child.id)
                    SetNpcParam(tbNpc.finalIndex, 4, 1)
                    SetNpcParam(child.finalIndex, 4, 2)

                    SetNpcParam(tbNpc.finalIndex, PARAM_TYPE, 1)
                    SetNpcParam(child.finalIndex, PARAM_TYPE, 1)

                    child.isDead = 1

                    --print("Doi chu PT sang nv " .. tbNpc.szName)
                    return 1
                end
            end
        end

        tbNpc.isDead = 1
        tbNpc.finalIndex = nil

        -- If child dead do nothing, let parent do it
        if tbNpc.role == "child" then
            return 1
        end

        local doRespawn = 0

        if tbNpc.isFighting == 1 and tbNpc.tick_breath > tbNpc.tick_canswitch then
            doRespawn = 1
        end


        -- Is every one dead?
        if (doRespawn == 1 or tbNpc.isDead == 1) then
            tbNpc.fightingScore = ceil(tbNpc.fightingScore * 0.7)
            SimCityTongKim:updateRank(tbNpc)


            -- No revive? Do removal
            if tbNpc.noRevive == 1 then
                if tbNpc.role == "citizen" then
                    simInstance:Remove(tbNpc.id)
                end
                return 1
            end
            -- Do revive? Reset and leave fight
            tbNpc.fightSys:LeaveFight(simInstance, tbNpc, 1, "die toan bo")
        end
    end
}

SimEntity.KeoXe = {
    CreateChar = function(self, simInstance, tbNpc, isNew, goX, goY)
        local nListId = tbNpc.id
        local nMapIndex = SubWorldID2Idx(tbNpc.nMapId)

        if nMapIndex >= 0 then
            local nNpcIndex

            local tX, tY
            local pW, pX, pY = CallPlayerFunction(simInstance:GetPlayer(nListId), GetWorldPos)
            tX = pX
            tY = pY

            if goX and goY and goX > 0 and goY > 0 then
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
                        name = "Tèng"
                    end
                end
                name = name .. " " .. SimCityTongKim.RANKS[tbNpc.rank]
            end

            if (tbNpc.hardsetName) then
                name = tbNpc.hardsetName
            end

            nNpcIndex = AddNpcEx(tbNpc.nNpcId, tbNpc.level, tbNpc.series, nMapIndex, tX * 32, tY * 32, 1, name, 0)

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
                        nY32 = tY * 32
                    }

                    -- Otherwise choose side
                    SetNpcCurCamp(nNpcIndex, tbNpc.camp)                
                    SetNpcActiveRegion(nNpcIndex, 1)
                    SetNpcParam(nNpcIndex, PARAM_LIST_ID, tbNpc.id)
                    SetNpcParam(nNpcIndex, 4, 1)
                    SetNpcParam(nNpcIndex, PARAM_TYPE, 2)
                    SetNpcScript(nNpcIndex, "\\script\\global\\vinh\\simcity\\components\\sim.timer.lua")

                    -- Ngoai trang?
                    if (tbNpc.ngoaitrang and tbNpc.ngoaitrang == 1) then
                        SimCityNgoaiTrang:makeup(tbNpc, nNpcIndex)
                    end


                    -- Disable fighting?
                    if (tbNpc.isFighting == 0) then
                        -- TODO An hien
                        -- if (tbNpc.isAttackable == 1) then
                        --     SetNpcKind(nNpcIndex, 0)
                        -- else
                        --     SetNpcKind(nNpcIndex, tbNpc.kind or 4)
                        -- end
                        SetNpcKind(nNpcIndex, 0)
                        tbNpc.fightSys:SetFightState(tbNpc, 0)
                    end

                    -- Set NPC MAX life
                    if tbNpc.maxHP then
                        NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, tbNpc.maxHP)
                    end

                    -- Life?
                    if tbNpc.lastHP then
                        NPCINFO_SetNpcCurrentLife(nNpcIndex, tbNpc.lastHP)
                    elseif tbNpc.maxHP then
                        NPCINFO_SetNpcCurrentLife(nNpcIndex, tbNpc.maxHP)
                    end
                    return tbNpc.id
                end
            end

            return 0
        end
        return 0
    end,
    Respawn = function(self, simInstance, tbNpc, code, reason)
        local nListId = tbNpc.id
        -- code: 0: con nv con song 1: da chet toan bo 2: keo xe qua map khac 3: chuyen sang chien dau 4: bi lag dung 1 cho nay gio ko di duoc
        --print("Respawn " .. nListId .. " " .. code .. " " .. reason)


        local isAllDead = code == 1 and 1 or 0

        local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)

        -- Do calculation
        nX = nX / 32
        nY = nY / 32

        -- 4 = bi lag? 2= qua map khac, tim cho khac hien len nao
        if code == 4 or code == 2 then
            nX = 0
            nY = 0
            tbNpc.movementSys:resetPos(simInstance, nListId)

            -- otherwise reset
        elseif isAllDead == 1 then
            nX = tbNpc.parentAppointPos[1]
            nY = tbNpc.parentAppointPos[2]    
        else
            tbNpc.lastPos = {
                nX32 = nX,
                nY32 = nY
            }
        end

        tbNpc.tick_checklag = nil
        tbNpc.lastHP = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
        if (isAllDead == 1) then
            tbNpc.lastHP = nil
        end


        -- Normal respawn ? Can del NPC
        DelNpcSafe(tbNpc.finalIndex)

        self:CreateChar(simInstance, tbNpc, 0, nX, nY)
    end,
    OnDeath = function(self, simInstance, tbNpc, nNpcIndex)
        if tbNpc == nil then
            return 0
        end

        tbNpc.funSys:OnDeath(tbNpc, nNpcIndex)
    
        tbNpc.isDead = 1
        tbNpc.finalIndex = nil
    

        local doRespawn = 0

        if tbNpc.isFighting == 1 and tbNpc.tick_breath > tbNpc.tick_canswitch then
            doRespawn = 1
        end


        -- Is every one dead?
        if (doRespawn == 1 or tbNpc.isDead == 1) then
            tbNpc.fightingScore = ceil(tbNpc.fightingScore * 0.7)
            SimCityTongKim:updateRank(tbNpc)


            -- No revive? Do removal
            if tbNpc.noRevive == 1 then 
                return 1
            end
            -- Do revive? Reset and leave fight
            tbNpc.fightSys:LeaveFight(simInstance, tbNpc, 1, "die toan bo")
        end
    end
} 

-- Helper function to create a movement behavior by name
function SimEntitySys(tbNpc)     
    if tbNpc.role == "keoxe" then
        return SimEntity.KeoXe
    end
    return SimEntity.Citizen
end