SimCityGraphToChienTranh = {

    -- Calculate distance between two nodes
    distance = function(self, node1, node2, nodes)
        local x1, y1 = nodes[node1][1], nodes[node1][2]
        local x2, y2 = nodes[node2][1], nodes[node2][2] 
        return GetDistanceRadius(x1, y1, x2, y2)
    end,

    -- Find nodes within and outside the radius of spawn points
    analyze_spawn_zones = function(self, nodes, spawn1, spawn2, radius)
        local valid_nodes = {}  -- Nodes outside both spawn zones
        local spawn1_zone = {[spawn1] = 1}  -- Nodes in spawn1's zone (including spawn1)
        local spawn2_zone = {[spawn2] = 1}  -- Nodes in spawn2's zone (including spawn2)

        -- Using direct iteration for Lua 4.0
        for node_name, nodeData in nodes do
            if node_name ~= spawn1 and node_name ~= spawn2 then
                local dist_to_spawn1 = self:distance(node_name, spawn1, nodes)
                local dist_to_spawn2 = self:distance(node_name, spawn2, nodes)
                
                if dist_to_spawn1 <= radius then
                    spawn1_zone[node_name] = 1
                end
                
                if dist_to_spawn2 <= radius then
                    spawn2_zone[node_name] = 1
                end
                
                if dist_to_spawn1 > radius and dist_to_spawn2 > radius then
                    valid_nodes[node_name] = 1
                end
            end
        end

        return valid_nodes, spawn1_zone, spawn2_zone
    end,
    

    breadth_first_search = function(self, max_paths,valid_nodes, nodes, fromNode, toNode)
        local all_paths = {}

        -- Use a queue with explicit front and rear indices
        local queue = {}
        local front = 1  -- Index for dequeue
        local rear = 1   -- Index for enqueue
        local visited = {}

        -- Initialize the queue with the start node and its path
        queue[rear] = {node = fromNode, path = {fromNode}}
        visited[fromNode] = 1  -- Track visited nodes globally to avoid cycles

        -- Set a reasonable path limit to prevent infinite loops
        local max_path_length = 100
        local paths_found = 0

        while front <= rear and paths_found < max_paths do
            local current = queue[front]
            front = front + 1  -- Dequeue by moving front pointer
            
            if not current then
                break
            end

            local current_node = current.node
            local current_path = current.path 
            
            -- If we've reached the destination, add the path to our results
            if toNode == current_node then
                paths_found = paths_found + 1
                tinsert(all_paths, current_path)
            elseif getn(current_path) < max_path_length then
                -- Otherwise, explore all connected nodes
                if nodes[current_node] and nodes[current_node][5] then
                    for i = 1, getn(nodes[current_node][5]) do
                        local neighbor = nodes[current_node][5][i] 
                        -- Check if the neighbor is valid (outside exclusion radius or is a main spawn point)
                        if (valid_nodes[neighbor] == 1 or neighbor == toNode) and not visited[neighbor] then
                            -- Create a new path with the neighbor added
                            local new_path = {}
                            for j = 1, getn(current_path) do
                                new_path[j] = current_path[j]  -- Direct index assignment
                            end
                            new_path[getn(current_path) + 1] = neighbor  -- Direct index assignment
                            
                            -- Add to queue and mark as visited
                            rear = rear + 1  -- Increment rear before adding
                            queue[rear] = {node = neighbor, path = new_path}
                            visited[neighbor] = 1
                        end
                    end
                end
            end
        end

        return all_paths
    end,

    shuffle = function(self,tbl)
        local size = getn(tbl)
        for i = size, 2, -1 do
            local j = random(1, i)
            tbl[i], tbl[j] = tbl[j], tbl[i]
        end
        return tbl
    end,

    -- Recursive DFS implementation with proper scope
    dfs = function(self, nodes, current_node, current_path, paths_found_ref, max_paths_param, max_path_length_param, all_paths_param, visited_param, valid_nodes_param, toNode_param)
        -- If we've found enough paths
        if paths_found_ref[1] >= max_paths_param then
            return paths_found_ref[1]
        end

        -- If we've reached the destination
        if current_node == toNode_param then
            paths_found_ref[1] = paths_found_ref[1] + 1
            -- Create a new path table to avoid reference issues
            local path_copy = {}
            for i = 1, getn(current_path) do
                path_copy[i] = current_path[i]
            end
            tinsert(all_paths_param, path_copy)
            return paths_found_ref[1]
        end

        -- If path is too long, backtrack
        if getn(current_path) >= max_path_length_param then
            return paths_found_ref[1]
        end

        -- Get all neighbors
        if nodes[current_node] and nodes[current_node][3] then
            -- Create a copy of edges to shuffle
            local neighbors = {}
            for i = 1, getn(nodes[current_node][3]) do
                local neighbor = nodes[current_node][3][i]
                -- Only add non-visited neighbors
                if not visited_param[neighbor] then
                    tinsert(neighbors, neighbor)
                end
            end
            
            -- Shuffle neighbors for randomization
            self:shuffle(neighbors)

            -- Try each neighbor
            for i = 1, getn(neighbors) do
                local neighbor = neighbors[i]
                
                -- Check if neighbor is valid and not visited
                if (valid_nodes_param[neighbor] == 1 or neighbor == toNode_param) then
                    -- Mark as visited
                    visited_param[neighbor] = 1
                    
                    -- Add to current path
                    tinsert(current_path, neighbor)
                    
                    -- Recurse with updated path
                    paths_found_ref[1] = self:dfs(nodes, neighbor, current_path, paths_found_ref, max_paths_param, max_path_length_param, all_paths_param, visited_param, valid_nodes_param, toNode_param)
                    
                    -- Backtrack: remove from path and visited
                    tremove(current_path)
                    visited_param[neighbor] = nil
                    
                    -- If we've found enough paths, stop exploring
                    if paths_found_ref[1] >= max_paths_param then
                        return paths_found_ref[1]
                    end
                end
            end
        end
        return paths_found_ref[1]
    end,
    -- Depth first search with randomization for finding paths
    depth_first_search = function(self, max_paths, valid_nodes, nodes, fromNode, toNode)
        local all_paths = {}
        local paths_found = 0
        local max_path_length = 100  -- Maximum length of any single path
        local visited = {}
        -- Start DFS from the beginning node
        visited[fromNode] = 1
        -- Use a table to pass paths_found by reference
        local paths_found_ref = {0}
        self:dfs(nodes, fromNode, {fromNode}, paths_found_ref, max_paths, max_path_length, all_paths, visited, valid_nodes, toNode)
        
        return all_paths
    end,

    -- Find all paths from source to destination
    find_all_paths = function(self, nodes, spawn1, spawn2, exclusion_radius, use_dfs)
        local valid_nodes, spawn1_zone, spawn2_zone = self:analyze_spawn_zones(nodes, spawn1, spawn2, exclusion_radius)
    
        local output = {}
        local meToOthers = {}
        for k,v in spawn1_zone do
            for k2,v2 in spawn2_zone do
                tinsert(meToOthers, {k, k2})
            end
        end

        local totalPaths = getn(meToOthers)

        -- Calculate limit per path based on total paths
        local limit = 1 
        limit = floor(30 / totalPaths)
        if limit < 1 then
            limit = 1
        end 

        for i=1,getn(meToOthers) do
            local k = meToOthers[i][1]
            local k2 = meToOthers[i][2]
            local all_paths

            if use_dfs == 1 then
                all_paths = self:depth_first_search(limit, valid_nodes, nodes, k, k2)
            else
                all_paths = self:breadth_first_search(limit, valid_nodes, nodes, k, k2)
            end

            for i=1,getn(all_paths) do
                local path = all_paths[i]
                tinsert(output, path)
            end
        end
        return output
    end,

    -- Main function to generate and display paths
    generate_paths = function(self, nodes, spawn1, spawn2, exclusion_radius)
        --print("Finding paths from " .. spawn1 .. " to " .. spawn2)
        --print("Identifying nodes within " .. exclusion_radius .. " units as spawn zones")

        -- Get nodes within spawn zones for display
        local _, spawn1_zone, spawn2_zone = self:analyze_spawn_zones(nodes, spawn1, spawn2, exclusion_radius)

        -- Display spawn zones
        --print("\nSpawn 1 Zone (" .. spawn1 .. "):")
        local spawn1_nodes = {}
        for node,_ in spawn1_zone do
            tinsert(spawn1_nodes, node) 
        end
        -- Basic sort for Lua 4.0
        for i = 1, getn(spawn1_nodes) do
            for j = i + 1, getn(spawn1_nodes) do
                if spawn1_nodes[i] > spawn1_nodes[j] then
                    spawn1_nodes[i], spawn1_nodes[j] = spawn1_nodes[j], spawn1_nodes[i]
                end
            end
        end
        for i = 1, getn(spawn1_nodes) do
            local node = spawn1_nodes[i]
            local dist_str = self:distance(node, spawn1, nodes) 
            --print("  " .. node .. " (Distance: " .. dist_str .. ")")
        end

        --print("\nSpawn 2 Zone (" .. spawn2 .. "):")
        local spawn2_nodes = {}
        for node,_ in spawn2_zone do
            tinsert(spawn2_nodes, node) 
        end
        -- Basic sort for Lua 4.0
        for i = 1, getn(spawn2_nodes) do
            for j = i + 1, getn(spawn2_nodes) do
            if spawn2_nodes[i] > spawn2_nodes[j] then
                spawn2_nodes[i], spawn2_nodes[j] = spawn2_nodes[j], spawn2_nodes[i]
            end
            end
        end
        for i = 1, getn(spawn2_nodes) do
            local node = spawn2_nodes[i]
            local dist_str = self:distance(node, spawn2, nodes)
            --print("  " .. node .. " (Distance: " .. dist_str .. ")")
        end

        -- Find paths between spawn points
        local paths = self:find_all_paths(nodes, spawn1, spawn2, exclusion_radius, 1)

        --print("\nFound " .. getn(paths) .. " paths:")
        for i = 1, getn(paths) do
            local path = paths[i]
            --print("\nPath " .. i .. " (length: " .. getn(path) .. "):")
            local path_str = ""
            for j = 1, getn(path) do
            if j > 1 then
                path_str = path_str .. " -> "
            end
            path_str = path_str .. path[j]
            end
            --print(path_str)
        end

        return paths, spawn1_zone, spawn2_zone
    end,

    -- Tao duong di cho NPCs
    autoFindSpawnPositions = function(self, nodes, firstNodeX, firstNodeY)

        
        

        -- Find diagonal extreme points for each camp region
        local allX, allY = {}, {}
        local totalY = 0
        local nodeCount = 0
        
        -- First collect all coordinates and find the average Y
        for nodeId, coords in nodes do
            local x, y = coords[1], coords[2]
            tinsert(allX, x)
            tinsert(allY, y)
            totalY = totalY + y
            nodeCount = nodeCount + 1
        end
        
        local avgY = totalY / nodeCount
        local camp1Points, camp2Points = {}, {}
        
        -- Separate points into two camps based on Y position
        for nodeId, coords in nodes do
            local x, y = coords[1], coords[2]
            if y > avgY then
                tinsert(camp1Points, {x = x, y = y, dist = GetDistanceRadius(x, y, firstNodeX, firstNodeY)})
            else
                tinsert(camp2Points, {x = x, y = y, dist = GetDistanceRadius(x, y, firstNodeX, firstNodeY)})
            end
        end
        
        -- Find camp points based on distance to first node and position
        local findCampExtreme = function(points, isFirstNodeCamp)
            if getn(points) == 0 then
                return nil
            end
            
            -- Sort points by distance to first node
            for i = 1, getn(points) do
                for j = i + 1, getn(points) do
                    if points[i].dist > points[j].dist then
                        points[i], points[j] = points[j], points[i]
                    end
                end
            end
            
            -- If this is the camp containing first node, use closest point
            if isFirstNodeCamp then
                return {
                    bottomRight = {x = points[1].x, y = points[1].y},
                    topLeft = {x = points[1].x, y = points[1].y}
                }
            end
            
            -- For the other camp, find point furthest from first node
            local lastPoint = points[getn(points)]
            return {
                bottomRight = {x = lastPoint.x, y = lastPoint.y},
                topLeft = {x = lastPoint.x, y = lastPoint.y}
            }
        end
        
        -- Determine which camp contains the first node
        local firstNodeInCamp1 = firstNodeY > avgY
        local camp1Extreme = findCampExtreme(camp1Points, firstNodeInCamp1)
        local camp2Extreme = findCampExtreme(camp2Points, not firstNodeInCamp1)
        
        -- Use these points as camp coordinates if original ones are invalid
        if camp1Extreme and camp2Extreme then
            -- Camp 1 (bottom) uses bottom-right point
            camp1X = floor(camp1Extreme.bottomRight.x)
            camp1Y = floor(camp1Extreme.bottomRight.y)
            -- Camp 2 (top) uses top-left point
            camp2X = floor(camp2Extreme.topLeft.x)
            camp2Y = floor(camp2Extreme.topLeft.y)
        end

        return camp1X, camp1Y, camp2X, camp2Y
    end,
    build = function(self, worldInfo, exclusion_radius)

        if not worldInfo or not worldInfo.nodes then
            return 0
        end

        -- Or prebuit?
        if worldInfo.chienTranhPaths then
            return 1
        end
        
        -- Lay nodes chien tranh
        local nodes = {}
        for k,v in worldInfo.nodes do
            if v.nodeType == 1 then
                nodes[k] = {v.x, v.y, v.linkedNodes}
            end
        end

        -- Tim spawn1 va spawn2
        local camp1X = GetMissionV(MS_HOMEOUT_X1)
        local camp1Y = GetMissionV(MS_HOMEOUT_Y1)
        local camp2X = GetMissionV(MS_HOMEOUT_X2)
        local camp2Y = GetMissionV(MS_HOMEOUT_Y2)

        -- Neu khong co camp
        if (camp1X == 0 or camp1Y == 0 or camp2X == 0 or camp2Y == 0) then
            camp1X, camp1Y, camp2X, camp2Y = self:autoFindSpawnPositions(nodes, worldInfo.firstNode[1], worldInfo.firstNode[2])           
        else
            -- Camp 2 o tren
            if (camp2X > camp1X) and (camp2Y < camp1Y) then 
            else 
                -- swap camp
                local temp = camp1X
                camp1X = camp2X
                camp2X = temp
                temp = camp1Y
                camp1Y = camp2Y
                camp2Y = temp 
            end
        end


        local spawn1
        local spawn2

        -- Find closest existing nodes to camp1 camp2 coordinates 
        local closestNode1 = getClosestNode(nodes, camp1X, camp1Y)
        local closestNode2 = getClosestNode(nodes, camp2X, camp2Y)
        
        -- Use closest existing nodes if found
        if closestNode1 then
            spawn1 = closestNode1
        end
        if closestNode2 then
            spawn2 = closestNode2 
        end  


        -- Already build
        if (worldInfo.spawn1 == spawn1 and worldInfo.spawn2 == spawn2) then
            return 1
        end
       
        if not spawn1 or not spawn2 then
            --print("Khong the thiet lap chien loan")
            return 0
        end

        local paths, spawn1_zone, spawn2_zone = self:generate_paths(nodes, spawn1, spawn2, exclusion_radius)

        if getn(paths) == 0 then
            return 0
        end      
        
        -- Setup camp spawns
        local campduoi = {}
        for node,_ in spawn1_zone do
            tinsert(campduoi, node) 
        end
        worldInfo.presetPaths.campduoi = campduoi

        local camptren = {}
        for node,_ in spawn2_zone do
            tinsert(camptren, node) 
        end
        worldInfo.presetPaths.camptren = camptren
        
        
        -- Setup walk path
        worldInfo.chienTranhPaths = {}

        for i = 1, getn(paths) do
            local pathName = "chienloan" .. i
            local pathNodes = {}
            local foundNodePath = paths[i]
            for j = 1, getn(foundNodePath) do
                local node = foundNodePath[j]
                if nodes[node] then
                    tinsert(pathNodes, node)
                else
                    --print("Khong tim thay node: " .. node)
                end
            end
            worldInfo.presetPaths[pathName] = pathNodes	
            tinsert(worldInfo.chienTranhPaths, pathName)
        end

        worldInfo.spawn1 = spawn1
        worldInfo.spawn2 = spawn2
        return 1
    end 

}