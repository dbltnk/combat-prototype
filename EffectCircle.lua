-- EffectCircle

EffectCircle = Sprite:extend
{
	class = "EffectCircle",

	props = {"x", "y", "r", "t", "color"},			
	
	--~ width = 1,
	--~ height = 1,
	--~ image = nil,
	
	color = {128,128,128,128},
	t = config.AEShowTime,
	
	dieAtTime = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		drawDebugWrapper(self)

		local d = Fill:new{ shape="circle", x = self.x-self.r, y = self.y-self.r, width = self.r*2, height = self.r*2, border = {0,0,0,0}, fill = self.color}
		the.view.layers.particles:add(d)
		the.view.timer:after(self.t, function() 
			the.view.layers.particles:remove(d)
			self:die()
		end)
		the.view.timer:every(0.05, function() 
			d.alpha = d.alpha - 0.05
		end)
	end,	
}
