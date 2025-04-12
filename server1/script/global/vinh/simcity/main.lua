Include("\\script\\global\\vinh\\simcity\\head.lua")
Include("\\script\\global\\vinh\\simcity\\controllers\\thanhthi.lua")

-- Main menu
function main()
	SimCityMainThanhThi:mainMenu()
	return 1
end

-- Main loop
function mainLoop()
    SimCitizen:ATick()
	SimTheoSau:ATick()
	SimCityWorld:ATick()
	--SimCityKeoXe:ATick()
    AddTimer(REFRESH_RATE, "mainLoop", SimCitizen)
end 

AddTimer(REFRESH_RATE, "mainLoop", SimCitizen)