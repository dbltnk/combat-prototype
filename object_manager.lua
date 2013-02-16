--[[
common object parameters:
oid
x
y
receive = function(name, a, b, c, ...)
]]

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
