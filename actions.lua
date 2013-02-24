
local object_manager = require 'object_manager'
local action_handling = require 'action_handling'
local tools = require 'tools'
local vector = require 'vector'
local input = require 'input'
local config = require 'config'
local utils = require 'utils'
local list = require 'list'

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
-- todo: cone, piercing_number, gfx
action_handling.register_target_selection("ae", function (start_target, target_selection, targets_selected_callback)
	local x,y = action_handling.get_target_position(start_target)
	
	local l = object_manager.find_in_sphere(x,y, target_selection.range)
	
	-- limited amount of targets? -> order and only use the nearest ones
	if target_selection.piercing_number then
		print(target_selection.piercing_number, #l)
		l = list.process_values(l)
			:select(function(t) 
				local xx,yy = action_handling.get_target_position(t)
				return {
					target=t, 
					dist=vector.lenFromTo(x,y, xx,yy) 
				} end)
			:orderby(function(a,b) return a.dist < b.dist end)
			:take(target_selection.piercing_number)
			:select(function(a) return a.target end)
			:done()
	end
	
	targets_selected_callback(utils.map1(l, function (o) 
		return action_handling.object_to_target(o)
	end))
end)


-- target_selection: projectile ----------------------------------------------------------
-- eg. {target_selection_type = "projectile", range = 200, speed = 150, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/action_projectiles/bow_shot_projectile.png"},
-- has: speed, gfx, range, piercing_number
-- todo: ae_size, ae_targets
action_handling.register_target_selection("projectile", function (start_target, target_selection, targets_selected_callback)
	local worldMouseX, worldMouseY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
	
	local cx,cy = action_handling.get_target_position(start_target)
	-- mouse -> player vector
	local dx,dy = cx - (worldMouseX), cy - (worldMouseY)
	
	-- cap target by range
	local dist = math.min(target_selection.range, vector.lenFromTo(cx,cy, worldMouseX, worldMouseY))
	local rx,ry = vector.fromToWithLen(cx,cy, worldMouseX, worldMouseY, dist)
	local tx,ty = vector.add(cx,cy, rx,ry)
	
	local rotation = math.atan2(dy, dx) - math.pi / 2
	
	local projectilevx, projectilevy = -dx, -dy
	local l = vector.len(projectilevx, projectilevy)
	projectilevx, projectilevy = vector.normalizeToLen(projectilevx, projectilevy, target_selection.speed)
	
	-- number of targets
	local target_left = target_selection.piercing_number or 1
	local last_target_oid = nil
		
	local imgObj = Cached:image(target_selection.gfx)
	local w,h = imgObj:getWidth(), imgObj:getHeight()
	-- assert: projectile size == player size
	local projectile = Projectile:new{ 
		origin_oid = start_target.oid,
		image = target_selection.gfx,
		x = cx-w/2, 
		y = cy-h/2, 
		rotation = rotation,
		velocity = { x = projectilevx, y = projectilevy },
		start = { x = cx, y = cy },
		target = { x = tx, y = ty },
	}
	
	-- decorate onCollide
	local oldOnCollide = projectile.onCollide
	projectile.onCollide = function(self, other, horizOverlap, vertOverlap)
		local doCollide = true
		
		-- ignore self check
		if other.oid and self.origin_oid and other.oid == self.origin_oid then
			doCollide = false
		end
		
		-- ignore multiple hits to one object in sequence
		if other.oid and last_target_oid == other.oid then
			doCollide = false
		end
		
		if doCollide and target_left > 0 then
			last_target_oid = other.oid
		
			-- call effect on collision target
			targets_selected_callback({action_handling.object_to_target(other)})
			
			-- TODO ignore last target
			target_left = target_left - 1
			
			if target_left <= 0 and oldOnCollide then 
				oldOnCollide(self, other, horizOverlap, vertOverlap) 
			end
		end
	end
	
	-- decorate onDie
	local oldOnDie = projectile.onDie
	projectile.onDie = function(self)
		-- target left? so trigger at location
		if target_left > 0 then
			local target = {x = self.x, y = self.y}
			targets_selected_callback({target})
		end

		if oldOnDie then oldOnDie(self) end
	end
	
	the.app.view.layers.projectiles:add(projectile)
	-- stores an projectile reference, projectiles get stored in the key
	the.projectiles[projectile] = true
	
	playSound('/assets/audio/bow.wav', 1, 'short') -- source: http://opengameart.org/content/battle-sound-effects
end)


-- effect: spawn ----------------------------------------------------------
-- eg. {effect_type = "spawn", application = ...},
-- has: application
action_handling.register_effect("spawn", function (target, effect)
	action_handling.start(effect.application, target)
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
