
local config = {}
 
-- combat balancing
config.walkspeed = 200
config.runspeed = 250
config.animspeed = 4 * config.walkspeed / 50
config.projectilespeed = 500
config.energyreg = 8
config.healthreg = 8 -- 50% of that when incapacitated
config.maxPain = 300
config.maxEnergy = 300
config.getUpPain = 0.5 -- in percent
config.dmgUnmodified = 100

-- next playtest - http://www.epochconverter.com/
config.nextPlaytestAt = 1372960800

-- progression and round time
config.timecompression = 1
config.barrierHealth = 50000 / config.timecompression -- 800 dpm * 60 minutes + 2.000 (so one player can't do it alone)
config.warmupTime = 600 -- in seconds
config.roundTime = 3600 / config.timecompression -- in seconds
config.afterTime = 60 -- in seconds
config.xpCap = 1000
config.levelCap = 10
config.dummyXPWorth = 40 * config.timecompression 
config.dummyRespawn = 180 -- seconds
config.xpCapTimer = config.roundTime / config.levelCap
config.ressourceHealth = 300
config.xpGainsEachNSeconds = 10
config.xpPerRessourceTick = config.xpCap * config.levelCap / config.roundTime * config.xpGainsEachNSeconds / 4
config.strIncreaseFactor = 0.1 -- 10% stronger per lvl
config.combatHealXP = 0.15 -- in % of damage / heal done
config.crowdControlXP = 0.2 -- in % of duration in seconds

-- tracking
config.trackingOverTimeTimeout = 5

-- mobs
config.mobSightRange = 250
config.mobMovementSpeed = config.walkspeed * 0.70
config.mobAttackRange = 60
config.mobDamage = 20
config.mobAnimSpeed = 3
config.mobAttackTimer = 2
config.dummyMaxPain = 90

-- visuals
config.show_fog_of_war = true
config.sightDistanceFar = 800
config.sightDistanceNear = 400
config.footStepVisibility = 15 -- beware: large numbers will be bad for performance
config.minPlayerNumberToDecreaseFootstepsAmount = 4
config.AEShowTime = 4
config.focusSpriteMaxRange = 2.5

-- gamepad
config.gamepad_cursor_speed_near = 300
config.gamepad_cursor_speed_far = 800
config.gamepad_cursor_near_distance = 400
config.gamepad_cursor_near_border = 200

-- debug
config.draw_debug_info = false
config.show_profile_info = false
config.show_object_list = false
config.show_prints = true

-- network
--~ config.server_hostname = "windegg"
config.server_hostname = "buffy.leenox.de"
--~ config.server_hostname = "localhost"
config.server_port = 9998
config.sync_high = 1 / 20
config.sync_low = 1
config.sync_zoneless_timeout = 3
config.sync_complete_timeout = 1

-- map
config.map_width = 3200
config.map_height = 3200
config.zones = 10

return config
