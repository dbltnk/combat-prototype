
local config = {}

 
-- combat balancing
config.walkspeed = 200
config.runspeed = 250
config.walkBackwardsPenalty = 0.75
config.walkSidewaysPenalty = 0.9
config.animspeed = 4 * config.walkspeed / 50
config.projectilespeed = 500
config.energyreg = 8
config.healthreg = 8 -- 50% of that when incapacitated
config.maxPain = 300
config.maxEnergy = 300
config.getUpPain = 0.5 -- in percent
config.getUpTime = 60
config.getUpTimeAddedPerLevel = 6
config.dmgUnmodified = 100

-- next playtest - http://www.epochconverter.com/
config.nextPlaytestAt = 1372960800

-- progression and round time
config.timecompression = 2
config.warmupTime = 600 -- in seconds
config.roundTime = 3600 / config.timecompression -- in seconds
config.afterTime = 60 -- in seconds
config.xpCap = 1000
config.levelCap = 10
config.dummyXPWorth = 45 * config.timecompression 
config.dummyRespawn = 300 -- seconds
config.xpCapTimer = config.roundTime / config.levelCap
config.ressourceHealth = 300
config.xpGainsEachNSeconds = 10
config.xpPerRessourceTick = config.xpCap * config.levelCap / config.roundTime * config.xpGainsEachNSeconds / 3
config.strIncreaseFactor = 0.1 -- 10% stronger per lvl
config.combatHealXP = 0.07 -- in % of damage / heal done
config.crowdControlXP = 0.15 -- in % of duration in seconds
config.ressourceQualityTable = {0.5, 1, 1.5, 3}
config.numberOfMaps = 4
config.mapNumber = 0 -- 0 means random

-- tracking
config.trackingOverTimeTimeout = 15

-- mobs
config.mobSightRange = 250
config.mobMovementSpeed = config.walkspeed * 0.65
config.mobAttackRange = 60
config.mobDamage = 20
config.mobAnimSpeed = 3
config.mobAttackTimer = 2
config.dummyMaxPain = 90
config.pBDuration = 1.6

-- boss mob (= barrier)
config.bossSightRange = 400
config.bossAnimSpeed = 3
config.bossAttackTimer = 2
config.bossDamage_1 = 35
config.bossDamage_2 = 50
config.bossDamage_3 = 65
config.bossDamage_4 = 80
config.bossDamage_5 = 100
config.bossHealth_1 = 2000 / config.timecompression -- 800 dpm * 60 minutes + 2.000 (so one player can't do it alone)
config.bossHealth_2 = 6000 / config.timecompression -- 800 dpm * 60 minutes + 2.000 (so one player can't do it alone)
config.bossHealth_3 = 10000 / config.timecompression -- 800 dpm * 60 minutes + 2.000 (so one player can't do it alone)
config.bossHealth_4 = 18000 / config.timecompression -- 800 dpm * 60 minutes + 2.000 (so one player can't do it alone)
config.bossHealth_5 = 20000 / config.timecompression -- 800 dpm * 60 minutes + 2.000 (so one player can't do it alone)
config.bossMovementSpeed_1 = config.walkspeed * 0.55
config.bossMovementSpeed_2 = config.walkspeed * 0.55
config.bossMovementSpeed_3 = config.walkspeed * 0.65
config.bossMovementSpeed_4 = config.walkspeed * 0.65
config.bossMovementSpeed_5 = config.walkspeed * 0.75
--~ config.bossPoints_1 = 1
--~ config.bossPoints_2 = 3
--~ config.bossPoints_3 = 5
--~ config.bossPoints_4 = 7
--~ config.bossPoints_5 = 9

-- blockers
config.blockerMaxPain = 200
config.blockerDecaySpeed = 0.5

-- visuals
config.show_fog_of_war = true
config.sightDistanceFar = 800
config.sightDistanceNear = 400
config.footStepVisibility = 15 -- beware: large numbers will be bad for performance
config.minPlayerNumberToDecreaseFootstepsAmount = 4
config.AEShowTime = 4
config.focusSpriteMaxRange = 2.5
config.cellsUntilDark = 3
config.cellSize = 40
config.cellUpdateEachNFrames = 0
config.characterViewRange = 800
config.characterViewAngle = 270
config.characterFeelRange = 80
config.textColor = {0.1,0.5,0.9}
config.lineOfSightColor = {32,32,32} -- 0 to 255
config.lineOfSightUnknown = 0
config.lineOfSightOutOfSight = 0.65
config.lineOfSightInSight = 1
config.audioRange = config.characterViewRange * 1.5

-- gamepad
config.gamepad_cursor_speed_near = 300
config.gamepad_cursor_speed_far = 800
config.gamepad_cursor_near_distance = 400
config.gamepad_cursor_near_border = 200

-- debug
config.draw_debug_info = false
config.draw_collision_info = false 
config.show_profile_info = false
config.show_object_list = false
config.show_prints = true

-- network
-- server ip and port are in localconfig
config.sync_high = 1 / 20
config.sync_low = 1
config.sync_zoneless_timeout = 3
config.sync_complete_timeout = 1
config.network_fps = 60
config.network_ms_to_wait_in_service = 3

-- map
config.map_width = 3200
config.map_height = 3200
config.zones = 10

-- team colors
config.teamColors = {
	alpha = {1,0.2,0.2},
	beta = {0.2,0.2,1},
	gamma = {0.2,1,0.2},
	delta = {0.9,0.9,0.9},
	dev = {0.1,0.2,0.3},
	neutral = {0.25,0.25,0.25},
}

-- determination
config.stunDeterminationRatio = 10
config.mezzDeterminationRatio = 7
config.pbDeterminationRatio = 5
config.rootDeterminationRatio = 5
config.snareDeterminationRatio = 3
config.determinationFade = 3

return config
