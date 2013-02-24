--[[
common object parameters:
oid
x
y
receive = function(name, a, b, c, ...)
]]

local list = require 'list'
local vector = require 'vector'

local object_manager = {}

object_manager.objects = {}
object_manager.nextFreeId = 1

function object_manager.visit (fun)
	for oid,o in pairs(object_manager.objects) do
		fun(oid,o)
	end
end

function object_manager.get (oid)
	if object_manager.objects[oid] then
		return object_manager.objects[oid]
	else
		print("OBJECTMANAGER", "there is no object with oid", oid)
	end
end

-- writes property oid into o (o.oid) and returns the changed object
function object_manager.create (o)
	local oid = object_manager.nextFreeId
	object_manager.nextFreeId = object_manager.nextFreeId + 1
	
	o.oid = oid
	object_manager.objects[oid] = o
	return o
end

function object_manager.delete (o)
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
function object_manager.find_in_sphere (x,y,r)
	return object_manager.find_where(function (oid, o)
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
