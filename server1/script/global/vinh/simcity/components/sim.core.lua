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
    removedIds = {}
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
    config.isDialogNpcAround = 0

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
    end
end

function SimCore:OnDeath(nListId, nNpcIndex)
    local tbNpc = self.fighterList[nListId]
    if tbNpc == nil then
        return 0
    end

    tbNpc.entitySys:OnDeath(self, tbNpc, nNpcIndex)    
end

function SimCore:OnTimer(nListId)
    local tbNpc = self.fighterList[nListId]
    if tbNpc == nil or tbNpc.isDead == 1 then
        return 0
    end

    tbNpc.tick_breath = tbNpc.tick_breath + 1

    if tbNpc.tick_breath > 1800*18/REFRESH_RATE then
        tbNpc.tick_breath = 0
        tbNpc.tick_canswitch = 0
        tbNpc.tick_checklag = nil
        tbNpc.tick_canWalk = 0
    end

    if tbNpc.isFighting == 1 then
        tbNpc.fightingScore = tbNpc.fightingScore + 10
    end

    if tbNpc.isDead == 1 then
        return 0
    end

    -- Move
    tbNpc.movementSys:Move(self, nListId)

    -- Fun
    tbNpc.funSys:Update(tbNpc)
end

function SimCore:ATick()    
    for key, fighter in self.fighterList do
        self:OnTimer(key)
    end
end 
