CHANCE_AUTO_ATTACK = 8000    -- 1/8000 co hoi chuyen sang chien dau
CHANCE_ATTACK_NPC = 3000     -- 1/3000 co hoi tham gia danh nhau khi di ngang qua dam danh nhau
CHANCE_ATTACK_PLAYER = 2000  -- 1/3000 co hoi danh nguoi neu den gan nguoi choi dang chien dau

STARTUP_AUTOADD_THANHTHI = 1 -- tu dong moi nhan si tren tat ca ban do

RADIUS_FIGHT_PLAYER = 8      -- tam quet nguoi choi chung quanh va tan cong
RADIUS_FIGHT_NPC = 8         -- tam quet NPC chung quanh va tan cong
RADIUS_FIGHT_SCAN = 8        -- tam quet dam danh nhau chung quanh de tham gia


CHANCE_CHAT = 200 -- 1/200 co hoi noi chuyen

TIME_FIGHTING = { -- khoang thoi gian danh nhau  (45-120giay)
	minTs = 45,
	maxTs = 120
}

TIME_RESTING = { -- nghi ngoi, khong danh nhau lai trong vong thoi gian nay
	minTs = 30,
	maxTs = 60
}


TONGKIM_AUTOCREATE = 0             -- if 1, auto add NPC to tongkim

PARAM_LIST_ID = 1                  -- param to store group id
PARAM_CHILD_ID = 2                 -- param to store child id
PARAM_PLAYER_ID = 3                -- param to store player to follow
PARAM_NPC_TYPE = 4                 -- param to store type of npc (parent/child/tieuxa v.v.)
REFRESH_RATE = 9                   -- refresh rate

DISTANCE_CAN_CONTINUE = 5          -- start next position if within 3 points from destination
DISTANCE_CAN_SPIN = 2              -- when spinning make sure the check is tighter
SPINNING_WAIT_TIME = 0             -- wait time to correct position
CHAR_SPACING = 1                   -- spacing between group characters

DISTANCE_FOLLOW_PLAYER = 12        -- chay theo nguoi choi neu cach xa
DISTANCE_SUPPORT_PLAYER = 8        -- neu gan nguoi choi khoang cach 12 thi chuyen sang chien dau
DISTANCE_FOLLOW_PLAYER_TOOFAR = 30 -- neu qua xa nguoi choi vi chay nhanh thi phai bien hinh theo
DISTANCE_VISION = 15               -- qua 15 = phai respawn vi no se quay ve cho cu
