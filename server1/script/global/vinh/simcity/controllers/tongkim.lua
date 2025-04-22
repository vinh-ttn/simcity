Include("\\script\\global\\vinh\\simcity\\head.lua")

Include("\\script\\battles\\marshal\\head.lua");


SimCityMainTongKim = {   }

 

function SimCityMainTongKim:xemBXH()
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:doShowBXH(nW)
end


function createTaskSayTongKim(extra)

	local tbOpt = {}
	local nSettingIdx = 1617
	local nActionId = 0
	if not extra then
		extra = ""
	end
	
	tinsert(tbOpt, 1, "<dec><link=image[8,15]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">TriÖu MÉn:<link> Ng­êi H¸n c¸c ng­¬i lu«n cho r»ng ng­êi Kim chóng ta lµ d· man, nh­ng c¸c ng­¬i cã biÕt chiÕn tranh b¾t ®Çu tõ ®©u kh«ng?" .. extra);
	return tbOpt
end

function SimCityMainTongKim:mainMenu()
	local nW, nX, nY = GetWorldPos()
	SimCityChienTranh.nW = nW
	SimCityChienTranh:mainMenu()
	return 1
end

function main()
	return SimCityMainTongKim:mainMenu()
end
 

function SimCityMainTongKim:addTongKimNpc()
	SimCityChienTranh:updateCampPosition()

	local worldInfo = SimCityWorld:Get(SubWorld)

	local home1InX = GetMissionV(MS_HOMEIN_X1)
	local home1InY = GetMissionV(MS_HOMEIN_Y1)
	local home1OutX = GetMissionV(MS_HOMEOUT_X1)
	local home1OutY = GetMissionV(MS_HOMEOUT_Y1)

	local home2InX = GetMissionV(MS_HOMEIN_X2)
	local home2InY = GetMissionV(MS_HOMEIN_Y2)
	local home2OutX = GetMissionV(MS_HOMEOUT_X2)
	local home2OutY = GetMissionV(MS_HOMEOUT_Y2)

	if worldInfo.nodes then
		local nodes = {}
		for k,v in worldInfo.nodes do			
			nodes[k] = {v.x, v.y}
		end

		local closestHome1In = getClosestNode(nodes, home1InX, home1InY)
		local closestHome1Out = getClosestNode(nodes, home1OutX, home1OutY)
		local closestHome2In = getClosestNode(nodes, home2InX, home2InY)
		local closestHome2Out = getClosestNode(nodes, home2OutX, home2OutY)

		if closestHome1In then
			home1InX = nodes[closestHome1In][1]
			home1InY = nodes[closestHome1In][2]
		end

		if closestHome1Out then
			home1OutX = nodes[closestHome1Out][1]
			home1OutY = nodes[closestHome1Out][2]
		end

		if closestHome2In then
			home2InX = nodes[closestHome2In][1]
			home2InY = nodes[closestHome2In][2]
		end

		if closestHome2Out then
			home2OutX = nodes[closestHome2Out][1]
			home2OutY = nodes[closestHome2Out][2]
		end
	end


	local vitriVoKy = {
		tientuyen = {home1OutX*32, home1OutY*32},
		hauphuong = {home1InX*32, home1InY*32},
		id = 103
	}

	local vitriTrieuMan = {
		tientuyen = {home2OutX*32, home2OutY*32},
		hauphuong = {home2InX*32, home2InY*32},
		id = 1617
	}


	-- Hau doanh
	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 1617, vitriTrieuMan.hauphuong[1],
		vitriTrieuMan.hauphuong[2], "TriÖu MÉn")
	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 103, vitriVoKy.hauphuong[1],
		vitriVoKy.hauphuong[2], "V« Kþ")


	local offSetUnit1 = 4 * 32
	local offSetUnit2 = 4 * 32

	-- Tien tuyen
	local id = 0
	local nX = 0
	local nY = 0
	local nW = 0

	-- Trieu man
	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 1617, vitriTrieuMan.tientuyen[1],
		vitriTrieuMan.tientuyen[2], "TriÖu MÉn")

	-- Bao ve cho Trieu Man
	nX, nY, nW = GetNpcPos(id)


	id = AddNpcEx(1702, 95, random(0, 4), nW, nX - offSetUnit1, nY + offSetUnit2, 1, "A §¹i", 0)
	SetNpcCurCamp(id, 2)

	id = AddNpcEx(1939, 95, random(0, 4), nW, nX, nY + offSetUnit2, 1, "A NhÞ", 0)
	SetNpcCurCamp(id, 2)

	id = AddNpcEx(1854, 95, random(0, 4), nW, nX + offSetUnit1, nY + offSetUnit2, 1, "A Tam", 0)
	SetNpcCurCamp(id, 2)

	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 103, vitriVoKy.tientuyen[1],
		vitriVoKy.tientuyen[2], "V« Kþ")

	-- Bao ve cho Vo Ky
	nX, nY, nW = GetNpcPos(id)
	id = AddNpcEx(1789, 95, random(0, 4), nW, nX - offSetUnit1, nY + offSetUnit2, 1, "V­¬ng Tiªu", 0)
	SetNpcCurCamp(id, 1)

	id = AddNpcEx(1683, 95, random(0, 4), nW, nX, nY + offSetUnit2, 1, "Chu ChØ Nh­îc", 0)
	SetNpcCurCamp(id, 1)

	id = AddNpcEx(1941, 95, random(0, 4), nW, nX + offSetUnit1, nY + offSetUnit2, 1, "TiÓu Chiªu", 0)
	SetNpcCurCamp(id, 1)


	-- Clear everyone
	SimCityChienTranh:removeAll(SubWorldIdx2ID(nW))
end

