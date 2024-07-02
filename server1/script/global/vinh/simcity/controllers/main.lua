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

 