-- Particles


Particles = Emitter:extend
{
    width = 0,
    height = 0,
    -- gameobject
    attached_to_object = nil,
 
    onNew = function (self)
        self:loadParticles(Fill:extend
        {
            width = 3,
            height = 3,
            fill = {255, 255, 255},
            onEmit = function (self)
                self.fill = {255, 255, 255}
                self.alpha = 1
                the.view.tween:start(self, 'fill', {0, 0, 255}, math.random())
                :andThen(bind(the.view.tween, 'start', self, 'alpha', 0, math.random() / 2))
            end
        },
        500)
        -- TODO use attached_to_object
		self.emitting = true
		self.period = 0
		self.emitCount = 10
		self.min = 0
		self.max = 500
		
		
        self.width = the.player.width / 2
        self.height = the.player.height / 2
        self:launch()
    end,
 
    onReset = function (self)
        self:launch()
    end,
 
    launch = function (self)
        --~ self:emit()
        -- 1.5 seconds is the maximum lifetime of our particles
        the.view.timer:after(10, bind(the.view.factory, 'recycle', self))
    end
}
