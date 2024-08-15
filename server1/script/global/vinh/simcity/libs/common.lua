IncludeLib("NPCINFO")

-- Helpers
function GetTabFileData(path, tab_name, start_row, max_col) -- Doc file txt
    if TabFile_Load(path, tab_name) ~= 1 then
        return {}, 0
    end
    if not start_row or start_row < 1 then start_row = 1 end
    if not max_col or max_col < 1 then max_col = 1 end
    local nCount = TabFile_GetRowCount(tab_name)
    local tbData = {}
    for y = start_row, nCount do
        local tbTemp = {}
        for x = 1, max_col do tinsert(tbTemp, TabFile_GetCell(tab_name, y, x)) end
        tinsert(tbData, tbTemp)
    end
    return tbData, nCount - start_row + 1
end

-- ·ÉÉ³£¨ÅüÑª¹È£©
-- §¾ý£¨
-- ²ÔåâåË£¨¸´ÖÆ£©
-- ¼ýËþ
-- 5ºÅÊÂ¼þÔÎÑ£¹Ö
-- ±¡
-- ÈË··
-- ÈË··Ê×Áì
--»ÆÉ«Ä¾ÃÞ»¨
--ÉÙÁÖ±äÉí

isChinese = { "<", ">", "ª¹", "³", "newboss", "²", "´", "åâ", "£¨", "¼ý", "ýË", "¼þ", "¼þ", "£", "º", "±", "¡", "»", "ÙÁ",
    "±", "··", "ÈË" }
function fixName(inp)
    local found = false
    for i = 1, getn(isChinese) do
        if strfind(inp, isChinese[i]) ~= nil then
            return "Qu¸i kh¸ch"
        end
    end
    return inp
end

function GetDistanceRadius(nX, nY, oX, oY)
    return sqrt((nX - oX) * (nX - oX) + (nY - oY) * (nY - oY))
end

function arrFlip(arr)
    local newFlipArr = {}
    local N = getn(arr)
    for i = 1, N do
        tinsert(newFlipArr, arr[N - i + 1])
    end
    return newFlipArr
end

function arrCopy(arr)
    local newFlipArr = {}
    local N = getn(arr)
    for i = 1, N do
        if type(arr[i]) == 'table' then
            tinsert(newFlipArr, arrCopy(arr[i]))
        else
            tinsert(newFlipArr, arr[i])
        end
    end
    return newFlipArr
end

function arrJoin(arr)
    local output = {}
    for i = 1, getn(arr) do
        for j = 1, getn(arr[i]) do
            tinsert(output, arr[i][j])
        end
    end
    return output
end

function objCopy(obj)
    local output = {}
    if obj then
        for k, v in obj do
            output[k] = v
        end
    end
    return output
end

function spawnN(arr, linh, N, config)
    N = N or 16
    for i = 1, N do
        local child = objCopy(config)
        child.nNpcId = linh
        tinsert(arr, child)
    end
    return arr
end

function DelNpcSafe(nNpcIndex)
    if (not nNpcIndex) or (nNpcIndex <= 0) then
        return
    end

    PIdx = NpcIdx2PIdx(nNpcIndex)
    if (PIdx > 0) then
        return
    end
    DelNpc(nNpcIndex)
end

function IsAttackableCamp(camp1, camp2)
    if (camp1 ~= camp2) then
        if camp1 == 0 and camp2 == 5 then
            return 1
        end

        if camp2 == 0 and camp1 == 5 then
            return 1
        end
        if camp1 ~= 0 and camp2 ~= 0 then
            return 1
        end
    end
    return 0
end

function KhoaTHP(nOwnerIndex, flag)
    if nOwnerIndex > 0 then
        CallPlayerFunction(nOwnerIndex, DisabledUseTownP, flag)
        CallPlayerFunction(nOwnerIndex, DisabledUseHeart, flag)
    end
end

function Simcity_GetNpcAroundNpcList(nNpcIndex, radius)
    local allNpcs = {}
    local nCount = 0

    -- 8.0: has GetNpcAroundNpcList function
    if GetNpcAroundNpcList then
        return GetNpcAroundNpcList(nNpcIndex, radius)

        -- 6.0: do the long route
    else
        local myListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
        local nX32, nY32, nW32 = GetNpcPos(nNpcIndex)
        local areaX = nX32 / 32
        local areaY = nY32 / 32
        local nW = SubWorldIdx2ID(nW32)

        -- Get info for npc in this world
        for key, fighter in FighterManager.fighterList do
            if fighter.isDead == 0 and fighter.nMapId == nW and fighter.id ~= myListId then
                local oX32, oY32 = GetNpcPos(fighter.finalIndex)
                local oX = oX32 / 32
                local oY = oY32 / 32
                if GetDistanceRadius(oX, oY, areaX, areaY) < radius then
                    tinsert(allNpcs, fighter.finalIndex)
                    nCount = nCount + 1
                end
            end
        end
    end

    return allNpcs, nCount
end

function IsNearStation(pId)
    local fighterList = CallPlayerFunction(pId, GetAroundNpcList, 30)
    local nNpcIdx
    for i = 1, getn(fighterList) do
        nNpcIdx = fighterList[i]
        local kind = GetNpcKind(nNpcIdx)
        local nSettingIdx = GetNpcSettingIdx(nNpcIdx)
        if kind == 3 and (nSettingIdx == 239 or nSettingIdx == 236 or nSettingIdx == 237 or nSettingIdx == 238) then
            return 1
        end
    end

    return 0
end

function arrRandomExtracItems(arr, n)
    if getn(arr) < n then
        return arr
    end

    local startIndex = random(1, getn(arr) - n + 1)
    local result = {}

    for i = startIndex, startIndex + n - 1 do
        tinsert(result, arr[i])
    end

    return result
end
