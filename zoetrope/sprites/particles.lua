-- Class: Particles
-- A Particles contains a löve particle system.
--
-- Extends:
--		<Sprite>

local profile = require 'profile'

Particles = Sprite:extend
{
	-- private property: keeps track of properties that need action
	-- to be taken when they are changed
	-- image must be a nonsense value, not nil,
	-- for the Particles to see that an image has been set if it
	-- was initially nil
	_set = { image = -1, },

	-- private property imageObj: actual Image instance used to draw
	-- this is normally set via the image property, but you may set it directly
	-- so long as you never change that image property afterwards.

	-- int maxParticleCount
	-- Image image
	
	new = function (self, obj)
		obj = obj or {}
		self:extend(obj)
		
		obj:updateSystem()
		
		obj.system:setEmissionRate(10)
		obj.system:setLifetime(1)
		obj.system:setParticleLife(7)
		obj.system:setDirection(0)
		obj.system:setSpread(2 * math.pi)
		obj.system:setSpeed(10, 20)
		obj.system:setSizes(2, 0.5)
		obj.system:setSizeVariation(0.3)
		--~ obj.system:setColors(190,190,190,255,
			--~ 200,200,200,255,
			--~ 222,222,222,100,
			--~ 255,255,255,0)

		obj.system:start()
		
		if obj.onNew then obj:onNew() end
		
		return obj
	end,

	updateSystem = function (self)
		if self.image then
			self._imageObj = Cached:image(self.image)
			self._imageObj:setWrap('repeat', 'repeat')
			self._set.image = self.image
			self.system = love.graphics.newParticleSystem( self._imageObj, self.maxParticleCount or 100 )
		end
	end,
	
	draw = function (self, x, y)
		if not self.visible or self.alpha <= 0 then return end

		x = math.floor(x or self.x)
		y = math.floor(y or self.y)
	
		if STRICT then
			assert(type(x) == 'number', 'visible fill does not have a numeric x property')
			assert(type(y) == 'number', 'visible fill does not have a numeric y property')
		end

		if not self.image then return end
		
		profile.start("Particles.draw")
		
		-- set color if needed

		local colored = self.alpha ~= 1 or self.tint[1] ~= 1 or self.tint[2] ~= 1 or self.tint[3] ~= 1

		if colored then
			love.graphics.setColor(self.tint[1] * 255, self.tint[2] * 255, self.tint[3] * 255, self.alpha * 255)
		end

		-- if the source image or offset has changed, we need to recreate the particle system
		if self.image and (self.image ~= self._set.image) then
			self:updateSystem()
		end
		
		-- draw the particle system
		local scaleX = self.scale * self.distort.x
		local scaleY = self.scale * self.distort.y

		if self.flipX then scaleX = scaleX * -1 end
		if self.flipY then scaleY = scaleY * -1 end

		if self.system then
			self.system:update(love.timer.getDelta())
			love.graphics.draw(self.system, x, y, self.rotation,
								scaleX, scaleY)
		end
		
		-- reset color
		
		if colored then
			love.graphics.setColor(255, 255, 255, 255)
		end
			
		Sprite.draw(self, x, y)
		
		profile.stop()
	end,

	__tostring = function (self)
		local result = 'Particles (x: ' .. self.x .. ', y: ' .. self.y ..
					   ', w: ' .. self.width .. ', h: ' .. self.height .. ', '

		if self.active then
			result = result .. 'active, '
		else
			result = result .. 'inactive, '
		end

		if self.visible then
			result = result .. 'visible, '
		else
			result = result .. 'invisible, '
		end

		if self.solid then
			result = result .. 'solid'
		else
			result = result .. 'not solid'
		end

		return result .. ')'
	end
}
