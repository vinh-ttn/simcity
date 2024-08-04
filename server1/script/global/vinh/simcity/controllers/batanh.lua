Include("\\script\\global\\vinh\\simcity\\head.lua")



function main()
	local tbSay = { "NhiÖm vô hé tèng b¸ t¸nh" }
	local fighter = SimCityBaTanh:getTieuXa()

	if fighter == nil then
		tinsert(tbSay, "B¶o vÖ b¸ t¸nh/#SimCityBaTanh:NewJob()")
	else
		tinsert(tbSay, "Di chuyÓn tíi vŞ trİ tiªu xa/#SimCityBaTanh:GoToJob()")
		tinsert(tbSay, "Hoµn thµnh nhiÖm vô/#SimCityBaTanh:FinishJob(0)")
		tinsert(tbSay, "Hñy bá nhiÖm vô/#SimCityBaTanh:FinishJob(1)")
	end

	tinsert(tbSay, "KÕt thóc ®èi tho¹i./no")
	CreateTaskSay(tbSay)
	return 1
end
