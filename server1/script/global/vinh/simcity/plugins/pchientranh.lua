

SimCityChienTranh = {	

	nW = 0,

	path1 = {},
	path2 = {},

	tongkim = 0,
	tongkim_camp2TopRight = 0
}
 

function SimCityChienTranh:modeTongKim(enable, camp2TopRight)
	self.tongkim = enable
	self.tongkim_camp2TopRight = camp2TopRight
end
function SimCityChienTranh:genWalkPath_tongkim(forCamp)

	local path1 = {map_tongkim_nguyensoai.huong1phai,map_tongkim_nguyensoai.huong1trai,map_tongkim_nguyensoai.huong1giua}
	local path2 = {map_tongkim_nguyensoai.huong2phai,map_tongkim_nguyensoai.huong2trai,map_tongkim_nguyensoai.huong2giua}

	local campDirection = 0
	if (self.tongkim_camp2TopRight == 1 and forCamp ==1) then
		campDirection = 1
	end

	if (self.tongkim_camp2TopRight == 1 and forCamp ==2) then
		campDirection = 0
	end

	if (self.tongkim_camp2TopRight == 0 and forCamp ==1) then
		campDirection = 0
	end

	if (self.tongkim_camp2TopRight == 0 and forCamp ==2) then
		campDirection = 1	-- 1 = bottom to top
	end

 

	-- Bottom to top
	local myPath = {}
	if (campDirection == 1) then

		local firstPath = path1[random(1,getn(path1))] 
		local secondPath = path2[random(1,getn(path2))] 

		for i=1,getn(firstPath) do
			tinsert(myPath, firstPath[i])
		end
		for i=1,getn(secondPath) do
			tinsert(myPath, secondPath[i])
		end
		for i=1,getn(map_tongkim_nguyensoai.huong2tt) do
			tinsert(myPath, map_tongkim_nguyensoai.huong2tt[i])
		end

	-- Top to bottom
	else
		local secondPath = arrFlip(path1[random(1,getn(path1))]) 
		local firstPath = arrFlip(path2[random(1,getn(path2))]) 

		for i=1,getn(firstPath) do
			tinsert(myPath, firstPath[i])
		end
		for i=1,getn(secondPath) do
			tinsert(myPath, secondPath[i])
		end
		for i=1,getn(map_tongkim_nguyensoai.huong1tt) do
			tinsert(myPath, map_tongkim_nguyensoai.huong1tt[i])
		end
	end
	return myPath
end
 

function SimCityChienTranh:genWalkPath(forCamp)

	if (self.tongkim == 1) then
		return self:genWalkPath_tongkim(forCamp)
	end

	local path1 = self.path1
	local path2 = self.path2

	 

	-- Bottom to top
	local myPath = {}
	if (forCamp == 1) then

		local firstPath = path1[random(1,getn(path1))] 
		for i=1,getn(firstPath) do
			tinsert(myPath, firstPath[i])
		end

	-- Top to bottom
	else
		local firstPath = path2[random(1,getn(path2))] 
		for i=1,getn(firstPath) do
			tinsert(myPath, firstPath[i])
		end
	end
	return myPath
end



function SimCityChienTranh:taoNV(id, camp, mapID, map, nt, theosau, cap)

	local name = "Kim"
	local rank = 1
	local realCamp = 5
	if camp == 1 then
		name = "Tèng"
		realCamp = 0
	end		

	local hardsetName = (nt == 1 and SimCityPlayerName:getName()) or SimCityNPCInfo:getName(id)
	if self.tongkim == 1 then
		realCamp = camp
		hardsetName = (nt == 1 and SimCityPlayerName:getName()) or nil
	end
 
 	

	local nListId = GroupFighter:New({

		szName = name or "",

		nNpcId = id,						-- required, main char ID
		nMapId = mapID,		-- required, map
		camp = realCamp,			-- optional, camp
		
		walkMode = (theosau and "keoxe") or "random",	-- optional: random, keoxe, or 1 for formation
		walkVar = (theosau and 2) or 4,		-- random walk of radius of 4*2
		tbPos = map,

		noStop = 1,				-- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5,	-- optional: leave fight instantly after no enemy, otherwise there's waiting period
		
		noRevive = 0,			-- optional: 0: keep reviving, 1: dead

		hardsetPos = random(1, (theosau and 5) or 3),

		attackPlayerChance = 1,	-- co hoi tan cong nguoi choi neu di ngang qua
		attackNpcChance = 1,	-- co hoi bat chien dau khi thay NPC khac phe
		joinFightChance = 1,	-- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		leaveFightChance = 1000000,
		fightPlayerRadius = 15,	-- scan for player around and randomly attack
		attackNpcRadius = 15,	-- scan for NPC around and start randomly attack,
		fightScanRadius = 15,	-- scan for fight around and join/leave fight it

		noBackward = 0,			-- do not walk backward
		kind = 0,				-- quai mode
		tg_danhnhau_minTs = 1800,
		tg_danhnhau_maxTs = 3000,
		tg_nghingoi_minTs = 1,
		tg_nghingoi_maxTs = 3,

		resetPosWhenRevive = random(1,3), 

		tongkim=1,
		tongkim_name=name,

		ngoaitrang = nt or 0,
		hardsetName = hardsetName,

		cap = cap or nil,

		children = theosau or nil,
		childrenCheckDistance = (theosau and 8) or nil   -- force distance check for child

	});
  
	return nListId
end



function SimCityChienTranh:taodoi(thonglinh, camp, mapID, map, children5)


	local children = nil
	local name = "Kim Binh"

	local realCamp = 5

	if camp == 1 then
		name = "Tèng Binh"
		realCamp = 0
	end
	if children5 then
		children = {}
		for i=1,getn(children5) do
			children = spawnN(children, children5[i][1], children5[i][2], name)
		end
	end
 
 	if self.tongkim == 1 then
		realCamp = camp 
	end


	groupID = GroupFighter:New({
		szName = name or "",

		nNpcId = thonglinh,						-- required, main char ID
		nMapId = mapID,		-- required, map
		camp = realCamp,			-- optional, camp
		children = children, -- optional, children
		walkMode = 1,	-- optional: random or 1 for formation
		tbPos = map,

		noStop = 1,				-- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5,	-- optional: leave fight instantly after no enemy, otherwise there's waiting period
		
		noRevive = 0,			-- optional: 0: keep reviving, 1: dead

		hardsetPos = random(1,3),

		attackPlayerChance = 1,	-- co hoi tan cong nguoi choi neu di ngang qua
		attackNpcChance = 1,	-- co hoi bat chien dau khi thay NPC khac phe
		joinFightChance = 1,	-- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		leaveFightChance = 1000000,
		fightPlayerRadius = 15,	-- scan for player around and randomly attack
		attackNpcRadius = 15,	-- scan for NPC around and start randomly attack,
		fightScanRadius = 15,	-- scan for fight around and join/leave fight it

		noBackward = 1,			-- do not walk backward
		kind = 0,				-- quai mode
		tg_danhnhau_minTs = 1800,
		tg_danhnhau_maxTs = 3000,
		tg_nghingoi_minTs = 1,
		tg_nghingoi_maxTs = 3,

		resetPosWhenRevive = random(1,3), 
	})
end

 



function SimCityChienTranh:taophe(nW, camp, linhthuong1, linhthuong2, hieuuy, photuong, daituong, nguyensoai, kybinh)
	self:taodoi(nguyensoai, camp, nW, self:genWalkPath(camp),{		
		{linhthuong1,20},
		{linhthuong2,20},
		{hieuuy,4},
		{photuong,2},
		{daituong,2},
	})

	-- Team thuong
	self:taodoi(hieuuy, camp, nW, self:genWalkPath(camp),{		
		{linhthuong1,20},
		{linhthuong2,20}
	})

	self:taodoi(kybinh, camp, nW, self:genWalkPath(camp),{				
		{kybinh,6},
	})


	self:taodoi(linhthuong2, camp, nW, self:genWalkPath(camp),{		
		{linhthuong1,16},
	})

	self:taodoi(photuong, camp, nW, self:genWalkPath(camp),{		
		{linhthuong2,16},
		{hieuuy, 12}
	})

	self:taodoi(hieuuy, camp, nW, self:genWalkPath(camp),{		
		{linhthuong1,16},
	})


	-- Team nguyen soai		
	self:taodoi(nguyensoai, camp, nW, self:genWalkPath(camp),{		
		{linhthuong1,20},
		{linhthuong2,20},
		{hieuuy,4},
		{photuong,2},
		{daituong,2},
	})

	-- Team thuong
	self:taodoi(hieuuy, camp, nW, self:genWalkPath(camp),{		
		{linhthuong1,20},
		{linhthuong2,20}
	})

	self:taodoi(kybinh, camp, nW, self:genWalkPath(camp), {				
		{kybinh,6},
	})


	self:taodoi(linhthuong2, camp, nW, self:genWalkPath(camp), {		
		{linhthuong1,16},
	})

	self:taodoi(photuong, camp, nW, self:genWalkPath(camp), {		
		{linhthuong2,16},
		{hieuuy, 12}
	})


	self:taodoi(hieuuy, camp, nW, self:genWalkPath(camp), {		
		{linhthuong1,16},
	})


	self:taodoi(hieuuy, camp, nW, self:genWalkPath(camp), {		
		{linhthuong1,16},
	})

end
  



function SimCityChienTranh:phe_tudo(startNPCIndex, perPage, ngoaitrang)
 	
	local forCamp = 1
	for i=0,perPage do 
		local id = startNPCIndex + i
		local myPath = self:genWalkPath(forCamp) 
 
		local id = self:taoNV(id, forCamp, self.nW, myPath, ngoaitrang or 0)
		if id > 0 then
			if forCamp == 1 then
				forCamp = 2
			else
				forCamp = 1
			end
		end
	end 


end
  



function SimCityChienTranh:phe_tudo_xe(startNPCIndex, perPage, ngoaitrang)
 	
	local forCamp = 1

	local maxIndex = startNPCIndex+perPage

	if maxIndex > SimCityNPCInfo.ALLNPCs_INFO_COUNT then
		maxIndex = SimCityNPCInfo.ALLNPCs_INFO_COUNT
	end

	for i=1,10 do 
		local pid = random(startNPCIndex, maxIndex)
		local myPath = self:genWalkPath(forCamp) 

		while SimCityNPCInfo:notFightingChar(pid) == 1 do
			pid = random(startNPCIndex, maxIndex)
		end

		-- 10 con theo sau
		local runSpeed = SimCityNPCInfo:getSpeed(pid) or 0

		local children = {}
		while getn(children) < 20 do
			local id = random(startNPCIndex, maxIndex)
			local mySpeed = SimCityNPCInfo:getSpeed(id) or 0
			if SimCityNPCInfo:notFightingChar(id) == 0 and (runSpeed == 0 or abs(mySpeed - runSpeed) <= 1)then
				tinsert(children, {
					nNpcId = id,
					szName = (ngoaitrang == 1 and SimCityPlayerName:getName()) or SimCityNPCInfo:getName(id)
				})

			end
		end

 
		self:taoNV(pid, forCamp, self.nW, myPath, ngoaitrang or 0, children) 

		if i > 5 then
			forCamp = 2
		end
	end 
 

 

end



function SimCityChienTranh:nv_tudo(cap)
 	
	local forCamp = 1
	
	local pool = SimCityNPCInfo.nvSoCap
	if cap == 1 then
		pool = SimCityNPCInfo.nvTrungCap
	end
	if cap == 2 then
		pool = SimCityNPCInfo.nvCaoCap
	end
	if cap == 3 then
		pool = SimCityNPCInfo.nvSieuNhan
	end

	local total = 0
	while total < 100 do
		local id = pool[random(1,getn(pool))]
		local myPath = self:genWalkPath(forCamp) 
 
		local id = self:taoNV(id, forCamp, self.nW, myPath, 1, nil, cap)
		if id > 0 then
			if forCamp == 1 then
				forCamp = 2
			else
				forCamp = 1
			end
			total = total + 1
		end

	end 


end
  



function SimCityChienTranh:nv_tudo_xe(cap)
 	
	local forCamp = 1


	local pool = SimCityNPCInfo.nvSoCap
	if cap == 1 then
		pool = SimCityNPCInfo.nvTrungCap
	end
	if cap == 2 then
		pool = SimCityNPCInfo.nvCaoCap
	end
	if cap == 3 then
		pool = SimCityNPCInfo.nvSieuNhan
	end

	for i=1,10 do 
		local pid = pool[random(1,getn(pool))]
		local myPath = self:genWalkPath(forCamp) 

		while SimCityNPCInfo:notFightingChar(pid) == 1 do
			pid = pool[random(1,getn(pool))]
		end

		-- 10 con theo sau
		local runSpeed = SimCityNPCInfo:getSpeed(pid) or 0

		local children = {}
		while getn(children) < 20 do
			local id = pool[random(1,getn(pool))]
			local mySpeed = SimCityNPCInfo:getSpeed(id) or 0
			if SimCityNPCInfo:notFightingChar(id) == 0 and (runSpeed == 0 or abs(mySpeed - runSpeed) <= 2)then
				tinsert(children, {
					nNpcId = id,
					szName = SimCityPlayerName:getName() or SimCityNPCInfo:getName(id)
				})

			end
		end

 
		self:taoNV(pid, forCamp, self.nW, myPath, 1, children, cap) 

		if i > 5 then
			forCamp = 2
		end
	end 
 

 

end


function SimCityChienTranh:phe_quanbinh() 
	-- PHE TONG BINH
	local linh = 682
	local kybinh = 1080
	local camp = 1

	self:taophe(self.nW, camp, linh, linh+1, linh+2, linh+3, linh+4, linh+5, kybinh)
 
 
	-- PHE KIM BINH
	linh = 688
	kybinh = 1090
	camp = 2
	
	self:taophe(self.nW, camp, linh, linh+1, linh+2, linh+3, linh+4, linh+5, kybinh)

	 

end

function SimCityChienTranh:removeAll()
	GroupFighter:ClearMap(self.nW)
end



 

function  SimCityChienTranh:goiAnhHungThiepNgoaiTrang()

	local worldInfo = SimCityWorld:Get(self.nW)
 	
 	local tbSay = {worldInfo.name.." ChiÕn Lo¹n"}


	tinsert(tbSay, "S¬ cÊp/#SimCityChienTranh:nv_tudo(0)")
	tinsert(tbSay, "S¬ cÊp (5 xe)/#SimCityChienTranh:nv_tudo_xe(0)") 

	tinsert(tbSay, "Trung cÊp/#SimCityChienTranh:nv_tudo(1)")
	tinsert(tbSay, "Trung cÊp (5 xe)/#SimCityChienTranh:nv_tudo_xe(1)") 


 	tinsert(tbSay, "Cao cÊp/#SimCityChienTranh:nv_tudo(2)")
 	tinsert(tbSay, "Cao cÊp 1 (5 xe)/#SimCityChienTranh:nv_tudo_xe(2)")

 	tinsert(tbSay, "Siªu cÊp/#SimCityChienTranh:nv_tudo(3)")
	tinsert(tbSay, "Siªu cÊp (5 xe)/#SimCityChienTranh:nv_tudo_xe(3)")


 	tinsert(tbSay, "Quay l¹i./#SimCityChienTranh:mainMenu()")
    tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbSay)
	return 1

end


function  SimCityChienTranh:goiAnhHungThiep()

	local worldInfo = SimCityWorld:Get(self.nW)
 	
 	local tbSay = {worldInfo.name.." ChiÕn Lo¹n"}


 	tinsert(tbSay, "Cao cÊp 1/#SimCityChienTranh:phe_tudo(1000,500,0)")
 	tinsert(tbSay, "Cao cÊp 1 (5 xe)/#SimCityChienTranh:phe_tudo_xe(1000,500,0)")

 	tinsert(tbSay, "Cao cÊp 2/#SimCityChienTranh:phe_tudo(1500,500,0)")
 	tinsert(tbSay, "Cao cÊp 2 (5 xe)/#SimCityChienTranh:phe_tudo_xe(1500,500,0)")

 	tinsert(tbSay, "Cao cÊp 3/#SimCityChienTranh:phe_tudo(2000,500,0)")
 	tinsert(tbSay, "Cao cÊp 3 (5 xe)/#SimCityChienTranh:phe_tudo_xe(2000,500,0)")



	tinsert(tbSay, "Trung cÊp/#SimCityChienTranh:phe_tudo(500,500,1)")
	tinsert(tbSay, "Trung cÊp (5 xe)/#SimCityChienTranh:phe_tudo_xe(500,500,0)") 
	
 	tinsert(tbSay, "Quay l¹i./#SimCityChienTranh:mainMenu()")
    tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbSay)
	return 1


end

function SimCityChienTranh:showBXH(inp)
	local worldInfo = SimCityWorld:Get(self.nW)

	worldInfo.showBXH = tonumber(inp)
	SimCityWorld:doShowBXH(self.nW)
	return SimCityChienTranh:caidat()
end
function SimCityChienTranh:showThangCap(inp)
	local worldInfo = SimCityWorld:Get(self.nW)

	worldInfo.showThangCap = inp
	return SimCityChienTranh:caidat()
end


function SimCityChienTranh:caidat()	
	local worldInfo = SimCityWorld:Get(self.nW)

 	local tbSay = {worldInfo.name.." ChiÕn Lo¹n"} 
 
	

	if worldInfo.showBXH == 1 then
 		tinsert(tbSay, "Th«ng b¸o xÕp h¹ng mçi phót [cã]/#SimCityChienTranh:showBXH(0)")
	else
		tinsert(tbSay, "Th«ng b¸o xÕp h¹ng mçi phót [kh«ng]/#SimCityChienTranh:showBXH(1)")
	end 

	if worldInfo.showThangCap == 1 then
 		tinsert(tbSay, "Th«ng b¸o th¨ng cÊp [cã]/#SimCityChienTranh:showThangCap(0)")
	else
		tinsert(tbSay, "Th«ng b¸o th¨ng cÊp [kh«ng]/#SimCityChienTranh:showThangCap(1)")
	end 
 

 	tinsert(tbSay, "Quay l¹i/#SimCityChienTranh:mainMenu()")  
    tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbSay)
	return 1
end

function SimCityChienTranh:mainMenu()
	local worldInfo = SimCityWorld:Get(self.nW)

	if (not worldInfo.chientranh) or (not worldInfo.chientranh.path1) or (not worldInfo.chientranh.path2) then 
		Say("TriÖu MÉn: chiÕn lo¹n t¹i thµnh thÞ nµy ch­a ®­îc më.<enter><enter>C¸c h¹ cã thÓ ®ãng gãp <color=yellow>b¶n ®å ®­êng ®i chiÕn tranh<color> ®Õn t¸c gi¶ trªn fb héi qu¸n kh«ng?")
		return 1
	end


	worldInfo.showFightingArea = 0

	self.path1 = worldInfo.chientranh.path1
	self.path2 = worldInfo.chientranh.path2

 
 	local tbSay = {worldInfo.name.." ChiÕn Lo¹n"}

	tinsert(tbSay, "Mêi anh hïng thiªn h¹/#SimCityChienTranh:goiAnhHungThiepNgoaiTrang()")
 	tinsert(tbSay, "Thªm qu¸i nh©n/#SimCityChienTranh:goiAnhHungThiep()")
 	tinsert(tbSay, "Thªm quan binh/#SimCityChienTranh:phe_quanbinh()")
 	tinsert(tbSay, "Xem b¶ng xÕp h¹ng/#GroupFighter:ThongBaoBXH("..(self.nW)..")")
	tinsert(tbSay, "ThiÕt lËp/#SimCityChienTranh:caidat()")	
	tinsert(tbSay, "Gi¶i t¸n/#SimCityChienTranh:removeAll()") 	
    tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbSay)  


	return 1
end

