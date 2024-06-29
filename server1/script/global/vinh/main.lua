
Include("\\script\\global\\vinh\\simcity\\main.lua")



function add_npc_vinh()


	-- SimCity: them Trieu Man o 7 thanh
	add_simcity_npc()
	

	-- KeoXe: them VoKy o TuongDuong
	add_dialognpc({ 
		{103,78,1608,3235,"\\script\\global\\vinh\\simcity\\controllers\\keoxe.lua","V« Kþ"}, 
	})

end
