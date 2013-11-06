-- Effect

Effect = Sprite:extend
{
	class = "Effect",

	props = {"x", "y", "rotation", "image", "width", "height", "r", "g", "b", "duration", "follow_oid" },			
	
	width = 1,
	height = 1,
	image = nil,
	
	r = nil,
	g = nil,
	b = nil,
	duration = nil,
	p = nil,
	follow_oid = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		drawDebugWrapper(self)
	
		local objSelf = self

		self.p = Particles:new{ 
			image = "/assets/graphics/particle.png",
			width = 100,
			height = 100,
			
			onNew = function (self)
				self:mixin(FogOfWarObject)
				local ps = self.system
				ps:setColors(objSelf.r, objSelf.g, objSelf.b, 128)
				ps:setEmissionRate(100)
				ps:setParticleLife(objSelf.duration)
				ps:setSpeed(20,30)
				ps:setSizes(3,4)

				the.app.view.layers.particles:add(self)
				-- destroy after cast time
				the.app.view.timer:after(objSelf.duration, function()
					self:die()
				end)
			end,
			
			onDie = function (self)
				the.app.view.layers.particles:remove(self)
				objSelf:die()
			end,
			
			onUpdate = function (self, elapsed)
				profile.start("effect.onupdate")
			
				local o = object_manager.get(objSelf.follow_oid)
				if o then
					self.x, self.y = o.x + o.width / 2, o.y + o.height / 2
				end
				
				self:updateFogAlpha()
				
				profile.stop()
			end,
		}
	end,
	
	onDieBoth = function (self)
	end,
}
