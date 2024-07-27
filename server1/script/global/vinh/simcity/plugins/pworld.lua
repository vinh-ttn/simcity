Include("\\script\\lib\\timerlist.lua")
SimCityWorld = {
	data = {},
	trangtri = {}
}

function SimCityWorld:New(data)
	if self.data["w"..data.worldId] == nil then


		data.showingId = 0
		data.allowFighting = 1
		data.allowChat = 1
		data.showFightingArea = 1
		data.showName = 1
		data.showDecoration = 0

		data.name = data.name or ""
		data.walkAreas = data.walkAreas or {}
		data.decoration = data.decoration or {}
		data.chientranh = data.chientranh or {}

		data.tick = 0
		data.announceBXHTick = 3
		
		self.data["w"..data.worldId] = data
	end	
end


function SimCityWorld:Get(nW)
	if self.data["w"..nW] ~= nil and self.data["w"..nW] ~= nil then
		return self.data["w"..nW]
	else
		return {}
	end
end

function SimCityWorld:Update(nW, key, value)
	local data = self:Get(nW)
	data[key] = value
end


function SimCityWorld:ShowTrangTri(nW, show)
	local info = self:Get(nW)
	local tbNpc = self.trangtri["w"..nW]
	-- Establish data
	if not tbNpc then
		self.trangtri["w"..nW] = {
			result = {},
			isShowing = 0		
		}
		tbNpc = self.trangtri["w"..nW]		
	end
	
	-- Show but not showing? Create it
	if show == 1 and tbNpc.isShowing == 0 then
		for i=1,getn(info.decoration) do
			local item = info.decoration[i]
			local id = item[1]
			local nX = item[2]
			local nY = item[3]
			local name = item[4]
			if not name then 
				name = " "
			end 
			local index = AddNpcEx(id, 1, 5, SubWorldID2Idx(nW),nX * 32, nY * 32, 1, name, 0)
			tinsert(tbNpc.result, index)
			
			SetNpcAI(index, 0)
		end
		tbNpc.isShowing = 1
		info.showDecoration = 1

	-- Dont want to show but showing? Delete it
	elseif show == 0 and tbNpc.isShowing == 1 then

		for i=1,getn(tbNpc.result) do
			DelNpc(tbNpc.result[i])
		end
		tbNpc.result = {}
		tbNpc.isShowing = 0
		info.showDecoration = 0
	end

end

function SimCityWorld:initThanhThi()
	self:New(map_tuongduong)
	self:New(map_bienkinh)
	self:New(map_laman)
	self:New(map_daily)
	self:New(map_phuongtuong)	 


	if self.m_TimerId then
		TimerList:DelTimer(self.m_TimerId)
	end
	self.m_TimerId = TimerList:AddTimer(self, 60 * 18)
end


function SimCityWorld:doShowBXH(mapID)
	GroupFighter:ThongBaoBXH(mapID)
end
function SimCityWorld:OnTime()
	for wId, worldInfo in self.data do
		worldInfo.tick = worldInfo.tick + 1
		if worldInfo.showBXH == 1 and mod(worldInfo.tick,worldInfo.announceBXHTick) == 0 then
			self:doShowBXH(worldInfo.worldId)
		end
	end
	self.m_TimerId = TimerList:AddTimer(self, 60 * 18)
end