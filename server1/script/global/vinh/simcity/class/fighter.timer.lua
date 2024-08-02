Include("\\script\\global\\vinh\\simcity\\head.lua")


function OnTimer(nNpcIndex, nTimeOut)
	local continue
	local nListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
	local foundFighter = FighterManager:Get(nListId)
	if foundFighter then
		continue = foundFighter:OnTimer()
		if continue == 1 then
			SetNpcTimer(nNpcIndex, REFRESH_RATE)
		end
	end
end

function OnDeath(nNpcIndex)
	local nListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
	local foundFighter = FighterManager:Get(nListId)
	if foundFighter then
		FighterManager:AddScoreToAroundNPC(foundFighter, nNpcIndex, foundFighter.rank or 1)
		if foundFighter.tongkim == 1 then
			SimCityTongKim:OnDeath(nNpcIndex, foundFighter.rank or 1)
		end
		foundFighter:OnDeath()
	end
end
