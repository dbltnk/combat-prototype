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
	
	dieAtTime = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		self.dieAtTime = network.time + self.duration
		drawDebugWrapper(self)
	
		local selfself = self

		self.p = Particles:new{ 
			image = "/assets/graphics/particle.png",
			width = 100,
			height = 100,
			onNew = function (self)
				local ps = self.system
				ps:setColors(selfself.r, selfself.g, selfself.b, 128)
				ps:setEmissionRate(100)
				ps:setParticleLife(selfself.duration)
				ps:setSpeed(20,30)
				ps:setSizes(3,4)

				the.app.view.layers.particles:add(self)
				-- destroy after cast time
				the.app.view.timer:after(selfself.duration, function()
					self:die()
				end)
			end,
			
			onDie = function (self)
				the.app.view.layers.particles:remove(self)
			end,
			
			onUpdate = function (self, elapsed)
				local o = object_manager.get(selfself.follow_oid)
				if o then
					self.x, self.y = o.x + o.width / 2, o.y + o.height / 2
				end
			end,
		}
	 
	end,
	
	onUpdateLocal = function (self)
		if network.time > self.dieAtTime then
			self:die()
		end
	end,
}
