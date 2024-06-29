IncludeLib("BATTLE")
Include("\\script\\battles\\battlehead.lua")
Include("\\script\\battles\\marshal\\head.lua")

SimCityTongKim = {

	playerInTK = {}

}


SimCityTongKim.RANKS={"Binh SÜ", "HiÖu óy", "Thèng LÜnh", "Phã T­íng", "§¹i T­íng" , "Nguyªn So¸i"}

SimCityTongKim.ITEM_DROPRATE_TABLE = { 
						{ { 6,1,156,1,0,0 }, { 0.003,0.0200,0.0520,0.0400,0.0500,0.0600 } },	-- Õ½¹Ä
						{ { 6,1,157,1,0,0 }, { 0.003,0.0200,0.0520,0.0400,0.0500,0.0600 } },	-- ÁîÆì
						{ { 6,1,158,1,0,0 }, { 0.003,0.0200,0.0300,0.0400,0.0500,0.0600 } },	-- ºÅ½Ç
						{ { 6,1,160,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0360 } },	-- ½ðÖ®Õ½»ê
						{ { 6,1,161,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0360 } },	-- Ä¾Ö®Õ½»ê
						{ { 6,1,162,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0360 } },	-- Ë®Ö®Õ½»ê
						{ { 6,1,163,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0360 } },	-- »ðÖ®Õ½»ê
						{ { 6,1,164,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0360 } },	-- ÍÁÖ®Õ½»ê
						{ { 6,1,165,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0120 } },	-- ½ðÖ®»¤¼×
						{ { 6,1,166,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0120 } },	-- Ä¾Ö®»¤¼×
						{ { 6,1,167,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0120 } },	-- Ë®Ö®»¤¼×
						{ { 6,1,168,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0120 } },	-- »ðÖ®»¤¼×
						{ { 6,1,169,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0376,0.0120 } },	-- ÍÁÖ®»¤¼×
						{ { 6,1,170,1,0,0 }, { 0.002,0.0360,0.0180,0.0390,0.0140,0.0360 } },	-- ½ðÖ®ÀûÈÐ
						{ { 6,1,171,1,0,0 }, { 0.002,0.0360,0.0180,0.0390,0.0140,0.0360 } },	-- Ä¾Ö®ÀûÈÐ
						{ { 6,1,172,1,0,0 }, { 0.002,0.0360,0.0180,0.0390,0.0140,0.0360 } },	-- Ë®Ö®ÀûÈÐ
						{ { 6,1,173,1,0,0 }, { 0.002,0.0360,0.0180,0.0390,0.0140,0.0360 } },	-- »ðÖ®ÀûÈÐ
						{ { 6,1,174,1,0,0 }, { 0.002,0.0360,0.0180,0.0390,0.0140,0.0360 } },	-- ÍÁÖ®ÀûÈÐ
						{ { 6,1,175,1,0,0 }, { 0.002,0.0200,0.0400,0.0390,0.0140,0.0120 } },	-- ÐÐ¾üµ¤
						{ { 6,1,176,1,0,0 }, { 0.002,0.0200,0.0400,0.0390,0.0140,0.0120 } },	-- Ð¡»¹µ¤
						{ { 6,1,177,1,0,0 }, { 0.002,0.0200,0.0400,0.0390,0.0140,0.0120 } },	-- Îå»¨Â¶
						{ { 6,1,178,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÍâÆÕÍè
						{ { 6,1,179,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÍâ¶¾Íè
						{ { 6,1,180,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÍâ±ùÍè
						{ { 6,1,181,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÄÚÆÕÍè
						{ { 6,1,182,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÄÚ¶¾Íè
						{ { 6,1,183,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÄÚ±ùÍè
						{ { 6,1,184,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÄÚ»ðÍè
						{ { 6,1,185,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÄÚµçÍè
						{ { 6,1,186,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ³¤ÃüÍè
						{ { 6,1,187,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ¼ÓÅÜÍè
						{ { 6,1,188,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ¸ßÉÁÍè
						{ { 6,1,189,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ¸ßÖÐÍè
						{ { 6,1,190,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ·ÉËÙÍè
						{ { 6,1,191,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÆÕ·ÀÍè
						{ { 6,1,192,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ±ù·ÀÍè
						{ { 6,1,193,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃÀ×·ÀÍè
						{ { 6,1,194,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ»ð·ÀÍè
						{ { 6,1,195,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ËÎ½ð×¨ÓÃ¶¾·ÀÍè
						{ { 6,1,207,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0360 } },	-- ¼²·çÖ®Ñ¥	
						{ { 6,1,209,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0360 } },	-- °×¾Ô»¤Íó	
						{ { 6,1,210,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	-- ºóôàÖ®ÑÛ	
						{ { 6,1,211,1,0,0 }, { 0.002,0.0200,0.0130,0.0160,0.0140,0.0120 } },	-- ÎÊºÅ
						{ { 6,1,208,1,0,0 }, { 0.002,0.0200,0.0180,0.0160,0.0140,0.0120 } },	--ÈýÇåÖ®Æø
						{ { 6,1,212,1,0,0 }, { 0.003,0.0200,0.0150,0.0200,0.0200,0.0200 } },	--ÐÅ¸ë
						{ { 6,1,214,1,0,0 }, { 0.003,0.0200,0.0520,0.0200,0.0200,0.0200 } },	--¿¹µ¯Ö®½Ç
					  }
					  
SimCityTongKim.NPC_RANK_DROPRATE_TABLE = { 1, 1, 2, 3, 4, 5 }


function SimCityTongKim:OnDeathTest( nNpcIndex )
	State = GetMissionV(MS_STATE) ;
	if (State ~= 2) then
		return
	end
	
	--Èç¹ûÊÇËÀÓÚÆäËüNpcÔò²»Í³¼ÆÅÅÐÐ
	if (PlayerIndex == nil or PlayerIndex == 0) then
		return
	end
	local rank = 1
	self:dropItem( nNpcIndex, rank, PlayerIndex )
	BT_SetData(PL_KILLNPC, BT_GetData(PL_KILLNPC) + 1);
	BT_SetData(PL_KILLRANK1 + rank - 1, BT_GetData(PL_KILLRANK1 + rank - 1) + 1)
	pointnpc = bt_addtotalpoint(BT_GetTypeBonus(PL_KILLRANK1 + rank - 1, GetCurCamp()))
	mar_addmissionpoint(BT_GetTypeBonus(PL_KILLRANK1 + rank - 1, GetCurCamp()))
	if (pointnpc == nil or pointnpc == 0 ) then
		Msg2Player("B¹n nhËn ®­îc <color=yellow>0<color> ®iÓm tÝch lòy!")
	else
		Msg2Player("B¹n nhËn ®­îc <color=yellow>"..pointnpc .."<color> ®iÓm tÝch lòy!")
	end
	BT_SortLadder()
	BT_BroadSelf()
end;

function SimCityTongKim:OnDeath( nNpcIndex , currank)
	State = GetMissionV(MS_STATE)
	if (State ~= 2) then
		return
	end
	
	if (PlayerIndex == nil or PlayerIndex == 0) then
		return
	end 

	local DeathName = GetNpcName(nNpcIndex)	
	self:dropItem( nNpcIndex, currank, PlayerIndex )
	local launchrank = BT_GetData(PL_CURRANK)
	
	LaunName = GetName();
	--¸üÐÂÉ±NpcÊýÄ¿ºÍÅÅÐÐ°ñ
	BT_SetData(PL_KILLPLAYER, BT_GetData(PL_KILLPLAYER) + 1) --¼ÇÂ¼Íæ¼ÒÉ±ÆäËüÍæ¼ÒµÄ×ÜÊý
	serieskill = BT_GetData(PL_SERIESKILL) + 1
	BT_SetData(PL_SERIESKILL, serieskill) --¼ÇÂ¼Íæ¼Òµ±Ç°µÄÁ¬Õ¶Êý
		
	if (TAB_SERIESKILL[launchrank] and TAB_SERIESKILL[launchrank][currank] == 1) then
		serieskill_r = GetTask(TV_SERIESKILL_REALY) 
		serieskill_r = serieskill_r + 1
		SetTask(TV_SERIESKILL_REALY,serieskill_r)

		if (mod(serieskill_r, 3) == 0) then
			if (deathcamp == 1) then
				local npoint = bt_addtotalpoint(BT_GetTypeBonus(PL_MAXSERIESKILL, 2)) or 0 
				mar_addmissionpoint(BT_GetTypeBonus(PL_MAXSERIESKILL, 2))
				Msg2Player("<color=yellow> b¹n nhËn ®­îc ®iÓm tÝch lòy Liªn tr¶m "..npoint)
			else
				local npoint = bt_addtotalpoint(BT_GetTypeBonus(PL_MAXSERIESKILL, 1)) or 0
				mar_addmissionpoint(BT_GetTypeBonus(PL_MAXSERIESKILL, 1))
				Msg2Player("<color=yellow> b¹n nhËn ®­îc ®iÓm tÝch lòy Liªn tr¶m "..npoint)
			end
		end
	end
	if (BT_GetData(PL_MAXSERIESKILL) < serieskill) then 
		BT_SetData(PL_MAXSERIESKILL, serieskill) -- Í³¼ÆÍæ¼ÒµÄ×î´óÁ¬Õ¶Êý
	end
	
	local rankradio = 1;
	
	if ( RANK_PKBONUS[launchrank] == nil or RANK_PKBONUS[launchrank][currank] == nil) then
		rankradio = 1
		--print("battle rank tab error!!!please check it !")
		return 1
	else
		rankradio = RANK_PKBONUS[launchrank][currank]
	end
	local earnbonus = 0
	earnbonus = floor(BT_GetTypeBonus(PL_KILLPLAYER, 1) * rankradio)
	pointplayer = bt_addtotalpoint(earnbonus) or 0
	mar_addmissionpoint(earnbonus)
	Msg2Player("<color=yellow> B¹n h¹ gôc ®èi ph­¬ng nh©n vµ nhËn d­îc <color>"..pointplayer.." <color=yellow>®iÓm tÝch lòy " )

	local rankname = "";
	rankname = tbRANKNAME[currank]
	launchrank = BT_GetData(PL_CURRANK)
	launrankname = tbRANKNAME[launchrank]
	
	BT_SortLadder();
	BT_BroadSelf();

	str  = "Ng­êi ch¬i "..launrankname.." "..LaunName.." h¹ träng th­¬ng "..DeathName..", tæng PK lµ "..BT_GetData(PL_KILLPLAYER);
	
	Msg2Player("<color=pink> Chóc mõng! B¹n ®· h¹ ®­îc: "..DeathName..", Tæng PK lµ "..BT_GetData(PL_KILLPLAYER))
	Msg2MSAll(MISSIONID, str);

	
	local nW, nX, nY = CallPlayerFunction(PlayerIndex, GetWorldPos)
	if not self.playerInTK[nW] then
		self.playerInTK[nW] = {}
	end
	self.playerInTK[nW][pId] = {
		phe = "T",
		rank = launrankname,
		score = BT_GetData(PL_TOTALPOINT),
		name = LaunName
	}

end;



function SimCityTongKim:dropItem( nNpcIndex, nNpcRank, nBelongPlayerIdx )
	local nItemCount = getn( self.ITEM_DROPRATE_TABLE );
	local nMpsX, nMpsY, nSubWorldIdx = GetNpcPos( nNpcIndex );
	
	for nDropTimes = 1, self.NPC_RANK_DROPRATE_TABLE[nNpcRank] do
		local nRandNum = random();
		local nSum = 0;
		for i = 1, nItemCount do
			nSum = nSum + self.ITEM_DROPRATE_TABLE[i][2][nNpcRank];
			if( nSum > nRandNum ) then
				DropItem( nSubWorldIdx, nMpsX, nMpsY, nBelongPlayerIdx, self.ITEM_DROPRATE_TABLE[i][1][1], self.ITEM_DROPRATE_TABLE[i][1][2], self.ITEM_DROPRATE_TABLE[i][1][3], self.ITEM_DROPRATE_TABLE[i][1][4], self.ITEM_DROPRATE_TABLE[i][1][5], self.ITEM_DROPRATE_TABLE[i][1][6], self.ITEM_DROPRATE_TABLE[i][1][7] );
				break
			end
		end
	end
end

 
function SimCityTongKim:announceRank(nW, name, newRank)
	Msg2Map(nW, "<color=white>"..name.."<color> th¨ng cÊp <color=yellow>"..self.RANKS[newRank].."<color>")
end