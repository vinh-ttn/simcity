Include("\\script\\global\\vinh\\simcity\\head.lua")

function OnDeath(nNpcIndex)
	local nListId = GetNpcParam(nNpcIndex, PARAM_LIST_ID)
	local nType = GetNpcParam(nNpcIndex, PARAM_TYPE)
	if nType == 1 then
		SimCitizen:OnDeath(nListId, nNpcIndex)	
	elseif nType == 2 then
		SimTheoSau:OnDeath(nListId, nNpcIndex)	
	end
end
