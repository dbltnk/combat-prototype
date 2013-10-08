-- Projectile


Projectile = Tile:extend
{
	class = "Projectile",

	props = {"x", "y", "rotation", "image", "width", "height", "velocity", "creation_time", "origin_oid", 
		"start", "target"},			
	--~ sync_high = {"x", "y", "velocity", "creation_time"},
			
	width = 12,
	height = 12,
	--~ image = '/assets/graphics/action_projectiles/bow_shot_projectile.png',
    -- target.x target.y start.x start.y	

	onCollideOnlyFirst = function(self, other, horizOverlap, vertOverlap)
		if other.class == "TargetDummy" or other.class == "Character" or other.class == "Barrier" or other.class == "Ressource" then
			local name = "";
			name = string.sub(self.image, 37, -5)
			track("skill_hit", name, self.origin_oid, other.class)			
			--~ print("skill_hit", name, self.origin_oid, other.class)
		end
	end,
	
	onCollide = function(self, other, horizOverlap, vertOverlap)
	--	self:particle(self.x, self.y)
		if self:isLocal() then 
			self:die() 
		end
	end,
	
	onUpdateLocal = function (self)
		local totalDistance = vector.lenFromTo(self.start.x, self.start.y, self.target.x, self.target.y)
		local cx,cy = tools.object_center(self)
		local distFromStart = vector.lenFromTo(self.start.x, self.start.y, cx,cy)
		
		if distFromStart >= totalDistance then
		--	self:particle(self.x, self.y)
			self.x = self.target.x - self.width/2
			self.y = self.target.y - self.height/2
			self:die()
			if not self.onCollideOnlyFirstAlreadyCalled then
				local name = "";
				name = string.sub(self.image, 37, -5)
				track("skill_miss", name, self.origin_oid)
				--~ print("skill_miss", name, self.origin_oid)
			end
		end
		
		if the.keys:pressed (localconfig.targetSelf) then self.target.x, self.target.y = self.start.x, self.start.y end
	end,
	
	onDieBoth = function (self)
		-- not possible to revive them later
		the.app.view.layers.projectiles:remove(self)
		-- will remove the projectile reference from the map
		the.projectiles[self] = nil	
	end,
	
	onNew = function (self)
		self:mixin(GameObject)
		self:mixin(FogOfWarObject)
		
		the.app.view.layers.projectiles:add(self)
		-- stores an projectile reference, projectiles get stored in the key
		the.projectiles[self] = true
		drawDebugWrapper(self)
		
		-- creation time? apply movement
		if self.creation_time and self.velocity then
			local dt = network.time - self.creation_time
			self.x = self.x + self.velocity.x * dt
			self.y = self.y + self.velocity.y * dt
		end
		
		--~ utils.vardump(self.start)
		--~ utils.vardump(self.target)
				
		-- this only displays the sprite
		local goSelf = self
		self.projectileSprite = Tile:new{
			x = goSelf.x,
			y = goSelf.y,
			width = 32,
			height = 32,
			image = goSelf.image,
			rotation = goSelf.rotation,
			solid = false,
			
			onNew = function(self)
				the.app.view.layers.projectiles:add(self)
			end,
			
			onDie = function(self)
				the.app.view.layers.projectiles:remove(self)
			end,
			
			onUpdate = function(self)
				self.x = goSelf.x + goSelf.width / 2 - self.width / 2
				self.y = goSelf.y + goSelf.height / 2  -self.height / 2
				self.visible = goSelf.visible
				self.alpha = goSelf.alpha
			end,
		}
	end,
	
	onUpdateBoth = function (self)
		self:updateFogAlpha()
	end,
}
