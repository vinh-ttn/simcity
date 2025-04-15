Include("\\script\\global\\vinh\\simcity\\components\\sim.core.lua")
SimTheoSau = objCopy(SimCore)

SimTheoSau.fighterList = {}
SimTheoSau.counter = 1
SimTheoSau.removedIds = {}

function SimTheoSau:New(fighter)

    -- Setup minimum config
    self:initCharConfig(fighter)

    local nListId
    if getn(self.removedIds) > 0 then
        nListId = tremove(self.removedIds)
    else
        nListId = self.counter
        self.counter = self.counter + 1
    end

    local tbNpc = {
        id = nListId     
    }
 
    for k, v in fighter do
        tbNpc[k] = v
    end


    self.fighterList[nListId] = tbNpc

    -- Setup walk paths
    if tbNpc.movementSys:resetPos(self, nListId) == 0 then
        return nil
    end

    -- Bugfix series
    tbNpc.series = tbNpc.series or random(0,4)

    tbNpc.isPlayerFighting = CallPlayerFunction(tbNpc.playerID, GetFightState)

    -- Create the character on screen
    tbNpc.entitySys:CreateChar(self, tbNpc, 1, tbNpc.goX, tbNpc.goY)
 
    return nListId
end
 


-- For keo xe
function SimTheoSau:GetPlayer(nListId)
    local tbNpc = self.fighterList[nListId]
    if tbNpc.playerID == "" then
        return 0
    end
    return SearchPlayer(tbNpc.playerID)
end

-- Override parent initCharConfig
function SimTheoSau:initCharConfig(config)
    config.role = "keoxe"
    config.playerID = config.playerID or "" -- dang theo sau ai do
    config.isPlayerFighting = 1
    
    SimCore:initCharConfig(config)
end