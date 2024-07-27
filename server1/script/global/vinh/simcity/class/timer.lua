Include("\\script\\global\\vinh\\simcity\\head.lua")


function OnTimer(nNpcIndex, nTimeOut)
	local npcType = GetNpcParam(nNpcIndex, 4)
	local continue
	if npcType == 1 or npcType == 2 then
		continue = %GroupFighter:ATick(nNpcIndex) 
		if continue == 1 then
			SetNpcTimer(nNpcIndex, %GroupFighter.ATICK_TIME)
		end
	end


	if npcType == 3 or npcType == 4 then
		continue = %XeTieu:ATick(nNpcIndex) 
		if continue == 1 then
			SetNpcTimer(nNpcIndex, %XeTieu.ATICK_TIME)
		end
	end
end

function OnDeath(nNpcIndex)
	local npcType = GetNpcParam(nNpcIndex, 4)

	if npcType == 1 or npcType == 2 then
		%GroupFighter:OnNpcDeath(nNpcIndex, PlayerIndex or 0)	
	end

	if npcType == 3 or npcType == 4 then
		%XeTieu:OnNpcDeath(nNpcIndex, PlayerIndex or 0)	
	end
end