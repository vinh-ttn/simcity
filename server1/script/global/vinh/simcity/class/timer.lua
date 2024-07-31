Include("\\script\\global\\vinh\\simcity\\head.lua")


function OnTimer(nNpcIndex, nTimeOut)
	local npcType = GetNpcParam(nNpcIndex, PARAM_NPC_TYPE)
	local continue
	if (npcType == 1) then
		local nListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
		local foundFighter = FighterManager:Get(nListId)
		continue = foundFighter:OnTimer()
		if continue == 1 then
			SetNpcTimer(nNpcIndex, REFRESH_RATE)
		end
	end
end

function OnDeath(nNpcIndex)
	local npcType = GetNpcParam(nNpcIndex, PARAM_NPC_TYPE)
	if (npcType == 1) then
		local nListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
		local foundFighter = FighterManager:Get(nListId)
		FighterManager:AddScoreToAroundNPC(foundFighter, nNpcIndex, foundFighter.rank or 1)
		if foundFighter.tongkim == 1 then
			SimCityTongKim:OnDeath(nNpcIndex, foundFighter.rank or 1)
		end
		foundFighter:OnDeath()
	end
end
