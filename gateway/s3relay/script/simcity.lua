Include("\\script\\mission\\sevencity\\war.lua")

--------------------------------------------------------------------

function Mo_TongKim(level)
	Battle_StartNewRound(1, level );
	zAddLocalCountNews = "ChiÕn tr­êng Tèng Kim ®ang trong giai ®o¹n b¸o danh. C¸c hiÖp kh¸ch muèn tham gia h·y nhanh chãng ®Õn T­¬ng D­¬ng hoÆc Chu Tiªn trÊn ®Ó b¸o danh! (hoÆc dïng Tèng Kim Chiªu th­)"
	GlobalExecute(format("dw Msg2SubWorld([[%s]])",zAddLocalCountNews))
	GlobalExecute(format("dw AddLocalCountNews([[%s]], 1)",zAddLocalCountNews))
end


