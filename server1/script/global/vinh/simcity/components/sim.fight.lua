function ChildrenLeaveFight(self, simInstance, tbNpc, code, reason)
    if not tbNpc.children then
        return 1
    end
    local size = getn(tbNpc.children)
    if size == 0 then
        return 1
    end

    for i = 1, size do
        local child = simInstance:Get(tbNpc.children[i])
        if child then
            LeaveFight(self, simInstance, child, code, reason)
        end
    end
    return 1
end

function LeaveFight(self, simInstance, tbNpc, isAllDead, reason)
    local nListId = tbNpc.id
    ChildrenLeaveFight(self, simInstance, tbNpc, isAllDead, reason)

    isAllDead = isAllDead or 0

    tbNpc.isFighting = 0

    -- Chien dau can switch back to fight after 0 tick    
    tbNpc.tick_canswitch = tbNpc.tick_breath +
        random(tbNpc.TIME_RESTING_minTs or TIME_RESTING.minTs,
            tbNpc.TIME_RESTING_maxTs or TIME_RESTING.maxTs) -- trong trang thai di bo 30s-1ph    

    reason = reason or "no reason"

    -- Do not need to respawn just disable fighting
    if (isAllDead ~= 1 and tbNpc.kind ~= 3 and (tbNpc.kind ~= 4 or tbNpc.isAttackable == 1)) then        
        self:SetFightState(tbNpc, 0)
    else
        tbNpc.entitySys:Respawn(simInstance, tbNpc, isAllDead, reason)
    end
end
 

function execCastNormalSkill(self, simInstance, tbNpc)

    -- No skill?
    if not tbNpc.faction or not SimCityPhai[tbNpc.faction] or tbNpc.faction == "ngami" then
        return
    end

    if tbNpc.fighting == 0 or (tbNpc.tick_canCast and tbNpc.tick_canCast > tbNpc.tick_breath) then
        return
    end

    local skillCount = getn(SimCityPhai[tbNpc.faction].normalCast)

    if skillCount == 0 then
        return
    end

    -- Random cast only 0.5% allowed
    if (random(1, 1000) > 50) then
        return
    end

    -- Random skill
    local selectedSkill = tbNpc.skillCastBua or SimCityPhai[tbNpc.faction].normalCast[random(1, skillCount)]
    local skillId = selectedSkill[1]
    local skillLevel = selectedSkill[2]

    
    -- Cast skill
    local foundPlayerEnemy = tbNpc.isPlayerEnemyAround
    if foundPlayerEnemy > 0 then
        local targetX, targetY, targetW = CallPlayerFunction(foundPlayerEnemy, GetWorldPos)
        NpcCastSkill(tbNpc.finalIndex, skillId, skillLevel, targetX*32, targetY*32)        
        tbNpc.tick_canCast = tbNpc.tick_breath + 15*18/REFRESH_RATE
        return
    end

    local foundNpcEnemy = self:IsNpcEnemyAround(simInstance, tbNpc)
    if foundNpcEnemy > 0 then
        local targetX, targetY, targetW = GetNpcPos(foundNpcEnemy)
        NpcCastSkill(tbNpc.finalIndex, skillId, skillLevel, targetX, targetY)
        tbNpc.tick_canCast = tbNpc.tick_breath + 15*18/REFRESH_RATE
        return
    end
end

function execCastOnParent(self, simInstance, tbNpc, pId, pX, pY)
    
    -- Hien tai chi ho tro Nga Mi
    if tbNpc.role ~= "keoxe" or tbNpc.faction ~= "ngami" then
        return
    end

    -- Ngung cast giua cac lan
    if (tbNpc.tick_canCast and tbNpc.tick_canCast > tbNpc.tick_breath) then
        return
    end

    local parentMax = NPCINFO_GetNpcCurrentMaxLife(PIdx2NpcIdx(pId))
    local parentCur = NPCINFO_GetNpcCurrentLife(PIdx2NpcIdx(pId))
    local parentPercent = parentCur / parentMax
    
    if parentPercent < 0.5 then
        NpcCastSkill(tbNpc.finalIndex, 93, 20, pX*32, pY*32)
        tbNpc.tick_canCast = tbNpc.tick_breath + 10*18/REFRESH_RATE
    end 
end
function execCastOnSelf(self, tbNpc)
    
    -- Hien tai chi ho tro Nga Mi
    if tbNpc.faction ~= "ngami" then
        return
    end

    -- Ngung cast giua cac lan
    if (tbNpc.tick_canCast and tbNpc.tick_canCast > tbNpc.tick_breath) then
        return
    end

    local parentMax = NPCINFO_GetNpcCurrentMaxLife(tbNpc.finalIndex)
    local parentCur = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
    local parentPercent = parentCur / parentMax
    
    if parentPercent < 0.3 then
        local nX, nY, nW = GetNpcPos(tbNpc.finalIndex)
        NpcCastSkill(tbNpc.finalIndex, 93, random(10,20), nX, nY)
        tbNpc.tick_canCast = tbNpc.tick_breath + 10*18/REFRESH_RATE
    end 
end

function BuffChar(self, simInstance, tbNpc)
    -- Ho tro
    if tbNpc.skillHoTro and tbNpc.faction and tbNpc.skillHoTro > 0 then

        -- Tat Sau Vo Hinh khi ko chien dau
        if SimCityPhai[tbNpc.faction].noCast[tbNpc.skillHoTro] then
            if SimCityPhai[tbNpc.faction].noCast[tbNpc.skillHoTro][1] == 69 
                and tbNpc.isFighting == 0 then
                SetNpcAuraSkill(tbNpc.finalIndex, 1, 1)
            else
                SetNpcAuraSkill(tbNpc.finalIndex, 
                    SimCityPhai[tbNpc.faction].noCast[tbNpc.skillHoTro][1], 
                    tbNpc.role == "keoxe" and SimCityPhai[tbNpc.faction].noCast[tbNpc.skillHoTro][2] or 1
                )
            end
        end
    end

    -- Tran phai
    if tbNpc.faction and SimCityPhai[tbNpc.faction].needCast then

        if tbNpc.skillTranPhai then
            local skillId = tbNpc.skillTranPhai[1]
            local skillLevel = tbNpc.skillTranPhai[2]
            if skillId > 0 then
                NpcCastSkill(tbNpc.finalIndex, skillId, skillLevel)
                -- Set new max life is not fighting
                local currentMaxLife = NPCINFO_GetNpcCurrentMaxLife(tbNpc.finalIndex)
                if tbNpc.isFighting == 0 and currentMaxLife > 0 and (not tbNpc.maxHP or tbNpc.maxHP < currentMaxLife) then
                    tbNpc.maxHP = currentMaxLife
                    NPCINFO_SetNpcCurrentLife(tbNpc.finalIndex, tbNpc.maxHP)
                end
            end
        else
            for i=1, getn(SimCityPhai[tbNpc.faction].needCast) do
                local skillId = SimCityPhai[tbNpc.faction].needCast[i][1]
                local skillLevel = tbNpc.role == "keoxe" and SimCityPhai[tbNpc.faction].needCast[i][2] or 1
                NpcCastSkill(tbNpc.finalIndex, skillId, skillLevel)

                -- Set new max life is not fighting
                local currentMaxLife = NPCINFO_GetNpcCurrentMaxLife(tbNpc.finalIndex)
                if tbNpc.isFighting == 0 and currentMaxLife > 0 and (not tbNpc.maxHP or tbNpc.maxHP < currentMaxLife) then
                    tbNpc.maxHP = currentMaxLife
                    NPCINFO_SetNpcCurrentLife(tbNpc.finalIndex, tbNpc.maxHP)
                end

            end
        end
    end
    
    
end
/*
    Public functions
*/
SimFight = {}

SimFight.Base = {
}

SimFight.Citizen = {
    LeaveFight = LeaveFight,
    BuffChar = BuffChar,
    execCastOnParent = execCastOnParent,
    execCastOnSelf = execCastOnSelf,    
    TriggerFightWithNPC = function(self, simInstance, tbNpc)
        if tbNpc.isPlayerFighting == 0 then
            return 0
        end
        if (self:IsNpcEnemyAround(simInstance, tbNpc) > 0) then
            return self:JoinFight(simInstance, tbNpc, "enemy around")
        end
        return 0
    end,
    IsNpcEnemyAround = function(self, simInstance, tbNpc)
        local allNpcs = {}
        local nCount = 0
        local radius = tbNpc.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN

        -- Thanh thi / tong kim / chien loan
        allNpcs, nCount = GetNpcAroundNpcList(tbNpc.finalIndex, radius)
        for i = 1, nCount do
            if allNpcs[i] ~= tbNpc.finalIndex then
                local fighter2Kind = GetNpcKind(allNpcs[i])
                local fighter2Camp = GetNpcCurCamp(allNpcs[i])
                if fighter2Kind == 0 and (IsAttackableCamp(tbNpc.camp, fighter2Camp) == 1) then
                    return allNpcs[i]
                end
            end
        end
        return 0
    end,
    CanLeaveFight = function(self, simInstance, tbNpc)
        if tbNpc.isDead == 1 then
            return 0
        end

        -- No attacker around including NPC and Player ? Stop
        if (self:IsNpcEnemyAround(simInstance, tbNpc) == 0 and
                tbNpc.isPlayerEnemyAround == 0) then
            if (tbNpc.leaveFightWhenNoEnemy and tbNpc.leaveFightWhenNoEnemy > 0) then
                local realCanSwitchTick = tbNpc.tick_breath + tbNpc.leaveFightWhenNoEnemy - 1

                if tbNpc.tick_canswitch > realCanSwitchTick then
                    tbNpc.tick_canswitch = realCanSwitchTick
                end
            end

            return 1
        end
        return 0
    end,
    TriggerFightWithPlayer = function(self, simInstance, tbNpc)
        -- FIGHT other player
        if GetNpcAroundPlayerList then
            if tbNpc.isPlayerEnemyAround > 0 then
                if tbNpc.role == "citizen" then                
                    if tbNpc.worldInfo.showFightingArea == 1 then
                        local name = GetNpcName(tbNpc.finalIndex)
                        local lastPos
                        
                        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.presetPaths and tbNpc.currentPathIndex then
                            local path = tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex]
                            if path and tbNpc.currentPointIndex and tbNpc.currentPointIndex <= getn(path) then
                                lastPos = path[tbNpc.currentPointIndex]
                            end
                        else
                            lastPos = tbNpc.nPosId
                        end
                        
                        if lastPos ~= nil and lastPos ~= "none" then
                            local node = getNodeInfoByNodeName(tbNpc, lastPos)
                            Msg2Map(tbNpc.nMapId,
                                "<color=white>" .. name .. "<color> ®¸nh ng­êi t¹i " .. tbNpc.worldInfo.name .. " " ..
                                floor(node.x / 8) .. " " .. floor(node.y / 16) .. "")
                        end
                    end
                end
                return self:JoinFight(simInstance, tbNpc, "player around")
            end
        end

        return 0
    end,
    SetFightState = function(self, tbNpc, mode, nX, nY)
        if mode == 9 then
            mode = 1
        end
        --if mode == 9 then
        --    SetNpcAI(tbNpc.finalIndex, mode, 20, -1, -1, -1, -1, -1, 0, nX, nY)            
        --else
            SetNpcAI(tbNpc.finalIndex, mode)
        --end
    end,


    ChildrenJoinFight = function(self, simInstance, tbNpc, code)
        if not tbNpc.children then
            return 1
        end
        local size = getn(tbNpc.children)
        if size == 0 then
            return 1
        end

        for i = 1, size do
            local child = simInstance:Get(tbNpc.children[i])
            if child then
                self:JoinFight(simInstance, child, code)
            end
        end
        return 1
    end,

    JoinFight = function(self, simInstance, tbNpc, reason)
        local nListId = tbNpc.id
        self:ChildrenJoinFight(simInstance, tbNpc, reason)
        tbNpc.isFighting = 1

        
        tbNpc.tick_canswitch = tbNpc.tick_breath +
            random(tbNpc.TIME_FIGHTING_minTs or TIME_FIGHTING.minTs,
                tbNpc.TIME_FIGHTING_maxTs or TIME_FIGHTING.maxTs) -- trong trang thai pk 1 toi 2ph
        

        reason = reason or "no reason"


        -- If already having last fight pos, we may simply chance AI to 1
        local currX, currY, currW = GetNpcPos(tbNpc.finalIndex)
        if tbNpc.lastFightPos then
            if tbNpc.lastFightPos.W == currW then
                if (GetDistanceRadius(tbNpc.lastFightPos.X/32, tbNpc.lastFightPos.Y/32, currX/32, currY/32) < 16) then
                    self:SetFightState(tbNpc, 9, currX, currY)
                    return 1
                end
            end
        end
        
        tbNpc.entitySys:Respawn(simInstance, tbNpc, 3, "JoinFight " .. reason)      
        return 1
    end,

    IsParentFighting = function(self, simInstance, tbNpc)
        local foundParent = simInstance:Get(tbNpc.parentID)
        if foundParent and foundParent.isFighting == 1 then
            return 1
        end
        return 0
    end,

    GetFightingNPCs = function(self, simInstance, tbNpc, myPosX, myPosY)
        local countFighting = 0
        for key, fighter2 in simInstance.fighterList do
            if fighter2.finalIndex and fighter2.isDead == 0 and fighter2.id ~= tbNpc.id and fighter2.nMapId == tbNpc.nMapId and
                (fighter2.isFighting == 0 and IsAttackableCamp(fighter2.camp, tbNpc.camp) == 1) then
                local otherPosX, otherPosY, otherPosW = GetNpcPos(fighter2.finalIndex)
                otherPosX = floor(otherPosX / 32)
                otherPosY = floor(otherPosY / 32)

                local distance = floor(GetDistanceRadius(otherPosX, otherPosY, myPosX, myPosY))
                local checkDistance = tbNpc.RADIUS_FIGHT_NPC or RADIUS_FIGHT_NPC
                if distance < checkDistance then
                    countFighting = countFighting + 1
                    fighter2.fightSys:JoinFight(simInstance, fighter2, "caused by others " ..
                        distance .. " (" .. otherPosX ..
                        " " .. otherPosY .. ") (" .. myPosX .. " " .. myPosY .. ")")
                end
            end
        end
        return countFighting
    end,

    Update = execCastNormalSkill
}

SimFight.KeoXe = {
    LeaveFight = LeaveFight,
    BuffChar = BuffChar,
    execCastOnParent = execCastOnParent,
    execCastOnSelf = execCastOnSelf,
    TriggerFightWithNPC = function(self, simInstance, tbNpc)
        if tbNpc.isPlayerFighting == 0 then
            return 0
        end
        if (self:IsNpcEnemyAround(simInstance, tbNpc) > 0) then
            return self:JoinFight(simInstance, tbNpc, "enemy around")
        end
        return 0
    end,

    IsNpcEnemyAround = function(self, simInstance, tbNpc)
        local allNpcs = {}
        local nCount = 0
        local radius = tbNpc.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN
        -- Keo xe?
        local pID = simInstance:GetPlayer(tbNpc.id)
        if pID > 0 then
            allNpcs, nCount = CallPlayerFunction(pID, GetAroundNpcList, radius)
        
            for i = 1, nCount do
                if allNpcs[i] ~= tbNpc.finalIndex then
                    local fighter2Kind = GetNpcKind(allNpcs[i])
                    local fighter2Camp = GetNpcCurCamp(allNpcs[i])
                    if fighter2Kind == 0 and (IsAttackableCamp(tbNpc.camp, fighter2Camp) == 1) then
                        return allNpcs[i]
                    end
                end
            end
        end
        return 0
    end,
    CanLeaveFight = function(self, simInstance, tbNpc)
        if tbNpc.isDead == 1 then
            return 0
        end

        -- No attacker around including NPC and Player ? Stop
        if (self:IsNpcEnemyAround(simInstance, tbNpc) == 0 and
                tbNpc.isPlayerEnemyAround == 0) then
            if (tbNpc.leaveFightWhenNoEnemy and tbNpc.leaveFightWhenNoEnemy > 0) then
                local realCanSwitchTick = tbNpc.tick_breath + tbNpc.leaveFightWhenNoEnemy - 1

                if tbNpc.tick_canswitch > realCanSwitchTick then
                    tbNpc.tick_canswitch = realCanSwitchTick
                end
            end

            return 1
        end
        return 0
    end,
    TriggerFightWithPlayer = function(self, simInstance, tbNpc)
        if tbNpc.isPlayerFighting == 0 then
            return 0
        end
        -- FIGHT other player        
        if tbNpc.isPlayerEnemyAround > 0 then
            return self:JoinFight(simInstance, tbNpc, "player around")
        end

        return 0
    end,
    SetFightState = function(self, tbNpc, mode, nX, nY)  
        
        -- Mode = 9 is no longer used
        if mode == 9 then 
            mode = 1            
        end

        --if mode == 9 then
        --    SetNpcAI(tbNpc.finalIndex, mode, 20, -1, -1, -1, -1, -1, 0, nX, nY)            
        --else
            SetNpcAI(tbNpc.finalIndex, mode)
        --end

        if tbNpc.mode == "tieuthiep" then
            if mode == 1 then 
                SetNpcKind(tbNpc.finalIndex, 0)
            else
                SetNpcKind(tbNpc.finalIndex, tbNpc.kind or 4)
            end
            return 1
        end

        if tbNpc.isPlayerFighting == 0 then
            SetNpcKind(tbNpc.finalIndex, 0)
        else
            SetNpcKind(tbNpc.finalIndex, tbNpc.kind or 4)
        end
    end,
    JoinFight = function(self, simInstance, tbNpc, reason)
        local nListId = tbNpc.id
        tbNpc.isFighting = 1
        tbNpc.tick_canswitch = tbNpc.tick_breath +
            random(tbNpc.TIME_FIGHTING_minTs or TIME_FIGHTING.minTs,
                tbNpc.TIME_FIGHTING_maxTs or TIME_FIGHTING.maxTs) -- trong trang thai pk 1 toi 2ph

        reason = reason or "no reason"

        local playerID = simInstance:GetPlayer(nListId)
        if playerID <= 0 then
            return 0
        end

        -- If already having last fight pos, we may simply change AI to 1
        local currX, currY, currW = GetNpcPos(tbNpc.finalIndex)
        if tbNpc.lastFightPos and (not tbNpc.mode or tbNpc.mode ~= "tieuthiep") then
            if tbNpc.lastFightPos.W == currW then
                if (GetDistanceRadius(tbNpc.lastFightPos.X/32, tbNpc.lastFightPos.Y/32, currX/32, currY/32) < 16) then
                    self:SetFightState(tbNpc, 9, currX, currY)
                    return 1
                end
            end
        end

        tbNpc.entitySys:Respawn(simInstance, tbNpc, 3, "JoinFight " .. reason)     
    
        return 1
    end,

    Update = execCastNormalSkill
} 

-- Helper function to create a movement behavior by name
function SimFightSys(tbNpc)     
    if tbNpc.role == "keoxe" then
        return SimFight.KeoXe
    end
    return SimFight.Citizen
end