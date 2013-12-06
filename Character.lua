-- Character

characterMap = {}

CHARACTER_XP_OTHER = 0
CHARACTER_XP_CREEPS = 1
CHARACTER_XP_RESOURCE = 2
CHARACTER_XP_COMBAT = 3

globalOneTimeStatsSend = false

Character = Animation:extend
{
	class = "Character",

	props = {"viewRange", "x", "y", "rotation", "image", "width", "height", "currentPain", "maxPain", "level", "anim_name", 
		"anim_speed", "velocity", "alive", "incapacitated", "hidden", "name", "weapon", "armor", "isInCombat", 
		"team", "invul", "dmgModified", "marked", "maxPainOverdrive", "deaths", "xp", "kills", "determination"},
		
	sync_high = {"x", "y", "rotation", "currentPain", "maxPain", "rotation", "anim_name", "anim_speed",
		"velocity", "alive", "incapacitated", "hidden", "isInCombat", 
		"invul", "width", "height", "rotation", "dmgModified", "marked", "rooted", "snared", "mezzed", "stunned", "powerblocked",
		"maxPainOverdrive", "viewRange", "determination"},	
		
	sync_low = {"image", "level", "name", "weapon", "armor", "team", "deaths", "xp", "kills", },
	
	maxPain = config.maxPain, 
	-- 1 = 100% health bar, 1.2 is 20% longer
	maxPainOverdrive = 1,
	currentPain = 0,
	maxEnergy = config.maxEnergy, 
	currentEnergy = config.maxEnergy, 
	xp = 0,
	xpCap = config.xpCap,
	level = 0,
	levelCap = config.levelCap,
	tempMaxxed = false,
	incapacitated = false,
	hidden = false,
	isInCombat = false,	
	name = nil,
	reminder = nil,
	targetable = true,
	team = "none",
	rooted = false,
	stunned = false,
	dmgModified = config.dmgUnmodified,
	invul = false,
	mezzed = false,
	snared = false,
	powerblocked = false,
	marked = false,
	interrupted = false,
	deaths = 0,
	kills_player = 0,
	xp_gained_from_creeps = 0,
	xp_gained_from_resource = 0,
	xp_gained_from_combat = 0,
	barrier_dmg = 0,
	resource_dmg = 0,
	selectedSkill = 1,
	selfTargetingSkill = false,
	viewRange = config.characterViewRange,
	feelRange = config.characterFeelRange,
	viewAngle = config.characterViewAngle,
	coverLocation = nil, 
	determination = 0,
	lastUsedSkill = "",
	respawned = false,
	
	xyMonitor = nil,
	
	--~ "bow" or "scythe" or "staff"
	weapon = "bow",
	--~ "robe" or "hide_armor" or "splint_mail"
	armor = "robe",

	-- for anim sync
	anim_name = nil,
	anim_speed = nil,
	
	send_zones = false,
		
	-- list of Skill
	skills = localconfig.skills or {
		"noskill",
		"noskill",
		"noskill",
		"noskill",
		"noskill",
		"noskill",
	},
	

	activeSkillNr = 1,
	
	-- 32x48, 4 per row, 4 rows
	
	pain_bar_size = 52,
	
	width = 26,
	height = 46,
	--~ image = '/assets/graphics/player_characters/robe_bow.png',
	image = nil,--'/assets/graphics/player_collision.png',

	charSprite = nil,
	hiddenSprite = nil,
	markedSprite = nil,

	-- UiBar
	painBar = nil,
	nameLevel = nil,
	charDebuffDisplay = nil,
		
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
		--~ print(self.oid, self.name, debug.traceback())
		
		self:mixin(GameObject)
		self:mixin(GameObjectCommons)
		self:mixin(FogOfWarObject)
		
		the.app.view.layers.characters:add(self)
		the.characters[self] = true
				--~ print(debug.traceback())
		self.maxPain = config.maxPain * (1 + config.strIncreaseFactor * self.level)
		-- fill up skill bar with missing skills
		for i = 1,8 do 
			if not self.skills[i] then self.skills[i] = "noskill" end
		end
		
		local skill_names = {
			bow_shot = true,
			bow_puncture = true,
			bow_snare = true,
			bow_blunt_arrow = true,
			bow_root = true,
			bow_mark_target = true,
			scythe_sweep = true,
			scythe_pirouette = true,
			scythe_jump = true,
			scythe_harpoon = true,
			scythe_stun = true,
			scythe_gank = true,
			staff_magic_bolt = true,
			staff_life_leech = true,
			staff_poison = true,
			staff_fireball = true,
			staff_healing_orb = true,
			staff_healing_breeze = true,
			staff_mezz = true,
			staff_wall = true,
			robe_bandage = true,
			robe_shrink = true,
			robe_sonic_boom = true,
			robe_fade = true,
			robe_quake = true,
			robe_gust = true,
			hide_armor_sprint = true,
			hide_armor_sneak = true,
			hide_armor_freedom = true,
			hide_armor_mend_wounds = true,
			hide_armor_regenerate = true,
			hide_armor_second_wind = true,
			splint_mail_absorb = true,
			splint_mail_ignore_pain = true,
			splint_mail_clarity = true,
			splint_mail_grow = true,
			splint_mail_shout = true,
			splint_mail_invulnerability = true,
			splint_mail_bulwark = true,
		}
		
		-- overwrite invalid skills
		for k,v in pairs(self.skills) do
			if not skill_names[v] then
				self.skills[k] = "noskill"
			end
		end

		for k,v in pairs(self.skills) do
			self.skills[k] = Skill:new { nr = k, id = v, character = self }
		end
		drawDebugWrapper(self)
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, inc = false,
			width = self.pain_bar_size,
		}
	
		-- colored name
		local nameColor = {0.1, 0.1, 0.1}
		if self.team == "alpha" then
			nameColor = config.teamColors.alpha
		elseif self.team == "beta" then
			nameColor = config.teamColors.beta
		elseif self.team == "gamma" then
			nameColor = config.teamColors.gamma
		elseif self.team == "delta" then
			nameColor = config.teamColors.delta
		elseif self.team == "dev" then
			nameColor = config.teamColors.dev
		else 
			nameColor = config.teamColors.neutral
		end	

		self.nameLevel = NameLevel:new{
			x = self.x, y = self.y, 
			level = self.level, name = self.name,
			weapon = self.weapon, armor = self.armor, team = self.team,
			width = self.pain_bar_size * 2, cover = self.coverLocation
		}
		self.nameLevel.tint = nameColor 
		
		self.charDebuffDisplay = CharDebuffDisplay:new{
			x = self.x, y = self.y, 
			width = self.pain_bar_size,
		}
	
		local goSelf = self

		-- TODO: remove this ugly hack
		if goSelf.weapon ~= "bow" then
			if goSelf.weapon ~= "scythe" then
				if goSelf.weapon ~= "staff" then
					goSelf.weapon = "bow"
				end
			end
		end

		-- TODO: remove this ugly hack
		if goSelf.armor ~= "robe" then
			if goSelf.armor ~= "hide_armor" then
				if goSelf.armor ~= "splint_mail" then
					goSelf.armor = "robe" 
				end
			end
		end
	
		self.charSprite = Animation:new{
			x = self.x,
			y = self.y,
			
			-- 32x48, 4 per row, 4 rows
			
			width = 48,
			height = 64,
			image = "/assets/graphics/player_characters/body.png",
			
			solid = false,
			
			sequences = 
			{
				incapacitated = { frames = {7}, fps = config.animspeed },
				walk = { frames = {7, 8, 9}, fps = config.animspeed },
				walk_down = { frames = {7, 8, 9}, fps = config.animspeed },
				walk_left = { frames = {10, 11, 12}, fps = config.animspeed },
				walk_right = { frames = {4, 5, 6}, fps = config.animspeed },
				walk_up = { frames = {1, 2, 3}, fps = config.animspeed },
				idle_down = { frames = {7}, fps = config.animspeed },
				idle_left = { frames = {10}, fps = config.animspeed },
				idle_right = { frames = {4}, fps = config.animspeed },
				idle_up = { frames = {1}, fps = config.animspeed },
			},
			
			onNew = function(self)
				the.app.view.layers.characters:add(self)
			end,
			
			onDie = function(self)
				the.app.view.layers.characters:remove(self)
			end,
			
			onUpdate = function(self)
				profile.start("char.update.1")

				self.x = goSelf.x - 12
				self.y = goSelf.y - self.height + goSelf.height
				self.visible = goSelf.visible

				if goSelf.anim_name then self:play(goSelf.anim_name) end
				
				self.alpha = goSelf.alpha
				
				profile.stop()
			end,
		}
		
		self.armorSprite = Animation:new{
			x = self.x,
			y = self.y,
			
			-- 32x48, 4 per row, 4 rows
			
			width = 48,
			height = 64,
			image = "/assets/graphics/player_characters/".. goSelf.armor ..".png",
			
			solid = false,
			
			sequences = 
			{
				incapacitated = { frames = {7}, fps = config.animspeed },
				walk = { frames = {7, 8, 9}, fps = config.animspeed },
				walk_down = { frames = {7, 8, 9}, fps = config.animspeed },
				walk_left = { frames = {10, 11, 12}, fps = config.animspeed },
				walk_right = { frames = {4, 5, 6}, fps = config.animspeed },
				walk_up = { frames = {1, 2, 3}, fps = config.animspeed },
				idle_down = { frames = {7}, fps = config.animspeed },
				idle_left = { frames = {10}, fps = config.animspeed },
				idle_right = { frames = {4}, fps = config.animspeed },
				idle_up = { frames = {1}, fps = config.animspeed },
			},
			
			onNew = function(self)
				the.app.view.layers.characters:add(self)
				self.tint = getTeamColor(goSelf.team)	
			end,
			
			onDie = function(self)
				the.app.view.layers.characters:remove(self)
			end,
			
			onUpdate = function(self)
				profile.start("char.update.2")
			
				self.x = goSelf.x - 12
				self.y = goSelf.y - self.height + goSelf.height
				self.visible = goSelf.visible

				if goSelf.anim_name then self:play(goSelf.anim_name) end
				
				self.alpha = goSelf.alpha
				
				profile.stop()
			end,
		}
		
		self.weaponSprite = Animation:new{
			x = self.x,
			y = self.y,
			
			-- 32x48, 4 per row, 4 rows
			
			width = 48,
			height = 64,
			image = "/assets/graphics/player_characters/" .. goSelf.weapon .. ".png",
			
			solid = false,
			
			sequences = 
			{
				incapacitated = { frames = {7}, fps = config.animspeed },
				walk = { frames = {7, 8, 9}, fps = config.animspeed },
				walk_down = { frames = {7, 8, 9}, fps = config.animspeed },
				walk_left = { frames = {10, 11, 12}, fps = config.animspeed },
				walk_right = { frames = {4, 5, 6}, fps = config.animspeed },
				walk_up = { frames = {1, 2, 3}, fps = config.animspeed },
				idle_down = { frames = {7}, fps = config.animspeed },
				idle_left = { frames = {10}, fps = config.animspeed },
				idle_right = { frames = {4}, fps = config.animspeed },
				idle_up = { frames = {1}, fps = config.animspeed },
			},
			
			onNew = function(self)
				the.app.view.layers.characters:add(self)
			end,
			
			onDie = function(self)
				the.app.view.layers.characters:remove(self)
			end,
			
			onUpdate = function(self)
				profile.start("char.update.3")
				
				self.x = goSelf.x - 12
				self.y = goSelf.y - self.height + goSelf.height
				self.visible = goSelf.visible

				if goSelf.anim_name then self:play(goSelf.anim_name) end
				
				self.alpha = goSelf.alpha
				
				profile.stop()
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
			
			onUpdate = function(self)
				self.alpha = goSelf.alpha
			end,
		}
		
		self.markedSprite = Tile:new{
			width = 32,
			height = 64,
			image = '/assets/graphics/mark.png',
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
	
		self:refreshLevelBar()
		
		-- update zones
		if self.send_zones then self:updateAndSendZones() end
		
		self:every(1, function()
			if self.send_zones then self:updateAndSendZones() end
		end)
		
		if self:isLocal() and globalOneTimeStatsSend then
		
			globalOneTimeStatsSend = true
			 
			-- send selected skills
			for k,v in pairs(self.skills) do
				local s = self.skills[k].definition
				track("skill_taken", self.name, s.key)
			end
			
			-- send config
			track("config", self.name, self.team, localconfig.fullscreen, localconfig.screenWidth, localconfig.screenHeight,
				localconfig.max_chat_lines, localconfig.audioVolume, 
				localconfig.skillOne,
				localconfig.skillTwo,
				localconfig.skillThree,
				localconfig.skillFour,
				localconfig.skillFive,
				localconfig.skillSix,
				localconfig.skillSeven,
				localconfig.skillEight,
				localconfig.targetSelf,
				localconfig.showHighscore,
				localconfig.toggleFullscreen,
				localconfig.quitGame
			)
		end
		
		-- over time tracking
		self:every(config.trackingOverTimeTimeout, function() 
			if self:isLocal() and the.phaseManager and the.phaseManager.phase == "playing" then
				track("player_ot", self.oid, self.name, self.level, self.xp, self.deaths, self.kills_player, 
					self.xp_gained_from_combat, self.xp_gained_from_creeps, self.xp_gained_from_resource, 
					self.barrier_dmg, self.resource_dmg, self.currentPain, self.maxPain, self.currentEnergy, self.maxEnergy
					)
			end
		end)
		
		-- keep character index in sync		
		the.gridIndexMovable:insertAt(self.x,self.y,self)
		print("INSERT INTO GRID", self.oid, self.x, self.y)
		self.xyMonitor = XYMonitor:new{
			obj = self,
			onChangeFunction = function(ox,oy, nx,ny)
				the.gridIndexMovable:moveFromTo(self, ox,oy, nx,ny)
			end,
		}
	end,
	
	updateAndSendZones = function (self)
		self:calculateZones()
		if the.player and the.player.oid == self.oid then
			-- update zone on server
			--~ print("SEND ZONE")
			--~ utils.vardump(self.zones)
			local msg = { channel = "server", cmd = "zones", zones = self.zones, }
			network.send (msg, true)
		end
	end,
	
	onDieBoth = function (self)
		the.gridIndexMovable:removeObject(self)
		the.app.view.layers.characters:remove(self)
		the.characters[self] = nil
		self.painBar:die()
		if self.reminder then self.reminder:die() end
		if self.markedSprite then self.markedSprite:die() end
	end,
	
	freezeCasting = function (self)
		--print("FREEEZ CAST")
		self.freezeCastingCounter = self.freezeCastingCounter + 1
	end,
	
	unfreezeCasting = function (self)
		--print("UNFREEEZ CAST")
		if self.freezeCastingCounter > 0 then
			self.freezeCastingCounter = self.freezeCastingCounter - 1
		end
	end,
	
	freezeMovement = function (self)
		--print("FREEEZ MOVE")
		self.freezeMovementCounter = self.freezeMovementCounter + 1
	end,
	
	unfreezeMovement = function (self)
		--print("UNFREEEZ MOVE")
		if self.freezeMovementCounter > 0 then
			self.freezeMovementCounter = self.freezeMovementCounter - 1
		end
	end,
	
	gainPain = function (self, str, source_oid)
		--print(self.oid, "gain pain", str)
		if self.invul and str >= 0 then 
			-- do nothing
		else
			self.currentPain = self.currentPain + str
			self:updatePain(source_oid)
		end
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
			self.respawned = false
		end
	end,
	
	updatePain = function (self, source_oid)
	--print("Player ", self.oid, " is incapacitated:", self.incapacitated)
		if self.currentPain >= self.maxPain then 
			self:setIncapacitation(true)
			self.deaths = self.deaths + 1
			gameStatsInc("times_died")
			
			-- kills tracking
			local killer = object_manager.get(source_oid)
			if killer then
				if killer.class == "Character" then
					object_manager.send(source_oid, "inc", "kills_player", 1)
					track("killed_by_player", self.oid, self.name, self.team, killer.oid, killer.name, killer.team, self.x, self.y)
				else
					track("killed_by_other", self.oid, self.name, self.team, killer.oid, killer.class, self.x, self.y)
				end
			else
				track("killed_by_unknown", self.oid, self.name, self.team, self.x, self.y)
			end
		end
		
		self.currentPain = utils.clamp(self.currentPain, 0, self.maxPain)
	end,
	
	updateEnergy = function (self)
	--print("Player ", self.oid, " is incapacitated:", self.incapacitated)
		self.currentEnergy = utils.clamp(self.currentEnergy, 0, self.maxEnergy)
	end,
	
	resetCooldowns = function (self)	
		for _,skill in pairs(self.skills) do
			--~ self.skills[k] = Skill:new { nr = k, id = v, character = self }
			--~ print(k,v)
			--~ utils.vardump(v)
			for k,v in pairs(skill) do
				--~ print(k,v)
				if k == "lastUsed" then skill[k] = -100000 end
			end
		end
	end,
		
	respawn = function (self)
		--self.x, self.y = the.respawnpoint.x, the.respawnpoint.y
		
		local randomNumber = math.random(1,4)
		
		if randomNumber == 1 then
			self.x, self.y = the.respawnpoint1.x, the.respawnpoint1.y
		elseif randomNumber == 2 then
			self.x, self.y = the.respawnpoint2.x, the.respawnpoint2.y
		elseif randomNumber == 3 then
			self.x, self.y = the.respawnpoint3.x, the.respawnpoint3.y
		else
			self.x, self.y = the.respawnpoint4.x, the.respawnpoint4.y
		end
		
		--~ self.currentPain = 0
		--~ self.currentEnergy = 300
		--~ self:setIncapacitation(false)
		--~ self.rooted = false
		--~ self.stunned = false
		--~ self.dmgModified = config.dmgUnmodified
		--~ self.invul = false
		--~ self.mezzed = false
		--~ self.snared = false
		--~ self.powerblocked = false
		--~ self.marked = false
		--~ self.freezeMovementCounter = 0
		--~ self.freezeCastingCounter = 0
		--~ self.speedOverride = 0
		--~ self.markedSprite.scale = 1
		--~ self.charSprite.scale = 1
		--~ self.armorSprite.scale = 1
		--~ self.weaponSprite.scale = 1
		--~ self:resetCooldowns()
	end,	
	
	gainXP = function (self, str, xpType)
		xpType = xpType or CHARACTER_XP_OTHER
		--~ print(self.oid, "gain xp", str, xpType)
		if self.tempMaxxed == false then
			self.xp = self.xp + str
			
			if xpType == CHARACTER_XP_CREEPS then self.xp_gained_from_creeps = self.xp_gained_from_creeps + str end
			if xpType == CHARACTER_XP_RESOURCE then self.xp_gained_from_resource = self.xp_gained_from_resource + str end
			if xpType == CHARACTER_XP_COMBAT then self.xp_gained_from_combat = self.xp_gained_from_combat + str end
		end
		--print(self.xp)
		if self.tempMaxxed == false and self.xp >= 1000 then 
			self:updateLevel()							
		end		
		if math.floor(str) > 0 then 
			str = tools.floor1(str)
			if not self.hidden or self == the.player then
				ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {1,1,0}, yOffset = 50}
			end
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
	
	refreshLevelBar = function (self)
		--~ if the.player then print("LALA", self.level, self.oid, the.player.level, the.player.oid, the.player.class, the.player == self) end
		
		if the.levelUI then
			for k,v in pairs(the.levelUI) do
				if the.player and the.player.class == "Character" and the.player.oid == self.oid then
					v.activated = self.level >= v.level
				else
					v.activated = false
				end
			end
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

		self:refreshLevelBar()
		
		self.maxPain = config.maxPain *	(1 + config.strIncreaseFactor * self.level) 
	end,
	
	showDamage = function (self, str)
		if not self.hidden or self == the.player then
			self:showDamageWithOffset (str, 50)
		end
	end,
	
	blink = function (self)
		if self.armorSprite.tint ~= {1,1,1} then
			self.armorSprite.tint = {1,1,1}
			self:after(0.2, function()
				self.armorSprite.tint = getTeamColor(self.team)
			end)
		end
	end,
	
	receiveBoth = function (self, message_name, ...)
		--~ print("BOTH", message_name)
		if message_name == "heal" then
			local str, source_oid = ...
			self:showDamage(-str)
		elseif message_name == "damage" then
			local str, source_oid = ...
			if not self.invul then
				if not self.incapacitated then 
					if self.dmgModified then
						self:showDamage(str / 100 * self.dmgModified) 
					else
						self:showDamage(str) 
					end
				end
			end
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			local oldDeaths = self.deaths
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then
						if not self.incapacitated and not self.invul then  
							if self.dmgModified then
								self:showDamage(str / 100 * self.dmgModified)
							else
								self:showDamage(str) 
							end
						end
					end
				end)				
			end	
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("CHARACTER HEAL_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					--~ if not self.incapacitated then 
						self:showDamage(-str) 
					--~ end
				end)
			end	
		elseif message_name == "changeSize" then
			local str, duration, source_oid = ...
			self.charSprite.scale = self.charSprite.scale / 100 * str
			self.armorSprite.scale = self.armorSprite.scale / 100 * str
			self.weaponSprite.scale = self.weaponSprite.scale / 100 * str
			self.markedSprite.scale = self.charSprite.scale / 100 * str
			self:after(duration, function()
				self.markedSprite.scale = 1
				self.armorSprite.scale = 1
				self.weaponSprite.scale = 1			
				self.charSprite.scale = 1
			end)
		elseif message_name == "mark" then
			local duration, source_oid = ...
			object_manager.send(source_oid, "xp", duration / 8 * config.crowdControlXP, CHARACTER_XP_COMBAT)
				self.marked = true
			self:after(duration, function()
				self.marked = false
			end)
		elseif message_name == "play_sound" then
			local sfx, loudness, source_oid = ...
			if self.oid == the.player.oid then
				playSound(sfx, audio.volume * loudness, 'short')		
				--~ print("played", self.oid, source_oid)
			end	
		elseif message_name == "blink" then
			local source_oid = ...
			if source_oid ~= self.oid then
				self:blink()
			end			
		end	
	end,
	
	receiveLocal = function (self, message_name, ...)
	--	print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str, source_oid = ...
		--	print("HEAL", str)
			self:gainPain(-str, source_oid)
			object_manager.send(source_oid, "xp", str * config.combatHealXP, CHARACTER_XP_COMBAT)
			if self.hidden then self.hidden = false self.speedOverride = 0 end			
		elseif message_name == "inc" then
			local key, value = ...
			if self[key] then self[key] = self[key] + value end
		elseif message_name == "reset_xp" then
			self:resetXP()
		elseif message_name == "stamHeal" then
			local str, source_oid = ...
		--	print("STAMHEAL", str)
			self:gainFatigue(-str)
			object_manager.send(source_oid, "xp", str * config.combatHealXP, CHARACTER_XP_COMBAT)	
		elseif message_name == "damage" then
			local str, source_oid = ...
		--	print("DAMANGE", str)
			if not self.incapacitated then 
				if self.dmgModified then
					self:gainPain(str / 100 * self.dmgModified, source_oid) 
				else
					self:gainPain(str, source_oid)
				end
				if source_oid ~= self.oid then object_manager.send(source_oid, "xp", str * config.combatHealXP, CHARACTER_XP_COMBAT) end
			end
			if self.hidden then self.hidden = false self.speedOverride = 0 end	
			if self.mezzed then
				self:unfreezeMovement()
				self:unfreezeCasting()
				self.mezzed = false
			end
			if self.rooted then
				self:unfreezeMovement()
				self.rooted = false
			end
		elseif message_name == "transfer" then
			--~ print("TRANSFER", self.oid)
			local str, duration, ticks, source_oid, targetOids, eff = ...
			
			-- collect initial death counts
			local ownDeaths = self.deaths
			local targetDeaths = {}
			for k,oid in pairs(targetOids) do targetDeaths[oid] = object_manager.get_field(oid, "deaths", -1) end
			
			--~ utils.vardump(targetOids)
			local strPerTargetPerTick = str / #targetOids
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if not self.incapacitated then  
						for k,v in pairs(targetOids) do
							-- only send messages if none of the pair died
							--~ print("OTHER", v, targetDeaths[v], object_manager.get_field(v, "deaths", -1))
							--~ print("OWN", ownDeaths, self.deaths)
							if v ~= self.oid and self.deaths == ownDeaths and 
								targetDeaths[v] == object_manager.get_field(v, "deaths", -1)
							then 
								object_manager.send(v, "damage", strPerTargetPerTick, self.oid) 
								object_manager.send(self.oid, "heal", eff * strPerTargetPerTick, self.oid) 
							end
						end
					end
					if self.mezzed then
						self:unfreezeMovement()
						self:unfreezeCasting()
						self.mezzed = false
					end
					if self.rooted then
						self:unfreezeMovement()
						self.rooted = false
					end
					if self.hidden then self.hidden = false self.speedOverride = 0 end						
				end)				
			end		
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			local oldDeaths = self.deaths
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then
						if not self.incapacitated and not self.invul then  
							if self.dmgModified then
								self:gainPain(str / 100 * self.dmgModified, source_oid)  
							else
								self:gainPain(str, source_oid)
							end
							if source_oid ~= self.oid then object_manager.send(source_oid, "xp", str * config.combatHealXP, CHARACTER_XP_COMBAT) end
						end
						if self.mezzed then
							self:unfreezeMovement()
							self:unfreezeCasting()
							self.mezzed = false
						end
						if self.rooted then
							self:unfreezeMovement()
							self.rooted = false
						end
						if self.hidden then self.hidden = false self.speedOverride = 0 end	
					end
				end)				
			end		
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					--~ if not self.incapacitated then  
						self:gainPain(-str, source_oid)
						object_manager.send(source_oid, "xp", str * config.combatHealXP, CHARACTER_XP_COMBAT)
					--~ end
				end)
			end	
			if self.hidden then self.hidden = false self.speedOverride = 0 end				
		elseif message_name == "stun" then
			local duration, source_oid = ...
			duration = duration/ 100 * (100 - self.determination)
		--	print("STUN", duration)
			self:freezeMovement()
			self:freezeCasting()
			self.stunned = true
			self.interrupted = true
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT) end
			self:after(duration, function()
				self:unfreezeMovement()
				self:unfreezeCasting()
				self.stunned = false
			end)
			self:gainDetermination(duration * config.stunDeterminationRatio)
		elseif message_name == "mezz" then
			local duration, source_oid = ...
			duration = duration/ 100 * (100 - self.determination)
		--	print("MEZZ", duration)
			self:freezeMovement()
			self:freezeCasting()
			self.mezzed = true
			self.interrupted = true			
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT) end
			self:after(duration, function()
				self:unfreezeMovement()
				self:unfreezeCasting()
				self.mezzed = false
			end)
			self:gainDetermination(duration * config.mezzDeterminationRatio)
		elseif message_name == "clarity" then
			local duration, source_oid = ...
			if self.mezzed then
				self.freezeMovementCounter = 0	
				self.freezeCastingCounter = 0					
				self.mezzed = false
			end	
			if self.stunned then
				self.freezeMovementCounter = 0	
				self.freezeCastingCounter = 0					
				self.stunned = false
			end	
			if self.powerblocked then
				self.freezeCastingCounter = 0					
				self.powerblocked = false
			end	
		elseif message_name == "powerblock" then
			local duration, source_oid = ...
			duration = duration/ 100 * (100 - self.determination)			
		--	print("POWERBLOCKED", duration)
			self:freezeCasting()
			self.powerblocked = true
			self.interrupted = true			
			if source_oid ~= self.oid then object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT) end
			self:after(duration, function()
				self:unfreezeCasting()
				self.powerblocked = false
			end)
			self:gainDetermination(duration * config.pbDeterminationRatio)									
		elseif message_name == "runspeed" then
			local str, duration, source_oid = ...
			--print("SPEED", str, duration)
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT)
			
			
			if self.snared and str == config.runspeed then
				-- nothing happens
			else
				self.speedOverride = str
			end
			
			if str < config.walkspeed then		
				duration = duration/ 100 * (100 - self.determination)
			end
			self:after(duration, function()
				self.speedOverride = 0
			end)
			if str < config.walkspeed then
				self:gainDetermination(duration * config.snareDeterminationRatio)
			end
			--~ print("det", self.determination)
		elseif message_name == "xp" then
			local str, xpType = ...
			--print("XP", str)
			self:gainXP(str, xpType)
		elseif message_name == "moveSelfTo" then
			local x,y = ...
			self.x = x
			self.y = y
		elseif message_name == "gank" then
			if self.incapacitated == true and not self.respawned then 
				self.respawned = true
				self:respawn() 
			end
		elseif message_name == "sneak" then
			local duration, speedPenalty, source_oid = ...
			self.hidden = true
			self.speedOverride = config.walkspeed * speedPenalty
			self:after(duration, function() self.hidden = false self.speedOverride = 0 end)
		elseif message_name == "hide" then
			local duration, speedPenalty, source_oid = ...
			self.hidden = true			
		elseif message_name == "dmgModifier" then
			local str, duration, source_oid = ...
			--print("dmgModifier", str, duration)
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT)
			self.dmgModified = str
			self:after(duration, function() 
					self.dmgModified = config.dmgUnmodified
			end)
		elseif message_name == "root" then
			local duration, source_oid = ...
			duration = duration/ 100 * (100 - self.determination)
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT)
			self:freezeMovement()
			self.rooted = true
			self:after(duration, function() 
				self:unfreezeMovement()
				self.rooted = false
			end)		
			self:gainDetermination(duration * config.rootDeterminationRatio)
			--~ print("det", self.determination)
		elseif message_name == "root_break" then
			local duration, source_oid = ...
			if self.rooted then
				self.freezeMovementCounter = 0	
				self.rooted = false
			end	
		elseif message_name == "snare_break" then
			local duration, source_oid = ...
			if self.snared then
				self.speedOverride = 0
				self.snared = false
			end		
		elseif message_name == "buff_max_pain" then
			local str, duration, source_oid = ...
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT)
			self.maxPainOverdrive = 1 + str / self.maxPain
			self.maxPain = self.maxPain + str
			self:after(duration, function()
				if self.currentPain >= self.maxPain - str then self:setIncapacitation(true) end
				self.maxPain = self.maxPain - str
				self.maxPainOverdrive = 1
			end)	
		elseif message_name == "invul" then
			local duration, source_oid = ...
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT)
			self.invul = true
			self:after(duration, function()
				self.invul = false
			end)	
		elseif message_name == "changeSize" then
			local str, duration, source_oid = ...
			object_manager.send(source_oid, "xp", duration * config.crowdControlXP, CHARACTER_XP_COMBAT)
			self.width = self.width / 100 * str
			self.height = self.height / 100 * str
			self:after(duration, function()
				self.width = self.width / str * 100 
				self.height = self.height / str * 100
			end)	
		elseif message_name == "stop_dots" then
			local duration, source_oid = ...
			self.deaths = self.deaths + 1	
		elseif message_name == "createBlockerAt" then
			local x,y = ...
			Blocker:new{x=x, y=y}
		end
	end,
	
	gainDetermination = function (self, amount)
		self.determination = self.determination + amount
		if self.determination > 100 then self.determination = 100 end
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
		
		-- don't regenerate when you have used a skill
		for k,v in pairs(self.skills) do
			if (v:isOutOfCombat() == false) then
				regenerating = false
			end
		end
		
		-- or when you are affected by crowd control
		if self.determination > 0 then regenerating = false end
		
		-- to do: no regeneration when someone has attacked you recently
		
		if self.incapacitated then
			if regenerating == true then self.currentPain = self.currentPain - config.healthreg * elapsed / 2 end
		else
			if regenerating == true then self.currentPain = self.currentPain - config.healthreg * elapsed end
		end	
			
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
			
			-- reduce speed if running backwards / sideways
			if the.keys:pressed('left', 'a') then
				if dir == "right" then 
					s = s * config.walkBackwardsPenalty
				elseif dir == "up" or dir == "down" then
					s = s * config.walkSidewaysPenalty
				else
					-- nothing happens because you're running forward
				end	
			elseif the.keys:pressed('right', 'd') then
				if dir == "left" then 
					s = s * config.walkBackwardsPenalty
				elseif dir == "up" or dir == "down" then
					s = s * config.walkSidewaysPenalty
				else
					-- nothing happens because you're running forward
				end	
			elseif the.keys:pressed('up', 'w') then
				if dir == "down" then 
					s = s * config.walkBackwardsPenalty
				elseif dir == "left" or dir == "right" then
					s = s * config.walkSidewaysPenalty
				else
					-- nothing happens because you're running forward
				end				
			elseif the.keys:pressed('down', 's') then
				if dir == "up" then 
					s = s * config.walkBackwardsPenalty
				elseif dir == "left" or dir == "right" then
					s = s * config.walkSidewaysPenalty
				else
					-- nothing happens because you're running forward
				end				
			else 
				--nothing happens
			end
			
			--~ print(dir, s)
			
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
			if self.hidden then self.speedOverride = 0 end
			self.hidden = false
		end
	end,
	
	onUpdateRemote = function (self, elapsed)
		-- reset velocity after 500ms
		local t = love.timer.getTime()
		if self.last_net_sync_time and t - self.last_net_sync_time > 0.5 then
		    self.velocity.x = 0
		    self.velocity.y = 0
		end

		if self.anim_freeze then 
			--~ xxx self:freeze(self.anim_freeze)
		elseif self.anim_play then
			--~ xxx self:play(self.anim_play)
		end
	end,
	
	onUpdateBoth = function (self, elapsed)
		profile.start("character.onupdateboth")
	
		if self.incapacitated then
			self.tint = {0.5,0.5,0.5}
			self.charSprite.tint = {0.5,0.5,0.5}
		else 
			self.tint = {1,1,1}
			self.charSprite.tint = {1,1,1}
		end
		
		self.nameLevel.x = self.x - 5
		self.nameLevel.y = self.y - 8
		self.nameLevel.level = self.level
		self.nameLevel.team = self.team
		self.nameLevel.alpha = self.alpha
		self.nameLevel.cover = self.coverLocation
		
		self.charDebuffDisplay.x = self.x - 5
		self.charDebuffDisplay.y = self.y - 8
		self.charDebuffDisplay.alpha = self.alpha
		self.charDebuffDisplay.determination = self.determination
		--~ print(self.charDebuffDisplay.determination, self.determination)
		
		if self.rooted then self.charDebuffDisplay.rooted = "rooted" else self.charDebuffDisplay.rooted = "" end
		if self.stunned then self.charDebuffDisplay.stunned = "stunned" else self.charDebuffDisplay.stunned = "" end		
		if self.mezzed then self.charDebuffDisplay.mezzed = "mezzed" else self.charDebuffDisplay.mezzed = "" end	
		if self.snared then self.charDebuffDisplay.snared = "snared" else self.charDebuffDisplay.snared = "" end			
		if self.powerblocked then self.charDebuffDisplay.powerblocked = "pb'ed" else self.charDebuffDisplay.powerblocked = "" end	
		if self.dmgModified > config.dmgUnmodified then self.charDebuffDisplay.exposed = "exposed" else self.charDebuffDisplay.exposed = "" end	
		if self.invul then self.charDebuffDisplay.invul = "invul" else self.charDebuffDisplay.invul = "" end			
		
		if self.hidden then
			self.visible = false
			self.painBar.visible = false
			self.painBar.bar.visible = false
			self.painBar.background.visible = false	
			self.nameLevel.visible = false	
			self.charDebuffDisplay.visible = false										
		else
			self.visible = true
			self.painBar.visible = true
			self.painBar.bar.visible = true
			self.painBar.background.visible = true						
			self.nameLevel.visible = true
			self.charDebuffDisplay.visible = true
		end	

		-- update pain bar
		self.painBar.currentValue = self.currentPain
		self.painBar.maxValue = self.maxPain
		self.painBar.bar.alpha = self.alpha
		self.painBar.background.alpha = self.alpha
		self.painBar.width = self.pain_bar_size * self.maxPainOverdrive

		self.painBar:updateBar()
		self.painBar.x = self.x - 10
		self.painBar.y = self.y + 5
		if self.incapacitated then 
			self.painBar.inc = true 
		else
			self.painBar.inc = false
		end 
		
		-- hide pain bar when not in combat and at full health
		--~ if not self.isInCombat and self.currentPain == 0 then
			--~ self.painBar.visible = false
			--~ self.painBar.bar.visible = false
			--~ self.painBar.background.visible = false	
			--~ self.nameLevel.visible = false
			--~ self.charDebuffDisplay.visible = false	
		--~ end
		
		-- local hidden image
		if self.hidden and self == the.player then
			self.hiddenSprite.visible = true
		else
			self.hiddenSprite.visible = false
		end
		self.hiddenSprite.x = self.x
		self.hiddenSprite.y = self.y
				
		if self.marked then 
			self.markedSprite.visible = true
		else
			self.markedSprite.visible = false
		end
		self.markedSprite.x = self.x
		self.markedSprite.y = self.y - 32
		
		self.alphaWithoutFog = 1
		
		self.coverLocation = self:calculateCoverOid()
		--~ print(self.coverLocation, self:calculateCoverOid())
		-- hide players who are in cover
		--~ print(the.player , self.team, the.player.team , self.coverLocation , self.coverLocation, the.player.coverLocation)
		
		if the.player and self.team ~= the.player.team and self.coverLocation and self.coverLocation ~= the.player.coverLocation then	
			self.alphaWithoutFog = 0
		end
		
		for char, _ in pairs(the.characters) do
			if self.coverLocation == char.coverLocation and self.team ~= char.team then
				self.alphaWithoutFog = 1
			end
		end
		
		self:updateFogAlpha()

		self.xyMonitor:checkAndCall()
		
		profile.stop()
	end,
	
	onUpdateLocal = function (self, elapsed)
	
		self:refreshLevelBar()
		
		-- move back into map if outside
		local px,py = self.x+self.width/2, self.y+self.height/2
		if px < 0 or px > config.map_width or py < 0 or py > config.map_height then
			local dx,dy = vector.fromToWithLen(px,py,config.map_width/2,config.map_height/2,200)
			self.x, self.y = self.x+dx,self.y+dy
		end
	
		self:onUpdateRegeneration(elapsed)
		
		local ipt = self:readInput(self.activeSkillNr)
		
		self:applyMovement(elapsed, ipt)
		
		--~ -- TODO hack
		--~ if self.armor == "robe" and not the.ignorePlayerCharacterInputs then
			--~ if the.keys:justPressed ("w") then self.hidden = false end	
			--~ if the.keys:justPressed ("a") then self.hidden = false end	
			--~ if the.keys:justPressed ("s") then self.hidden = false end	
			--~ if the.keys:justPressed ("d") then self.hidden = false end	
			--~ if the.keys:justPressed ("up") then self.hidden = false end	
			--~ if the.keys:justPressed ("down") then self.hidden = false end	
			--~ if the.keys:justPressed ("left") then self.hidden = false end	
			--~ if the.keys:justPressed ("right") then self.hidden = false end	
		--~ end
		
		if self.speedOverride > 1 and self.speedOverride < config.walkspeed then 
			self.snared = true 
		else 
			self.snared = false
		end
		
		-- combat music?
		audio.isInCombat = self.isInCombat
		
		-- kill yourself with space if incap
		local Reminder = Text:extend
		{
			font = 18,
			text = "You respawn here at 50% pain. Press SPACE to teleport away.",
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
		
		-- check if we're in combat
		self.isInCombat = false
		for k,v in pairs(self.skills) do
			self.isInCombat = self.isInCombat or (v:isOutOfCombat() == false)
		end
		
		if not the.ignorePlayerCharacterInputs and the.keys:pressed(' ') and self.incapacitated then 
			object_manager.send(self.oid, "gank") 
		end
		
		-- udpate line of sight sources
		if the.lineOfSight then
			local l = object_manager.find_where(function(oid, o)
				--~ print(oid, o, o.class, o.team)
				return o.class and o.class == "Character" and o.team == self.team
			end)
			
			the.lineOfSight.sourceOids = list.keys(l)			
			the.lineOfSight.allVisible = #the.lineOfSight.sourceOids == 0
		end
		
		-- determination fades over time
		if self.determination > 0 then
			self.determination = self.determination - config.determinationFade * elapsed
		end
	end,
 
        calculateCoverOid = function (self)
            local l = object_manager.find_where(function(oid,o)
                return o.class == "Cover"
            end)

            for oid,o in pairs(l) do
                local d = collision.minDistPointToAABB(self.x, self.y, o.x, o.y, o.x+o.width, o.y+o.height)
                if d < self.width / 2 then return oid end
            end

            return nil
        end,


}
