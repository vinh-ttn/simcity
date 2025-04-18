Include("\\script\\global\\vinh\\simcity\\head.lua")

Include("\\script\\battles\\marshal\\head.lua");


SimCityMainTongKim = { camp2TopRight = 0 }


function SimCityMainTongKim:updateCampPosition()
	local camp1X = GetMissionV(MS_HOMEIN_X1) / 8
	local camp1Y = GetMissionV(MS_HOMEIN_Y1) / 16
	local camp2X = GetMissionV(MS_HOMEIN_X2) / 8
	local camp2Y = GetMissionV(MS_HOMEIN_Y2) / 16

	self.camp2TopRight = 0
	if (camp2X > camp1X) and (camp2Y < camp1Y) then
		self.camp2TopRight = 1
	end
end

function SimCityMainTongKim:xemBXH()
	local nW, nX, nY = GetWorldPos()
	SimCityWorld:doShowBXH(nW)
end

function SimCityMainTongKim:setUpMap(nW)
	local worldInfo = SimCityWorld:Get(nW)
	if not worldInfo.name then
		local config = objCopy(SimCityMap[10000])
		config.worldId = nW
		config.name = "Tèng Kim"
		config.decoration = {}
		config.isTongKim = 1
		SimCityWorld:New(config);
		worldInfo = SimCityWorld:Get(nW)
		worldInfo.showFightingArea = 0
		worldInfo.showThangCap = 1
		worldInfo.showBXH = 1
		worldInfo.announceBXHTick = 1 -- show BXH moi 1 phut
	end
end

function SimCityMainTongKim:mainMenu()
	SimCityMainTongKim:updateCampPosition()
	SimCityChienTranh:modeTongKim(1, self.camp2TopRight)

	local nW, nX, nY = GetWorldPos()
	SimCityMainTongKim:setUpMap(nW)

	SimCityChienTranh.nW = nW
	local worldInfo = SimCityWorld:Get(nW)
	local counter = SimCityChienTranh:countMap(nW)
	local extra = "<enter><enter><color=yellow>Nh©n sè hiÖn t¹i: " .. counter .. "<color>"

	local tbSay = createTaskSayChienTranh(nW, worldInfo.name .. " khãi löa chinh chiÕn" .. extra)

	tinsert(tbSay, "Ph¸t anh hïng thiÕp/#SimCityChienTranh:goiAnhHungThiepNgoaiTrang()")
	tinsert(tbSay, "Ph¸t qu¸i nh©n thiÕp/#SimCityChienTranh:goiAnhHungThiep()")
	tinsert(tbSay, "§iÒu ®éng qu©n binh/#SimCityChienTranh:phe_quanbinh()") 
	tinsert(tbSay, "Xem b¶ng xÕp h¹ng/#SimCityMainTongKim:xemBXH()")
	tinsert(tbSay, "ThiÕt lËp/#SimCityChienTranh:caidat()")
	tinsert(tbSay, "Gi¶i t¸n/#SimCityChienTranh:removeAll()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function main()
	return SimCityMainTongKim:mainMenu()
end

function SimCityMainTongKim:clearTongKimNpc(targetWorld)
	for k, world in SimCityWorld.data do
		if world.isTongKim == 1 and (not targetWorld or world.worldId == targetWorld) then
			SimCityChienTranh.nW = world.worldId
			SimCityChienTranh:removeAll()
		end
	end
end

function SimCityMainTongKim:addTongKimNpc()
	SimCityMainTongKim:updateCampPosition()

	local vokyTienTuyen = { 1343 * 32, 3410 * 32 }
	local vokyHauPhuong = { 1241 * 32, 3549 * 32 }

	local trieumanTienTuyen = { 1541 * 32, 3200 * 32 }
	local trieumanHauPhuong = { 1688 * 32, 3072 * 32 }


	local vitriTrieuMan = {
		tientuyen = {},
		hauphuong = {},
		id = 1617
	}

	local vitriVoKy = {
		tientuyen = {},
		hauphuong = {},
		id = 103
	}


	if self.camp2TopRight == 1 then
		vitriTrieuMan.tientuyen = trieumanTienTuyen
		vitriTrieuMan.hauphuong = trieumanHauPhuong
		vitriVoKy.tientuyen = vokyTienTuyen
		vitriVoKy.hauphuong = vokyHauPhuong
	else
		vitriTrieuMan.tientuyen = vokyTienTuyen
		vitriTrieuMan.hauphuong = vokyHauPhuong
		vitriVoKy.tientuyen = trieumanTienTuyen
		vitriVoKy.hauphuong = trieumanHauPhuong
	end


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
	SimCityMainTongKim:clearTongKimNpc(SubWorldIdx2ID(nW))

	-- Add auto
	if TONGKIM_AUTOCREATE and TONGKIM_AUTOCREATE == 1 then 
		local counter = SimCityChienTranh:countMap(nW)
		if counter == 0 then
			SimCityChienTranh:modeTongKim(1, self.camp2TopRight)
			SimCityChienTranh:nv_tudo(1)
		end
	end
end

