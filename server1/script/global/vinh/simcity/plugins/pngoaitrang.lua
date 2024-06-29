
SimCityNgoaiTrang = {}

SimCityNgoaiTrang.ALLTRANGBI_DATA={
	ao={
		nam={},
		nam_count=0,
		nu={},
		nu_count=0,
	}, 
	non={
		nam={},
		nam_count=0,
		nu={},
		nu_count=0,
	}, 
	vukhi={
		nam={},
		nam_count=0,
		nu={},
		nu_count=0,
	}, 
	ngua={
		nam={},
		nam_count=0,
		nu={},
		nu_count=0,
	}
}

SimCityNgoaiTrang.found = 0



function SimCityNgoaiTrang:init()

	if TabFile_Load and GetTabFileData and self.found == 0 then

		local toLoadData = {
			{
				"\\settings\\npcres_simple\\男主角躯体.txt",
				self.ALLTRANGBI_DATA.ao.nam,
				self.ALLTRANGBI_DATA.ao.nam_count
			},
			{
				"\\settings\\npcres_simple\\女主角躯体.txt",
				self.ALLTRANGBI_DATA.ao.nu,
				self.ALLTRANGBI_DATA.ao.nu_count
			},
			{
				"\\settings\\npcres_simple\\男主角头部.txt",
				self.ALLTRANGBI_DATA.non.nam,
				self.ALLTRANGBI_DATA.non.nam_count
			},
			{
				"\\settings\\npcres_simple\\女主角头部.txt",
				self.ALLTRANGBI_DATA.non.nu,
				self.ALLTRANGBI_DATA.non.nu_count
			},
			{
				"\\settings\\npcres_simple\\男主角未骑马关联表.txt",
				self.ALLTRANGBI_DATA.vukhi.nam,
				self.ALLTRANGBI_DATA.vukhi.nam_count
			},
			{
				"\\settings\\npcres_simple\\女主角未骑马关联表.txt",
				self.ALLTRANGBI_DATA.vukhi.nu,
				self.ALLTRANGBI_DATA.vukhi.nu_count
			},
			{
				"\\settings\\npcres_simple\\男主角马中.txt",
				self.ALLTRANGBI_DATA.ngua.nam,
				self.ALLTRANGBI_DATA.ngua.nam_count,
				1
			},
			{
				"\\settings\\npcres_simple\\女主角马中.txt",
				self.ALLTRANGBI_DATA.ngua.nu,
				self.ALLTRANGBI_DATA.ngua.nu_count,
				1
			}
		}

		for j=1,getn(toLoadData) do
			local info = toLoadData[j]

			local tbData, nCount = GetTabFileData(info[1], "temp"..j, 2, 4)
			for i=1,nCount do
				local name = tbData[i][2]
				if info[4] or (name and name ~= "") then
					tinsert(info[2], i)
				end			
			end

			info[3] = getn(info[2])
		end
	 
	 	self.found = 1
	end
end
SimCityNgoaiTrang.used = {}


function SimCityNgoaiTrang:doRandom() 
	local tbNpc = {}
	tbNpc.nSettingsIdx = random(-2, -1)
	tbNpc.nNewHelmType = self:getData(tbNpc.nSettingsIdx, "non") or random(1,53)
	tbNpc.nNewArmorType = self:getData(tbNpc.nSettingsIdx, "ao") or random(1,53)
	tbNpc.nNewWeaponType =self:getData(tbNpc.nSettingsIdx, "vukhi") or random(1,50)
	tbNpc.nNewHorseType = self:getData(tbNpc.nSettingsIdx, "ngua") or random(1,20)	 
	return tbNpc
end


function SimCityNgoaiTrang:getData(charType, objectName)

	local target = {}
	if objectName == "non" then
		target = self.ALLTRANGBI_DATA.non
	end
	if objectName == "ao" then
		target = self.ALLTRANGBI_DATA.ao
	end
	if objectName == "vukhi" then
		target = self.ALLTRANGBI_DATA.vukhi
	end
	if objectName == "ngua" then
		target = self.ALLTRANGBI_DATA.ngua
	end


	local collection = {}
	if charType == -1 then
		collection = target.nam
	elseif charType == -2 then
		collection = target.nu
	else
		return nil
	end

	local N = getn(collection)
	if N > 0 then
		return collection[random(1,N)]
	end
	return nil
end
 