
function IsPlayerEnemyAround(tbNpc)
    -- FIGHT other player
    if GetNpcAroundPlayerList then
        local allNpcs, nCount = GetNpcAroundPlayerList(tbNpc.finalIndex, tbNpc.RADIUS_FIGHT_PLAYER or RADIUS_FIGHT_PLAYER)
        for i = 1, nCount do
            if (CallPlayerFunction(allNpcs[i], GetFightState) == 1 and
                    IsAttackableCamp(CallPlayerFunction(allNpcs[i], GetCurCamp), tbNpc.camp) == 1 and
                    tbNpc.camp ~= 0) then
                return 1
            end
        end
    end
    return 0
end

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
    if (isAllDead ~= 1 and (tbNpc.kind ~= 4 or tbNpc.isAttackable == 1)) then        
        self:SetFightState(tbNpc, 0)
    else
        tbNpc.entitySys:Respawn(simInstance, tbNpc, isAllDead, reason)
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
    TriggerFightWithNPC = function(self, simInstance, tbNpc)
        if tbNpc.isPlayerFighting == 0 then
            return 0
        end
        if (self:IsNpcEnemyAround(tbNpc) == 1) then
            return self:JoinFight(simInstance, tbNpc, "enemy around")
        end
        return 0
    end,
    IsNpcEnemyAround = function(self, tbNpc)
        local allNpcs = {}
        local nCount = 0
        local radius = tbNpc.RADIUS_FIGHT_SCAN or RADIUS_FIGHT_SCAN

        -- Thanh thi / tong kim / chien loan
        allNpcs, nCount = GetNpcAroundNpcList(tbNpc.finalIndex, radius)
        for i = 1, nCount do
            local fighter2Kind = GetNpcKind(allNpcs[i])
            local fighter2Camp = GetNpcCurCamp(allNpcs[i])
            if fighter2Kind == 0 and (IsAttackableCamp(tbNpc.camp, fighter2Camp) == 1) then
                return 1
            end
        end
        return 0
    end,
    CanLeaveFight = function(self, simInstance, tbNpc)
        if tbNpc.isDead == 1 then
            return 0
        end

        -- No attacker around including NPC and Player ? Stop
        if (self:IsNpcEnemyAround(tbNpc) == 0 and
                IsPlayerEnemyAround(tbNpc) == 0) then
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
            if IsPlayerEnemyAround(tbNpc) == 1 then
                if tbNpc.role == "citizen" then                
                    if tbNpc.worldInfo.showFightingArea == 1 then
                        local name = GetNpcName(tbNpc.finalIndex)
                        local lastPos
                        
                        if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths and tbNpc.currentPathIndex then
                            local path = tbNpc.worldInfo.walkPaths[tbNpc.currentPathIndex]
                            if path and tbNpc.currentPointIndex and tbNpc.currentPointIndex <= getn(path) then
                                lastPos = path[tbNpc.currentPointIndex]
                            end
                        else
                            lastPos = tbNpc.worldInfo.walkGraph.nodes[tbNpc.nPosId]
                        end
                        
                        if lastPos ~= nil then
                            Msg2Map(tbNpc.nMapId,
                                "<color=white>" .. name .. "<color> ®¸nh ng­êi t¹i " .. tbNpc.worldInfo.name .. " " ..
                                floor(lastPos[1] / 8) .. " " .. floor(lastPos[2] / 16) .. "")
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
            SetNpcAI(tbNpc.finalIndex, mode, 20, -1, -1, -1, -1, -1, 0, nX, nY)
            
        else
            SetNpcAI(tbNpc.finalIndex, mode)
        end
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
        if tbNpc.lastFightPos then
            local currX, currY, currW = GetNpcPos(tbNpc.finalIndex)
            if tbNpc.lastFightPos.W == currW then
                if (GetDistanceRadius(tbNpc.lastFightPos.X/32, tbNpc.lastFightPos.Y/32, currX/32, currY/32) < 15) then
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
    end
}

SimFight.KeoXe = {
    LeaveFight = LeaveFight,
    TriggerFightWithNPC = function(self, simInstance, tbNpc)
        if tbNpc.isPlayerFighting == 0 then
            return 0
        end
        if (self:IsNpcEnemyAround(simInstance, tbNpc) == 1) then
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
                local fighter2Kind = GetNpcKind(allNpcs[i])
                local fighter2Camp = GetNpcCurCamp(allNpcs[i])
                if fighter2Kind == 0 and (IsAttackableCamp(tbNpc.camp, fighter2Camp) == 1) then
                    return 1
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
                IsPlayerEnemyAround(tbNpc) == 0) then
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
        if GetNpcAroundPlayerList then
            if IsPlayerEnemyAround(tbNpc) == 1 then
                return self:JoinFight(simInstance, tbNpc, "player around")
            end
        end

        return 0
    end,
    SetFightState = function(self, tbNpc, mode, nX, nY)            
        if mode == 9 then
            SetNpcAI(tbNpc.finalIndex, mode, 20, -1, -1, -1, -1, -1, 0, nX, nY)            
        else
            SetNpcAI(tbNpc.finalIndex, mode)
        end

        if tbNpc.isPlayerFighting == 0 then
            SetNpcCurCamp(tbNpc.finalIndex, 0)
            SetNpcKind(tbNpc.finalIndex, 0)
        else
            SetNpcCurCamp(tbNpc.finalIndex, tbNpc.camp)
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

        -- If already having last fight pos, we may simply chance AI to 1
        if tbNpc.lastFightPos then
            local currX, currY, currW = GetNpcPos(tbNpc.finalIndex)
            if tbNpc.lastFightPos.W == currW then
                if (GetDistanceRadius(tbNpc.lastFightPos.X/32, tbNpc.lastFightPos.Y/32, currX/32, currY/32) < 15) then
                    self:SetFightState(tbNpc, 9, currX, currY)
                    return 1
                end
            end
        end

        tbNpc.entitySys:Respawn(simInstance, tbNpc, 3, "JoinFight " .. reason)
        return 1
    end
} 

-- Helper function to create a movement behavior by name
function SimFightSys(tbNpc)     
    if tbNpc.role == "keoxe" then
        return SimFight.KeoXe
    end
    return SimFight.Citizen
end