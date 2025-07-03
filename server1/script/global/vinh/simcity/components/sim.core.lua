Include("\\script\\global\\vinh\\simcity\\config.lua")
Include("\\script\\global\\vinh\\simcity\\libs\\index.lua")
Include("\\script\\global\\vinh\\simcity\\components\\sim.movement.lua")
Include("\\script\\global\\vinh\\simcity\\components\\sim.fun.lua")
Include("\\script\\global\\vinh\\simcity\\components\\sim.entity.lua")
Include("\\script\\global\\vinh\\simcity\\components\\sim.fight.lua")
IncludeLib("NPCINFO")
SimCore = {
    fighterList = {},
    counter = 1,
    removedIds = {},
    currentProcessGroup = 1,
    totalFighters = 0
}

function SimCore:Get(nListId)
    return self.fighterList[nListId]
end


function SimCore:initCharConfig(config)
    -- Init stats
    config.isFighting = 0
    config.tick_breath = 0
    config.tick_canWalk = 0
    config.tick_canswitch = 0
    config.tick_canCast = 0
    config.camp = config.camp or random(1, 3)
    config.noRevive = config.noRevive or 0
    config.fightingScore = 0
    config.rank = 1
    config.ngoaitrang = config.ngoaitrang or 0
    config.capHP = config.capHP or 1
    config.level = config.level or 95
    config.isAttackable = config.isAttackable or 0
    if config.capHP and config.capHP ~= "auto" then
        config.maxHP = SimCityNPCInfo:getHPByCap(config.capHP)
    end
    config.parentAppointPos = {0, 0}
    config.walkMode = config.walkMode or "random"
    config.isAttractionAround = 0
    config.isPlayerEnemyAround = 0

    -- Phai nhan vat?
    if not config.faction and SimCityPhai.id2phai[config.nNpcId] then
        config.faction = SimCityPhai.id2phai[config.nNpcId]

        if (config.faction == "thienvuong" or config.faction == "thieulam") then
            config.series = 0
        end

        if (config.faction == "ngudoc" or config.faction == "duongmon") then
            config.series = 1
        end

        if (config.faction == "ngami" or config.faction == "thuyyen") then
            config.series = 2
        end

        if (config.faction == "caibang" or config.faction == "thiennhan") then
            config.series = 3
        end

        if (config.faction == "vodang" or config.faction == "conlon") then
            config.series = 4
        end
        
        
        
        
    end

    -- He nhan vat?
    if config.series == nil then
        config.series = random(0,4)
    end

    if config.faction then
        if (SimCityPhai[config.faction] and SimCityPhai[config.faction].knownIds[config.nNpcId]) then

            -- He nhan vat
            config.series = SimCityPhai[config.faction].knownIds[config.nNpcId].series

            -- Nam hay nu
            if SimCityPhai[config.faction].knownIds[config.nNpcId].gen == 1 then
                config.nSettingsIdx = -1
            elseif SimCityPhai[config.faction].knownIds[config.nNpcId].gen == 2 then
                config.nSettingsIdx = -2
            end

            -- Ho tro
            local pool = SimCityPhai[config.faction].noCast
            if pool and getn(pool) > 0 then
                config.skillHoTro = random(1, getn(pool))
            end

        end
    end

    -- Setup movement behavior    
    config.movementSys = SimMovementSys(config)
    config.funSys = SimFunSys(config)
    config.entitySys = SimEntitySys(config)
    config.fightSys = SimFightSys(config)


end


function SimCore:Remove(nListId)
    local tbNpc = self.fighterList[nListId]
    if tbNpc then
        DelNpcSafe(tbNpc.finalIndex)

        if tbNpc.children then
            for i = 1, getn(tbNpc.children) do
                self:Remove(tbNpc.children[i])
            end
        end

        self.fighterList[nListId] = nil
        tinsert(self.removedIds, nListId)
        
        -- Decrement total fighters
        self.totalFighters = self.totalFighters - 1
    end
end

function SimCore:OnDeath(nListId, nNpcIndex, attackerIndex)
    local tbNpc = self.fighterList[nListId]
    if tbNpc == nil then
        return 0
    end

    tbNpc.entitySys:OnDeath(self, tbNpc, nNpcIndex, attackerIndex)    
end

function SimCore:OnTimer(tbNpc, rate)
    local tickRate = rate or 1 
    if tbNpc.isDead == 1 or (tbNpc.isStanding and tbNpc.isStanding == 1) then
        return 0
    end

    -- Check if should be active
    if tbNpc.movementSys:IsActive(self, tbNpc) == 0 then
        if (not tbNpc.tongkim or tbNpc.tongkim ~= 1) then
            tbNpc.movementSys:MoveInactive(self, tbNpc)
            return 0
        end
    end

    tbNpc.tick_breath = tbNpc.tick_breath + 1*tickRate

    if tbNpc.tick_breath > 1800*18/REFRESH_RATE then
        tbNpc.tick_breath = 0
        tbNpc.tick_canswitch = 0
        tbNpc.tick_checklag = nil
        tbNpc.tick_canWalk = 0
        tbNpc.tick_canCast = 0
    end
    
    -- Move
    tbNpc.movementSys:Move(self, tbNpc)

    -- Fun
    tbNpc.funSys:Update(tbNpc)

    -- The rest 10 seconds per call   
    if mod(tbNpc.tick_breath, 10*18/REFRESH_RATE) == 0 then
        
        -- Cast skill
        if tbNpc.faction and SimCityPhai[tbNpc.faction].normalCast then
            tbNpc.fightSys:Update(self, tbNpc)
        end
            
        -- Update fighting score
        if tbNpc.isFighting == 1 then
            tbNpc.fightingScore = tbNpc.fightingScore + 100
        end
    end
end

function SimCore:ATick(rate)    
    -- Process all fighters if total count <= 800
    if self.totalFighters <= 600 then
        for _, fighter in self.fighterList do
            self:OnTimer(fighter, rate)
        end
        return
    end

    -- Over 800 fighters - process only current group
    for _, fighter in self.fighterList do
        if fighter.processGroup == self.currentProcessGroup then
            self:OnTimer(fighter, rate)
        end
    end

    -- Move to next group (alternating between 1 and 2)
    self.currentProcessGroup = self.currentProcessGroup == 1 and 2 or 1
end 
