Include("\\script\\global\\vinh\\simcity\\data\\vantieu\\daohuongthon_congtuongduong_congduongchau.lua")
Include("\\script\\global\\vinh\\simcity\\data\\vantieu\\tuongduong_phu_congdaohuongthon.lua")
Include("\\script\\global\\vinh\\simcity\\data\\vantieu\\duongchau_congdaohuongthon_phu.lua")
Include("\\script\\global\\vinh\\simcity\\libs\\common.lua")

VT_ROUTES = {
	vt_tuongduong_duongchau = arrJoin({tuongduong_phu_congdaohuongthon, daohuongthon_congtuongduong_congduongchau, duongchau_congdaohuongthon_phu}),
	vt_duongchau_tuongduong = arrFlip(arrJoin({tuongduong_phu_congdaohuongthon, daohuongthon_congtuongduong_congduongchau, duongchau_congdaohuongthon_phu})),

	vt_test = arrCopy(tuongduong_phu_congdaohuongthon)
}