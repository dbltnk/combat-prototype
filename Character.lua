-- Character

characterMap = {}

Character = Animation:extend
{
	maxPain = config.maxPain, 
	currentPain = 0,
	maxEnergy = config.maxEnergy, 
	currentEnergy = config.maxEnergy, 
	changeMonitor = nil,

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
		changeMonitor = MonitorChanges:new{ obj = self, keys = {"x", "y", 
			"currentEnergy", "currentPain", "rotation",  } }
		object_manager.create(self)
		the.view.layers.characters:add(self)
		
		for k,v in pairs(self.skills) do
			self.skills[k] = Skill:new { nr = k, id = v, character = self }
		end
		drawDebugWrapper(self)
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
		}
	end,
	
	onDie = function (self)
		the.view.layers.characters:remove(self)
	
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
	
	gainPain = function (self, str)
		print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
	end,
	
	updatePain = function (self)
		if self.currentPain < 0 then self.currentPain = 0 end
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			self:die()
		end	
	end,
	
	receive = function (self, message_name, ...)
		print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str = ...
			print("HEAL", str)
			self:gainPain(-str)
		elseif message_name == "damage" then
			local str = ...
			print("DAMANGE", str)
			self:gainPain(str)
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
		if self:isCasting() == false then self.currentEnergy = self.currentEnergy + config.energyreg * elapsed end
		if self.currentEnergy < 0 then self.currentEnergy = 0 end
		if self.currentEnergy > self.maxEnergy then self.currentEnergy = self.maxEnergy end
		
		-- health regeneration
		if self.currentPain < 0 then self.currentPain = 0 end
		local regenerating = true		
		for k,v in pairs(self.skills) do
			if (v:isOutOfCombat() == false) then
				regenerating = false
			end
		end
		if regenerating == true then self.currentPain = self.currentPain - config.healthreg * elapsed end
		if self.currentPain < 0 then self.currentPain = 0 end
		if self.currentPain > self.maxPain then self.currentPain = self.maxPain end
		
		-- upate pain bar
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y
	end,

	readInput = function (self, activeSkillNr)
		-- 0 slowest -> 1 fastest
		local speed = 0
		-- [-1,1], [-1,1]
		local movex, movey = 0,0
		-- has an arbitrary length
		local viewx, viewy = 0,0
		
		local shootSkillNr = activeSkillNr
		local doShoot = false	
		
		return { speed = speed, 
			movex = movex, movey = movey, 
			viewx = viewx, viewy = viewy, 
			doShoot = doShoot, shootSkillNr = shootSkillNr, }
	end,
	
	-- ips : result from readInput
	applyMovement = function (self, elapsed, ipt)
		self.velocity.x = 0
		self.velocity.y = 0

		local isMoving = self.freezeMovementCounter == 0 and vector.len(ipt.movex, ipt.movey) > 0
		
		if isMoving and self:footstepsPossible() then 
			local rot = vector.toVisualRotation(ipt.movex, ipt.movey)
			local footstep = Footstep:new{ 
				x = self.x+17, y = self.y+15, 
				rotation = rot,
			}
			the.app.view.layers.ground:add(footstep)
			the.footsteps[footstep] = true
			self:makeFootstep()
		end
		
		-- move into direction?
		if self.freezeMovementCounter == 0 and vector.len(ipt.movex, ipt.movey) > 0 then
			-- replace second 0 by a 1 to toggle runspeed to analog
			local s = config.walkspeed -- utils.mapIntoRange (speed, 0, 0, config.walkspeed, config.runspeed)
			
			-- patched speed?
			if self.speedOverride and self.speedOverride > 0 then s = self.speedOverride end
			
			self.velocity.x, self.velocity.y = vector.normalizeToLen(ipt.movex, ipt.movey, s)
			
			local animspeed = utils.mapIntoRange (ipt.speed, 0, 1, config.animspeed, config.animspeed * config.runspeed / config.walkspeed)
			
			self:play('walk')
		else
			self:freeze(5)
		end
		
		if self:isCasting() == false and ipt.doShoot and self.skills[ipt.shootSkillNr] and 
			self.skills[ipt.shootSkillNr]:isPossibleToUse()
		then
			local cx,cy = self.x + self.width / 2, self.y + self.height / 2
			self.skills[ipt.shootSkillNr]:use(cx, cy, ipt.viewx, ipt.viewy, self)
		end
		
		-- combat music?
		local isInCombat = false
		for k,v in pairs(self.skills) do
			isInCombat = isInCombat or (v:isOutOfCombat() == false)
		end
		
		audio.isInCombat = isInCombat
	end,
	
	onUpdate = function (self, elapsed)
		self:onUpdateRegeneration(elapsed)
		
		local ipt = self:readInput(self.activeSkillNr)
		
		self:applyMovement(elapsed, ipt)
		
		if changeMonitor:changed() then
			network.send ({ channel = "game", cmd = "sync", oid = self.oid, x = self.x, y = self.y, owner = self.owner, 
				currentPain = self.currentPain, currentEnergy = self.currentEnergy, rotation = self.rotation })
		end
	end,
}
