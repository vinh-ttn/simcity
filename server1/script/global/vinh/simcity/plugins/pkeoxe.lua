

SimCityKeoXe = {	
	ALLXE = {
	 
		{1355,1356,523,1358,513,1360,1361,1362,511,1364,},
		{566,739,567,568,741,1366,742,582,743, 1365,740,},
		{744,745,583,565,563,748,746,562,1367,1368,747,},
		{1194,1193,1195,1196,1197,1198,1199,1200,1201,1202,1231,},
		{1875,1874,1873,},
		{1466,1437,1479,1438,},
	}

} 
 

function SimCityKeoXe:genWalkPath(forCamp)
	return {}
end



function SimCityKeoXe:taoNV(id, camp, mapID, map, nt, theosau)

	local name = GetName()
	local rank = 1

	local nListId = GroupFighter:New({

		szName = name or "",

		nNpcId = id,						-- required, main char ID
		nMapId = mapID,		-- required, map
		camp = camp,			-- optional, camp
		
		walkMode = "random",	-- optional: random, keoxe, or 1 for formation
		walkVar = 2,		-- random walk of radius of 4*2
		tbPos = map,

		noStop = 1,				-- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5,	-- optional: leave fight instantly after no enemy, otherwise there's waiting period
		
		noRevive = 0,			-- optional: 0: keep reviving, 1: dead

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
		tg_nghingoi_minTs = 0,
		tg_nghingoi_maxTs = 1, 


		ngoaitrang = nt or 0,

		children = theosau or nil,
		childrenCheckDistance = (theosau and 8) or nil,   -- force distance check for child

		playerID = PlayerIndex

	});
  
	return nListId
end 

 
 
 



function SimCityKeoXe:nv_tudo_xe(cap)
 	
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()


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

	-- 10 con theo sau
	for i=1,10 do 
		local pid = pool[random(1,getn(pool))]
		local myPath = self:genWalkPath(forCamp) 

		while SimCityNPCInfo:notFightingChar(pid) == 1 do
			pid = pool[random(1,getn(pool))]
		end

		local children = {} 
		self:taoNV(pid, forCamp, pW, myPath, 1, children)
	end 
 

 

end

function SimCityKeoXe:removeAll()
	for key, tbNpc in GroupFighter.tbNpcList do
		if tbNpc.playerID == PlayerIndex then
			DelNpcSafe(tbNpc.finalIndex)
			GroupFighter:DelNpcSafe_children(tbNpc.nNpcListIndex)
			GroupFighter.tbNpcList[key] = nil
			GroupFighter.npcByWorld["w"..tbNpc.nMapId][key] = nil
		end
	end
end



 

function  SimCityKeoXe:goiAnhHungThiepNgoaiTrang()
 	
 	local tbSay = {"KÐo Xe"}


	tinsert(tbSay, "S¬ cÊp/#SimCityKeoXe:nv_tudo_xe(0)") 
	tinsert(tbSay, "Trung cÊp/#SimCityKeoXe:nv_tudo_xe(1)") 
 	tinsert(tbSay, "Cao cÊp/#SimCityKeoXe:nv_tudo_xe(2)")
	tinsert(tbSay, "Siªu cÊp/#SimCityKeoXe:nv_tudo_xe(3)")

 	tinsert(tbSay, "Quay l¹i./#SimCityKeoXe:mainMenu()")
    tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbSay)
	return 1

end


function  SimCityKeoXe:goiAnhHungThiep()
 	
 	local tbSay = {"KÐo Xe"}
 
 	-- Chon xe nao 
	tinsert(tbSay,"Më tÊt c¶/#SimCityKeoXe:taonhanhnhom_confirm(0)")

	for i=1, getn(self.ALLXE) do
		tinsert(tbSay,format("Më nhãm %d/#SimCityKeoXe:taonhanhnhom_confirm(%d)", i, i))
	end
	
 	tinsert(tbSay, "Quay l¹i./#SimCityKeoXe:mainMenu()")
    tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbSay)
	return 1


end
 


function SimCityKeoXe:taonhanhnhom_confirm(mode)

	local ALLXE = self.ALLXE
	-- 0 = all in
	if (mode == 0) then
		for i=1, getn(ALLXE) do
			self:tao1xe(ALLXE[i], ngoaitrang)
		end
	-- Mode 0: full 5 xe 
	elseif (mode > 0 and mode <= getn(ALLXE)) then
		self:tao1xe(ALLXE[mode], ngoaitrang)

	end
	
end



function SimCityKeoXe:tao1xe(data)
 	
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()

	-- 10 con theo sau
	for i=1,getn(data) do 
		local pid = data[i]
		local myPath = self:genWalkPath(forCamp)
		local children = {} 
		self:taoNV(pid, forCamp, pW, myPath, 0, children)
	end 

end


function SimCityKeoXe:mainMenu()

 
 	local tbSay = {"KÐo Xe"}

	tinsert(tbSay, "T¹o nhãm anh hïng/#SimCityKeoXe:goiAnhHungThiepNgoaiTrang()")
 	tinsert(tbSay, "T¹o nhãm qu¸i nh©n/#SimCityKeoXe:goiAnhHungThiep()")
	--tinsert(tbSay, "ThiÕt lËp/#SimCityKeoXe:caidat()")	
	tinsert(tbSay, "Gi¶i t¸n/#SimCityKeoXe:removeAll()") 	
    tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbSay)  

	return 1
end

