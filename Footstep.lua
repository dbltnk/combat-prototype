-- Footstep

Footstep = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
	
	onUpdate = function (self)
		--~ self.changeMonitor:checkAndSend()
	end,
	
	onNew = function (self)
		object_manager.create(self)
		--~ self.changeMonitor = MonitorChanges:new{ obj = self, keys = {"x", "y", 
			--~ "currentEnergy", "currentPain", "rotation", "alive" } }
		network.send(self:netCreate())
		the.app.view.layers.ground:add(self)
	end,
	
	onDie = function (self)
		object_manager.destroy(self)
		network.send({channel = "game", cmd = "delete", oid = self.oid, })
		the.app.view.layers.ground:remove(self)
	end,
	
	netCreate = function (self)
		return { 
			channel = "game", cmd = "create", class = "Footstep", oid = self.oid, 
			x = self.x, y = self.y, owner = self.owner, 
			rotation = self.rotation,
			image = self.image, width = self.width, height = self.height, 
			solid = false,
		}
	end,
}
