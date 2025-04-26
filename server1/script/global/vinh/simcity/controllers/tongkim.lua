Include("\\script\\global\\vinh\\simcity\\head.lua")

Include("\\script\\battles\\marshal\\head.lua");


SimCityMainTongKim = {   }
 
function SimCityMainTongKim:runTongKim(level)
	RemoteExc("\\script\\simcity.lua", "Mo_TongKim", {level})
end

function SimCityMainTongKim:showBaoDanhTongKim(nW)
	
	local tbSay = createTaskSayChienTranh(nW, "")

	tinsert(tbSay, "Më Tèng Kim s¬ cÊp/#SimCityMainTongKim:runTongKim(1)")
	tinsert(tbSay, "Më Tèng Kim trung cÊp/#SimCityMainTongKim:runTongKim(2)")
	tinsert(tbSay, "Më Tèng Kim cao cÊp/#SimCityMainTongKim:runTongKim(3)")

	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1

end

function SimCityMainTongKim:mainMenu()
	local nW, nX, nY = GetWorldPos()
	SimCityChienTranh.nW = nW

	if nW == 323 or nW == 324 or nW == 325 then
		self:showBaoDanhTongKim(nW)
	else
		SimCityChienTranh:mainMenu()
	end
	return 1
end

-- Main menu
function main()
	return SimCityMainTongKim:mainMenu()
end

-- Empty function for older Simcity version
function SimCityMainTongKim:addTongKimNpc()
end

function SimCityMainTongKim:addTongKimNpcByPlayer()

	local pW, pX, pY = GetWorldPos()
	local worldInfo = SimCityWorld:Get(pW)

	-- Determine camp
	local myCamp = GetCurCamp() 
	local camp1X, camp1Y, camp2X, camp2Y = 0, 0, 0, 0
	local id
	if (myCamp == 1) then
		camp1X = pX
		camp1Y = pY
		id = AddNpc(103, 1, SubWorldID2Idx(pW), (pX+random(-2,2))*32, (pY+random(-2,2))*32, 1, "V« Kþ")
	else 
		camp2X = pX
		camp2Y = pY
		id = AddNpc(1617, 1, SubWorldID2Idx(pW), (pX+random(-2,2))*32, (pY+random(-2,2))*32, 1, "TriÖu MÉn")		
	end
	if id > 0 then
		SetNpcScript(id, "\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua")
	end

	-- Find the nodes
	if worldInfo.nodes then

		local furthestDist = 0
		for k,v in worldInfo.nodes do
			local dist = GetDistanceRadius(v.x, v.y, pX, pY)
			if dist > furthestDist then
				furthestDist = dist
				furthestNode = v
			end
		end

		if (myCamp == 1) then
			camp2X = furthestNode.x
			camp2Y = furthestNode.y
		else 
			camp1X = furthestNode.x
			camp1Y = furthestNode.y
		end		
	end

	-- Finally set it
	worldInfo.camp2TopRight = 0
	if (camp2X ~= 0) and (camp2Y ~= 0) and (camp2X > camp1X) and (camp2Y < camp1Y) then
		worldInfo.camp2TopRight = 1
	end

	worldInfo.camp1X = camp1X
	worldInfo.camp1Y = camp1Y
	worldInfo.camp2X = camp2X
	worldInfo.camp2Y = camp2Y
	local result = SimCityGraphToChienTranh:build(worldInfo, 32) 
	 

	-- Auto added?
	if (result ~= 0) then
		local counter = SimCityChienTranh:countMap(pW)
		
		if STARTUP_AUTOADD_THANHTHI == 1 and counter == 0 then
			SimCityChienTranh:nv_tudo(1)
			SimCityChienTranh:nv_tudo(1)
		end

		-- Add hau doanh
		SimCityChienTranh:taoHauDoanh(1)		
	end
end

function SimCityMainTongKim:addTongKimOpenNpc()

	local pW, pX, pY = GetWorldPos()
	local id	
	id = AddNpc(1617, 1, SubWorldID2Idx(pW), (pX+random(-2,2))*32, (pY+random(-2,2))*32, 1, "TriÖu MÉn")		
	if id > 0 then
		SetNpcScript(id, "\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua")
	end
end

function SimCityMainTongKim:onPlayerEnterMap(pW)
  	local isBaoDanh = 0 
	if pW == 323 or pW == 324 or pW == 325 then
		isBaoDanh = 1
	end

	-- Check if there is a Trieu Man or Vo Ky in the map
	local fighterList = GetAroundNpcList(isBaoDanh and 32 or 50)

	local tmpFound
	local nNpcIdx
	local didRemove = 0

	for i = 1, getn(fighterList) do
		nNpcIdx = fighterList[i]
		local script = GetNpcScript(nNpcIdx)
		local kind = GetNpcKind(nNpcIdx)

		-- Neu da add roi thi xoa di
		if kind == 3 and script == "\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua" then
			DelNpcSafe(nNpcIdx)
			didRemove = 1
		end

		if kind == 3 then
			if strfind(script, "transport.lua") or strfind(script, "doctor.lua") or strfind(script, "openbox.lua") then
				tmpFound = nNpcIdx
			end
		end
	end

	-- Neu la dia diem bao danh thi them vao Trieu Man va Vo Ky
	if isBaoDanh == 1 then
		return SimCityMainTongKim:addTongKimOpenNpc()
	end
	
	-- Neu tim thay Quan Nhu Quan thi them vao Trieu Man va Vo Ky
	if tmpFound then
		if didRemove == 0 then
			SimCityChienTranh:removeAll(pW)
		end
		AddTimer(18*3, "SimCityMainTongKim:addTongKimNpcByPlayer", self)
	end

end

