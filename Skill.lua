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
	iconColor = nil,
	
	nr = 0,	
	timeout = 0,
	combatTimer = 10,
	lastUsed = -100000,
	
	-- here starts the effect/application
	source = {
		x = 0,
		y = 0,
		viewx = 0,
		viewy = 0,
		player = nil,
	},
	
	isCasting = function (self)
		return love.timer.getTime() - self.lastUsed < self.cast_time
	end,

	isPossibleToUse = function (self)
		return self.character.freezeCastingCounter <= 0 and 
			love.timer.getTime() - self.lastUsed >= self.timeout and 
			self.character.currentEnergy >= self.energyCosts 
	end,
	
	timeTillCastFinished = function (self)
		return math.max(0, self.lastUsed + self.cast_time - love.timer.getTime())
	end,
	
	timeTillPossibleToUse = function (self)
		return math.max(0, self.lastUsed + self.timeout - love.timer.getTime())
	end,
	
	use = function (self, x, y, viewx, viewy, player)
		if self:freezeMovementDuringCasting() then player:freezeMovement() end
		--print("SKILL", self.nr, "START USING")
		
		player.interrupted = false
		self.source.x = x
		self.source.y = y
		-- read input can overwrite view later
		self.source.viewx = viewx
		self.source.viewy = viewy
		self.source.player = player
		
		self.lastUsed = love.timer.getTime()
		
		-- start particle
		--~ local p = the.app.view.factory:create(Particles, { 
			--~ duration = self.cast_time, 
			--~ attached_to_object = player,
			--~ particle_color = self.definition.cast_particle_color or {255,255,255}
		--~ })
		
		local castTime = self.cast_time
		local colour = self.definition.cast_particle_color or {128,128,128}
		for k,v in pairs(colour) do
			if k == 1 then 
				r = v
			elseif k == 2 then 
				g = v
			elseif k == 3 then 
				b = v
			end
		end
		-- new particle system example
		Effect:new{r=r, g=g, b=b, duration=castTime, follow_oid=player.oid}
		
		if self.onUse then 
			-- call use after casttime timeout
			the.app.view.timer:after(self.cast_time, function() 
				-- finished casting	
				the.player.selectedSkill = 1 
				if self:freezeMovementDuringCasting() then player:unfreezeMovement() end
				if player.interrupted == false then			
					--print("SKILL", self.nr, "REALLY USE")
					playSound(self.definition.sound or '/assets/audio/missing.wav', 1, 'short')
					-- update view pos
					if player.readInput then
						local ipt = player:readInput()
						self.source.viewx = ipt.viewx
						self.source.viewy = ipt.viewy
					end
					if self.character.freezeCastingCounter <= 0 then self:onUse() end
				end
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
		self.iconColor = self.definition.cast_particle_color or {255,255,255}   
	end,
	
	freezeMovementDuringCasting = function (self)
		return self.definition.on_the_run == false
	end,
	
	onUse = function (self)
		local startTarget = { oid = self.character.oid, 
			viewx = self.source.viewx, viewy = self.source.viewy }
		action_handling.start(self.definition.application, startTarget, self.character.oid)
	--	print("out of combat:", self:isOutOfCombat())
		end,

	isOutOfCombat = function (self)
		return love.timer.getTime() - self.lastUsed >= self.combatTimer
	end,
}
