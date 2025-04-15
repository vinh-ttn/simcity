Include("\\script\\global\\vinh\\simcity\\components\\sim.core.lua")
SimCitizen = objCopy(SimCore)

SimCitizen.fighterList = {}  -- Override with own list
SimCitizen.counter = 1
SimCitizen.removedIds = {}

function SimCitizen:New(fighter)

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
        id = nListId,
        children = nil,
        worldInfo = SimCityWorld:Get(fighter.nMapId),
        last2VisitedEdges = {} -- Track last visited edges for more natural movement
    }

    -- Check if worldInfo is nil
    if (tbNpc.worldInfo == nil) then
        return nil
    end


    for k, v in fighter do
        tbNpc[k] = v
    end

    -- Check if walkGraph is nil
    if (tbNpc.role == "citizen" and tbNpc.worldInfo.walkGraph == nil) then
        return nil
    end

    -- Initialize foundDialogNpcOnPaths in worldInfo if it doesn't exist
    if tbNpc.worldInfo.walkPaths and not tbNpc.worldInfo.foundDialogNpcOnPaths then
        tbNpc.worldInfo.foundDialogNpcOnPaths = {}
    end

    
    -- All good generate name for Thanh Thi
    if tbNpc.mode == nil or tbNpc.mode == "thanhthi" or tbNpc.mode == "train" then
        if tbNpc.worldInfo.showName == 1 then
            if (not tbNpc.szName) or tbNpc.szName == "" then
                tbNpc.szName = SimCityNPCInfo:getName(tbNpc.nNpcId)
            end
        else
            tbNpc.szName = " "
        end
    end

    self.fighterList[nListId] = tbNpc

    -- Setup walk paths
    if tbNpc.movementSys:resetPos(self, nListId) == 0 then
        return nil
    end

    -- Bugfix series
    if tbNpc.series == nil then
        tbNpc.series = random(0,4)
    end

    -- Create the character on screen
    local canCreate = tbNpc.entitySys:CreateChar(self, tbNpc, 1, tbNpc.goX, tbNpc.goY)
    if canCreate == 0 then
        return nil
    end


    -- What about childrenSetup?
    self:initChildrenConfig(nListId, fighter)
    return nListId
end
 

-- For parent
function SimCitizen:initChildrenConfig(nListId, parentConfig)
    local tbNpc = self.fighterList[nListId]
    if tbNpc.childrenSetup and getn(tbNpc.childrenSetup) > 0 then
        local createdChildren = {}

        local nX32, nY32, nW32 = GetNpcPos(tbNpc.finalIndex)
        local nW = SubWorldIdx2ID(nW32)
        local nX = nX32 / 32
        local nY = nY32 / 32

        -- Create children
        for i = 1, getn(tbNpc.childrenSetup) do
            local childConfig = objCopy(parentConfig)
            childConfig.parentID = tbNpc.id
            childConfig.childID = i
            childConfig.role = "child"
            childConfig.hardsetName = nil
            childConfig.childrenSetup = nil
            for k, v in tbNpc.childrenSetup[i] do
                childConfig[k] = v
            end
            childConfig.goX = nX
            childConfig.goY = nY
            local childId = self:New(childConfig)
            tinsert(createdChildren, childId)
        end

        tbNpc.children = createdChildren
    end
end

function SimCitizen:ClearMap(nW, clearType)
    -- Get info for npc in this world
    for key, fighter in self.fighterList do
        if fighter.nMapId == nW then
            if (not clearType) then
                self:Remove(fighter.id)
            elseif clearType == "thanhthi" then
                if fighter.mode ~= "chiendau" then
                    self:Remove(fighter.id)
                end
            elseif clearType == "chiendau" then
                if fighter.mode == "chiendau" then
                    self:Remove(fighter.id)
                end
            end
        end
    end
end


function SimCitizen:ThongBaoBXH(nW)
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



-- Override parent initCharConfig
function SimCitizen:initCharConfig(config)

    config.role = config.role or "citizen"
    config.currentPointIndex = nil
    config.pathDirection = 1  -- 1 for forward, -1 for backward

    SimCore:initCharConfig(config)
end