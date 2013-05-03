-- Footstep

Footstep = Tile:extend
{
	class = "Footstep",

	props = {"x", "y", "rotation", "image", "width", "height", },			
	
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
	
	fogAlpha = 1,
	fadeAlpha = 1,
	duration = config.footStepVisibility,

	owner = 0,
	
	dieAtTime = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		the.app.view.layers.ground:add(self)
		self.dieAtTime = network.time + self.duration
		drawDebugWrapper(self)
	end,
	
	onUpdateLocal = function (self)
		if network.time > self.dieAtTime then
			self:die()
		end
	end,

	onUpdateBoth = function (self, elapsed)
		self.fadeAlpha = utils.mapIntoRange (network.time, self.dieAtTime - self.duration, self.dieAtTime, 1, 0)		
		self.alpha = math.min(self.fadeAlpha, self.fogAlpha)
	end,
	
	onDieBoth = function (self)
		the.app.view.layers.ground:remove(self)
	end,
}
