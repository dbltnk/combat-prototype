-- SyncedObject

SyncedObject = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/unknown_object.png',
	oid = nil,
	owner = nil,
    	
	onUpdate = function (self)
		
	end,
	
	onDie = function (self)
		-- not possible to revive them later
		the.app.view.layers.characters:remove(self)
	end,
	
	onNew = function (self)
		the.app.view.layers.characters:add(self)
		drawDebugWrapper(self)
		
		-- creation time? apply movement
		if self.creation_time and self.velocity then
			local dt = network.time - self.creation_time
			self.x = self.x + self.velocity.x * dt
			self.y = self.y + self.velocity.y * dt
		end
	end,
	
	receive = function (self, message_name, ...)
		local params = {...}
		network.send({channel = "game", cmd = "msg", oid = self.oid, 
			name = message_name, params = params, time = network.time})
	end,
}
