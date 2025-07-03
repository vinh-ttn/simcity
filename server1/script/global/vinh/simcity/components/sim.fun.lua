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

    -- Hieu thuoc
    if tbNpc.isAttractionAround == 203 then
        if random(1, 10000) <= CHANCE_DROP_MONEY then
            local nX, nY, nMapIndex = GetNpcPos(tbNpc.finalIndex)
            for i=1, 10 do 
                DropItem(SubWorldID2Idx(nMapIndex), nX, nY, -1, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            end
        end
    end

    -- Tap hoa
    if tbNpc.isAttractionAround == 384 then
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
        and mod(tbNpc.tick_breath, 10*18/REFRESH_RATE) == 0
        then
        local currentLife = NPCINFO_GetNpcCurrentLife(tbNpc.finalIndex)
        local maxLife = NPCINFO_GetNpcCurrentMaxLife(tbNpc.finalIndex)

        -- Ngami = tu buff nao
        if tbNpc.faction == "ngami" then
            return tbNpc.fightSys:execCastOnSelf(tbNpc)            
        end 

        -- Binh thuong = 3000 moi 10 giay
        if currentLife and maxLife and currentLife < maxLife then
            -- Calculate life to restore (percentage of max life)
            local restoreAmount = 3000 --maxLife * LIFE_RESTORE_PERCENT  -- Default 1% if not specified
                
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
    local scoreTotal = currRank * 1000

    local  allNpcs, nCount = GetNpcAroundNpcList(finalIndex, 15)
    local fighter2
    local found = {}
    if nCount > 0 then
        for i = 1, nCount do
            local fighter2Kind = GetNpcKind(allNpcs[i])
            local fighter2Camp = GetNpcCurCamp(allNpcs[i])
            if (fighter2Kind == 0) then
                if (fighter2Camp ~= fighter.camp) then
                    local nListId2 = GetNpcParam(allNpcs[i], PARAM_LIST_ID) or 0
                 
                    if (nListId2 > 0) then
                        tinsert(found, nListId2)
                    end
                end
            end
        end
    end

    local N = getn(found)

    for i = 1, N do
        local fighter2 = self.fighterList[found[i]]
        if fighter2 and fighter2.id ~= fighter.id and fighter2.isFighting == 1 then
            fighter2.fightingScore = ceil(fighter2.fightingScore + (scoreTotal / N) + (scoreTotal / N) * fighter2.rank / 10)
            SimCityTongKim:updateRank(fighter2)
        end
    end
end
 
function execFindDialogNpcAround(tbNpc)
    if tbNpc.mode ~= "thanhthi" then   
        tbNpc.isAttractionAround = 0
        return 0
    end

    -- Atrraction points
    if (tbNpc.walkMode == "preset" or tbNpc.walkMode == "formation") and tbNpc.worldInfo.presetPaths and tbNpc.currentPathIndex then    
        tbNpc.isAttractionAround = getNodeInfoByNodeName(tbNpc, tbNpc.worldInfo.presetPaths[tbNpc.currentPathIndex][tbNpc.currentPointIndex]).isNearAtraction
        return tbNpc.isAttractionAround
    elseif tbNpc.nPosId and tbNpc.nPosId ~= "none" and tbNpc.worldInfo.nodes[tbNpc.nPosId] then
        tbNpc.isAttractionAround = getNodeInfoByNodeName(tbNpc, tbNpc.nPosId).isNearAtraction
        return tbNpc.isAttractionAround
    end 

    tbNpc.isAttractionAround = 0
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
                
        execChat(tbNpc, 0)
        execRestoreLife(tbNpc)
    end,

    OnDeath = function(self, simInstance, tbNpc, finalIndex, attackerIndex)
        if tbNpc.tongkim == 1 then
            if not PlayerIndex or PlayerIndex == 0 then
                execAddScoreToAroundNPC(simInstance, tbNpc, finalIndex)            
            else
                SimCityTongKim:OnDeath(tbNpc.finalIndex, tbNpc.rank or 1, attackerIndex)
            end
        
        -- Random rot tien khi chet
        elseif tbNpc.mode ~= "chiendau" then
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
        execChat(tbNpc, 1)
        execRestoreLife(tbNpc)
    end,
    OnDeath = function(self, simInstance, tbNpc, finalIndex, attackerIndex)
        
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