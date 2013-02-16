
local object_manager = require 'object_manager'
local action_handling = require 'action_handling'
local tools = require 'tools'
local vector = require 'vector'
local input = require 'input'
local config = require 'config'

require 'zoetrope'

-- function targets_selected_callback({t0,t1,t2,...})
-- target_selection: eg. {target_selection_type = "ae", range = 10, cone = 60, piercing_number = 3, gfx = "/assets/action_projectiles/shield_bash_projectile.png"},
-- start_target: {oid=} or {x=,y=}
-- function target_selection_callback(start_target, target_selection, targets_selected_callback)
-- -- function action_handling.register_target_selection(name, target_selection_callback)

-- effect: see action_definitions.lua, eg. {effect_type = "damage", str = 15},
-- target: {oid=} or {x=,y=}
-- function effect_callback(target, effect)
-- -- function action_handling.register_effect(name, effect_callback)

-- target_selection: self ----------------------------------------------------------
action_handling.register_target_selection("self", function (start_target, target_selection, targets_selected_callback)
	targets_selected_callback({start_target})
end)

-- target_selection: projectile ----------------------------------------------------------
action_handling.register_target_selection("projectile", function (start_target, target_selection, targets_selected_callback)
	local worldMouseX, worldMouseY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
	
	local cx,cy = action_handling.get_target_position(start_target)
	-- mouse -> player vector
	local dx,dy = cx - (worldMouseX), cy - (worldMouseY)
	
	local rotation = math.atan2(dy, dx) - math.pi / 2
	
	local projectilevx, projectilevy = -dx, -dy
	local l = vector.len(projectilevx, projectilevy)
	projectilevx, projectilevy = vector.normalizeToLen(projectilevx, projectilevy, config.projectilespeed)
	
	-- assert: projectile size == player size
	local projectile = Projectile:new{ 
		x = the.player.x, 
		y = the.player.y, 
		rotation = rotation,
		velocity = { x = projectilevx, y = projectilevy },
		start = { x = cx, y = cy },
		target = { x = worldMouseX, y = worldMouseY },
	}
	
	the.app.view.layers.projectiles:add(projectile)
	-- stores an projectile reference, projectiles get stored in the key
	the.projectiles[projectile] = true
	
	playSound('/assets/audio/bow.wav', 1, 'short') -- source: http://opengameart.org/content/battle-sound-effects
end)
