
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
-- start_target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=}
-- function target_selection_callback(start_target, target_selection, targets_selected_callback)
-- -- function action_handling.register_target_selection(name, target_selection_callback)

-- effect: see action_definitions.lua, eg. {effect_type = "damage", str = 15},
-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=}
-- function effect_callback(target, effect)
-- -- function action_handling.register_effect(name, effect_callback)

-- x,y centered

spawnExplosionCircle = function (x,y,r,t,color)
	t = config.AEShowTime
	color = color or {255,0,255,128}
	for k,v in pairs(color) do
		print(k,v)
	end
	local d = Fill:new{ shape="circle", x = x-r, y = y-r, width = r*2, height = r*2, border = {0,0,0,0}, fill = color or defaultColor}
	the.view.layers.particles:add(d)
	the.view.timer:after(t, function() 
		the.view.layers.particles:remove(d)
	end)
	the.view.timer:every(0.05, function() 
		d.alpha = d.alpha - 0.05
	end)
end


-- target_selection: self ----------------------------------------------------------
action_handling.register_target_selection("self", function (start_target, target_selection, source_oid, targets_selected_callback)
	targets_selected_callback({start_target})
end)

-- target_selection: ae ----------------------------------------------------------
-- eg. {target_selection_type = "ae", range = 10, cone = 60, piercing_number = 3, gfx = "/assets/graphics/action_projectiles/shield_bash_projectile.png"},
-- has: range, piercing_number
-- todo: cone, gfx
action_handling.register_target_selection("ae", function (start_target, target_selection, source_oid, targets_selected_callback)
	local x,y = action_handling.get_target_position(start_target)
	
	spawnDebugCircle(x,y,target_selection.range)
	spawnExplosionCircle(x,y,target_selection.range,target_selection.explosion_color) -- TODO: fix target_selection.explosion_color
	
	local l = action_handling.find_ae_targets(x,y, target_selection.range, 
		target_selection.piercing_number or 1000000)
	
	targets_selected_callback(utils.map1(l, function (o) 
		local t = action_handling.object_to_target(o)
		action_handling.add_view_on_demand(t, start_target)
		return t
	end))
end)


-- target_selection: projectile ----------------------------------------------------------
-- eg. {target_selection_type = "projectile", range = 200, speed = 150, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/action_projectiles/bow_shot_projectile.png"},
-- has: speed, gfx, range, piercing_number, ae_size, ae_targets
action_handling.register_target_selection("projectile", function (start_target, target_selection, source_oid, targets_selected_callback)
	local cx,cy = action_handling.get_target_position(start_target)
	
	local vx,vy = action_handling.get_view(start_target)
	local dx,dy = cx - vx, cy - vy
	
	if vector.len(dx,dy) == 0 then
		print("ERROR it is not possible to shoot a projectile without a view/destination position")
		return
	end
	
	-- cap target by range
	local dist = math.min(target_selection.range, vector.lenFromTo(cx,cy, vx, vy))
	local rx,ry = vector.fromToWithLen(cx,cy, vx, vy, dist)
	local tx,ty = vector.add(cx,cy, rx,ry)
	
	local rotation = vector.toVisualRotation(dx,dy)
	
	local projectilevx, projectilevy = -dx, -dy
	local l = vector.len(projectilevx, projectilevy)
	projectilevx, projectilevy = vector.normalizeToLen(projectilevx, projectilevy, target_selection.speed)
	
	-- number of targets
	local target_left = target_selection.piercing_number or 1
	local last_target_oid = nil
	local targets_hit = {}
		
	local imgObj = Cached:image(target_selection.gfx)
	local w,h = imgObj:getWidth(), imgObj:getHeight()
	-- assert: projectile size == player size
	local projectile = Projectile:new{ 
		origin_oid = start_target.oid,
		image = target_selection.gfx,
		x = cx-w/2, 
		y = cy-h/2, 
		rotation = rotation - math.pi,
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
		if other.oid and targets_hit[other.oid] then
			doCollide = false
		end
		
		if doCollide and target_left > 0 then
			last_target_oid = other.oid
			if other.oid then targets_hit[other.oid] = true end
						
			-- call effect on collision target
			local t = action_handling.get_target(other)
			action_handling.add_view_on_demand(t, start_target)
			targets_selected_callback({t})
			
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
			action_handling.add_view_on_demand(target, start_target)
			targets_selected_callback({target})
		end
		-- ae effect at the end?
		if target_selection.ae_targets and target_selection.ae_size and 
			target_selection.ae_targets > 0 and target_selection.ae_size > 0 
		then
			print("PIERCING AE", target_selection.ae_targets, target_selection.ae_size)
			local x,y = action_handling.get_target_position(self)
			spawnDebugCircle(x,y,target_selection.ae_size)
			spawnExplosionCircle(x,y,target_selection.range, target_selection.explosion_color)  -- TODO: fix target_selection.explosion_color

			local l = action_handling.find_ae_targets(x,y, target_selection.ae_size, 
				target_selection.piercing_number or 1000000)
			
			targets_selected_callback(utils.map1(l, function (t) 
				action_handling.add_view_on_demand(t, start_target)
				return t
			end))
		end

		if oldOnDie then oldOnDie(self) end
	end
	
	playSound('/assets/audio/bow.wav', 1, 'short') -- source: http://opengameart.org/content/battle-sound-effects
end)


-- effect: spawn ----------------------------------------------------------
-- eg. {effect_type = "spawn", application = ...},
-- has: application
action_handling.register_effect("spawn", function (target, effect, source_oid)
	action_handling.start(effect.application, target, source_oid, source_oid)
end)

-- effect: xp (gain) ----------------------------------------------------------
-- eg. {effect_type = "xp", str = 60},
-- has: str
action_handling.register_effect("xp", function (target, effect, source_oid)
	object_manager.send(target.oid, "xp", effect.str, source_oid)
end)

-- effect: gank ----------------------------------------------------------
-- eg. {effect_type = "gank"},
-- has: n/a
action_handling.register_effect("gank", function (target, effect, source_oid)
	object_manager.send(target.oid, "gank")
end)

-- effect: invis ----------------------------------------------------------
-- eg. {effect_type = "invis"},
-- has: duration, speedPenalty TODO: not while moving, not while casting, etc.
action_handling.register_effect("invis", function (target, effect, source_oid)
	object_manager.send(target.oid, "invis", effect.duration, effect.speedPenalty, source_oid)
end)

-- effect: heal ----------------------------------------------------------
-- eg. {effect_type = "heal", str = 60},
-- has: str
action_handling.register_effect("heal", function (target, effect, source_oid)
	object_manager.send(target.oid, "heal", effect.str, source_oid)
end)

-- effect: damage ----------------------------------------------------------
-- eg. {effect_type = "damage", str = 60},
-- has: str
action_handling.register_effect("damage", function (target, effect, source_oid)
	object_manager.send(target.oid, "damage", effect.str, source_oid)
end)

-- effect: damage_over_time ----------------------------------------------------------
-- eg. {effect_type = "damage_over_time", ticks = 5, duration = 20, str = 5},
-- has: str
action_handling.register_effect("damage_over_time", function (target, effect, source_oid)
	object_manager.send(target.oid, "damage_over_time", effect.str, effect.duration, effect.ticks, source_oid)
end)

-- effect: runspeed ----------------------------------------------------------
-- eg. {effect_type = "runspeed", str = 100, duration = 10},
-- has: str, duration
action_handling.register_effect("runspeed", function (target, effect, source_oid)
	object_manager.send(target.oid, "runspeed", effect.str, effect.duration, source_oid)
end)

-- effect: stun ----------------------------------------------------------
-- eg. {effect_type = "stun", duration = 10},
-- has: duration
action_handling.register_effect("stun", function (target, effect, source_oid)
	object_manager.send(target.oid, "stun", effect.duration, source_oid)
end)

-- effect: transfer ----------------------------------------------------------
-- eg. {effect_type = "transfer", from = "targets", to = "self", eff = 0.5, attribute = "hp", ticks = 5, duration = 30, str = 10}
-- todo: duration, from, to, eff, attribute, ticks, duration, str
action_handling.register_effect("stun", function (target, effect, source_oid)
	--~ object_manager.send(target.oid, "stun", effect.duration, source_oid)
end)
