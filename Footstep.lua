-- Footstep

Footstep = Tile:extend
{
	class = "Footstep",

	props = {"x", "y", "rotation", "image", "width", "height", },			
	
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
	lifetime = 3,
	
	dieAtTime = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		the.app.view.layers.ground:add(self)
		self.dieAtTime = network.time + self.lifetime
	end,
	
	onUpdateLocal = function (self)
		if network.time > self.dieAtTime then
			self:die()
		end
	end,
	
	onDie = function (self)
		the.app.view.layers.ground:remove(self)
	end,
}
