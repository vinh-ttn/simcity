Include("\\script\\global\\vinh\\simcity\\head.lua")


function OnTimer(nNpcIndex, nTimeOut)
	local continue = %GroupFighter:ParentTick(nNpcIndex) 
	if continue == 1 then
		SetNpcTimer(nNpcIndex, %GroupFighter.ATICK_TIME)
	end
end

function OnDeath(nNpcIndex)
	%GroupFighter:OnNpcDeath(nNpcIndex, PlayerIndex or 0)	
end