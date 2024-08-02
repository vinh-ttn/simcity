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

function getCenteredCell(X)
    local centerRow = floor((X[2] + 1) / 2)
    local centerCol = floor((X[1] + 1) / 2)
    return centerRow * centerCol
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

function genCoords_squareshape(targetFrom, targetTo, N)
    local walkpath = { targetFrom, { (targetFrom[1] + targetTo[1]) / 2, (targetFrom[2] + targetTo[2]) / 2 }, targetTo }
    local f = createFormation(N)
    local targetPointer = 3
    local rows = f[1] > f[2] and f[1] or f[2]
    local cols = f[1] > f[2] and f[2] or f[1]
    local spacing = 1
    local pathLength = getn(walkpath)

    -- Variables
    local toPos = walkpath[targetPointer]

    local fromPos
    if (targetPointer == 1) then
        fromPos = walkpath[2]
    else
        fromPos = walkpath[targetPointer - 1]
    end

    -- Given a target X and Y
    local x = toPos[1]
    local y = toPos[2]
    local xF = fromPos[1]
    local yF = fromPos[2]

    local mostLeft = 0
    local mostRight = 0
    local mostTop = 0
    local mostBottom = 0

    local rhombus = {}
    local total = 0
    for i = 0, rows do
        for j = 0, cols - 1 do
            total = total + 1

            local newX = x + j * spacing
            local newY = y + j * spacing

            local newXF = xF + j * spacing
            local newYF = yF + j * spacing

            if (mostLeft > newX or mostLeft == 0) then
                mostLeft = newX
            end
            if (mostTop > newY or mostTop == 0) then
                mostTop = newY
            end
            if (mostRight < newX or mostRight == 0) then
                mostRight = newX
            end
            if (mostBottom < newY or mostBottom == 0) then
                mostBottom = newY
            end
            tinsert(rhombus, { newX, newY, newXF, newYF })
        end
        y = y - spacing
        x = x + spacing

        yF = yF - spacing
        xF = xF + spacing
    end

    -- And we need to shift it back to centre of the original path
    local centreX = (mostRight + mostLeft) / 2
    local centreY = (mostBottom + mostTop) / 2
    local offSetX = centreX - toPos[1]
    local offSetY = centreY - toPos[2]
    for i = 1, total do
        rhombus[i] = transformRhombus({ rhombus[i][1] - offSetX, rhombus[i][2] - offSetY, rhombus[i][3] - offSetX,
            rhombus[i][4] - offSetY }, toPos, fromPos, toPos)
    end

    -- DONE
    return rhombus
end
