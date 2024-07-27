
Include("\\script\\global\\vinh\\simcity\\main.lua")
Include("\\script\\misc\\eventsys\\eventsys.lua")


function add_npc_vinh()
end

function simcity_addNpcs()
	-- SimCity: them Trieu Man o 7 thanh
	add_simcity_npc()
	-- KeoXe: them VoKy o TuongDuong
	add_dialognpc({ 
		{103,78,1608,3235,"\\script\\global\\vinh\\simcity\\controllers\\keoxe.lua","V« Kþ"}, 
	})


	EventSys:GetType("EnterMap"):Reg("ALL", SimcityManager.onPlayerEnterMap, SimcityManager)
	EventSys:GetType("LeaveMap"):Reg("ALL", SimcityManager.onPlayerExitMap, SimcityManager)
end