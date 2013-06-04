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
	
	circleFill = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		drawDebugWrapper(self)

		local d = Fill:new{ alphaWithoutFog = 1, shape="circle", x = self.x-self.r, y = self.y-self.r, width = self.r*2, height = self.r*2, border = {0,0,0,0}, fill = self.color}
		d:mixin(FogOfWarObject)
		d.onUpdate = function (self) self:updateFogAlpha() end
		the.app.view.layers.particles:add(d)
		the.app.view.timer:after(self.t, function() 
			the.app.view.layers.particles:remove(d)
			self:die()
		end)
		the.app.view.timer:every(0.05, function() 
			d.alphaWithoutFog = d.alphaWithoutFog - 0.05
		end)
		self.circleFill = d
	end,	
}
