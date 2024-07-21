Include("\\script\\activitysys\\config\\801\\head.lua")
tbConfig = {}
tbConfig[1] = --Ò»¸öÏ¸½Ú
{
	nId = 1,
	szMessageType = "ServerStart",
	szName = "creatSimcityDialogNpc",
	nStartDate = nil,
	nEndDate  = nil,
	tbMessageParam = {nil},
	tbCondition = 
	{
	},
	tbActition = 
	{
		{"ThisActivity:InitAddNpc",	{nil} },
	},
}