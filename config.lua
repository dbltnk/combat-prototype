
local config = {}

-- combat balancing
config.walkspeed = 150
config.runspeed = 300
config.animspeed = 16 * config.walkspeed / 50
config.projectilespeed = 500
config.energyreg = 6
config.healthreg = 1
config.maxPain = 200
config.maxEnergy = 300
config.getUpPain = 0.5 -- in percent

-- progression and round time
config.timecompression = 4
config.barrierHealth = 50000 / config.timecompression -- 800 dpm * 60 minutes + 2.000 (so one player can't do it alone)
config.roundTime = 3600 / config.timecompression -- in seconds
config.xpCap = 1000
config.levelCap = 10
config.dummyXPWorth = 500
config.dummyRespawn = 10
config.xpCapTimer = config.roundTime / config.levelCap
config.ressourceHealth = 300
config.xpGainsEachNSeconds = 10
config.xpPerRessourceTick = config.xpCap * config.levelCap / config.roundTime * config.xpGainsEachNSeconds / config.timecompression
config.strIncreaseFactor = 0.1 -- 10% stronger per lvl

-- visuals
config.show_fog_of_war = true
config.sightDistanceFar = 600
config.sightDistanceNear = 300
config.footStepVisibility = 30 -- beware: large numbers will be bad for performance
config.AEShowTime = 2

-- audio
config.volume = 0.3

-- gamepad
config.gamepad_cursor_speed_near = 300
config.gamepad_cursor_speed_far = 800
config.gamepad_cursor_near_distance = 400
config.gamepad_cursor_near_border = 200

-- debug
config.draw_debug_info = false
config.show_profile_info = false
config.show_object_list = false
config.show_prints = false

-- network
--~ config.server_hostname = "192.168.2.1"
config.server_hostname = "buffy.leenox.de"
config.server_port = 9999
config.sync_high = 1 / 30
config.sync_low = 1

return config
