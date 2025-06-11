Include("\\script\\mission\\sevencity\\war.lua")

--------------------------------------------------------------------

function Mo_TongKim(level)
	Battle_StartNewRound(1, level );
	zAddLocalCountNews = "ChiÕn tr­êng Tèng Kim ®ang trong giai ®o¹n b¸o danh. C¸c hiÖp kh¸ch muèn tham gia h·y nhanh chãng ®Õn T­¬ng D­¬ng hoÆc Chu Tiªn TrÊn ®Ó b¸o danh! (hoÆc dïng Tèng Kim chiªu th­ )"
	GlobalExecute(format("dw Msg2SubWorld([[%s]])",zAddLocalCountNews))
	GlobalExecute(format("dw AddLocalCountNews([[%s]], 1)",zAddLocalCountNews))
end


function Mo_PhongHoaLienThanh(loai, phe)
	if (phe == 2) then
		OutputMsg("'VÖ quèc liªn thµnh'   phe Kim ®· b¾t ®Çu b¸o danh.");

		if loai == 1 then 
			GlobalExecute("dw CityDefence_OpenMain(2)");
		else
			GlobalExecute("dw NewCityDefence_OpenMain(2)");
		end
	else
		OutputMsg("'VÖ quèc liªn thµnh'   Tèng ®· b¾t ®Çu b¸o danh.");
		if loai == 1 then 
			GlobalExecute("dw CityDefence_OpenMain(1)");
		else
			GlobalExecute("dw NewCityDefence_OpenMain(1)");
		end
	end
end