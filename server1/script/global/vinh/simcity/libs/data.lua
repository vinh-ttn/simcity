Include("\\script\\global\\vinh\\simcity\\libs\\common.lua")

settingsPath = "\\settings\\global\\vinh\\simcity\\"
SimCityPlayerNames = {}
SimCityChat = {}
SimCityMap = {}

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

-- Doc map thanh thi va chien tranh
function loadMap()
    local mapPath = settingsPath.. "maps\\"
    local thanhthiData = SimCityTableFromFile(mapPath.. "thanhthi.txt", {"*n", "*w", "*w"})
    local chientranhData = SimCityTableFromFile(mapPath.. "chientranh.txt", {"*n", "*w", "*w", "*w"})
    local trangtriData = SimCityTableFromFile(mapPath.. "trangtri.txt", {"*n", "*w", "*w"})

    if not thanhthiData or not chientranhData then
        return
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
        local foundWalkPath = SimCityTableFromFile(mapPath.. filePath, {"*w", "*n", "*n"})

        local allPath = {}
        for i=1, getn(foundWalkPath) do
            if not allPath[foundWalkPath[i][1]] then
                allPath[foundWalkPath[i][1]] = {}
            end
            tinsert(allPath[foundWalkPath[i][1]], {foundWalkPath[i][2], foundWalkPath[i][3]})
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

-- EXECUTION
loadNames()
loadChat()
loadMap()