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
		
		for i = 1, self.duration do
			the.app.view.timer:after(i, function()
				self.fadeAlpha = self.fadeAlpha - i * (1 / self.duration)
			end)
		end
	end,
	
	onUpdateLocal = function (self)
		if network.time > self.dieAtTime then
			self:die()
		end
	end,
	
	onDieBoth = function (self)
		the.app.view.layers.ground:remove(self)
	end,
	
	onUpdateBoth = function (self, elapsed)
		if self.fadeAlpha <= self.fogAlpha then self.alpha = self.fadeAlpha else self.alpha = self.fogAlpha end
	end,
}
