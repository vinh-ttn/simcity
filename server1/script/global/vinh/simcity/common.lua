
-- Helpers
function GetTabFileData( path, tab_name, start_row, max_col ) -- Doc file txt
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

isChinese = {"<",">","ª¹","³","newboss","²","´","åâ","£¨","¼ý","ýË","¼þ","¼þ","£","º","±", "¡", "»", "ÙÁ","±", "··", "ÈË"}
function fixName(inp)
	local found = false 
	for i=1,getn(isChinese) do 
		if strfind(inp,isChinese[i]) ~= nil then
			return "Qu¸i kh¸ch"
		end
	end 
	return inp
end



function GetDistanceRadius(nX,nY,oX,oY)
	return sqrt((nX-oX)*(nX-oX) + (nY - oY)*(nY - oY))		
end


function arrFlip(arr)
    local newFlipArr = {}
    local N = getn(arr)
    for i=1,N do         
        tinsert(newFlipArr, arr[N-i+1])
    end
    return newFlipArr
end


function spawnN(arr, linh, N, name) 
    N = N or 16
    for i=1,N do
        tinsert(arr, {nNpcId=linh, szName = name})
    end 
    return arr
end


function DelNpcSafe(nNpcIndex)

    if (not nNpcIndex) or (nNpcIndex <= 0 )  then
            return
    end

    PIdx = NpcIdx2PIdx(nNpcIndex)
    if (PIdx > 0) then
        return
    end

    DelNpc(nNpcIndex)
end

