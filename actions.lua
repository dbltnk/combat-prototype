
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
	EffectCircle:new{x = x, y = y, r = r, t = t,color = color}
end


-- target_selection: self ----------------------------------------------------------
action_handling.register_target_selection("self", function (start_target, target_selection, source_oid, targets_selected_callback)
	targets_selected_callback({start_target})
end)

-- target_selection: ae ----------------------------------------------------------
-- eg. {target_selection_type = "ae", range = 10, piercing_number = 3},
-- has: range, piercing_number
action_handling.register_target_selection("ae", function (start_target, target_selection, source_oid, targets_selected_callback)
	local x,y = action_handling.get_target_position(start_target)
	
	spawnDebugCircle(x,y,target_selection.range)
	spawnExplosionCircle(x,y, target_selection.range, nil, target_selection.explosion_color)
	
	local l = action_handling.find_ae_targets(x,y, target_selection.range, 
		target_selection.piercing_number or 1000000)
	--print(x,y, target_selection.range, target_selection.piercing_number)
	--utils.vardump(l)
	
	local c = 0
	
	targets_selected_callback(utils.map1(l, function (o) 
		local t = action_handling.object_to_target(o)
		action_handling.add_view_on_demand(t, start_target)
		--~ utils.vardump(t)
		
		-- hit tracking
		for k,v in pairs(t) do
			if k == "oid" and t[k] ~= source_oid then
				c = c + 1
			end
		end
		
		return t
	end))
	
	local lastSkill = object_manager.get(source_oid).lastUsedSkill
	if c > 0 then
		track("skill_hit", lastSkill, source_oid, c)
		print("skill_hit", lastSkill, source_oid, c)
	else
		track("skill_miss", lastSkill, source_oid, c)
		print("skill_miss", lastSkill, source_oid, c)
	end
	
end)

-- target_selection: cone ----------------------------------------------------------
-- eg. {target_selection_type = "cone", range = 10, cone = 60, piercing_number = 3, gfx = "/assets/graphics/action_projectiles/shield_bash_projectile.png"},
-- has: range, piercing_number, cone, gfx
action_handling.register_target_selection("cone", function (start_target, target_selection, source_oid, targets_selected_callback)
	local cx,cy = action_handling.get_target_position(start_target)
	
	local vx,vy = action_handling.get_view(start_target)
	local dx,dy = vx - cx, vy - cy
	
	if vector.len(dx,dy) == 0 then
		print("ERROR it is not possible to shoot a cone without a view/destination position")
		return
	end
	
	local x,y = action_handling.get_target_position(start_target)
	local rotation = vector.toVisualRotation(dx,dy)
	
	if (target_selection.gfx and target_selection.gfx_radius) then
		EffectImage:new{x = x, y = y, r = target_selection.gfx_radius, image = target_selection.gfx, 
			rotation = rotation, color = target_selection.explosion_color,}
	else
		spawnExplosionCircle(x,y, target_selection.range, nil, target_selection.explosion_color)
	end

	spawnDebugCircle(x,y,target_selection.range)
	
	local coneRadians = target_selection.cone / 180 * math.pi
	local l = action_handling.find_cone_targets(x,y, dx,dy, coneRadians / 2, target_selection.range, 
		target_selection.piercing_number or 1000000)
	--print(x,y, target_selection.range, target_selection.piercing_number)
	--utils.vardump(l)
	
	local c = 0
	
	targets_selected_callback(utils.map1(l, function (o) 
		local t = action_handling.object_to_target(o)
		action_handling.add_view_on_demand(t, start_target)
		--utils.vardump(t)
		
		-- hit tracking
		for k,v in pairs(t) do
			if k == "oid" and t[k] ~= source_oid then
				c = c + 1
			end
		end
		
		return t
	end))
	
	local lastSkill = object_manager.get(source_oid).lastUsedSkill
	if c > 0 then
		track("skill_hit", lastSkill, source_oid, c)
		--~ print("skill_hit", lastSkill, source_oid, c)
	else
		track("skill_miss", lastSkill, source_oid, c)
		--~ print("skill_miss", lastSkill, source_oid, c)
	end
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
		start_time = network.time,
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
		
		if doCollide and projectile.onCollideOnlyFirst and 
			not projectile.onCollideOnlyFirstAlreadyCalled 
		then
			projectile.onCollideOnlyFirstAlreadyCalled = true
			projectile.onCollideOnlyFirst(self, other, horizOverlap, vertOverlap) 
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
			local x,y = action_handling.get_target_position(self)
			local target = {x = x, y = y}
			action_handling.add_view_on_demand(target, start_target)
			targets_selected_callback({target})
		end
		if target_selection.ae_targets == 0 and target_selection.ae_size == 0 then 
			local x,y = action_handling.get_target_position(self)
			spawnExplosionCircle(x, y, 6, nil, {64,32,32,128})
		end
		--~ -- ae effect at the end?
		if target_selection.ae_targets and target_selection.ae_size and 
			target_selection.ae_targets > 0 and target_selection.ae_size > 0 
		then
			print("PIERCING AE", target_selection.ae_targets, target_selection.ae_size)
			local x,y = action_handling.get_target_position(self)
			spawnDebugCircle(x,y,target_selection.ae_size)
			spawnExplosionCircle(x,y,target_selection.range, nil, target_selection.explosion_color)

			local l = action_handling.find_ae_targets(x,y, target_selection.ae_size, 
				target_selection.piercing_number or 1000000)
			
			targets_selected_callback(utils.map1(l, function (t) 
				action_handling.add_view_on_demand(t, start_target)
				return t
			end))
		end

		if oldOnDie then oldOnDie(self) end
	end
	
end)


-- effect: spawn ----------------------------------------------------------
-- eg. {effect_type = "spawn", application = ...},
-- has: application
action_handling.register_effect("spawn", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	--~ utils.vardump(target)
	action_handling.start(effect.application, target, source_oid, source_oid)
end)

-- effect: xp (gain) ----------------------------------------------------------
-- eg. {effect_type = "xp", str = 60},
-- has: str
action_handling.register_effect("xp", function (target, effect, source_oid)
	object_manager.send(target.oid, "xp", effect.str, source_oid, CHARACTER_XP_COMBAT)
end)

-- effect: gank ----------------------------------------------------------
-- eg. {effect_type = "gank"},
-- has: n/a
action_handling.register_effect("gank", function (target, effect, source_oid)
	object_manager.send(target.oid, "gank")
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: sneak ----------------------------------------------------------
-- eg. {effect_type = "sneak"},
-- has: duration, speedPenalty
action_handling.register_effect("sneak", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "sneak", effect.duration , effect.speedPenalty, source_oid)
end)

-- effect: hide ----------------------------------------------------------
-- eg. {effect_type = "hide"},
-- has: 
action_handling.register_effect("hide", function (target, effect, source_oid)
	object_manager.send(target.oid, "hide", source_oid)
end)

-- effect: heal ----------------------------------------------------------
-- eg. {effect_type = "heal", str = 60},
-- has: str
action_handling.register_effect("heal", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "heal", effect.str * increase, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: healOnlyOthers ----------------------------------------------------------
-- eg. {effect_type = "heal", str = 60},
-- has: str
action_handling.register_effect("healOnlyOthers", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	if target.oid ~= source_oid then 
		object_manager.send(target.oid, "heal", effect.str * increase, source_oid) 
		object_manager.send(target.oid, "blink", source_oid)
	end
end)

-- effect: heal_over_time ----------------------------------------------------------
-- eg. {effect_type = "heal_over_time", ticks = 5, duration = 20, str = 5},
-- has: str
action_handling.register_effect("heal_over_time", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "heal_over_time", effect.str * increase, effect.duration, effect.ticks, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: stamHeal ----------------------------------------------------------
-- eg. {effect_type = "stamHeal", str = 60},
-- has: str
action_handling.register_effect("stamHeal", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "stamHeal", effect.str * increase, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
	--print("actions",effect.str)
end)

-- effect: damage ----------------------------------------------------------
-- eg. {effect_type = "damage", str = 60},
-- has: str
action_handling.register_effect("damage", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "damage", effect.str * increase, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: damageOnlyOthers ----------------------------------------------------------
-- eg. {effect_type = "damage", str = 60},
-- has: str
action_handling.register_effect("damageOnlyOthers", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	if target.oid ~= source_oid then 
		object_manager.send(target.oid, "damage", effect.str * increase, source_oid) 
		object_manager.send(target.oid, "blink", source_oid)
	end
end)

-- effect: damage_over_time ----------------------------------------------------------
-- eg. {effect_type = "damage_over_time", ticks = 5, duration = 20, str = 5},
-- has: str
action_handling.register_effect("damage_over_time", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "damage_over_time", effect.str * increase, effect.duration, effect.ticks, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: runspeed ----------------------------------------------------------
-- eg. {effect_type = "runspeed", str = 100, duration = 10},
-- has: str, duration
action_handling.register_effect("runspeed", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "runspeed", effect.str, effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: snare_only_others ----------------------------------------------------------
-- eg. {effect_type = "snare_only_others", str = 100, duration = 10},
-- has: str, duration
action_handling.register_effect("snare_only_others", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	if target.oid ~= source_oid then 
		object_manager.send(target.oid, "runspeed", effect.str, effect.duration, source_oid) 
		object_manager.send(target.oid, "blink", source_oid)
	end
end)

-- effect: snare_break ----------------------------------------------------------
-- eg. {effect_type = "snare_break"},
-- has: 
action_handling.register_effect("snare_break", function (target, effect, source_oid)
	object_manager.send(target.oid, "snare_break", source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: stun ----------------------------------------------------------
-- eg. {effect_type = "stun", duration = 10},
-- has: duration
action_handling.register_effect("stun", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "stun", effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: stunOnlyOthers ----------------------------------------------------------
-- eg. {effect_type = "stun", duration = 10},
-- has: duration
action_handling.register_effect("stunOnlyOthers", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	if target.oid ~= source_oid then 
		object_manager.send(target.oid, "stun", effect.duration, source_oid) 
		object_manager.send(target.oid, "blink", source_oid)
	end
end)

-- effect: stun_break ----------------------------------------------------------
-- eg. {effect_type = "stun_break"},
-- has: 
action_handling.register_effect("stun_break", function (target, effect, source_oid)
	object_manager.send(target.oid, "stun_break", source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: powerblock ----------------------------------------------------------
-- eg. {effect_type = "powerblock", duration = 10},
-- has: powerblock
action_handling.register_effect("powerblock", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "powerblock", effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: powerblockOnlyOthers ----------------------------------------------------------
-- eg. {effect_type = "powerblockOnlyOthers", duration = 10},
-- has: powerblock
action_handling.register_effect("powerblockOnlyOthers", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	if target.oid ~= source_oid then 
		object_manager.send(target.oid, "powerblock", effect.duration, source_oid) 
		object_manager.send(target.oid, "blink", source_oid)
	end
end)

-- effect: mezz ----------------------------------------------------------
-- eg. {effect_type = "mezz", duration = 10},
-- has: duration
action_handling.register_effect("mezz", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "mezz", effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: clarity ----------------------------------------------------------
-- eg. {effect_type = "clarity"},
-- has: 
action_handling.register_effect("clarity", function (target, effect, source_oid)
	object_manager.send(target.oid, "clarity", source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: root ----------------------------------------------------------
-- eg. {effect_type = "root", duration = 10},
-- has: duration
action_handling.register_effect("root", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "root", effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: root_only_others ----------------------------------------------------------
-- eg. {effect_type = "root_only_others", duration = 10},
-- has: duration
action_handling.register_effect("root_only_others", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	if target.oid ~= source_oid then 
		object_manager.send(target.oid, "root", effect.duration, source_oid) 
		object_manager.send(target.oid, "blink", source_oid)
	end
end)

-- effect: root_break ----------------------------------------------------------
-- eg. {effect_type = "root_break"},
-- has: 
action_handling.register_effect("root_break", function (target, effect, source_oid)
	object_manager.send(target.oid, "root_break", source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: stop_dots ----------------------------------------------------------
-- eg. {effect_type = "stop_dots"},
-- has: 
action_handling.register_effect("stop_dots", function (target, effect, source_oid)
	object_manager.send(target.oid, "stop_dots", source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: dmgModifier ----------------------------------------------------------
-- eg. {effect_type = "dmgModifier", duration = 10},
-- has: str, duration
action_handling.register_effect("dmgModifier", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "dmgModifier", effect.str, effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: transfer ----------------------------------------------------------
-- eg. {effect_type = "transfer", eff = 0.5, ticks = 5, duration = 30, str = 10}
-- has: duration, ticks, duration, str, eff
action_handling.register_effect_multitarget("transfer", function (targets, effect, source_oid) --TODO:  * increase
	--~ object_manager.send(target.oid, "stun", effect.duration, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	local targetOids = list.process(targets)
		:where(function(t) return t.oid end)
		:select(function(t) return t.oid end)
		:done()
	object_manager.send(source_oid, "transfer", effect.str * increase, effect.duration, effect.ticks, source_oid, targetOids, effect.eff)
end)

-- effect: moveSelfTo ----------------------------------------------------------
-- eg. {effect_type = "moveSelfTo"},
-- has: 
action_handling.register_effect("moveSelfTo", function (target, effect, source_oid)
	local x,y = action_handling.get_target_position(target)
	object_manager.send(source_oid, "moveSelfTo", x,y)
end)

-- effect: createWallAt ----------------------------------------------------------
-- eg. {effect_type = "createWallAt"},
-- has: 
action_handling.register_effect("createWallAt", function (target, effect, source_oid)
	local x,y = action_handling.get_target_position(target)
	local sx, sy = action_handling.get_target_position(object_manager.get(source_oid))
	local dx, dy = x - sx, y - sy	
	local displacement = 33
	
	if math.abs(dx) >= math.abs(dy) then 
		object_manager.send(source_oid, "createBlockerAt", x,y)
		for i = 1, 3 do
			object_manager.send(source_oid, "createBlockerAt", x,y+displacement*i)
		end
			for i = 1, 3 do
			object_manager.send(source_oid, "createBlockerAt", x,y+(displacement*i*-1))
		end
	else
		object_manager.send(source_oid, "createBlockerAt", x,y)
		for i = 1, 3 do
			object_manager.send(source_oid, "createBlockerAt", x+displacement*i,y)
		end
			for i = 1, 3 do
			object_manager.send(source_oid, "createBlockerAt", x+(displacement*i*-1),y)
		end
	end
end)

-- effect: createBollwerkAt ----------------------------------------------------------
-- eg. {effect_type = "createBollwerkAt"},
-- has: radius
action_handling.register_effect("createBollwerkAt", function (target, effect, source_oid)
	local x,y = action_handling.get_target_position(target)
	local sx, sy = action_handling.get_target_position(object_manager.get(source_oid))
	local dx, dy = x - sx, y - sy	
	local displacement = 33
	local r = effect.radius
	
	object_manager.send(source_oid, "createBlockerAt", x + r, y + r)
	object_manager.send(source_oid, "createBlockerAt", x + r, y - r)
	object_manager.send(source_oid, "createBlockerAt", x - r, y + r)
	object_manager.send(source_oid, "createBlockerAt", x - r, y - r)

	object_manager.send(source_oid, "createBlockerAt", x, y + r * 1.5)
	object_manager.send(source_oid, "createBlockerAt", x, y - r * 1.5)
	object_manager.send(source_oid, "createBlockerAt", x + r * 1.5, y)
	object_manager.send(source_oid, "createBlockerAt", x - r * 1.5, y)		
	
end)

-- effect: moveToMe ----------------------------------------------------------
-- eg. {effect_type = "moveToMe"},
-- has: 
action_handling.register_effect("moveToMe", function (target, effect, source_oid)
	local sx,sy = action_handling.get_target_position(object_manager.get(source_oid))
	local tx,ty = action_handling.get_target_position(target)
	local dx, dy = (sx * 8 + tx) / 9, (sy * 8 + ty) / 9
	object_manager.send(target.oid, "moveSelfTo", dx,dy)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: moveAwayFromMe ----------------------------------------------------------
-- eg. {effect_type = "moveAwayFromMe", str = 100},
-- has: str
action_handling.register_effect("moveAwayFromMe", function (target, effect, source_oid)
	local sx,sy = action_handling.get_target_position(object_manager.get(source_oid))
	local tx,ty = action_handling.get_target_position(target)
	local dx, dy = vector.fromToWithLen(sx,sy, tx,ty, effect.str)
	if target.oid ~= source_oid then 
		object_manager.send(target.oid, "moveSelfTo", tx+dx, ty+dy) 
		object_manager.send(target.oid, "blink", source_oid)
	end
end)

-- effect: buff_max_pain ----------------------------------------------------------
-- eg. {effect_type = "buff_max_pain", str = 100, duration = 15},
-- has: str, duration
action_handling.register_effect("buff_max_pain", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "buff_max_pain", effect.str, effect.duration * increase, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: invul ----------------------------------------------------------
-- eg. {effect_type = "invul", duration = 15},
-- has: duration
action_handling.register_effect("invul", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "invul", effect.duration * increase, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: changeSize ----------------------------------------------------------
-- eg. {effect_type = "changeSize", str = 150, duration = 15},
-- has: str, duration
action_handling.register_effect("changeSize", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "changeSize", effect.str, effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)

-- effect: mark ----------------------------------------------------------
-- eg. {effect_type = "mark", duration = 15},
-- has: duration
action_handling.register_effect("mark", function (target, effect, source_oid)
	local increase = (1 + config.strIncreaseFactor * object_manager.get_field(source_oid, "level", 0))
	object_manager.send(target.oid, "mark", effect.duration, source_oid)
	object_manager.send(target.oid, "blink", source_oid)
end)
