Include("\\script\\global\\vinh\\simcity\\head.lua")
-- Main menu
function main()
	SimCityThanhThi:mainMenu()
	return 1
end

-- Main loop
function mainLoop()
    SimCitizen:ATick()
	SimTheoSau:ATick()
	--SimCityKeoXe:ATick()
    AddTimer(REFRESH_RATE, "mainLoop", SimCitizen)
end 

function worldLoop()
	SimCityWorld:ATick(20)
    AddTimer(REFRESH_RATE*20, "worldLoop", SimCityWorld)
end 

AddTimer(REFRESH_RATE, "mainLoop", SimCitizen)
AddTimer(REFRESH_RATE*20, "worldLoop", SimCityWorld)