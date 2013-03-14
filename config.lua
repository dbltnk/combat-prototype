
local config = {}

-- balancing variables
config.walkspeed = 100
config.runspeed = 200
config.animspeed = 16
config.projectilespeed = 500
config.energyreg = 1
config.healthreg = 1
config.maxPain = 200
config.maxEnergy = 300
config.barrierHealth = 10000
config.roundTime = 3600 -- in seconds
config.xpCap = 1000
config.levelCap = 10
config.dummyXPWorth = 450
config.xpCapTimer = config.roundTime / config.levelCap

-- audio
config.volume = 0.3


-- gamepad
config.gamepad_cursor_speed_near = 300
config.gamepad_cursor_speed_far = 800
config.gamepad_cursor_near_distance = 400
config.gamepad_cursor_near_border = 200

config.draw_debug_info = true
config.show_profile_info = false

return config
