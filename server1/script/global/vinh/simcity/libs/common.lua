IncludeLib("NPCINFO")
if not GetNpcAroundNpcList then
    function GetNpcAroundNpcList(nNpcIndex, nRadius)
        return {}, 0
    end
end

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


function SimCityTableFromFile(strFilePatch, tbPattern)	
	if (TabFile_Load(strFilePatch, strFilePatch) == 0) then
		print("Load TabFile Error!"..strFilePatch)
		return nil
	else
		local tbResult = {}
		local nRowCount = TabFile_GetRowCount(strFilePatch)
        
		for i = 2, nRowCount do
			tbResult[i-1] = {}
			for j = 1, getn(tbPattern) do
				local tmp = nil
				if tbPattern[j] == "*n" then
					tmp = tonumber(TabFile_GetCell(strFilePatch, i, j))
				elseif tbPattern[j] == "*w" then
					tmp = tostring(TabFile_GetCell(strFilePatch, i, j))
				end
				tinsert(tbResult[i-1], tmp)
			end
		end
		return tbResult
	end
end

function getObjectKeys(tbl)
    local result = {}
    for k,v in tbl do
        tinsert(result, k)
    end
    return result
end

function _sortByScore(tb1, tb2)
	return tb1[2] > tb2[2]
end