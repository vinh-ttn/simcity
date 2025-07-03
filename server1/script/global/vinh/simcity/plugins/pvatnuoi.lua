Include("\\script\\lib\\timerlist.lua")

VATNUOI_TSK_PET_IDS = 2480
VATNUOI_TSK_PET_FACTIONS = 2481
VATNUOI_TSK_PET_SKILLS_1 = 2482
VATNUOI_TSK_PET_SKILLS_2 = 2483
VATNUOI_TSK_PET_SKILLS_3 = 2484
 
SimCityVatNuoi = { 
	collections = {},
	collections_knownPoint = {},
	
	doNotShow = {}
}

function createTaskSayVatNuoi()
	local tbOpt = {}
	local nSettingIdx = 662
	local nActionId = 1
	tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ta chÝnh lµ T©y §éc ¢u D­¬ng Phong. Ng­¬i muèn mua chiÕn lîi phÈm cña ta? ");
	return tbOpt
end

function SimCityVatNuoi:showCategories()
	local tbSay = createTaskSayVatNuoi()
	
	-- Add categories from SimCityPets
	for i=1, getn(SimCityPets.allCats) do
		local category = SimCityPets.allCats[i]
		local displayName = category
		tinsert(tbSay, format("%s/#SimCityVatNuoi:showDemoPet('%s', 1)", displayName, category))
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
	if profilePets < 3 then
		tinsert(tbSay, "Ta muèn mua thó c­ng/#SimCityVatNuoi:showCategories()")
	end

	-- List available pets for management
	if profilePets > 0 then
		tinsert(tbSay, "Ta muèn qu¶n lý thó c­ng/#SimCityVatNuoi:showPetList()")
		tinsert(tbSay, format("Ta muèn b¸n hÕt cho ng­¬i/#SimCityVatNuoi:RemoveConfirmation()"))
	end

	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end

function SimCityVatNuoi:RemoveConfirmation()
	local name = GetName()
	local tbOpt = {}
	local nSettingIdx = 662
	local nActionId = 1

	-- Show confirmation dialog
	tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ng­¬i cã ch¾c ch¾n muèn tr¶ l¹i tÊt c¶ thó c­ng? Ta sÏ hoµn l¹i 5 v¹n l­îng cho mçi con!");
	tinsert(tbOpt, "§ång ý/#SimCityVatNuoi:RemoveAll(1)")
	tinsert(tbOpt, "Kh«ng ®ång ý/#SimCityVatNuoi:mainMenu()")
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)
	return 1
end

function SimCityVatNuoi:showDemoPet(category,id)

	if id < 1 then
		id = 1
	end
	if id > getn(SimCityPets[category]) then
		id = 1
	end

	local dataRowId = SimCityPets[category][id]

	local petData = SimCityPets.allPets[dataRowId]	
	local petName = petData[1]
	local nSettingIdx = petData[2]
	local petCost = petData[3]
	local petCostDisplay = floor(petCost/10000) .. " v¹n l­îng"

	local tbOpt = {}
	

	local extra = "<enter><enter><color=yellow>Gi¸: "..petCostDisplay.."<color>"
	local nActionId = 1
	tinsert(tbOpt, "<dec><link=image[0,108]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ta chÝnh lµ T©y §éc ¢u D­¬ng Phong. Ng­¬i muèn mua <color=yellow>"..petName.."<color> kh«ng?" .. extra);
	
	
	tinsert(tbOpt, format("Mua %s (%s)/#SimCityVatNuoi:taoPet(%s, 0)", petName, petCostDisplay, dataRowId))	
	tinsert(tbOpt, "Xem kÕ tiÕp/#SimCityVatNuoi:showDemoPet('"..category.."', "..(id+1)..")")
	tinsert(tbOpt, "Quay l¹i/#SimCityVatNuoi:showCategories()")
	tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbOpt)	
end

function SimCityVatNuoi:RemoveAll(saveToProfile)
	local name = GetName()
	local totalPets = 0

	if self.collections[name] then
		totalPets = getn(self.collections[name])
		self.collections[name] = nil
	end

	for key, fighter in SimTheoSau.fighterList do
		if fighter.playerID == name and fighter.mode == "pet" then
			SimTheoSau:Remove(fighter.id)
		end
	end

	

	if saveToProfile and saveToProfile > 0 then

		-- Return money to player
		if totalPets > 0 then
			local returnMoney = totalPets * 50000
			Earn(returnMoney)
		end
		
		-- Clear all task values
		SetTask(VATNUOI_TSK_PET_IDS, 0)
		SetTask(VATNUOI_TSK_PET_FACTIONS, 0)
		SetTask(VATNUOI_TSK_PET_SKILLS_1, 0)
		SetTask(VATNUOI_TSK_PET_SKILLS_2, 0)
		SetTask(VATNUOI_TSK_PET_SKILLS_3, 0)

		local tbOpt = {}
		local nSettingIdx = 662
		local nActionId = 1
		tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ta ®· tr¶ l¹i thó c­ng vµ hoµn tiÒn cho ng­¬i!");
		tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
		CreateTaskSay(tbOpt)
	end

	
	return 1
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
		if (GetCash() > petCost) then
			Pay(petCost)
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
	local n_ids = GetTask(VATNUOI_TSK_PET_IDS)
	local n_factions = GetTask(VATNUOI_TSK_PET_FACTIONS)
	local name = GetName()

	-- Initialize if not exists
	if not n_ids then n_ids = 0 end
	if not n_factions then n_factions = 0 end
	
	-- Store total number of pets
	local total = 0
	if SimCityVatNuoi.collections[name] then
		total = getn(SimCityVatNuoi.collections[name])
	end
	n_ids = SetByte(n_ids, 1, total)

	-- Store each pet's ID and faction
	for i=1, total do
		if i <= 3 then
			local sim = SimTheoSau:Get(SimCityVatNuoi.collections[name][i])
			local petId = sim.petId 
			
			-- Store pet ID
			if GetByte(n_ids, i + 1) == 0 then
				n_ids = SetByte(n_ids, i + 1, petId)
			end
			
			-- Store faction (initialize to 0 if not set)
			if GetByte(n_factions, i) == 0 then
				n_factions = SetByte(n_factions, i, 0)
			end
		end
	end

	-- Save the tasks
	SetTask(VATNUOI_TSK_PET_IDS, n_ids)
	SetTask(VATNUOI_TSK_PET_FACTIONS, n_factions)
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
	local n_ids = GetTask(VATNUOI_TSK_PET_IDS);
	if n_ids and n_ids > 0 then 
		local total = GetByte(n_ids, 1)
		return total
	end
	return 0
end

function SimCityVatNuoi:loadPetsFromProfile()
	local total = self:countShowingPets()

	if total == 0 then
		local n_ids = GetTask(VATNUOI_TSK_PET_IDS);
		if n_ids and n_ids > 0 then 
			local total = GetByte(n_ids, 1)
			for i=1, total do
				local petId = GetByte(n_ids, i+1)
				self:taoPet(petId, 1)
			end
		end
		self:loadSkillsFromProfile()
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
		self:showPetList()
	else 
		self:RemoveAll()
		self:showPetList()
	end
end 


function SimCityVatNuoi:showPetList()
    local tbOpt = {}
    local nSettingIdx = 662
    local nActionId = 1

    tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ng­¬i muèn qu¶n lý thó c­ng nµo?");

    local name = GetName()
    local n_factions = GetTask(VATNUOI_TSK_PET_FACTIONS)
    
	if (self.collections[name]) then
		for i=1, getn(self.collections[name]) do
			local sim = SimTheoSau:Get(self.collections[name][i])
			local petFaction = GetByte(n_factions, i)
			
			if petFaction > 0 then
				local faction = faction2Key(petFaction)
				tinsert(tbOpt, format("%s (huÊn luyÖn tõ %s)/#SimCityVatNuoi:showFactionSkills('%s', %d)", sim.szName, faction2DisplayName(petFaction), faction, i))
			else
				tinsert(tbOpt, format("%s (ch­a huÊn luyÖn)/#SimCityVatNuoi:showFactionList(%d)", sim.szName, i))
			end
		end
	end

	-- Can hide/remove pets
	if (self.doNotShow[name] == 1) then
		tinsert(tbOpt, format("TriÖu håi l¹i thó c­ng/#SimCityVatNuoi:HideMine(%s)", 0))
	end

	if (self.doNotShow[name] ~= 1) then
		tinsert(tbOpt, format("Thu håi thó c­ng/#SimCityVatNuoi:HideMine(%s)", 1))
	end
	

    tinsert(tbOpt, "Quay l¹i/#SimCityVatNuoi:mainMenu()")
    tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbOpt)
    return 1
end

function SimCityVatNuoi:showFactionSkills(faction, petIndex)
    local tbOpt = {}
    local nSettingIdx = 662
    local nActionId = 1
    tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ng­¬i muèn luyÖn kü n¨ng nµo cho thó c­ng?");

    -- Add all skills in a single list
    local allSkills = {}
    
    -- Add noCast skills
    for i=1, getn(SimCityPhai[faction].noCast) do
        local skill = SimCityPhai[faction].noCast[i]
        tinsert(allSkills, {skill[5], skill[2], skill[3], skill[4], "noCast"})
    end

    -- Add needCast skills
    for i=1, getn(SimCityPhai[faction].needCast) do
        local skill = SimCityPhai[faction].needCast[i]
        tinsert(allSkills, {skill[5], skill[2], skill[3], skill[4], "needCast"})
    end

    -- Add normalCast skills
    for i=1, getn(SimCityPhai[faction].normalCast) do
        local skill = SimCityPhai[faction].normalCast[i]
        tinsert(allSkills, {skill[5], skill[2], skill[3], skill[4], "normalCast"})
    end

    -- Show all skills in a single list
    for i=1, getn(allSkills) do
        local skill = allSkills[i]
        tinsert(tbOpt, format("%s (CÊp %d) - %d v¹n l­îng/#SimCityVatNuoi:assignSkill('%s', %d, '%s', %d)", 
            skill[3], skill[2], floor(skill[4]/10000), faction, skill[1], skill[5], petIndex))
    end

    tinsert(tbOpt, "Quay l¹i/#SimCityVatNuoi:showPetList()")
    tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbOpt)
    return 1
end

function SimCityVatNuoi:assignSkill(faction, dataRowId, skillType, petIndex)
    local name = GetName()
    local n_skills = GetTask(VATNUOI_TSK_PET_SKILLS_1 + petIndex - 1)
    
    -- Initialize task value if not exists
    if not n_skills or n_skills == 0 then
        n_skills = 0
    end

    -- Find the skill cost
    local skillCost = 0
    if skillType == "noCast" then
        for i=1, getn(SimCityPhai[faction].noCast) do
            local skill = SimCityPhai[faction].noCast[i]
            if skill[5] == dataRowId then
                skillCost = skill[4] -- Cost is the 4th element
                break
            end
        end
    elseif skillType == "needCast" then
        for i=1, getn(SimCityPhai[faction].needCast) do
            local skill = SimCityPhai[faction].needCast[i]
            if skill[5] == dataRowId then
                skillCost = skill[4] -- Cost is the 4th element
                break
            end
        end
    else
        for i=1, getn(SimCityPhai[faction].normalCast) do
            local skill = SimCityPhai[faction].normalCast[i]
            if skill[5] == dataRowId then
                skillCost = skill[4] -- Cost is the 4th element
                break
            end
        end
    end

    -- Check if player has enough money
    if GetCash() < skillCost then
        local tbOpt = {}
        local nSettingIdx = 662
        local nActionId = 1
        tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ng­¬i kh«ng ®ñ tiÒn ®Ó huÊn luyÖn kü n¨ng nµy!");
        tinsert(tbOpt, "Quay l¹i/#SimCityVatNuoi:showFactionSkills('"..faction.."', "..petIndex..")")
        tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
        CreateTaskSay(tbOpt)
        return 1
    end

    -- Directly assign the skill to the selected pet
    return self:saveSkillToPet(petIndex, faction, dataRowId, skillType, skillCost)
end

function SimCityVatNuoi:saveSkillToPet(petIndex, faction, dataRowId, skillType, skillCost)
    local name = GetName()
    local n_skills = GetTask(VATNUOI_TSK_PET_SKILLS_1 + petIndex - 1)
    
    -- Initialize if not exists
    if not n_skills then n_skills = 0 end

    -- Check if player has enough money
    if GetCash() < skillCost then
        local tbOpt = {}
        local nSettingIdx = 662
        local nActionId = 1
        tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ng­¬i kh«ng ®ñ tiÒn ®Ó huÊn luyÖn kü n¨ng nµy!");
        tinsert(tbOpt, "Quay l¹i/#SimCityVatNuoi:showFactionSkills('"..faction.."', "..petIndex..")")
        tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
        CreateTaskSay(tbOpt)
        return 1
    end

    -- Deduct money
    Pay(skillCost)

	-- 20% chance to fail
	if (random(1, 100) <= 80) then
		
		local Talk =
		"Con thó cña ng­¬i qu¸ ngç nghÞch. Ta kh«ng thÓ huÊn luyÖn. Tr¶ l¹i cho ng­¬i."
		local tb = {
			"Quay l¹i/#SimCityVatNuoi:showFactionSkills('"..faction.."', "..petIndex..")",
		}
		Say(Talk, getn(tb), tb)
		return 1
	end

    -- Save skill to pet
    if skillType == "noCast" then
        n_skills = SetByte(n_skills, 1, dataRowId)
    elseif skillType == "needCast" then
        n_skills = SetByte(n_skills, 2, dataRowId)
    else
        n_skills = SetByte(n_skills, 3, dataRowId)
    end

    -- Save the task
    SetTask(VATNUOI_TSK_PET_SKILLS_1 + petIndex - 1, n_skills)

    self:loadSkillsFromProfile()

    local tbOpt = {}
    local nSettingIdx = 662
    local nActionId = 1
    tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link><enter>Thó c­ng cña ng­¬i ®· ®­îc <color=yellow>huÊn luyÖn thµnh c«ng!<color>"); 
    tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbOpt)
    return 1
end

function SimCityVatNuoi:loadSkillsFromProfile()
    local name = GetName()
    local n_ids = GetTask(VATNUOI_TSK_PET_IDS)
    local n_factions = GetTask(VATNUOI_TSK_PET_FACTIONS)
    
    if n_ids and n_ids > 0 then
        local totalPets = GetByte(n_ids, 1)
        
        for i=1, totalPets do
            if self.collections[name] and self.collections[name][i] then
                local sim = SimTheoSau:Get(self.collections[name][i])
                
                -- Get pet data
                local petId = GetByte(n_ids, i + 1)
                local factionId = GetByte(n_factions, i)
                
                -- Get skill data
                local n_skills = GetTask(VATNUOI_TSK_PET_SKILLS_1 + i - 1)
                local normalSkillId = GetByte(n_skills, 1)
                local tranPhaiSkillId = GetByte(n_skills, 2)
                local castBuaSkillId = GetByte(n_skills, 3)
                
                if factionId > 0 then
                    local faction = faction2Key(factionId)
                    sim.faction = faction
                    
                    -- Find and apply normalSkill (noCast)
                    if normalSkillId > 0 then
                        for j=1, getn(SimCityPhai[faction].noCast) do
                            local skill = SimCityPhai[faction].noCast[j]
                            if skill[5] == normalSkillId then
                                sim.skillHoTro = j
                                sim.fightSys:BuffChar(SimTheoSau, sim)
                                break
                            end
                        end
                    end
                    
                    -- Find and apply tranPhaiSkill (needCast)
                    if tranPhaiSkillId > 0 then
                        for j=1, getn(SimCityPhai[faction].needCast) do
                            local skill = SimCityPhai[faction].needCast[j]
                            if skill[5] == tranPhaiSkillId then
                                sim.skillTranPhai = skill
                                sim.fightSys:BuffChar(SimTheoSau, sim)
                                break
                            end
                        end
                    end
                    
                    -- Find and apply castBuaSkill (normalCast)
                    if castBuaSkillId > 0 then
                        for j=1, getn(SimCityPhai[faction].normalCast) do
                            local skill = SimCityPhai[faction].normalCast[j]
                            if skill[5] == castBuaSkillId then
                                sim.skillCastBua = skill
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end




function SimCityVatNuoi:showFactionList(petIndex)
    local tbOpt = {}
    local nSettingIdx = 662
    local nActionId = 1
    tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ng­¬i muèn gëi ®Õn ®©u ®Ó huÊn luyÖn?");

    -- Add all available factions
    for faction, _ in SimCityPhai do
        if faction ~= "id2phai" and faction ~= "duongmon" then
			local factionIdx = factionKey2Idx(faction)	
            tinsert(tbOpt, format("%s - 100 v¹n l­îng/#SimCityVatNuoi:buyFaction(%d, %d)", faction2DisplayName(factionIdx), petIndex, factionIdx))
        end
    end

    tinsert(tbOpt, "Quay l¹i/#SimCityVatNuoi:showPetList()")
    tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbOpt)
    return 1
end

function SimCityVatNuoi:buyFaction(petIndex, factionIdx)
    local name = GetName()
    local n_factions = GetTask(VATNUOI_TSK_PET_FACTIONS)
    local factionCost = 1000000

    -- Check if player has enough money
    if GetCash() < factionCost then
        local tbOpt = {}
        local nSettingIdx = 662
        local nActionId = 1
        tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> Ng­¬i kh«ng ®ñ tiÒn ®Ó huÊn luyÖn!");
        tinsert(tbOpt, "Quay l¹i/#SimCityVatNuoi:showFactionList("..petIndex..")")
        tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
        CreateTaskSay(tbOpt)
        return 1
    end

    -- Deduct money
    Pay(factionCost)
 
	-- 20% chance to fail
	if (random(1, 100) <= 20) then
		
		local Talk =
		"Con thó cña ng­¬i qu¸ ngç nghÞch. "..faction2DisplayName(factionIdx).." kh«ng thÓ huÊn luyÖn vµ ®· tr¶ l¹i."
		local tb = {
			"Tho¸t./Quit",
		}
		Say(Talk, getn(tb), tb)
		return 1
	end

    -- Initialize if not exists
    if not n_factions then n_factions = 0 end

    -- Store faction in the correct position
    n_factions = SetByte(n_factions, petIndex, factionIdx)

    -- Save the task
    SetTask(VATNUOI_TSK_PET_FACTIONS, n_factions)

    -- Update the pet's faction in memory
    if self.collections[name] and self.collections[name][petIndex] then
        local sim = SimTheoSau:Get(self.collections[name][petIndex])
        sim.faction = faction2Key(factionIdx)
    end

    local tbOpt = {}
    local nSettingIdx = 662
    local nActionId = 1
    tinsert(tbOpt, 1, "<dec><link=image[0,14]:#npcspr:?NPCSID="..tostring(nSettingIdx).."?ACTION="..tostring(nActionId)..">L·o §éng VËt:<link> <enter><color=yellow>"..faction2DisplayName(factionIdx).."<color> ®· huÊn luyÖn cho thó c­ng cña ng­¬i thµnh c«ng!"); 
    tinsert(tbOpt, "KÕt thóc ®èi tho¹i./no")
    CreateTaskSay(tbOpt)
    return 1
end