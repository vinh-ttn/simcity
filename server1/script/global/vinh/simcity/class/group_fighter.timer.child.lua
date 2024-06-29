Include("\\script\\global\\vinh\\simcity\\head.lua")


function OnTimer(nNpcIndex, nTimeOut)
	local continue = %GroupFighter:ChildrenTick(nNpcIndex) 
	if continue == 1 then
		SetNpcTimer(nNpcIndex, %GroupFighter.ATICK_TIME)
	end
end

function OnDeath(nNpcIndex)
	%GroupFighter:ChildrenDead(nNpcIndex, PlayerIndex or 0)
end