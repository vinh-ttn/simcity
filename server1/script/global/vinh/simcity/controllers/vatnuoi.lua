Include("\\script\\global\\vinh\\simcity\\head.lua")
Include("\\script\\lib\\timerlist.lua")

VATNUOI_TSK_PET = 2480

SimCityVatNuoi = { 
	collections = {},
	collections_knownPoint = {},
	
	doNotShow = {}
}

function createTaskSayVatNuoi()
	local tbOpt = {}
	local nSettingIdx = 662
	local nActionId = 1
	tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ta chÝnh lµ T©y §éc ¢u D­¬ng Phong. Ng­¬i muèn mua chiÕn lîi phÈm tõ téc nµo? ");
	return tbOpt
end

function SimCityVatNuoi:showCategories()
	local tbSay = createTaskSayVatNuoi()
	
	-- Add categories from SimCityPets
	for i=1, getn(SimCityPets.allCats) do
		local category = SimCityPets.allCats[i]
		local displayName = category
		tinsert(tbSay, format("%s/#SimCityVatNuoi:showPetsInCategory('%s')", displayName, category))
	end
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end


function SimCityVatNuoi:mainMenu()
	local tbSay = createTaskSayVatNuoi()
	local name = GetName()

	local profilePets = self:countPetsFromProfile()

	-- Can buy more pets?
	if profilePets < 3 and self.doNotShow[name] ~= 1 then
		tinsert(tbSay, "Ta muèn mua thó c­ng/#SimCityVatNuoi:showCategories()")
	end

	-- Can retrieve pets?
	if profilePets > 0 then
		if (self.doNotShow[name] == 1) then
			tinsert(tbSay, format("Ta muèn nhËn l¹i thó c­ng/#SimCityVatNuoi:HideMine(%s)", 0))
		end
	end

	-- Can hide/remove pets
	if self.collections[name] then	
		if (self.doNotShow[name] ~= 1) then
			tinsert(tbSay, format("Ng­¬i t¹m gi÷ chóng dïm ta nhÐ/#SimCityVatNuoi:HideMine(%s)", 1))
		end
		tinsert(tbSay, format("Tr¶ hÕt l¹i cho ng­¬i/#SimCityVatNuoi:RemoveAll(%s)", 1))
	end

	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end


function SimCityVatNuoi:showPetsInCategory(category)
	local tbSay = createTaskSayVatNuoi()
	
	-- Add all pets from the selected category
	for i=1, getn(SimCityPets[category]) do
		local petData = SimCityPets.allPets[SimCityPets[category][i]]
		local petName = petData[1]
		local petCost = petData[3]
		local petCostDisplay = floor(petCost/10000) .. " v¹n l­îng"
		tinsert(tbSay, format("%s (%s)/#SimCityVatNuoi:taoPet(%s, 0)", petName, petCostDisplay, SimCityPets[category][i]))
	end

	tinsert(tbSay, "Quay l¹i./#SimCityVatNuoi:mainMenu()")
	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end


function SimCityVatNuoi:RemoveAll(saveToProfile)
	local name = GetName()

	if self.collections[name] then
		self.collections[name] = nil
	end
	for key, fighter in SimTheoSau.fighterList do
        local name = GetName()
        if fighter.playerID == name and fighter.mode == "pet" then
            SimTheoSau:Remove(fighter.id)
        end
    end

	if saveToProfile and saveToProfile > 0 then
		self:savePetsToProfile()
	end
end

function SimCityVatNuoi:taoPet(dataRowId, skipSaveProfile)

	local petData = SimCityPets.allPets[dataRowId]
	if not petData then 
		return 0
	end
	local petName = petData[1]
	local petId = petData[2]
	local petCost = petData[3]
	local forCamp = GetCurCamp()
	local pW, pX, pY = GetWorldPos()
	local name = GetName()

	-- Buy mode?
	if skipSaveProfile == 0 then
		if (GetCash() > petCost*10000) then
			Pay(petCost*10000)
		else
			local tbSay = createTaskSayVatNuoi()
			tinsert(tbSay, "Cã tiÒn råi h·y quay l¹i./no")
			CreateTaskSay(tbSay)
			return 1 
		end
	end
	
	-- Create pet
	self:taoNV(petId, forCamp, pW, 1, 0, {}, 1, {
		szName = petName .. " cña ".. name,
		petId = dataRowId
	})

	-- Save the pet
	if skipSaveProfile == 0 then
		self:savePetsToProfile()
	end

end


function SimCityVatNuoi:taoNV(id, camp, mapID, map, nt, theosau, capHP, extraConfig)
	local name = GetName()
	local rank = 1

	local tbNpc = {

		szName = SimCityNPCInfo:generateName(),

		nNpcId = id,   -- required, main char ID
		nMapId = mapID, -- required, map
		camp = camp,   -- optional, camp

		walkMode = "random", -- optional: random, keoxe, or 1 for formation
		walkVar = 2,   -- random walk of radius of 4*2
		

		noStop = 1,          -- optional: cannot pause any stop (otherwise 90% walk 10% stop)
		leaveFightWhenNoEnemy = 5, -- optional: leave fight instantly after no enemy, otherwise there's waiting period

		noRevive = 0,        -- optional: 0: keep reviving, 1: dead

		CHANCE_ATTACK_PLAYER = 1, -- co hoi tan cong nguoi choi neu di ngang qua
		CHANCE_ATTACK_NPC = 1, -- co hoi bat chien dau khi thay NPC khac phe
		CHANCE_JOIN_FIGHT = 1, -- co hoi tang cong NPC neu di ngang qua NPC danh nhau
		RADIUS_FIGHT_PLAYER = 15, -- scan for player around and randomly attack
		RADIUS_FIGHT_NPC = 10, -- scan for NPC around and start randomly attack,
		RADIUS_FIGHT_SCAN = 10, -- scan for fight around and join/leave fight it
 
		kind = 0,            -- quai mode
		TIME_FIGHTING_minTs = 1800,
		TIME_FIGHTING_maxTs = 3000,
		TIME_RESTING_minTs = 0,
		TIME_RESTING_maxTs = 1,


		ngoaitrang = nt or 0,

		childrenSetup = theosau or nil,
		childrenCheckDistance = (theosau and 8) or nil, -- force distance check for child

		playerID = name,
		capHP = capHP,
		role = "keoxe",
		mode = "pet"

	};
	if extraConfig then
		for k, v in extraConfig do
			tbNpc[k] = v
		end
	end
	local nListId = SimTheoSau:New(tbNpc);

	if not self.collections[name] then
		self.collections[name] = {}
	end

	if nListId and nListId > 0 then
		tinsert(self.collections[name], nListId)
	end

	return nListId
end
  

function SimCityVatNuoi:ATick()
	-- Get info for npc in this world
	for name, children in self.collections do
		local parentID = SearchPlayer(name)

		if parentID > 0 then
			local pW, pX, pY = CallPlayerFunction(parentID, GetWorldPos)
			local newLoc = "" .. pW .. pY .. pX
			if not self.collections_knownPoint[name] or self.collections_knownPoint[name] ~= newLoc then
				self.collections_knownPoint[name] = newLoc
				local size = getn(children)
				local centerCharId = getCenteredCell(createFormation(size))
				local fighter = SimTheoSau:Get(children[centerCharId])
				local nX, nY, nMapIndex = GetNpcPos(fighter.finalIndex)
				local newPath = genCoords_squareshape({ nX / 32, nY / 32 }, { pX, pY }, size)
				for i = 1, size do
					SimTheoSau:Get(children[i]).parentAppointPos = newPath[i]
				end
			end
		end
	end

end



-- MAIN FUNCTIONS


function SimCityVatNuoi:addNpcs()
	add_dialognpc({
		{ 662, 78,  1578, 3185, "\\script\\global\\vinh\\simcity\\controllers\\vatnuoi.lua", "L·o §éng VËt" }, -- TD
	})
end

function main()
	SimCityVatNuoi:mainMenu()
end



-- USER PROFILE SETTINGS FUNCTIONS
function SimCityVatNuoi:savePetsToProfile()
	local n_value = GetTask(VATNUOI_TSK_PET);
	local name = GetName()

	n_value = 0
	
	-- Store total number of pets
	local total = 0
	if SimCityVatNuoi.collections[name] then
		total = getn(SimCityVatNuoi.collections[name])
	end
	n_value = SetByte(n_value, 1, total)

	-- Store each pet ID
	for i=1, total do
		if i <= 3 then
			local sim = SimTheoSau:Get(SimCityVatNuoi.collections[name][i])
			local petId = sim.petId 
			n_value = SetByte(n_value, i+1, petId)
		end
	end

	-- Save the task
	SetTask(VATNUOI_TSK_PET, n_value)
end

function SimCityVatNuoi:countShowingPets()
	local total = 0
	local name = GetName()
	if self.collections[name] then
		total = getn(self.collections[name])
	end	
	return total
end

function SimCityVatNuoi:countPetsFromProfile()
	local n_value = GetTask(VATNUOI_TSK_PET);
	if n_value and n_value > 0 then 
		local total = GetByte(n_value, 1)
		return total
	end
	return 0
end

function SimCityVatNuoi:loadPetsFromProfile()
	local total = self:countShowingPets()

	if total == 0 then
		local n_value = GetTask(VATNUOI_TSK_PET);
		if n_value and n_value > 0 then 
			local total = GetByte(n_value, 1)
			for i=1, total do
				local petId = GetByte(n_value, i+1)
				self:taoPet(petId, 1)
			end
		end
	end
end

function SimCityVatNuoi:onPlayerEnterMap()
	local name = GetName()
	if (self.doNotShow[name] ~= 1) then
		self:loadPetsFromProfile()
	end
end

function SimCityVatNuoi:HideMine(doHide)
	local name = GetName()
	self.doNotShow[name] = doHide

	if doHide ~= 1 then 
		self:loadPetsFromProfile()
	else 
		self:RemoveAll()
	end
end 