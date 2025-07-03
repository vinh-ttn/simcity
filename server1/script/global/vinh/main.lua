
Include("\\script\\global\\vinh\\simcity\\main.lua")
Include("\\script\\misc\\eventsys\\eventsys.lua")

function add_npc_vinh()

	if ENABLE_BANNGUAMIXDEV == 1 then
		-- Ban ngua
		local startX = 1557
		local startY = 3184
		add_dialognpc({ 
			{233,78,startX+2,startY+2,"\\script\\global\\vinh\\npc\\banngua\\caocap.lua","B¸n ngùa cao cÊp"},  --189
			{233,78,startX+4,startY+4,"\\script\\global\\vinh\\npc\\banngua\\hobao.lua","B¸n hæ b¸o"},  -- 190
			{233,78,startX+6,startY+6,"\\script\\global\\vinh\\npc\\banngua\\hoangkim.lua","B¸n ngùa Hoµng Kim"}, --191
			{233,78,startX+8,startY+8,"\\script\\global\\vinh\\npc\\banngua\\kiemthe.lua","B¸n ngùa KiÕm ThÕ"},  -- 193
		})
	end
end

function simcity_addNpcs()
	-- SimCity: them Trieu Man o 7 thanh
	SimCityThanhThi:addNpcs()
	
	-- KeoXe: them VoKy o TuongDuong
	add_dialognpc({ 
		{103,78,1619,3251,"\\script\\global\\vinh\\simcity\\controllers\\keoxe.lua","V« Kþ"}, 
		{103,53,1614,3210,"\\script\\global\\vinh\\simcity\\controllers\\keoxe.lua","V« Kþ"},
	})

	-- VatNuoi: them VatNuoi o TuongDuong
	SimCityVatNuoi:addNpcs()

	-- Event sys when user enter/leave map
	for id, map in SimCityMap do
		EventSys:GetType("EnterMap"):Reg(id, SimCityThanhThi.onPlayerEnterMap, SimCityThanhThi)
		EventSys:GetType("LeaveMap"):Reg(id, SimCityThanhThi.onPlayerExitMap, SimCityThanhThi)
		EventSys:GetType("EnterMap"):Reg(id, SimCityVatNuoi.onPlayerEnterMap, SimCityVatNuoi)		
	end
	

end

function simcity_clearTongKim()
	SimCityChienTranh:removeAll()
end