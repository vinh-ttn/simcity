Include("\\script\\global\\vinh\\simcity\\head.lua")
Include("\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua")

-- Main menu
function main()
	SimCityMainThanhThi:mainMenu()
	return 1
end

-- Helper: add NPCs

function add_simcity_npc(enable)
	SimCityMainThanhThi:addNpcs()
end

 

-- Tu dong add NPCs khi nguoi choi den map nao do/tu dong xoa khi khong con ai
SimcityManager = {
	worldStatus = {},
	enabled = "on"		-- tat hay mo chuc nang tu dong add NPC nay
}



function SimcityManager:onPlayerEnterMap() 
	if self.enabled ~= "on" then
		return 1
	end
	local nW,_,_ = GetWorldPos()
	if not self.worldStatus["w"..nW] then
		self.worldStatus["w"..nW] = {
			count = 1,
			enabled = 0
		}
	else
		self.worldStatus["w"..nW].count = self.worldStatus["w"..nW].count + 1
	end

	-- If not enabled, create it
	if self.worldStatus["w"..nW].enabled == 0 then
		self.worldStatus["w"..nW].enabled = 1
		local worldInfo = SimCityWorld:Get(nW)		

		if (worldInfo.name ~= "") then
			SimCityMainThanhThi:createNpcSet(750,250,1)
			SimCityWorld:Update(nW, "showFightingArea", 0)
		end
	end

end
function SimcityManager:onPlayerExitMap() 
	if self.enabled ~= "on" then
		return 1
	end

	local nW,_,_ = GetWorldPos()
	if not self.worldStatus["w"..nW] then
		self.worldStatus["w"..nW] = {
			count = 0,
			enabled = 0
		}
	end

	-- If enabled but no one left, clean it
	if self.worldStatus["w"..nW].count > 0 and self.worldStatus["w"..nW].enabled == 1 then
		self.worldStatus["w"..nW].enabled = 0
		SimCityMainThanhThi:removeAll()
	end

end



