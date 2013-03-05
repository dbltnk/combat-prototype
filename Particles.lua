-- Particles


Particles = Emitter:extend
{
    width = 0,
    height = 0,
	particleSpeed = 30,
    
    -- gameobject
    attached_to_object = nil,
    duration = 0,
    particle_color = {255, 255, 255},
 
    onNew = function (self)
		the.app.view.layers.particles:add(self)
		
		local emitter = self
		
        self.emitting = true
		self.period = 0.1
		self.emitCount = 10
		
		if self.attached_to_object then
			self.x, self.y = tools.object_center(self.attached_to_object)
			self.width, self.height = tools.object_size(self.attached_to_object)
		end
		
		local outerSelf = self
        
		self:loadParticles(Fill:extend
        {
            width = 5,
            height = 5,
            fill = {255, 255, 255},
            onEmit = function (self)
                self.fill = {255, 255, 255}
                self.alpha = 1
                the.view.tween:start(self, 'fill', emitter.particle_color, math.random())
                :andThen(bind(the.view.tween, 'start', self, 'alpha', 0, math.random() / 2))
                local cx, cy = tools.object_center(outerSelf.attached_to_object)
                if cx > self.x then self.velocity.x = outerSelf.particleSpeed else self.velocity.x = - outerSelf.particleSpeed end
                if cy > self.y then self.velocity.y = outerSelf.particleSpeed else self.velocity.y = - outerSelf.particleSpeed end
            end
        },
        25)
        
        self:launch()
    end,
    
    onUpdate = function (self, elapsed)
		-- stay attached to object
		if self.attached_to_object then
			local x,y = tools.object_center(self.attached_to_object)
			x = x - self.width / 2
			y = y - self.height / 2
			self.x, self.y = x,y
		end
    end,
 
    onReset = function (self)
        self:launch()
    end,
 
    launch = function (self)
        the.view.timer:after(self.duration, bind(the.view.factory, 'recycle', self))
    end
}
