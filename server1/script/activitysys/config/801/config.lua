Include("\\script\\activitysys\\config\\801\\head.lua")
tbConfig = {
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
	},
	{
		nId = 2,
		szMessageType = "FinishSongJin",
		szName = "clearSimcityTk",
		nStartDate = nil,
		nEndDate  = nil,
		tbMessageParam = {nil},
		tbCondition = 
		{
		},
		tbActition = 
		{
			{"ThisActivity:ClearTkNpc",	{nil} },
		},
	}
}