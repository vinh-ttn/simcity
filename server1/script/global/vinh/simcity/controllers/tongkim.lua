Include("\\script\\global\\vinh\\simcity\\head.lua")

Include("\\script\\battles\\marshal\\head.lua");


SimCityMainTongKim = {camp2TopRight = 0}


function SimCityMainTongKim:updateCampPosition()

	local camp1X = GetMissionV(MS_HOMEIN_X1)/8
	local camp1Y = GetMissionV(MS_HOMEIN_Y1)/16
	local camp2X = GetMissionV(MS_HOMEIN_X2)/8
	local camp2Y = GetMissionV(MS_HOMEIN_Y2)/16

	self.camp2TopRight = 0
	if (camp2X > camp1X) and (camp2Y < camp1Y) then
		self.camp2TopRight = 1
	end

end

function SimCityMainTongKim:xemBXH()
	local nW, nX, nY = GetWorldPos()	
	SimCityWorld:doShowBXH(nW)
end
function SimCityMainTongKim:mainMenu()
	SimCityMainTongKim:updateCampPosition()
	SimCityChienTranh:modeTongKim(1, self.camp2TopRight)

	local nW, nX, nY = GetWorldPos()	


	SimCityChienTranh.nW = nW


	local worldInfo = SimCityWorld:Get(nW)
	if not worldInfo.name then
		
		SimCityWorld:New({
			worldId = nW, 
			name = "Tèng Kim", 
			walkAreas = {map_tongkim_nguyensoai.huong1phai,map_tongkim_nguyensoai.huong1trai,map_tongkim_nguyensoai.huong1giua,map_tongkim_nguyensoai.huong2tt}, 
			decoration = {},
			chientranh = {}
		})

		worldInfo = SimCityWorld:Get(nW)
		worldInfo.showFightingArea = 0
		worldInfo.showThangCap = 1
		worldInfo.showBXH = 1
	end
 	
 	local tbSay = {worldInfo.name.." khãi löa chinh chiÕn"}
	tinsert(tbSay, "Mêi anh hïng thiªn h¹/#SimCityChienTranh:goiAnhHungThiepNgoaiTrang()")
 	tinsert(tbSay, "Thªm qu¸i nh©n/#SimCityChienTranh:goiAnhHungThiep()")
 	tinsert(tbSay, "Thªm quan binh/#SimCityChienTranh:phe_quanbinh()")
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


function SimCityMainTongKim:addTongKimNpc()


	SimCityMainTongKim:updateCampPosition()

	local vokyTienTuyen = {1343*32, 3410*32}
	local vokyHauPhuong = {1241*32, 3549*32}

	local trieumanTienTuyen = {1541*32, 3200*32}
	local trieumanHauPhuong = {1688*32, 3072*32}
	

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
	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 1617, vitriTrieuMan.hauphuong[1], vitriTrieuMan.hauphuong[2], "TriÖu MÉn")
	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 103, vitriVoKy.hauphuong[1], vitriVoKy.hauphuong[2], "V« Kþ")	


 	local offSetUnit1 = 4*32
 	local offSetUnit2 = 4*32

	-- Tien tuyen
	local id = 0
	local nX = 0
	local nY = 0
	local nW = 0

	-- Trieu man	
	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 1617, vitriTrieuMan.tientuyen[1], vitriTrieuMan.tientuyen[2], "TriÖu MÉn")

	-- Bao ve cho Trieu Man
 	nX, nY, nW = GetNpcPos(id)


	id = AddNpcEx(1702, 95, random(0,4), nW,nX - offSetUnit1, nY + offSetUnit2, 1, "A NhÊt (b¶o vÖ TriÖu MÉn)" , 0)
	SetNpcCurCamp(id, 2)

	id = AddNpcEx(1939, 95, random(0,4), nW,nX,nY + offSetUnit2, 1, "A NhÞ (b¶o vÖ TriÖu MÉn)" , 0)
	SetNpcCurCamp(id, 2)

	id = AddNpcEx(1854, 95, random(0,4), nW,nX + offSetUnit1, nY + offSetUnit2, 1, "A Tam (b¶o vÖ TriÖu MÉn)" , 0)
	SetNpcCurCamp(id, 2)

	id = bt_add_a_diagnpc("\\script\\global\\vinh\\simcity\\controllers\\tongkim.lua", 103, vitriVoKy.tientuyen[1], vitriVoKy.tientuyen[2], "V« Kþ")	

	-- Bao ve cho Vo Ky	
 	nX, nY, nW = GetNpcPos(id)
	id = AddNpcEx(1789, 95, random(0,4), nW,nX - offSetUnit1, nY + offSetUnit2, 1, "V­¬ng Tiªu (b¶o vÖ V« Kþ)" , 0)
	SetNpcCurCamp(id, 1)

	id = AddNpcEx(1683, 95, random(0,4), nW,nX, nY + offSetUnit2, 1, "Chu ChØ Nh­îc (b¶o vÖ V« Kþ)" , 0)
	SetNpcCurCamp(id, 1)

	id = AddNpcEx(1941, 95, random(0,4), nW,nX + offSetUnit1, nY + offSetUnit2, 1, "TiÓu Chiªu (b¶o vÖ V« Kþ)" , 0)
	SetNpcCurCamp(id, 1)
  
	

	if tongkim_tudongThemNV and tongkim_tudongThemNV == 1 then

		SimCityMainTongKim:updateCampPosition()
		SimCityChienTranh:modeTongKim(1, self.camp2TopRight)

 		nW = SubWorldIdx2ID(nW) 
		SimCityChienTranh.nW = nW
		SimCityChienTranh:removeAll()
		local worldInfo = SimCityWorld:Get(nW)
		if not worldInfo.name then
			
			SimCityWorld:New({
				worldId = nW, 
				name = "Tèng Kim", 
				walkAreas = {map_tongkim_nguyensoai.huong1phai,map_tongkim_nguyensoai.huong1trai,map_tongkim_nguyensoai.huong1giua,map_tongkim_nguyensoai.huong2tt}, 
				decoration = {},
				chientranh = {}
			})

			worldInfo = SimCityWorld:Get(nW)
			worldInfo.showFightingArea = 0
			worldInfo.showThangCap = 1
			worldInfo.showBXH = 1
			worldInfo.announceBXHTick = 1	-- show BXH moi 1 phut
		end

		SimCityChienTranh:nv_tudo(0)
		--SimCityChienTranh:nv_tudo(1)
		--SimCityChienTranh:phe_tudo(1500,500,1)
		--SimCityChienTranh:phe_tudo_xe(1500,500,1)
	end
end
