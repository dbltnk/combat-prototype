-- Character

characterMap = {}

Character = Animation:extend
{
	class = "Character",

	props = {"x", "y", "rotation", "image", "width", "height", "currentPain", "level", "anim_name", 
		"anim_speed", "velocity", "alive", "incapacitated", "hidden", "name", "weapon", "armor"},
		
	sync_high = {"x", "y", "rotation", "currentPain", "rotation", "anim_name", "anim_speed",
		"velocity", "alive", "incapacitated", "hidden"},
	sync_low = {"image", "width", "height", "rotation", "level", "name", "weapon", "armor"},			
	
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
	isInCombat = false,	
	name = nil,
	reminder = nil,
	targetable = true,

	--~ "bow" or "scythe" or "staff"
	weapon = "bow",
	--~ "robe" or "hide_armor" or "splint_mail"
	armor = "robe",

	-- for anim sync
	anim_name = nil,
	anim_speed = nil,
			
	-- list of Skill
	skills = localconfig.skills or {
		"bow_shot",
		"bow_shot",
		"bow_shot",
		"bow_shot",
		"bow_shot",
		"bow_shot",
	},
	

	activeSkillNr = 1,
	
	-- 32x48, 4 per row, 4 rows
	
	width = 26,
	height = 26,
	--~ image = '/assets/graphics/player_characters/robe_bow.png',
	image = nil,--'/assets/graphics/player_collision.png',

	charSprite = nil,
	hiddenSprite = nil,

	-- UiBar
	painBar = nil,
	nameLevel = nil,
		
	-- if > 0 the player is not allowed to move
	freezeMovementCounter = 0,
	-- if > 0 the player is not allowed to cast actions
	freezeCastingCounter = 0,
	
	-- if > 0 then player use this speed other than the normal one
	speedOverride = 0,
	
	lastFootstep = 0,
	
	footstepsPossible = function (self)
		if self.hidden == false then return love.timer.getTime() - self.lastFootstep >= .25 end
	end,
	
	makeFootstep = function (self)
		self.lastFootstep = love.timer.getTime()
	end,
	
	onNew = function (self)
		self:mixin(GameObject)

		the.app.view.layers.characters:add(self)
		self.wFactor = self.width / self.maxPain		
		self.maxPain = config.maxPain * (1 + config.strIncreaseFactor * self.level)
		-- fill up skill bar with missing skills
		for i = 1,6 do 
			if not self.skills[i] then self.skills[i] = "bow_shot" end
		end
		for k,v in pairs(self.skills) do
			self.skills[k] = Skill:new { nr = k, id = v, character = self }
		end
		drawDebugWrapper(self)
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, inc = false, wFactor = self.wFactor
		}
		
		self.nameLevel = NameLevel:new{
			x = self.x, y = self.y, 
			level = self.level, name = self.name
		}
	
		local goSelf = self
	
		self.charSprite = Animation:new{
			x = self.x,
			y = self.y,
			
			-- 32x48, 4 per row, 4 rows
			
			width = 32,
			height = 48,
			image = '/assets/graphics/player_characters/' .. goSelf.armor .. "_" .. goSelf.weapon .. ".png",
			
			solid = false,
			
			sequences = 
			{
				incapacitated = { frames = {1}, fps = config.animspeed },
				walk = { frames = {1,2,3,4}, fps = config.animspeed },
				walk_down = { frames = {1,2,3,4}, fps = config.animspeed },
				walk_left = { frames = {5,6,7,8}, fps = config.animspeed },
				walk_right = { frames = {9,10,11,12}, fps = config.animspeed },
				walk_up = { frames = {13,14,15,16}, fps = config.animspeed },
				idle_down = { frames = {1}, fps = config.animspeed },
				idle_left = { frames = {5}, fps = config.animspeed },
				idle_right = { frames = {9}, fps = config.animspeed },
				idle_up = { frames = {13}, fps = config.animspeed },
			},
			
			onNew = function(self)
				the.app.view.layers.characters:add(self)
			end,
			
			onDie = function(self)
				the.app.view.layers.characters:remove(self)
			end,
			
			onUpdate = function(self)
				self.x = goSelf.x
				self.y = goSelf.y - self.height + goSelf.height
				self.visible = goSelf.visible

				self:play(goSelf.anim_name)
			end,
		}
		
		self.hiddenSprite = Tile:new{
			width = 26,
			height = 26,
			image = '/assets/graphics/player_hidden.png',
			solid = false,
			visible = false,
			
			onNew = function(self)
				the.app.view.layers.characters:add(self)
			end,
			
			onDie = function(self)
				the.app.view.layers.characters:remove(self)
			end,
		}
	
				
		--~ print(debug.traceback())
		
		-- attach network stuff to anim functions
		--~ xxx
		--~ local _play = self.play
		--~ self.play = function (self, name)
			--~ _play(self, name)
			--~ self.anim_play = name
			--~ self.anim_freeze = nil
		--~ end
		--~ 
		--~ local _freeze = self.freeze
		--~ self.freeze = function (self, index)
			--~ _freeze(self, index)
			--~ self.anim_freeze = index
		--~ end
	
	end,
	
	onDieBoth = function (self)
		the.app.view.layers.characters:remove(self)
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
	end,
	
	gainFatigue = function (self, str)
		--print(self.oid, "gain fatigue", str)
		self.currentEnergy = self.currentEnergy - str
		self:updateEnergy()
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
	
	updateEnergy = function (self)
	--print("Player ", self.oid, " is incapacitated:", self.incapacitated)
		self.currentEnergy = utils.clamp(self.currentEnergy, 0, self.maxEnergy)
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
			self:updateLevel()							
		end		
		if math.floor(str) > 0 then 
			ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = math.floor(str), tint = {1,1,0}}
		end	
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
		self.level = self.level +1
		self.nameLevel.level = self.level
		self.xp = 1000
		self.tempMaxxed = true
		--	print("leveled", self.level, self.oid)
		-- new particle system example
		local particleTime = 3
		Effect:new{r=255, g=255, b=0, duration=particleTime, follow_oid=self.oid}
		--	print("update reveived! character level = ",  self.level)
		for i = 0, config.levelCap - 1 do
			local width = (love.graphics.getWidth() / 2 - the.controlUI.width / 2) / 10
			if self.level == i then  
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * (i - 1), fill = {255,255,0,255}} 
				the.hud:add(the.levelUI)			
			end							
		end
		self.maxPain = config.maxPain *	(1 + config.strIncreaseFactor * self.level) 
	end,
	
	showDamage = function (self, str)
		if str >= 0 then
			ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {1,0,0}}
		else
			ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {0,0,1}}
		end
	end,
	
	receiveBoth = function (self, message_name, ...)
		print("BOTH", message_name)
		if message_name == "heal" then
			local str, source_oid = ...
			self:showDamage(-str)
		elseif message_name == "damage" then
			local str, source_oid = ...
			if not self.incapacitated then self:showDamage(str) end
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("CHARACTER DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if not self.incapacitated then self:showDamage(str) end
				end)
			end
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("CHARACTER HEAL_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if not self.incapacitated then self:showDamage(-str) end
				end)
			end			
		end	
	end,
	
	receiveLocal = function (self, message_name, ...)
	--	print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str, source_oid = ...
		--	print("HEAL", str)
			self:gainPain(-str)
			object_manager.send(source_oid, "xp", str * config.combatHealXP)
		elseif message_name == "stamHeal" then
			local str, source_oid = ...
		--	print("STAMHEAL", str)
			self:gainFatigue(-str)
			object_manager.send(source_oid, "xp", str * config.combatHealXP)	
		elseif message_name == "damage" then
			local str, source_oid = ...
		--	print("DAMANGE", str)
			if not self.incapacitated then 
				self:gainPain(str)
				if source_oid ~= self.oid then object_manager.send(source_oid, "xp", str * config.combatHealXP) end
			end
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if not self.incapacitated then  
						self:gainPain(str)
						if source_oid ~= self.oid then object_manager.send(source_oid, "xp", str * config.combatHealXP) end
					end
				end)
			end
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if not self.incapacitated then  
						self:gainPain(-str)
						object_manager.send(source_oid, "xp", str * config.combatHealXP)
					end
				end)
			end		
		elseif message_name == "stun" then
			local duration, source_oid = ...
		--	print("STUN", duration)
			self:freezeMovement()
			self:freezeCasting()
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", duration * config.crowdControlXP) end
			the.app.view.timer:after(duration, function()
				self:unfreezeMovement()
				self:unfreezeCasting()
			end)
		elseif message_name == "runspeed" then
			local str, duration, source_oid = ...
			--print("SPEED", str, duration)
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP)
			self.speedOverride = str
			the.app.view.timer:after(duration, function()
				self.speedOverride = 0
			end)
		elseif message_name == "xp" then
			local str = ...
			--print("XP", str)
			self:gainXP(str)
		elseif message_name == "moveSelfTo" then
			local x,y = ...
			self.x = x
			self.y = y
		elseif message_name == "gank" then
			if self.incapacitated == true then 
				self:respawn() 
			end
		elseif message_name == "invis" then
			local duration, speedPenalty, source_oid = ...
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP)
			self.hidden = true
			self.speedOverride = config.walkspeed * speedPenalty
			the.app.view.timer:after(duration, function() self.hidden = false self.speedOverride = 0 end)
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
				x = self.x+self.width/2-16, y = self.y+self.height/2-16, 
				rotation = rot,
			}
			the.footsteps[footstep] = true
			self:makeFootstep()
		end

		-- rotation
		self.rotation = vector.toVisualRotation(vector.fromTo (self.x ,self.y, ipt.viewx, ipt.viewy))	
		local ddx,ddy = vector.fromVisualRotation(self.rotation, 1)
		local dir = vector.dirFromVisualRotation(ddx,ddy)

		-- move into direction?
		if self.freezeMovementCounter == 0 and vector.len(ipt.movex, ipt.movey) > 0 then
			-- replace second 0 by a 1 to toggle runspeed to analog
			local s = config.walkspeed -- utils.mapIntoRange (speed, 0, 0, config.walkspeed, config.runspeed)
			
			-- patched speed?
			if self.speedOverride and self.speedOverride > 0 then s = self.speedOverride end
			
			self.velocity.x, self.velocity.y = vector.normalizeToLen(ipt.movex, ipt.movey, s)
			
			self.anim_name = "walk_" .. dir
			self.anim_speed = utils.mapIntoRange (ipt.speed, 0, 1, config.animspeed, config.animspeed * config.runspeed / config.walkspeed)
			
		elseif self.incapacitated then
			self.anim_name = "incapacitated"
			self.anim_speed = 0
		else
			self.anim_name = "idle_" .. dir
			self.anim_speed = 0
		end
		
		if self:isCasting() == false and ipt.doShoot and self.skills[ipt.shootSkillNr] and 
			self.skills[ipt.shootSkillNr]:isPossibleToUse()
		then
			local cx,cy = self.x + self.width / 2, self.y + self.height / 2
			self.skills[ipt.shootSkillNr]:use(cx, cy, ipt.viewx, ipt.viewy, self)
			self.hidden = false
		end
	end,
	
	onUpdateRemote = function (self, elapsed)
		if self.anim_freeze then 
			--~ xxx self:freeze(self.anim_freeze)
		elseif self.anim_play then
			--~ xxx self:play(self.anim_play)
		end
	end,
	
	onUpdateBoth = function (self, elapsed)
		if self.incapacitated then
			self.tint = {0.5,0.5,0.5}
			self.charSprite.tint = {0.5,0.5,0.5}
		else 
			self.tint = {1,1,1}
			self.charSprite.tint = {1,1,1}
		end
		
		self.nameLevel.x = self.x - 5
		self.nameLevel.y = self.y - 28
		self.nameLevel.level = self.level
		
		if self.hidden then
			self.visible = false
			self.painBar.visible = false
			self.painBar.bar.visible = false
			self.painBar.background.visible = false	
			self.nameLevel.visible = false					
		else
			self.visible = true
			self.painBar.visible = true
			self.painBar.bar.visible = true
			self.painBar.background.visible = true						
			self.nameLevel.visible = true
		end	

		-- update pain bar
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y
		if self.incapacitated then 
			self.painBar.inc = true 
		else
			self.painBar.inc = false
		end 
		
		-- check if we're in combat
		
		self.isInCombat = false
		for k,v in pairs(self.skills) do
			self.isInCombat = self.isInCombat or (v:isOutOfCombat() == false)
		end
		
		-- hide pain bar when not in combat and at full health
		if not self.isInCombat and self.currentPain == 0 then
			self.painBar.visible = false
			self.painBar.bar.visible = false
			self.painBar.background.visible = false	
			self.nameLevel.visible = false
		end
		
		
		-- local hidden image
		if self.hidden and self == the.player then
			self.hiddenSprite.visible = true
		else
			self.hiddenSprite.visible = false
		end
		self.hiddenSprite.x = self.x
		self.hiddenSprite.y = self.y
	end,
	
	onUpdateLocal = function (self, elapsed)
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
		
		-- combat music?
		audio.isInCombat = self.isInCombat
		
		-- kill yourself with space if incap
		local Reminder = Text:extend
		{
			font = 18,
			text = "Press SPACE to re-spawn now. Or wait to get up here at 50% pain.",
			x = 0,
			y = 0, 
			width = 600,
			tint = {0.1,0.1,0.1},
			 
			onUpdate = function (self)
				self.x = (love.graphics.getWidth() - self.width) / 2
				self.y = love.graphics.getHeight() - 100
			end,
			
			onNew = function (self)
				the.hud:add(self)
			end,
		}

		if self.incapacitated and self.reminder ==  nil then 
			self.reminder = Reminder:new() 
		elseif self.incapacitated and self.reminder ~=  nil then 
			self.reminder:revive() 
		end
		if self.incapacitated == false and self.reminder ~=  nil then 
			self.reminder:die() 
		end
		
		if the.keys:pressed(' ') and self.incapacitated then object_manager.send(self.oid, "gank") end
	end,

}
