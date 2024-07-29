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

function spawnN(arr, linh, N, config)
    N = N or 16
    for i = 1, N do
        local child = {}
        if config ~= nil then
            for k, v in config do
                child[k] = v
            end
        end
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

function createDiagonalFormPath(points)
    local n = getn(points)

    if n < 3 then
        -- Not enough points to form a line
        return points
    end

    local results = { points[1] }

    -- Iterate through the points starting from the second point
    for i = 2, n - 1 do
        local A = points[i - 1]
        local B = points[i]
        local C = points[i + 1]

        -- Calculate the angles between line segments AB and BC
        local angleAB = atan2(B[2] - A[2], B[1] - A[1])
        local angleBC = atan2(C[2] - B[2], C[1] - B[1])

        -- Calculate the difference in angles
        local angleDiff = abs(angleBC - angleAB)


        if (B[3] and B[3] == 1) or angleDiff >= 20 then
            tinsert(results, B)
        else
            local distance = GetDistanceRadius(A[1], A[2], C[1], C[2])

            -- Too close, we get rid of point B
            if distance < 20 then
                i = i + 1 -- jump
            else
                -- Adjust the position of point B to make the angle closer to 180 degrees
                --B[1] = (A[1] + C[1]) / 2
                --B[2] = (A[2] + C[2]) / 2
                tinsert(results, B)
            end
        end
    end

    tinsert(results, points[getn(points)])

    -- Return the corrected points
    return results
end

function createFormation(N)
    local bestX = 1
    local bestY = N

    local stop = 0
    local closestDifference = 1000

    for x = 1, N do
        if stop == 0 then
            local y = N / x
            if mod(N, x) == 0 and mod(N, y) == 0 and y <= x and y ~= 1 then
                bestX = x
                bestY = y
                stop = 1
            elseif (y < x) and (x - y < closestDifference) then
                bestX = x
                bestY = ceil(y)
                closestDifference = x - y
            end
        end
    end

    return { bestX, bestY }
end

function randomRange(point, walkVar)
    if walkVar == 0 then
        return { point[1], point[2] }
    end
    return { point[1] + random(-walkVar, walkVar), point[2] + random(-walkVar, walkVar) }
end

function transformRhombus(point, centrePoint, fromPos, toPos)
    local deltaX = toPos[1] - fromPos[1]
    local deltaY = toPos[2] - fromPos[2]

    local offsetAngle = atan2(deltaY, deltaX) + 45


    offsetAngle = floor(offsetAngle / 45 + 0.5) * 45

    -- Input coordinates
    local x = centrePoint[1] -- x-coordinate of point O
    local y = centrePoint[2] -- y-coordinate of point O
    local x1 = point[1]      -- x-coordinate of point A
    local y1 = point[2]      -- y-coordinate of point A
    local xF = fromPos[1]    -- x-coordinate of point A
    local yF = fromPos[2]    -- y-coordinate of point A

    -- Calculate the angle OA makes with the x-axis
    local angle_OA = atan2(y1 - y, x1 - x)

    -- Calculate the new angle for OA' (45 degrees more than angle_OA)
    local angle_OA_prime = angle_OA + offsetAngle

    -- Calculate the distance from O to A'
    local distance_OA_prime = sqrt((x1 - x) ^ 2 + (y1 - y) ^ 2)

    -- Calculate the new coordinates for A'
    local x_prime = x + distance_OA_prime * cos(angle_OA_prime)
    local y_prime = y + distance_OA_prime * sin(angle_OA_prime)

    local xF_prime = xF + distance_OA_prime * cos(angle_OA_prime)
    local yF_prime = yF + distance_OA_prime * sin(angle_OA_prime)

    -- New toPos and fromPos
    return { x_prime, y_prime, xF_prime, yF_prime }
end

function KhoaTHP(nOwnerIndex, flag)
    if nOwnerIndex > 0 then
        CallPlayerFunction(nOwnerIndex, DisabledUseTownP, flag)
        CallPlayerFunction(nOwnerIndex, DisabledUseHeart, flag)
    end
end
