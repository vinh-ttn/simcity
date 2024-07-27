Include("\\script\\global\\vinh\\main.lua")
Include("\\script\\activitysys\\activity.lua")

pActivity = ActivityClass:new()
pActivity.nId = 801
pActivity.szName = "Simcity"
pActivity.nStartDate = 202400000000
pActivity.nEndDate = 302400010000
pActivity.szDescription = "nil"
pActivity.nGroupId = nil
pActivity.nVersion = 5

 

function pActivity:InitAddNpc()
    simcity_addNpcs()
end
 


