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


	if SimCityChienTranh.camp2TopRight == 1 then
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
	SimCityChienTranh:removeAll(SubWorldIdx2ID(nW))
end

