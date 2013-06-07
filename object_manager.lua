--[[
common object parameters:
oid
x
y
owner
rotation
receive = function(name, a, b, c, ...)
]]

local list = require 'list'
local vector = require 'vector'

local object_manager = {}

object_manager.objects = {}

function object_manager.visit (fun)
	for oid,o in pairs(object_manager.objects) do
		fun(oid,o)
	end
end

function object_manager.count ()
	local c = 0
	for k,v in pairs(object_manager.objects) do c = c + 1 end
	return c
end

-- returns the value stored in a objects (oid) field or defaultValue if the oid does not exist
function object_manager.get_field (oid, field, defaultValue)
	local o = object_manager.objects[oid]
	if o and o[field] then
		return o[field]
	else
		return defaultValue or nil
	end
end

function object_manager.get (oid)
	oid = tonumber(oid)
	if object_manager.objects[oid] then
		return object_manager.objects[oid]
	else
		--~ print("OBJECTMANAGER", "there is no object with oid", oid, type(oid))
		return nil
	end
end

function object_manager.generate_free_oid ()
	local oid = nil
	
	repeat
		oid = tonumber(math.random(1,1000000))
	until not object_manager.objects[oid]
	
	return oid
end

-- writes property oid, owner into o (o.oid) and returns the changed object
function object_manager.create (o)
	if not o.oid then
		o.oid = object_manager.generate_free_oid()
	else
		o.oid = tonumber(o.oid)
	end
	
	if not o.owner then
		o.owner = network.client_id
	end
	
	if o.oid == 0 then
		utils.vardump(o)
		print(debug.traceback())
		os.exit()
	end
	
	object_manager.objects[o.oid] = o
	return o
end

function object_manager.delete (o)
	o.oid = tonumber(o.oid)
	if o.oid then
		object_manager.objects[o.oid] = nil
	else
		for oid,oo in pairs(object_manager.objects) do
			if oo == o then
				object_manager.objects[oid] = nil
			end
		end
	end
end

-- returns {oid0=o0, oid1=o1, ...}
function object_manager.find_by_owner (owner)
	return object_manager.find_where(function (oid, o)
		return o.owner == owner
	end)
end

-- returns {oid0=o0, oid1=o1, ...}
function object_manager.find_in_sphere (x,y,r)
	return object_manager.find_where(function (oid, o)
		--print("stuff",vector.lenFromTo(x,y, o.x,o.y),x,y,o.x,o.y,r,oid,o.class)
		return vector.lenFromTo(x,y, o.x,o.y) <= r
	end)
end

-- returns {oid0=o0, oid1=o1, ...}
-- function filter(oid,o) -> bool (true is contained in result)
function object_manager.find_where (filter)
	local l = {}
	
	for oid,o in pairs(object_manager.objects) do
		if filter(oid,o) then
			l[oid] = o
		end
	end
	
	return l
end 

-- oids: oid or list or oids
function object_manager.send (oids, message_name, ...)
	if type(oids) ~= "table" then
		oids = {oids}
	end
	
	for k,oid in pairs(oids) do
		local o = object_manager.get(oid)
		if o and o.receive then
			o:receive(message_name, ...)
		end
	end
end

return object_manager
