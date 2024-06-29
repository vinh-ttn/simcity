IncludeLib("FILESYS")
IncludeLib("TITLE")
IncludeLib("ITEM")
IncludeLib("NPCINFO")
IncludeLib("TIMER")
IncludeLib("SETTING")
IncludeLib("TASKSYS")
IncludeLib("PARTNER")
IncludeLib("BATTLE")
IncludeLib("RELAYLADDER")
IncludeLib("TONG")
IncludeLib("LEAGUE")

Include("\\script\\lib\\remoteexc.lua")
Include("\\script\\lib\\common.lua")
Include("\\script\\lib\\string.lua" )
Include("\\script\\lib\\log.lua")
Include("\\script\\lib\\awardtemplet.lua")
--Include("\\script\\lib\\droptemplet.lua")

Include("\\script\\activitysys\\playerfunlib.lua")
Include("\\script\\misc\\eventsys\\type\\npc.lua")
Include("\\script\\dailogsys\\dailogsay.lua")
Include("\\script\\activitysys\\functionlib.lua")
Include("\\script\\activitysys\\npcdailog.lua")
Include("\\script\\global\\titlefuncs.lua")
Include("\\script\\lib\\string.lua")


-- Common Helpers
Include("\\script\\global\\vinh\\simcity\\config.lua")
Include("\\script\\global\\vinh\\simcity\\common.lua")

-- Plugins first
Include("\\script\\global\\vinh\\simcity\\plugins\\index.lua")

-- Data load 
Include("\\script\\global\\vinh\\simcity\\data\\index.lua")

-- Now main class
Include("\\script\\global\\vinh\\simcity\\class\\group_fighter.class.lua")

-- Kick start all plugins if needed
SimCityNgoaiTrang:init()
SimCityNPCInfo:init()
