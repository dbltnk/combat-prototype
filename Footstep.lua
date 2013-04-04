-- Footstep

Footstep = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
	duration = config.footStepVisibility, -- TODO: integrate with fog of war alpha
	
	onNew = function (self, elapsed)
		for i = 1, self.duration do
			the.app.view.timer:after(i, function()
				self.alpha = self.alpha - i * (1 / self.duration)
			end)
		end
	end,
	
	onUpdate = function (self, elapsed)
		if self.alpha <= 0.1 then self:die() end
	end,
}
