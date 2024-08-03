Include("\\script\\misc\\eventsys\\type\\player.lua")
Include("\\script\\misc\\eventsys\\type\\map.lua")
Include("\\script\\global\\vinh\\simcity\\config.lua")
Include("\\script\\global\\vinh\\simcity\\class\\fighter.class.lua")
IncludeLib("NPCINFO")
FighterManager = {
    fighterList = {},
    counter = 0,

}
function FighterManager:initCharConfig(config)
    config.playerID = config.playerID or "" -- dang theo sau ai do


    -- Init stats
    config.isFighting = 0
    config.tick_breath = 0
    config.tick_canswitch = 0
    config.camp = config.camp or random(1, 3)
    config.walkMode = config.walkMode or "random"
    config.noRevive = config.noRevive or 0
    config.fightingScore = 0
    config.rank = 1
    local randomPos = 1
    if config.originalWalkPath ~= nil then
        randomPos = getn(config.originalWalkPath)
        if randomPos < 1 then
            randomPos = 1
        end
    end
    config.hardsetPos = config.hardsetPos or random(1, randomPos)
    config.ngoaitrang = config.ngoaitrang or 0
    config.cap = config.cap or 1
    config.role = config.role or "citizen"
    config.level = config.level or 95

    if config.cap and config.cap ~= "auto" then
        config.maxHP = SimCityNPCInfo:getHPByCap(config.cap)
    end
end

function FighterManager:isValidChar(id)
    if SimCityNPCInfo:notValidChar(id) == 1 or SimCityNPCInfo:isBlacklisted(id) == 1 or
        SimCityNPCInfo:notFightingChar(id) == 1 then
        return 0
    end

    return 1
end

function FighterManager:Add(config)
    -- Not a valid char ?
    if self:isValidChar(config.nNpcId) == 0 then
        return 0
    end

    local worldInfo = SimCityWorld:Get(config.nMapId)

    -- All good generate name for Thanh Thi
    if config.mode == nil or config.mode == "thanhthi" then
        if worldInfo.showName == 1 then
            if (not config.szName) or config.szName == "" then
                config.szName = SimCityNPCInfo:getName(config.nNpcId)
            end
        else
            config.szName = " "
        end
    end

    self:initCharConfig(config)

    -- Setup GROUP ID and keep a record of it
    self.counter = self.counter + 1

    local id = self.counter
    config.id = id

    local newFighter = NpcFighter:New(config)
    if newFighter then
        self.fighterList["n" .. id] = newFighter
        return id
    else
        return 0
    end
end

function FighterManager:Get(nListId)
    return self.fighterList["n" .. nListId]
end

function FighterManager:Remove(nListId)
    local fighter = self.fighterList["n" .. nListId]
    if fighter.children then
        for i = 1, getn(fighter.children) do
            local child = self:Get(fighter.children[i])
            if child then
                self.fighterList["n" .. child.id] = nil
                child:Remove()
            end
        end
    end
    fighter:Remove()
    self.fighterList["n" .. nListId] = nil
end

function FighterManager:ClearMap(nW, targetListId)
    -- Get info for npc in this world
    for key, fighter in self.fighterList do
        if fighter.nMapId == nW then
            if (not targetListId) or (targetListId == fighter.id) then
                self:Remove(fighter.id)
            end
        end
    end
end

function _sortByScore(tb1, tb2)
    return tb1[2] > tb2[2]
end

function FighterManager:ThongBaoBXH(nW)
    -- Collect all data
    local allPlayers = {}
    for i, fighter in self.fighterList do
        if fighter.nMapId == nW then
            tinsert(allPlayers, { i, fighter.fightingScore, "npc" })
        end
    end

    if (SimCityTongKim.playerInTK and SimCityTongKim.playerInTK[nW]) then
        for pId, data in SimCityTongKim.playerInTK[nW] do
            tinsert(allPlayers, { pId, data.score, "player" })
        end
    end

    if getn(allPlayers) > 1 then
        local maxIndex = getn(allPlayers)
        if maxIndex > 10 then
            maxIndex = 10
        end

        sort(allPlayers, _sortByScore)

        Msg2Map(nW, "<color=yellow>========= B¶NG XÕP H¹NG =========<color>")
        Msg2Map(nW, "<color=yellow>=================================<color>")

        for j = 1, maxIndex do
            local info = allPlayers[j]

            if info[3] == "npc" then
                local fighter = self.fighterList[info[1]]
                if fighter then
                    local phe = ""

                    if (fighter.tongkim == 1) then
                        if (fighter.tongkim_name) then
                            phe = fighter.tongkim_name
                        else
                            phe = "Kim"
                            if fighter.camp == 1 then
                                phe = "Tèng"
                            end
                        end
                    end

                    if phe == "Kim" then
                        phe = "K"
                    else
                        phe = "T"
                    end

                    local msg = "<color=white>" .. j .. " <color=yellow>[" .. phe .. "] " ..
                        SimCityTongKim.RANKS[fighter.rank] .. " <color>" ..
                        (fighter.hardsetName or SimCityNPCInfo:getName(fighter.nNpcId)) .. "<color=white> (" ..
                        allPlayers[j][2] .. ")<color>"
                    Msg2Map(nW, msg)
                end
            else
                local tbPlayer = SimCityTongKim.playerInTK[nW][info[1]]
                local msg = "<color=white>" .. j .. " <color=red>[" .. (tbPlayer.phe) .. "] " .. (tbPlayer.rank) ..
                    " <color>" .. (tbPlayer.name) .. "<color=white> (" .. (tbPlayer.score) .. ")<color>"
                Msg2Map(nW, msg)
            end
        end
        Msg2Map(nW, "<color=yellow>=================================<color>")
    end
end

function FighterManager:AddScoreToAroundNPC(fighter, nNpcIndex, currRank)
    local allNpcs, nCount = Simcity_GetNpcAroundNpcList(nNpcIndex, 15)
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

--EventSys:GetType("LeaveMap"):Reg("ALL", FighterManager.OnPlayerLeaveMap, FighterManager)
-- EventSys:GetType("EnterMap"):Reg("ALL", FighterManager.OnPlayerEnterMap, FighterManager)
