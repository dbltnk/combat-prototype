-- Character

Character = Animation:extend
{
	maxPain = config.maxPain, 
	currentPain = 0,
	maxEnergy = config.maxEnergy, 
	currentEnergy = config.maxEnergy, 

	-- list of Skill
	skills = {
		"bow_shot",
		"xbow_piercing_shot",	
		--"scythe_attack",
		--"scythe_pirouette",			
		--"shield_bash",		
		"sprint",		
		"bandage",
		"fireball",
		"life_leech",
	},
	

	activeSkillNr = 1,
	
	width = 64,
	height = 64,
	image = '/assets/graphics/player.png', -- source: http://www.synapsegaming.com/forums/t/1711.aspx

	-- UiBar
	painBar = nil,
	
	sequences = 
	{
		walk = { frames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, fps = config.animspeed },
	},
	
	-- if > 0 the player is not allowed to move
	freezeMovementCounter = 0,
	
	-- if > 0 then player use this speed other than the normal one
	speedOverride = 0,
	
	lastFootstep = 0,
	
	footstepsPossible = function (self)
		return love.timer.getTime() - self.lastFootstep >= .25
	end,
	
	makeFootstep = function (self)
		self.lastFootstep = love.timer.getTime()
	end,
	
	onNew = function (self)
		for k,v in pairs(self.skills) do
			self.skills[k] = Skill:new { nr = k, id = v }
		end
		drawDebugWrapper(self)
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
		}
	end,
	
	onDie = function (self)
		self.painBar:die()
	end,
	
	freezeMovement = function (self)
		print("FREEEZ")
		self.freezeMovementCounter = self.freezeMovementCounter + 1
	end,
	
	unfreezeMovement = function (self)
		print("UNFREEEZ")
		self.freezeMovementCounter = self.freezeMovementCounter - 1
	end,
	
	receive = function (self, message_name, ...)
		print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str = ...
			print("HEAL", str)
			self.currentPain = self.currentPain - str
		elseif message_name == "damage" then
			local str = ...
			print("DAMANGE", str)
		elseif message_name == "stun" then
			local duration = ...
			print("STUN", duration)
			self:freezeMovement()
			the.app.view.timer:after(duration, function()
				self:unfreezeMovement()
			end)
		elseif message_name == "runspeed" then
			local str, duration = ...
			print("SPEED", str, duration)
			self.speedOverride = str
			the.app.view.timer:after(duration, function()
				self.speedOverride = 0
			end)
		end
	end,
	
	isCasting = function (self)
		local c = false
		for k,v in pairs(self.skills) do
			c = c or v:isCasting()
		end
		return c
	end,
		
	onUpdateRegeneration = function (self, elapsed)
		-- energy regeneration
		if self.currentEnergy < 0 then self.currentEnergy = 0 end
		if self:isCasting() == false then self.currentEnergy = self.currentEnergy + config.energyreg end
		if self.currentEnergy > self.maxEnergy then self.currentEnergy = self.maxEnergy end
		
		-- health regeneration
		if self.currentPain < 0 then self.currentPain = 0 end
		local regenerating = true		
		for k,v in pairs(self.skills) do
			if (v:isOutOfCombat() == false) then
				regenerating = false
			end
		end
		if regenerating == true then self.currentPain = self.currentPain - config.healthreg end
		if self.currentPain > self.maxPain then self.currentPain = self.maxPain end
		
		-- upate pain bar
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y
	end,
}
