-- Character

characterMap = {}

Character = Animation:extend
{
	maxPain = config.maxPain, 
	currentPain = 0,
	maxEnergy = config.maxEnergy, 
	currentEnergy = config.maxEnergy, 
	xp = 0,
	xpCap = config.xpCap,
	level = 0,
	levelCap = config.levelCap,
	tempMaxxed = false,
	incapacitated = false,
	wFactor = 0,	
	hidden = false,

	-- list of Skill
	skills = {
		"bow_shot",
		"xbow_piercing_shot",	
		--"scythe_attack",
		--"scythe_pirouette",			
		--"shield_bash",		
		"sprint",
		"camouflage",		
		--"bandage",
		"fireball",
		--"life_leech",
		"gank",
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
	-- if > 0 the player is not allowed to cast actions
	freezeCastingCounter = 0,
	
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
		object_manager.create(self)
		the.view.layers.characters:add(self)
		self.wFactor = self.width / self.maxPain		
		
		for k,v in pairs(self.skills) do
			self.skills[k] = Skill:new { nr = k, id = v, character = self }
		end
		drawDebugWrapper(self)
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, inc = false, wFactor = self.wFactor
		}
	end,
	
	onDie = function (self)
		the.view.layers.characters:remove(self)
		self.painBar:die()
	end,
	
	freezeCasting = function (self)
		--print("FREEEZ CAST")
		self.freezeCastingCounter = self.freezeCastingCounter + 1
	end,
	
	unfreezeCasting = function (self)
		--print("UNFREEEZ CAST")
		self.freezeCastingCounter = self.freezeCastingCounter - 1
	end,
	
	freezeMovement = function (self)
		--print("FREEEZ MOVE")
		self.freezeMovementCounter = self.freezeMovementCounter + 1
	end,
	
	unfreezeMovement = function (self)
		--print("UNFREEEZ MOVE")
		self.freezeMovementCounter = self.freezeMovementCounter - 1
	end,
	
	gainPain = function (self, str)
		--print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
		if str >= 0 then
			self.scrollingText  = ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {1,0,0}}
			GameView.layers.ui:add(self.scrollingText)	
		else
			self.scrollingText  = ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {0,0,1}}
			GameView.layers.ui:add(self.scrollingText)	
		end
	end,
	
	setIncapacitation = function (self, incapState)
		if incapState == self.incapacitated then return end
		
		if incapState then
			self.incapacitated = true
			self:freezeCasting()
			self:freezeMovement()
		else
			self.incapacitated = false
			self:unfreezeCasting()
			self:unfreezeMovement()
		end
	end,
	
	updatePain = function (self)
	--print("Player ", self.oid, " is incapacitated:", self.incapacitated)
		if self.currentPain >= self.maxPain then 
			self:setIncapacitation(true) 
		end
		
		self.currentPain = utils.clamp(self.currentPain, 0, self.maxPain)
	end,
		
	respawn = function (self)
		self.x, self.y = the.respawnpoint.x, the.respawnpoint.y
		self.currentPain = 0
		self:setIncapacitation(false)
	end,	
	
	gainXP = function (self, str)
		--print(self.oid, "gain xp", str)
		if self.tempMaxxed == false then
			self.xp = self.xp + str
		end
		--self:updatePain()
		--print(self.xp)
		if self.tempMaxxed == false and self.xp >= 1000 then 
			self.level = self.level +1
			self.xp = 1000
			self.tempMaxxed = true
		--	print("leveled", self.level, self.oid)
			-- TODO: add particle-fx here
		end		
		self:updateLevel()
		if math.floor(str) > 0 then self.scrollingText  = ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = math.floor(str), tint = {1,1,0}}
		GameView.layers.ui:add(self.scrollingText) end	
	end,	
	
	resetXP = function (self)
	--	print("xp: ", self.xp)
		if self.xp == 1000 then
			self.xp = 0
			self.tempMaxxed = false
			--print("reset to ", self.tempMaxxed)
		end
	end,
	
	updateLevel = function (self, elapsed)
	--	print("update reveived! character level = ",  self.level)
		for i = 0, config.levelCap - 1 do
			local width = (love.graphics.getWidth() / 2 - the.controlUI.width / 2) / 10
			if self.level > i then  
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i, fill = {255,255,0,255}} 
				the.hud:add(the.levelUI)			
			end							
		end
	end,
	
	receive = function (self, message_name, ...)
	--	print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str, source_oid = ...
		--	print("HEAL", str)
			self:gainPain(-str)
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", str/100) end
		elseif message_name == "damage" then
			local str, source_oid = ...
		--	print("DAMANGE", str)
			self:gainPain(str)
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", str/100) end
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if self.incapacitated == false then 
						self:gainPain(str)
						if source_oid ~= self.oid then object_manager.send(source_oid, "xp", str/100) end
					end
				end)
			end			
		elseif message_name == "stun" then
			local duration, source_oid = ...
		--	print("STUN", duration)
			self:freezeMovement()
			self:freezeCasting()
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", duration) end
			the.app.view.timer:after(duration, function()
				self:unfreezeMovement()
				self:unfreezeCasting()
			end)
		elseif message_name == "runspeed" then
			local str, duration, source_oid = ...
			--print("SPEED", str, duration)
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", duration) end
			self.speedOverride = str
			the.app.view.timer:after(duration, function()
				self.speedOverride = 0
			end)
		elseif message_name == "xp" then
			local str = ...
			--print("XP", str)
			self:gainXP(str)
		elseif message_name == "gank" then
			if self.incapacitated == true then 
				self:respawn() 
			end
		elseif message_name == "invis" then
			local duration, speedPenalty = ...
			self.hidden = true
			self.speedOverride = config.walkspeed * speedPenalty
			the.view.timer:after(duration, function() self.hidden = false self.speedOverride = 0 end)
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
		if self.incapacitated then 
			self.painBar.inc = true 
		else
			self.painBar.inc = false
		end 
		
		if self.currentPain <= self.maxPain * config.getUpPain then self:setIncapacitation(false) end
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
		elseif self.incapacitated then
			self:freeze(8)
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
		
		self.rotation = vector.toVisualRotation(vector.fromTo (self.x ,self.y, ipt.viewx, ipt.viewy))
		
		audio.isInCombat = isInCombat
	end,
	
	onUpdate = function (self, elapsed)
		self:onUpdateRegeneration(elapsed)
		
		local ipt = self:readInput(self.activeSkillNr)
		
		self:applyMovement(elapsed, ipt)
		
		local done = {}
		for i = 1, 10 do 
			if (math.floor(love.timer.getTime()) == config.xpCapTimer * i) and done[i] == nil then
				self:resetXP()
				done[i] = true
			end
		end
		
		if self.incapacitated then
			self.tint = {0.5,0.5,0.5}
		else 
			self.tint = {1,1,1}
		end
		
		if self.hidden then
			self.visible = false
			self.painBar.visible = false
			self.painBar.bar.visible = false
			self.painBar.background.visible = false						
		else
			self.visible = true
			self.painBar.visible = false
			self.painBar.bar.visible = true
			self.painBar.background.visible = true						
		end
	end,
}
