Include("\\script\\global\\vinh\\simcity\\libs\\common.lua")

settingsPath = "\\settings\\global\\vinh\\simcity\\"
SimCityPlayerNames = {}
SimCityChat = {}
SimCityMap = {}
SimCityPets = {}

SimCityPhai = {
    id2phai={}
}


-- Doc ten
function loadNames()
    local namesData = SimCityTableFromFile(settingsPath.. "names.txt", {"*w"})
    for i=1, getn(namesData) do
        tinsert(SimCityPlayerNames, namesData[i][1])
    end
end

-- Doc chat
function loadChat()
    local chatData = SimCityTableFromFile(settingsPath.. "chat.txt", {"*w", "*w"})
    for i=1, getn(chatData) do
    if not SimCityChat[chatData[i][1]] then  
        SimCityChat[chatData[i][1]] = {}
    end
        tinsert(SimCityChat[chatData[i][1]], chatData[i][2])
    end
end

-- Doc pets
function loadPets()
    -- nId cat name
    local petsData = SimCityTableFromFile(settingsPath.. "pets.txt", {"*n", "*w", "*w", "*n"})

    SimCityPets.allCats = {}
    SimCityPets.allPets = {}
    for i=1, getn(petsData) do
        local petId = petsData[i][1]
        local petCategory = petsData[i][2]		
		local petName = petsData[i][3]
        local petCost = petsData[i][4]

        if petId > 0 then
            if not SimCityPets[petCategory] then  
                SimCityPets[petCategory] = {}
                tinsert(SimCityPets.allCats, petCategory)
            end
            tinsert(SimCityPets[petCategory], i)
            SimCityPets.allPets[i] = {petName, petId, petCost}
        end
    end
end

-- Doc map thanh thi va chien tranh
function createWorldIfNotExists(worldId, worldName)
    if not SimCityMap[worldId] then
        SimCityMap[worldId] = {
            worldId = worldId,
            name = worldName,
            nodes = {},
            presetPaths = {},
            decoration = {}
        }
    end
    return SimCityMap[worldId]
end
function loadMap()
    local mapPath = settingsPath.. "maps\\"
    local thanhthiData = SimCityTableFromFile(mapPath.. "thanhthi.txt", {"*n", "*w", "*w", "*w"})
    local haudoanhData = SimCityTableFromFile(mapPath.. "haudoanh.txt", {"*n", "*w", "*w"})
    local trangtriData = SimCityTableFromFile(mapPath.. "trangtri.txt", {"*n", "*w", "*w"})
    local attractionsData = SimCityTableFromFile(mapPath.. "attractions.txt", {"*n", "*w", "*n", "*n", "*w", "*n"}) -- worldId, worldName, pX, pY, description, dialogNpcId
    if not thanhthiData then
        return
    end

    -- Load attractions
    local mapAtractions = {}
    for i = 1, getn(attractionsData) do
        local entry = attractionsData[i]
        local worldId = entry[1]
        local worldName = entry[2]
        local pX = entry[3]
        local pY = entry[4]
        local description = entry[5]
        local dialogNpcId = entry[6]
        if not mapAtractions[worldId] then
            mapAtractions[worldId] = {
                {pX, pY, dialogNpcId}
            }
        else
            tinsert(mapAtractions[worldId], {pX, pY, dialogNpcId})
        end
    end


    -- Load thanh thi nodes
    for i = 1, getn(thanhthiData) do
        local entry = thanhthiData[i]
        local worldId = entry[1]
        local worldName = entry[2]
        local filePath = entry[3]
        local fileType = entry[4]

        local world = createWorldIfNotExists(worldId, worldName)

        -- Nodes
        if fileType == "nodes" then
            -- nodename, linkednodes, isExact, type
            local foundWalkPath = SimCityTableFromFile(mapPath.. filePath, {"*w", "*w", "*n", "*n"})

            local allNodes = {}
            
            for i=1, getn(foundWalkPath) do
                
                local col = foundWalkPath[i]
                local nodeName = col[1]

                local x, y = nodeNameToCoords(nodeName)
                if i == 1 then
                    world.firstNode = {x, y}
                end
                local linkedNodes = split(col[2], ",")
                local isExact = col[3]
                local nodeType = col[4]
                
                allNodes[nodeName] = {
                    x = x,
                    y = y,
                    linkedNodes = linkedNodes, 
                    isExact = isExact, 
                    nodeType = nodeType, -- 0: normal, 1: war
                    isNearAtraction = 0,
                    isNotPreset = 1
                }

                if mapAtractions[worldId] then
                    for j=1, getn(mapAtractions[worldId]) do
                        local atraction = mapAtractions[worldId][j]
                        if GetDistanceRadius(x, y, atraction[1], atraction[2]) < 8 then
                            allNodes[nodeName].isNearAtraction = atraction[3]
                            break
                        end
                    end
                end
            end
            world.nodes = allNodes
        end
    end

    -- Load thanh thi preset
    for i = 1, getn(thanhthiData) do
        local entry = thanhthiData[i]
        local worldId = entry[1]
        local worldName = entry[2]
        local filePath = entry[3]
        local fileType = entry[4]

        local world = createWorldIfNotExists(worldId, worldName)
        
        if fileType == "preset" then
            local foundWalkMap = SimCityTableFromFile(mapPath.. filePath, {"*w", "*w"})

            allPaths = {}
            for i=1, getn(foundWalkMap) do
                local pathName = foundWalkMap[i][1]
                local nodeName = foundWalkMap[i][2]

                if not allPaths[pathName] then
                    allPaths[pathName] = {}
                end
                tinsert(allPaths[pathName], nodeName)
            end
            world.presetPaths = allPaths
        end
    end

    -- Load trang tri
    for i = 1, getn(trangtriData) do
        local entry = trangtriData[i]
        local worldId = entry[1]
        local worldName = entry[2]
        local filePath = entry[3]

        local trangtriData = SimCityTableFromFile(mapPath.. filePath, {"*n", "*n", "*n", "*w", "*w"})
        if SimCityMap[worldId] and trangtriData then
            local allData = {}
            for i=1, getn(trangtriData) do
                tinsert(allData, {trangtriData[i][1], trangtriData[i][2], trangtriData[i][3], trangtriData[i][5]})
            end
            SimCityMap[worldId].decoration = allData
        end
    end

    -- Load haudoanh
    for i = 1, getn(haudoanhData) do
        local entry = haudoanhData[i]
        local worldId = entry[1]
        local campName = entry[2]
        local nodeName = entry[3]

        if SimCityMap[worldId] then
            if not SimCityMap[worldId].presetPaths[campName] then
                SimCityMap[worldId].presetPaths[campName] = {}
            end
            tinsert(SimCityMap[worldId].presetPaths[campName], nodeName)
        end
    end

    -- Final touch, for those missing node definition in preset paths
    for worldId, world in SimCityMap do
        if world.presetPaths then
            for presetName, preset in world.presetPaths do
                for i=1, getn(preset) do
                    local nodeName = preset[i]
                    if not world.nodes[nodeName] then
                        local x, y = nodeNameToCoords(nodeName)

                        -- Try to snap to existing nodes within 16 radius
                        local snappedNode = nil
                        local minDist = 8
                        for existingNode, nodeData in world.nodes do
                            local dist = GetDistanceRadius(x, y, nodeData.x, nodeData.y)
                            if dist <= minDist then
                                snappedNode = existingNode
                                minDist = dist
                            end
                        end

                        -- Replace current preset node with snapped node if found
                        local testNode = nodeName
                        if snappedNode then
                            testNode = snappedNode
                        end

                        if world.nodes[testNode] and world.nodes[testNode].isNotPreset == 1 then
                            preset[i] = testNode
                        else
                            world.nodes[nodeName] = {
                                nodeType = 1,
                                x = x,
                                y = y,
                                linkedNodes = {},
                                isExact = 0,
                                isNearAtraction = 0,
                                isNotPreset = 0
                            }
                        
                            -- Find linked nodes within 16 radius
                            for otherNodeName, otherNode in world.nodes do
                                if otherNodeName ~= testNode and otherNodeName ~= nodeName then
                                    local dx = otherNode.x - world.nodes[testNode].x
                                    local dy = otherNode.y - world.nodes[testNode].y
                                    
                                    if GetDistanceRadius(x, y, otherNode.x, otherNode.y) <= 16 then
                                        tinsert(world.nodes[nodeName].linkedNodes, otherNodeName)
                                        
                                        -- Add this node to the other node's linkedNodes that other was not preset
                                        local found = 0
                                        if otherNode.isNotPreset == 0 then
                                            for j=1, getn(otherNode.linkedNodes) do
                                                if otherNode.linkedNodes[j] == nodeName then
                                                    found = 1
                                                    break
                                                end
                                            end
                                            if found == 0 then
                                                tinsert(otherNode.linkedNodes, nodeName)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if world.presetPaths.campduoi then
                world.presetPaths.baseDuoi = {"campduoi"}
            end

            if world.presetPaths.camptren then
                world.presetPaths.baseTren = {"camptren"}
            end
        end
    end
end

-- Doc phai
function loadFactions()
    local phaiData = SimCityTableFromFile(settingsPath.. "skills.txt", {"*w", "*n", "*w", "*w", "*n", "*n", "*n", "*n"})
    
    -- Duong mon khong co skill bi dong gi ca
    SimCityPhai["duongmon"] = {
        noCast = {},
        needCast = {},
        normalCast = {},
        knownIds = {}
    }

    for i=1, getn(phaiData) do
        local phai = phaiData[i][1]
        local skillId = phaiData[i][2]
        local skillName = phaiData[i][3]
        local skillDesc = phaiData[i][4]
        local skillMaxLevel = phaiData[i][5]
        local skillNoCast = phaiData[i][6]
        local skillNeedCast = phaiData[i][7]
        local skillCost = phaiData[i][8]
        

        if not SimCityPhai[phai] then
            SimCityPhai[phai] = {
                noCast = {},
                needCast = {},
                normalCast = {},
                knownIds = {}
            }
        end
        if skillNoCast > 0 then
            tinsert(SimCityPhai[phai].noCast, {skillId, skillMaxLevel, skillName, skillCost, i})
        elseif skillNeedCast > 0 then
            tinsert(SimCityPhai[phai].needCast, {skillId, skillMaxLevel, skillName, skillCost, i})
        else
            tinsert(SimCityPhai[phai].normalCast, {skillId, skillMaxLevel, skillName, skillCost, i})
        end
    end

    local id2factionData = SimCityTableFromFile(settingsPath.. "npcid2faction.txt", {"*n", "*w", "*n", "*n"})
    for i=1, getn(id2factionData) do
        local id = id2factionData[i][1]
        local faction = id2factionData[i][2]
        local series = id2factionData[i][3]
        local gen = id2factionData[i][4]
        if SimCityPhai[faction] then    
            SimCityPhai[faction].knownIds[id] = {series=series, gen=gen}
            SimCityPhai.id2phai[id] = faction
        end
        
    end

end

-- EXECUTION
loadNames()
loadChat()
loadMap()
loadPets()
loadFactions()