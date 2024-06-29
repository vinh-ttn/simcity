SimCityNPCInfo = {
	npc_blacklist = {
		0,
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		11,
		12,
		13,
		14,
		15,
		16,
		17,
		18,
		19,
		20,
		21,
		22,
		23,
		24,
		25,
		26,
		27,
		31,
		32,
		33,
		34,
		35,
		36,
		37,
		38,
		39,
		42,
		44,
		45,
		46,
		147,
		413,
		414,
		415,
		446,
		456,
		467,
		524,
		525,
		527,
		528,
		529,
		530,
		531,
		532,
		533,
		539,
		585,
		586,
		587,
		590,
		603,
		604,
		605,
		606,
		607,
		608,
		609,
		610,
		611,
		612,
		613,
		614,
		615,
		616,
		617,
		618,
		619,
		620,
		621,
		622,
		623,
		624,
		643,
		771,
		859,
		861,
		862,
		863,
		867,
		1322,
		1337,
		1341,
		1343,
		1343,
		1344,
		1345,
		1346,
		1347,
		1375,
		1378,
		1380,
		1381,
		1388,
		1397,
		1431,
		1440,
		1441,
		1498,
		1518,
		1539,
		1549,
		1591,
		1605,
		1611,
		1626,
		1628,
		1629,
		1632,
		1632,
		1643,
		1672,
		1673,
		1700,
		1703,
		1714,
		1715,
		1716,
		1720,
		1723,
		1724,
		1724,
		1725,
		1726,
		1743,
		1892,
		1893,
		1897,
		1906,
		1906,
		1912,
		1913,
		1914,
		1914,
		1915,
		1918,
		1991,
		1992,
		1993,
		1993,
		1994,
		1995,
		1995,
		1996,
		1997,
		1998,
		2000,
		2037,
		2040,
		2041,
		2042,
		2043,
		2044,
		2045,
		2046,
		2047,
		2048,
		2049,
		2050,
		2051,
		2052,
		2053,
		2054,
		2055,
		2056,
		2057,
		2100,
		2197,
		2220,
		2230,
		2250,
		2261,
		2315,
		2318,
		2325,
		2328,
		2331,
		2332,
		2333,
		2334,
		2335,
		2339,
		2347,
		2349,
		2382,
		2387,
		2389,
		2392,
		2395,
		2396,
		2397,
		2398,
		2399,
		2403,
		2198,
		2221,
		2320,
		2384
	},

	blacklistNPC = {},
	ALLNPCs_INFO  = {},
	ALLNPCs_INFO_COUNT = 2200,


	nhanvat = {
		socap = {

			{1480, 1488},-- 4tr6

			{1786, 1795}, -- 100k
			{1765, 1774},-- 5tr
		},
		trungcap = {
			{1193, 1202}, --12tr
			{1239, 1248}, --12tr
			{1465, 1475}, --10tr
			{1674, 1683}, --12tr

		},
		caocap = {
			{1355, 1368}, --20tr
			{739, 748}, --16tr
			{1775, 1779}, --25tr
		},
		sieunhan = {
			{1849, 1852},
			{1869, 1875},
			{1750, 1754}, -- 99tr
		}
	}
}


function SimCityNPCInfo:init()
	-- Produce blacklist NPCs
	for i=1, getn(self.npc_blacklist) do
		self.blacklistNPC["z"..self.npc_blacklist[i]] = 1
	end

	self.nvSoCap={}
	self.nvTrungCap={}
	self.nvCaoCap={}
	self.nvSieuNhan={}

	for i=1, getn(self.nhanvat.socap) do
		for j=self.nhanvat.socap[i][1],self.nhanvat.socap[i][2] do
			tinsert(self.nvSoCap, j)
		end
	end

	for i=1, getn(self.nhanvat.trungcap) do
		for j=self.nhanvat.trungcap[i][1],self.nhanvat.trungcap[i][2] do
			tinsert(self.nvTrungCap, j)
		end
	end
	for i=1, getn(self.nhanvat.caocap) do
		for j=self.nhanvat.caocap[i][1],self.nhanvat.caocap[i][2] do
			tinsert(self.nvCaoCap, j)
		end
	end
	for i=1, getn(self.nhanvat.sieunhan) do
		for j=self.nhanvat.sieunhan[i][1],self.nhanvat.sieunhan[i][2] do
			tinsert(self.nvSieuNhan, j)
		end
	end

	-- Try reading NPCS info
	if TabFile_Load and getn(self.ALLNPCs_INFO) == 0 then
		local tbData, nCount = GetTabFileData("\\settings\\npcs.txt", "all_npcs",1,60)
		for i=1,nCount do

			local lifeParame = tonumber(tbData[i][38])
			local lifeParame1 = tonumber(tbData[i][39])
			local lifeParame2 = tonumber(tbData[i][40])
			local lifeParame3 = tonumber(tbData[i][41])

			local maxLife = 0

			if lifeParame and maxLife < lifeParame then
				maxLife = lifeParame
			end
			if lifeParame1 and maxLife < lifeParame1 then
				maxLife = lifeParame1
			end
			if lifeParame2 and maxLife < lifeParame2 then
				maxLife = lifeParame2
			end
			if lifeParame3 and maxLife < lifeParame3 then
				maxLife = lifeParame3
			end



			self.ALLNPCs_INFO["n"..(i-2)] = {
				name = fixName(tbData[i][1]),
				kind = tonumber(tbData[i][2]),
				camp = tonumber(tbData[i][3]),
				series = tonumber(tbData[i][4]),
				maxLife = maxLife,
				runspeed = tonumber(tbData[i][59] or 0),
			}
		end

		if nCount > 0 then
			self.ALLNPCs_INFO_COUNT = nCount
		end
	end
end


function SimCityNPCInfo:isBlacklisted(id)
	return self.blacklistNPC["z"..id]	
end

function SimCityNPCInfo:notFightingChar(id)
	if self.ALLNPCs_INFO["n"..id] and (self.ALLNPCs_INFO["n"..id].kind ~= 0) then
		return 1
	end

	return 0
end
function SimCityNPCInfo:notValidChar(id)
	if id > self.ALLNPCs_INFO_COUNT then
		return 1
	end
	return 0
end

function SimCityNPCInfo:getName(id)

	if self.ALLNPCs_INFO["n"..id] and self.ALLNPCs_INFO["n"..id].name then
		return self.ALLNPCs_INFO["n"..id].name
	end
	return ""
end


function SimCityNPCInfo:getSpeed(id)

	if self.ALLNPCs_INFO["n"..id] and self.ALLNPCs_INFO["n"..id].name then
		return self.ALLNPCs_INFO["n"..id].runspeed
	end
	return 0
end