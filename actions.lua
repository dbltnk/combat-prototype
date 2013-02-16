
local object_manager = require 'object_manager'
local action_handling = require 'action_handling'
local tools = require 'tools'
local vector = require 'vector'
local input = require 'input'
local config = require 'config'
local utils = require 'utils'

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

-- target_selection: ae ----------------------------------------------------------
-- eg. {target_selection_type = "ae", range = 10, cone = 60, piercing_number = 3, gfx = "/assets/graphics/action_projectiles/shield_bash_projectile.png"},
-- has: range
-- todo: range, cone, piercing_number, gfx
action_handling.register_target_selection("ae", function (start_target, target_selection, targets_selected_callback)
	local x,y = action_handling.get_target_position(start_target)
	
	local l = object_manager.find_in_sphere(x,y, target_selection.range)
	targets_selected_callback(utils.map1(l, function (o) 
		return action_handling.object_to_target(o)
	end))
end)


-- target_selection: projectile ----------------------------------------------------------
-- eg. {target_selection_type = "projectile", range = 200, speed = 150, stray = 5, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/action_projectiles/bow_shot_projectile.png"},
-- has: speed, gfx
-- todo: range, stray, ae_size, ae_targets, piercing_number
action_handling.register_target_selection("projectile", function (start_target, target_selection, targets_selected_callback)
	local worldMouseX, worldMouseY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
	
	local cx,cy = action_handling.get_target_position(start_target)
	-- mouse -> player vector
	local dx,dy = cx - (worldMouseX), cy - (worldMouseY)
	
	local rotation = math.atan2(dy, dx) - math.pi / 2
	
	local projectilevx, projectilevy = -dx, -dy
	local l = vector.len(projectilevx, projectilevy)
	projectilevx, projectilevy = vector.normalizeToLen(projectilevx, projectilevy, target_selection.speed)
	
	-- assert: projectile size == player size
	local projectile = Projectile:new{ 
		image = target_selection.gfx,
		x = cx, 
		y = cy, 
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


-- effect: heal ----------------------------------------------------------
-- eg. {effect_type = "heal", str = 60},
-- has: str
action_handling.register_effect("heal", function (target, effect)
	object_manager.send(target.oid, "heal", effect.str)
end)

-- effect: damage ----------------------------------------------------------
-- eg. {effect_type = "damage", str = 60},
-- has: str
action_handling.register_effect("damage", function (target, effect)
	object_manager.send(target.oid, "damage", effect.str)
end)

-- effect: runspeed ----------------------------------------------------------
-- eg. {effect_type = "runspeed", str = 100, duration = 10},
-- has: str, duration
action_handling.register_effect("runspeed", function (target, effect)
	object_manager.send(target.oid, "runspeed", effect.str, effect.duration)
end)
