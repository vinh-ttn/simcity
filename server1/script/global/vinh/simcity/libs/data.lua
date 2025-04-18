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
function loadMap()
    local mapPath = settingsPath.. "maps\\"
    local thanhthiData = SimCityTableFromFile(mapPath.. "thanhthi.txt", {"*n", "*w", "*w"})
    local chientranhData = SimCityTableFromFile(mapPath.. "chientranh.txt", {"*n", "*w", "*w", "*w"})
    local trangtriData = SimCityTableFromFile(mapPath.. "trangtri.txt", {"*n", "*w", "*w"})
    local attractionsData = SimCityTableFromFile(mapPath.. "attractions.txt", {"*n", "*w", "*n", "*n", "*w", "*n"}) -- worldId, worldName, pX, pY, description, dialogNpcId
    if not thanhthiData or not chientranhData then
        return
    end

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

    for i = 1, getn(thanhthiData) do
        local entry = thanhthiData[i]
        local worldId = entry[1]
        local worldName = entry[2]
        local filePath = entry[3]

        if not SimCityMap[worldId] then
            SimCityMap[worldId] = {
                worldId = worldId,
                name = worldName,
                walkPaths = {},
                decoration = {}
            }
        end
        local world = SimCityMap[worldId]
        local foundWalkPath = SimCityTableFromFile(mapPath.. filePath, {"*w", "*n", "*n", "*n"})

        local allPath = {}
        for i=1, getn(foundWalkPath) do
            if not allPath[foundWalkPath[i][1]] then
                allPath[foundWalkPath[i][1]] = {}
            end

            local nX = foundWalkPath[i][2]
            local nY = foundWalkPath[i][3]
            local isExact = foundWalkPath[i][4]
            local isNearAtraction = 0
            if mapAtractions[worldId] then
                for j=1, getn(mapAtractions[worldId]) do
                    local atraction = mapAtractions[worldId][j]
                    if GetDistanceRadius(nX, nY, atraction[1], atraction[2]) < 8 then
                        isNearAtraction = atraction[3]
                        break
                    end
                end
            end
            tinsert(allPath[foundWalkPath[i][1]], {nX, nY, isExact, isNearAtraction})
        end
        world.walkPaths = allPath
 
    end

    for i = 1, getn(chientranhData) do
        local entry = chientranhData[i]
        local worldId = entry[1]
        local worldName = entry[2]
        local camp = entry[3]
        local pathName = entry[4]

        if not SimCityMap[worldId] then
            SimCityMap[worldId] = {
                worldId = worldId,
                name = worldName,
                chientranh = {
                    path1 = {},
                    path2 = {}
                },
                decoration = {},
                walkPaths = {}
            }
        end

        local world = SimCityMap[worldId]
        if not world.chientranh then
            world.chientranh = {
                path1 = {},
                path2 = {}
            }
        end
        
        if camp == "camp1" then            
            tinsert(world.chientranh.path1, pathName)
        elseif camp == "camp2" then
            tinsert(world.chientranh.path2, pathName)
        end
    end

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
end

-- Doc phai
function loadFactions()
    local phaiData = SimCityTableFromFile(settingsPath.. "skills.txt", {"*w", "*n", "*w", "*w", "*n", "*n", "*n"})
    
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
        

        if not SimCityPhai[phai] then
            SimCityPhai[phai] = {
                noCast = {},
                needCast = {},
                normalCast = {},
                knownIds = {}
            }
        end
        if skillNoCast > 0 then
            tinsert(SimCityPhai[phai].noCast, {skillId, skillMaxLevel, skillName})
        elseif skillNeedCast > 0 then
            tinsert(SimCityPhai[phai].needCast, {skillId, skillMaxLevel, skillName})
        else
            tinsert(SimCityPhai[phai].normalCast, {skillId, skillMaxLevel, skillName})
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