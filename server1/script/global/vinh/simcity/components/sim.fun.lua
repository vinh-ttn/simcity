-- movement_behavior.lua
-- A module for different movement behaviors that can be used by various sim types

function execChat(tbNpc, isKeoXe) 
    -- Otherwise just Random chat
    if isKeoXe or (tbNpc.worldInfo and tbNpc.worldInfo.allowChat == 1) then
        if tbNpc.isFighting == 1 or tbNpc.tongkim == 1 or tbNpc.mode == "chiendau" then
            if random(1, 1000) <= CHANCE_CHAT then
                NpcChat(tbNpc.finalIndex, SimCityChat.fighting[random(1, getn(SimCityChat.fighting))])
            end
        else
            if random(1, 1000) <= CHANCE_CHAT then
                NpcChat(tbNpc.finalIndex, SimCityChat.general[random(1, getn(SimCityChat.general))])
            end
        end
    end

    -- Show my ID
    if not isKeoXe and tbNpc.worldInfo and (tbNpc.worldInfo.showingId == 1) then
        local dbMsg = tbNpc.debugMsg or ""
        NpcChat(tbNpc.finalIndex, tbNpc.id .. " " .. tbNpc.nNpcId)
    end 
end

function execRotDropMoney(tbNpc)

    -- Random rot tien
    if random(1, 10000) <= CHANCE_DROP_MONEY then
        NpcDropMoney(tbNpc.finalIndex, random(1000, 10000), -1)
    end
    
    -- Neu gan ban thuoc va TDP thi se quang ra TDP hoac ngu hoa
    -- Handle special cases for cached dialog NPCs 
    if tbNpc.isDialogNpcAround == 203 then
        if random(1, 10000) <= CHANCE_DROP_MONEY then
            local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)
            for i=1, 10 do 
                DropItem(SubWorldID2Idx(nMapIndex), nX, nY, -1, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            end
        end
    end

    if tbNpc.isDialogNpcAround == 384 then
        if random(1, 10000) <= CHANCE_DROP_MONEY then
            local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)
            for i=1, 3 do 
                DropItem(SubWorldID2Idx(nMapIndex), nX, nY, -1, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            end
        end
    end 
end

function execRestoreLife(tbNpc)
    if tbNpc.isDead == 0 and tbNpc.tick_breath > 0 
        and tbNpc.finalIndex 
        and LIFE_RESTORE_PERCENT > 0 
        and mod(tbNpc.tick_breath, 10*18/REFRESH_RATE) == 0 then
        local currentLife = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
        local maxLife = NPCINFO_GetNpcCurrentMaxLife(tbNpc.finalIndex)
        if currentLife and maxLife and currentLife < maxLife then
            -- Calculate life to restore (percentage of max life)
            local restoreAmount = maxLife * LIFE_RESTORE_PERCENT  -- Default 1% if not specified
                
            -- Apply the restoration
            local newLife = currentLife + restoreAmount
            if newLife > maxLife then
                newLife = maxLife
            end
            
            NPCINFO_SetNpcCurrentLife(tbNpc.finalIndex, newLife)
        end
    end
end


function execAddScoreToAroundNPC(self, fighter, finalIndex)
    local currRank = fighter.rank or 1
    local  allNpcs, nCount = GetNpcAroundNpcList(finalIndex, 15)
    local foundfighters = {}
    if nCount > 0 then
        for i = 1, nCount do
            local fighter2Kind = GetNpcKind(allNpcs[i])
            local fighter2Camp = GetNpcCurCamp(allNpcs[i])
            if (fighter2Kind == 0) then
                if (fighter2Camp ~= fighter.camp) then
                    local nListId2 = GetNpcParam(allNpcs[i], PARAM_LIST_ID) or 0
                    if (nListId2 > 0) then
                        tinsert(foundfighters, nListId2)
                    end
                end
            end
        end

        local N = getn(foundfighters)
        if N > 0 then
            local scoreTotal = currRank * 1000
            for key, fighter2 in self.fighterList do
                if fighter2 and fighter2.id ~= fighter.id and fighter2.isFighting == 1 then
                    fighter2.fightingScore = ceil(
                        fighter2.fightingScore + (scoreTotal / N) + (scoreTotal / N) * fighter2.rank / 10)
                    SimCityTongKim:updateRank(fighter2)
                end
            end
        end
    end

    return 0
end
 
function execFindDialogNpcAround(tbNpc)
    if tbNpc.mode ~= "thanhthi" then   
        tbNpc.isDialogNpcAround = 0
        return 0
    end

    -- Check cache for preset path
    if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths and tbNpc.currentPathIndex then
        local pathKey = tbNpc.currentPathIndex .. "_" .. tbNpc.currentPointIndex
        local cachedNpcId = tbNpc.worldInfo.foundDialogNpcOnPaths[pathKey]
        
        if cachedNpcId then
            tbNpc.isDialogNpcAround = cachedNpcId
            return cachedNpcId
        end
    else
        -- Original walkGraph cache check
        local foundDialogNpc = tbNpc.worldInfo.walkGraph.foundDialogNpc
        if foundDialogNpc[tbNpc.nPosId] ~= nil then
            tbNpc.isDialogNpcAround = foundDialogNpc[tbNpc.nPosId]
            return foundDialogNpc[tbNpc.nPosId]
        end
    end

    -- If not in cache, search for dialog NPCs nearby
    local allNpcs = {}
    local nCount = 0
    local radius = 8    
    allNpcs, nCount = GetNpcAroundNpcList(tbNpc.finalIndex, radius)
    for i = 1, nCount do
        local fighter2Kind = GetNpcKind(allNpcs[i])
        local fighter2Name = GetNpcName(allNpcs[i])
        local nNpcId = GetNpcSettingIdx(allNpcs[i])
        if fighter2Kind == 3 and (nNpcId == 108 or nNpcId == 198 or nNpcId == 203 or nNpcId == 384 or nNpcId == 55 or nNpcId == 62) then
            -- Cache the found NPC ID
            if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.walkPaths and tbNpc.currentPathIndex then
                local pathKey = tbNpc.currentPathIndex .. "_" .. tbNpc.currentPointIndex
                tbNpc.worldInfo.foundDialogNpcOnPaths[pathKey] = nNpcId
            else
                tbNpc.worldInfo.walkGraph.foundDialogNpc[tbNpc.nPosId] = nNpcId
            end
            tbNpc.isDialogNpcAround = nNpcId
            return nNpcId
        end
    end
    tbNpc.isDialogNpcAround = 0
    return 0
end

/*
    Public functions
*/
SimFun = {}

SimFun.Base = {
    Update = function(self, tbNpc)
    end,
    OnDeath = function(self, tbNpc, finalIndex)
    end
}

SimFun.Citizen = {
    Update = function(self, tbNpc)
        -- No fun if dead
        if tbNpc.isDead == 1 then
            return
        end

        if tbNpc.mode ~= "chiendau" then
            execFindDialogNpcAround(tbNpc)
            execRotDropMoney(tbNpc)
        end
                
        execChat(tbNpc)
        execRestoreLife(tbNpc)
    end,

    OnDeath = function(self, simInstance, tbNpc, finalIndex)
        if tbNpc.tongkim == 1 then
            execAddScoreToAroundNPC(simInstance, tbNpc, finalIndex)
            SimCityTongKim:OnDeath(nNpcIndex, tbNpc.rank or 1)
        end     
        
        -- Random rot tien khi chet
        if tbNpc.mode ~= "chiendau" then
            if random(1, 1000) <= CHANCE_DROP_MONEY then
                NpcDropMoney(tbNpc.finalIndex, random(1000, 100000), -1)
            end
        end
    end
}

SimFun.KeoXe = {
    Update = function(self, tbNpc)
        if tbNpc.isDead == 1 then
            return
        end
        execChat(tbNpc, true)
        execRestoreLife(tbNpc)
    end,
    OnDeath = function(self, simInstance, tbNpc, finalIndex)
        if tbNpc.tongkim == 1 then
            execAddScoreToAroundNPC(simInstance, tbNpc, finalIndex)
            SimCityTongKim:OnDeath(nNpcIndex, tbNpc.rank or 1)
        end     
    end
} 

-- Helper function to create a movement behavior by name
function SimFunSys(tbNpc)    
    if tbNpc.role == "citizen" then
        return SimFun.Citizen
    end
    if tbNpc.role == "keoxe" then
        return SimFun.KeoXe
    end
    return SimFun.Base
end