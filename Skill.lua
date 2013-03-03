-- Skill

Skill = Class:extend
{
	-- required
	id = nil,
	-- Character
	character = nil,
	
	-- ---------------
	-- see action_definitions.lua
	definition = nil,
	
	nr = 0,	
	timeout = 0,
	combatTimer = 10,
	lastUsed = -100000,
	
	-- here starts the effect/application
	source = {
		x = 0,
		y = 0,
		rotation = 0,
		player = nil,
	},
	
	isCasting = function (self)
		return love.timer.getTime() - self.lastUsed < self.cast_time
	end,

	isPossibleToUse = function (self)
		return love.timer.getTime() - self.lastUsed >= self.timeout and self.character.currentEnergy >= self.energyCosts 
	end,
	
	timeTillCastFinished = function (self)
		return math.max(0, self.lastUsed + self.cast_time - love.timer.getTime())
	end,
	
	timeTillPossibleToUse = function (self)
		return math.max(0, self.lastUsed + self.timeout - love.timer.getTime())
	end,
	
	use = function (self, x, y, rotation, player)
		if self:freezeMovementDuringCasting() then player:freezeMovement() end
		print("SKILL", self.nr, "START USING")
		
		self.source.x = x
		self.source.y = y
		self.source.rotation = rotation
		self.source.player = player
		
		self.lastUsed = love.timer.getTime()
		
		-- start particle
		local p = the.view.factory:create(Particles, { 
			duration = self.cast_time, 
			attached_to_object = player,
			particle_color = self.definition.cast_particle_color or {255,255,255}
		})
		
		if self.onUse then 
			-- call use after casttime timeout
			the.app.view.timer:after(self.cast_time, function() 
				-- finished casting				
				if self:freezeMovementDuringCasting() then player:unfreezeMovement() end
				print("SKILL", self.nr, "REALLY USE")
				self:onUse()
				self.character.currentEnergy = self.character.currentEnergy - self.energyCosts
			end)
		end
	end,
	
	onNew = function (self) 
		self.definition = action_definitions[self.id]
		
		if not self.definition then print("ERROR there is no skill with id", self.id) return end
		
		self.timeout = self.definition.timeout
		self.cast_time = self.definition.cast_time
		self.lastUsed = -10000000
		self.energyCosts = self.definition.energy   
	end,
	
	freezeMovementDuringCasting = function (self)
		return self.definition.on_the_run == false
	end,
	
	onUse = function (self)
		local startTarget = { oid = self.character.oid }
		action_handling.start(self.definition.application, startTarget)
		print("out of combat:", self:isOutOfCombat())
		end,

	isOutOfCombat = function (self)
		return love.timer.getTime() - self.lastUsed >= self.combatTimer
	end,
}
