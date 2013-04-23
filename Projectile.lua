-- Projectile


Projectile = Tile:extend
{
	class = "Projectile",

	props = {"x", "y", "rotation", "image", "width", "height", "velocity", "creation_time"},			
	sync_high = {"x", "y", "velocity", "creation_time"},
			
	width = 32,
	height = 32,
	--~ image = '/assets/graphics/action_projectiles/bow_shot_projectile.png',
    -- target.x target.y start.x start.y	

	onCollide = function(self, other, horizOverlap, vertOverlap)
	--	self:particle(self.x, self.y)
		self:die()
	end,
	
	onUpdateLocal = function (self)
		local totalDistance = vector.lenFromTo(self.start.x, self.start.y, self.target.x, self.target.y)
		local distFromStart = vector.lenFromTo(self.start.x, self.start.y, self.x, self.y)
		
		if distFromStart >= totalDistance then
		--	self:particle(self.x, self.y)
			self:die()
		end
	end,
	
	onDieBoth = function (self)
		-- not possible to revive them later
		the.app.view.layers.projectiles:remove(self)
		-- will remove the projectile reference from the map
		the.projectiles[self] = nil	
	end,
	
	onNew = function (self)
		self:mixin(GameObject)
		
		the.app.view.layers.projectiles:add(self)
		-- stores an projectile reference, projectiles get stored in the key
		the.projectiles[self] = true
		drawDebugWrapper(self)
	end,
	
	--~ particle = function (self, xd, yd)
		--~ local castTime = 3 --self.cast_time
		--~ local p = Particles:new{ 
			--~ image = "/assets/graphics/action_particles/firebal_particle.png",
			--~ width = 100,
			--~ height = 100,
			--~ onNew = function (self)
				--~ self.x, self.y = xd, yd
				--~ the.app.view.layers.particles:add(self)
				--~ the.app.view.timer:after(castTime, function()
					--~ self:die()
				--~ end)
			--~ end,
			--~ onDie = function (self)
				--~ the.app.view.layers.particles:remove(self)
			--~ end,
		 --~ }
	--~ end,
}
