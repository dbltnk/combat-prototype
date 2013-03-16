-- Projectile


Projectile = Tile:extend
{
	width = 32,
	height = 32,
	--~ image = '/assets/graphics/action_projectiles/bow_shot_projectile.png',
    -- target.x target.y start.x start.y
	
	changeMonitor = nil,

	onCollide = function(self, other, horizOverlap, vertOverlap)
		self:die()
	end,
	
	onUpdate = function (self)
		local totalDistance = vector.lenFromTo(self.start.x, self.start.y, self.target.x, self.target.y)
		local distFromStart = vector.lenFromTo(self.start.x, self.start.y, self.x, self.y)
		
		if distFromStart >= totalDistance then
			self:die()
		end
		
		self.changeMonitor:checkAndSend()
	end,
	
	onDie = function (self)
		-- not possible to revive them later
		the.app.view.layers.projectiles:remove(self)
		-- will remove the projectile reference from the map
		the.projectiles[self] = nil	
		
		object_manager.delete(self)
		network.send({channel = "game", cmd = "delete", oid = self.oid, })
	end,
	
	onNew = function (self)
		object_manager.create(self)

		the.app.view.layers.projectiles:add(self)
		-- stores an projectile reference, projectiles get stored in the key
		the.projectiles[self] = true
		
		drawDebugWrapper(self)
		
		self.changeMonitor = MonitorChanges:new{ obj = self, keys = {"x", "y", 
			"rotation", } }
			
		network.send(self:netCreate())
	end,
	
	netCreate = function (self)
		return { 
			channel = "game", cmd = "create", class = "Projectile", oid = self.oid, 
			x = self.x, y = self.y, owner = self.owner, 
			rotation = self.rotation,
			image = self.image, width = self.width, height = self.height, 
		}
	end,
}
