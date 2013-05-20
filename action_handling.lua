
local object_manager = require 'object_manager'

local action_handling = {}

-- target_selection_type -> { ... }
action_handling.registered_target_selections = {}
-- effect_type -> { ... }
action_handling.registered_effects = {}
action_handling.registered_effects_multitarget = {}

-- target_selection_type: projectile, ae, self
-- effect_type: damage, heal, runspeed, spawn, transfer, damage_over_time

--[[
application = {
			target_selection = {target_selection_type = "ae", range = 10, cone = 60, piercing_number = 3, gfx = "/assets/action_projectiles/shield_bash_projectile.png"},
			effects = {
				{effect_type = "damage", str = 15},
				{effect_type = "stun", duration = 3},
			},
		},	
]]

-- any: contains x,y,rotation or oid
-- returns {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
function action_handling.get_target (any)
	if any.oid then return { oid = any.oid }
	else return { x = any.x or 0, y = any.y or 0, rotation = any.rotation or 0 } end
end

-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- returns x,y or view
function action_handling.get_view (target)
	local x,y = action_handling.get_target_position(target)
	return target.viewx or x, target.viewy or y
end

-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- returns x,y (id oid it returns its center)
function action_handling.get_target_position (target)
	local x,y = target.x, target.y
	local w,h = 0,0
	
	if target.oid then
		local o = object_manager.get(target.oid)
		x = o.x or x
		y = o.y or y
		
		w = o.width or w
		h = o.height or h
	end
	
	return x + w/2, y + h/2
end

-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- returns rotation
function action_handling.get_target_rotation (target)
	if target.rotation then 
		return target.rotation
	elseif target.oid then
		local o = object_manager.get(target.oid)
		return o.rotation
	else
		print("ACTION could not determine rotation of target", action_handling.to_string_target(target))
		return 0
	end
end

-- o : object_mangers object
-- returns {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=}
function action_handling.object_to_target (o)
	return {oid=o.oid}
end

-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (INOUT)
-- target_with_view: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=}
-- returns target with added view necessary
function action_handling.add_view_on_demand (target, target_with_view)
	target.viewx = target.viewx or target_with_view.viewx
	target.viewy = target.viewy or target_with_view.viewy
	return target
end

-- function targets_selected_callback({t0,t1,t2,...})
-- target_selection: eg. {target_selection_type = "ae", range = 10, cone = 60, piercing_number = 3, gfx = "/assets/action_projectiles/shield_bash_projectile.png"},
-- start_target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- function target_selection_callback(start_target, target_selection, source_oid, targets_selected_callback)
function action_handling.register_target_selection(name, target_selection_callback)
	action_handling.registered_target_selections[name] = target_selection_callback
end

-- effect: see action_definitions.lua, eg. {effect_type = "damage", str = 15},
-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- function effect_callback(target, effect, source_oid)
function action_handling.register_effect(name, effect_callback)
	action_handling.registered_effects[name] = effect_callback
end

-- effect: see action_definitions.lua, eg. {effect_type = "damage", str = 15},
-- targets: list of {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- function effect_callback(targets, effect, source_oid)
function action_handling.register_effect_multitarget(name, effect_callback)
	action_handling.registered_effects_multitarget[name] = effect_callback
end

-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
function action_handling.to_string_target(target)
	return "oid=" .. (target.oid or "nil") .. " x=" .. (target.x or "nil") .. " y=" .. (target.y or "nil") .. " rotation=" .. (target.rotation or "nil")
end

-- target_selection: eg. {target_selection_type = "ae", range = 10, cone = 60, piercing_number = 3, gfx = "/assets/action_projectiles/shield_bash_projectile.png"},
-- function targets_selected_callback({t0,t1,t2,...})
function action_handling.start_target_selection (start_target, target_selection, source_oid, targets_selected_callback)
	local t = target_selection.target_selection_type
	
	--~ print("ACTION start_target_selection", t, action_handling.to_string_target(start_target), source_oid)
	
	local ts = action_handling.registered_target_selections[t]
	
	if ts then
		ts(start_target, target_selection, source_oid, targets_selected_callback)
	else
		--print("ACTION start_target_selection", "unknown type")
	end
end

-- application: see action_definitions.lua
-- target: {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- source_oid
function action_handling.start (application, target, source_oid)
	action_handling.start_target_selection(target, application.target_selection, source_oid, function (targets)
		-- target selection finished
		
		-- start each effect on each target
		for ke,effect in pairs(application.effects) do
			action_handling.start_effect(effect, targets, source_oid)
		end
	end)
end

-- returns list of ( {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center) )
function action_handling.find_ae_targets (x,y, range, maxTargetCount)
	local l = object_manager.find_in_sphere(x,y, range)
	--~ utils.vardump(l)
	--~ print(x,y, range)
	
	l = list.process_values(l)
		:where(function(f) 
			return f.targetable
		end)
		:select(function(t) 
			local xx,yy = action_handling.get_target_position(t)
			return {
				target=t, 
				dist=vector.lenFromTo(x,y, xx,yy) 
			} end)
		:orderby(function(a,b) return a.dist < b.dist end)
		:take(maxTargetCount)
		:select(function(a) return a.target end)
		:done()
		
	return l
end

-- effect: see action_definitions.lua, eg. {effect_type = "damage", str = 15},
-- targets: list of {oid=,viewx=,viewy=} or {x=,y=,viewx=,viewy=} (x,y is center)
-- source_oid
function action_handling.start_effect (effect, targets, source_oid)
	local t = effect.effect_type
	
	--~ print("ACTION start_effect", t, action_handling.to_string_target(targets), source_oid)
	
	if action_handling.registered_effects[t] then
		for k,v in pairs(targets) do
			action_handling.registered_effects[t](v, effect, source_oid)
		end
	elseif action_handling.registered_effects_multitarget[t] then
		action_handling.registered_effects_multitarget[t](targets, effect, source_oid)
	else
		print("ACTION start_effect", "unknown type")
	end
end

return action_handling
