-- Footstep

Footstep = Tile:extend
{
	class = "Footstep",

	props = {"x", "y", "rotation", "image", "width", "height", },			
	
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
	
	onNew = function (self)
		self:mixin(GameObject)
		the.app.view.layers.ground:add(self)
	end,
	
	onDie = function (self)
		the.app.view.layers.ground:remove(self)
	end,
}
