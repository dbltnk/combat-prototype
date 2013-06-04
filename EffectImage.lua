-- EffectImage

EffectImage = Sprite:extend
{
	class = "EffectImage",

	props = {"x", "y", "r", "t", "color","image", "rotation"},			
	
	--~ width = 1,
	--~ height = 1,
	--~ image = nil,
	
	color = {128,128,128,128},
	t = config.AEShowTime,
	
	dieAtTime = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		drawDebugWrapper(self)

		local d = Tile:new{ x = self.x-self.r, y = self.y-self.r, width = self.r*2, height = self.r*2, tint = self.color, image = self.image, rotation = self.rotation, }
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
	end,	
}
