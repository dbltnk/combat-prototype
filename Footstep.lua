-- Footstep

Footstep = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
	fogAlpha = 1,
	fadeAlpha = 1,
	duration = config.footStepVisibility,
	
	onNew = function (self, elapsed)
		for i = 1, self.duration do
			the.app.view.timer:after(i, function()
				self.fadeAlpha = self.fadeAlpha - i * (1 / self.duration)
			end)
		end
	end,
	
	onUpdate = function (self, elapsed)
		if self.fadeAlpha <= self.fogAlpha then self.alpha = self.fadeAlpha else self.alpha = self.fogAlpha end
		if self.fadeAlpha <= 0.1 then self:die() end
	end,
}
