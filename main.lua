STRICT = true
DEBUG = true

-- local profiler = require 'profiler'
--~ profiler.start('profile.out')
require 'zoetrope'

local vector = require 'vector'
local utils = require 'utils'
local config = require 'config'
local input = require 'input'
local tween = require 'tween'
local action_definitions = require 'action_definitions'

local object_manager = require 'object_manager'
local action_handling = require 'action_handling'
local tools = require 'tools'
local profile = require 'profile'

require 'actions'

volume = 0.3



Skill = Class:extend
{
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
		return love.timer.getTime() - self.lastUsed >= self.timeout and the.player.currentEnergy >= self.energyCosts 
	end,
	
	timeTillCastFinished = function (self)
		return math.max(0, self.lastUsed + self.cast_time - love.timer.getTime())
	end,
	
	timeTillPossibleToUse = function (self)
		return math.max(0, self.lastUsed + self.timeout - love.timer.getTime())
	end,
	
	freezeMovementDuringCasting = function (self)
		return true
	end,
	
	use = function (self, x, y, rotation, player)
		if self:freezeMovementDuringCasting() then player:freezeMovement() end
		print("SKILL", self.nr, "START USING")
		
		self.source.x = x
		self.source.y = y
		self.source.rotation = rotation
		self.source.player = player
		
		self.lastUsed = love.timer.getTime()
		if self.onUse then 
			-- call use after casttime timeout
			the.app.view.timer:after(self.cast_time, function() 
				if self:freezeMovementDuringCasting() then player:unfreezeMovement() end
				print("SKILL", self.nr, "REALLY USE")
				self:onUse()
				the.player.currentEnergy = the.player.currentEnergy - self.energyCosts
			end)
		end
	end,
}

SkillFromDefintion = Skill:extend
{
	-- required
	id = nil,
	-- ---------------
	-- see action_definitions.lua
	definition = nil,

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
		local startTarget = { oid = the.player.oid }
		action_handling.start(self.definition.application, startTarget)
		print("out of combat:", self:isOutOfCombat())
	end,

	isOutOfCombat = function (self)
		return love.timer.getTime() - self.lastUsed >= self.combatTimer
	end,	
}

SkillIcon = Animation:extend
{
	width = 32,
	height = 32,
	image = "/assets/graphics/action_icons/unknown.png",
	sequences = 
	{
		available = { frames = {1}, fps = 1 },
		casting = { frames = {1}, fps = 1 },
		disabled = { frames = {1}, fps = 1 },
	},
	
	onNew = function (self)
		
	end,
	
	setSkill = function (self, image)
		self.image = image
	end,
}

SkillBar = Class:extend
{
	-- skill nrs
	skills = {
		"/assets/graphics/action_icons/unknown.png",
		"/assets/graphics/action_icons/unknown.png",
		"/assets/graphics/action_icons/unknown.png",
		"/assets/graphics/action_icons/unknown.png",
		"/assets/graphics/action_icons/unknown.png",
		"/assets/graphics/action_icons/unknown.png",
--~ 		"/assets/graphics/action_icons/unknown.png",
	},
	
	-- contains references to SkillIcon
	skillIcons = {},
	-- inactive overlay tiles
	skillInactiveIcons = {},
	-- timeout texts
	skillTimerText = {},
	
	-- position
	x = love.graphics.getWidth() / 2 - SkillIcon.width / 2 * 6, -- to-do: 6 ersetzen durch table.getn(skills) oder ähnliche zählmethode
	y = love.graphics.getHeight()  - SkillIcon.height,
	
	onNew = function (self)
		for index, skillImage in pairs(self.skills) do
			local icon = SkillIcon:new { x = 0, y = 0 }
			the.hud:add(icon)
			
			self.skillIcons[index] = icon
			
			-- black inactive overlay
			local overlay = Tile:new{
				width = 32, height = 32, image = "/assets/graphics/skills_inactive_overlay.png",
			}
			self.skillInactiveIcons[index] = overlay
			the.hud:add(overlay)

			-- timeout text
			local t = Text:new{
				font = 14,
				text = "X",
			}
			self.skillTimerText[index] = t
			the.hud:add(t)
		end
		
		self:setPosition (self.x, self.y)
		self:setSkills (self.skills)
	end,
	
	setPosition = function (self, x, y)
		self.x = x
		self.y = y
		
		for index, skillIcon in pairs(self.skillIcons) do
			local space = 0
			if index >=3 then space = 10 end
			
			skillIcon.x = (index - 1) * 32 + self.x + space
			skillIcon.y = self.y
			
			self.skillInactiveIcons[index].x = skillIcon.x
			self.skillInactiveIcons[index].y = skillIcon.y

			self.skillTimerText[index].x = skillIcon.x + 8
			self.skillTimerText[index].y = skillIcon.y + 8
		end
	end,
	
	setSkills = function (self, skills)
		self.skills = skills
		
		for index, skillImage in pairs(self.skills) do
			self.skillIcons[index]:setSkill(skillImage)
		end
	end,
	
	onUpdate = function (self, elapsed)
		-- mark inactive skill as inactive
		for index, overlay in pairs(self.skillInactiveIcons) do
			if the.player and the.player.skills and the.player.skills[index] then
				local skill = the.player.skills[index]
				overlay.visible = skill:isCasting() == false and skill:isPossibleToUse() == false
			end
		end
		
		-- show timeout
		for index, timeout in pairs(self.skillTimerText) do
			if the.player and the.player.skills and the.player.skills[index] then
				local skill = the.player.skills[index]
				timeout.visible = skill:isCasting() or skill:isPossibleToUse() == false
				
				local c = skill:timeTillCastFinished()
				local t = skill:timeTillPossibleToUse()
				
				if c > 0 then t = c end
				
				if t >= 10 then
					timeout.text = string.format("%0.0f", t)
				else
					timeout.text = string.format("%0.1f", t)
				end
			end
		end
	end,
}

TargetDummy = Tile:extend
{
	image = '/assets/graphics/dummy.png',
	currentPain = 0,
	maxPain = 100,
	pb = nil,
	pbb = nil,
	wFactor = 0.30,
	movable = false,
	
	onNew = function (self)
		the.targetDummies[self] = true
		
		self.width = 32
		self.height = 64
		self:updateQuad()
		object_manager.create(self)
		--print("NEW DUMMY", self.x, self.y, self.width, self.height)
		the.view.layers.characters:add(self)
		self.pb = PainBar:new{x = self.x, y = self.y, width = self.currentPain * self.wFactor}
		self.pbb = PainBarBG:new{x = self.x, y = self.y, width = self.maxPain * self.wFactor}
		the.view.layers.ui:add(self.pbb)
		the.view.layers.ui:add(self.pb)
		self:updateBarPositions()
		drawDebugWrapper(self)
		if (math.random(-1, 1) > 0) then self.movable = true end
	end,
	
	updateBarPositions = function (self)
		self.pb.x = self.x
		self.pb.y = self.y + 64
		self.pbb.x = self.x
		self.pbb.y = self.y + 64
	end,
	
	gainPain = function (self, str)
		print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
	end,
	
	receive = function (self, message_name, ...)
		print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str = ...
			print("DUMMY HEAL", str)
		elseif message_name == "damage" then
			local str = ...
			print("DUMMY DAMANGE", str)
			self:gainPain(str)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks = ...
			print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(str)
				end)
			end
		elseif message_name == "runspeed" then
			local str, duration = ...
			print("DUMMY SPEED", str, duration)
		end
	end,
	
	updatePain = function (self)
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			self:die()
		else
			self.pb.width = self.currentPain * self.wFactor
		end	
	end,
	
	onDie = function (self)
		self.pb:die()
		self.pbb:die()		
		
		the.targetDummies[self] = nil
	end,
	
	onUpdate = function (self)
		if ((math.random(-1, 1) > 0) and self.movable == true) then
			self.dx = math.random(-10, 10)
			self.dy = math.random(-10, 10)
			self.x = self.x + self.dx
			self.y = self.y + self.dy
		end
		
		self:updateBarPositions()
	end,	
}

PainBar = Fill:extend
{
	width = 0,
	height = 5,
	fill = {255,0,0,255},
	border = {0,0,0,255}	
}

PainBarBG = Fill:extend
{
	width = 0,
	height = 5,
	fill = {0,255,0,255},
	border = {0,0,0,255}
}

Player = Animation:extend
{
	maxPain = config.maxPain, 
	currentPain = 0,
	maxEnergy = config.maxEnergy, 
	currentEnergy = config.maxEnergy, 

	-- list of Skill
	skills = {
		"bow_shot",
		"shield_bash",		
--~ 		"scythe_attack",
		-- "scythe_pirouette",
		"bandage",
		"sprint",
		"fireball",
		"xbow_piercing_shot",
		--~ "life_leech",
	},
	

	activeSkillNr = 1,
	
	width = 64,
	height = 64,
	image = '/assets/graphics/player.png', -- source: http://www.synapsegaming.com/forums/t/1711.aspx

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
	
	makeStep = function (self)
		self.lastFootstep = love.timer.getTime()
	end,
	
	loudness = volume,	
	loudness_is_fading = false,
	
	onNew = function (self)
		for k,v in pairs(self.skills) do
			self.skills[k] = SkillFromDefintion:new { nr = k, id = v }
		end
		drawDebugWrapper(self)
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
	
	onUpdate = function (self, elapsed)
	
		self.velocity.x = 0
		self.velocity.y = 0

		-- 0 slowest -> 1 fastest
		local speed = 0
		-- -1->1, -1->1
		local dirx, diry = 0,0
		
		local shootSkillNr = self.activeSkillNr
		local doShoot = false
		
		tween.update(elapsed)
		
		if input.getMode() == input.MODE_GAMEPAD then
			-- move player by axes 12
			dirx = the.gamepads[1].axes[1]
			diry = the.gamepads[1].axes[2]
			local l = vector.len(dirx, diry)
			if l < 0.2 then 
				speed = 0
				dirx, diry = 0,0 
			else
				speed = utils.mapIntoRange (l, 0, 1, 0,1)
			end
			
			-- move cursor by axes 34
			local curx = the.gamepads[1].axes[5]
			local cury = the.gamepads[1].axes[4]
			local cur = vector.len(curx, cury)
			if cur < 0.2 then 
				curx, cury = 0,0 
			else
				-- adjust speed depending on cursor-player-distance
				local speed = 0
				local len = vector.lenFromTo (self.x, self.y, tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y))
				
				if len < config.gamepad_cursor_near_distance - config.gamepad_cursor_near_border / 2 then
					-- near
					speed = config.gamepad_cursor_speed_near
				elseif len < config.gamepad_cursor_near_distance + config.gamepad_cursor_near_border / 2 then
					-- blend
					local border = len - (config.gamepad_cursor_near_distance - config.gamepad_cursor_near_border / 2)
					speed = utils.mapIntoRange (border, 0, config.gamepad_cursor_near_border, 
						config.gamepad_cursor_speed_near, config.gamepad_cursor_speed_far)
				else
					-- far
					speed = config.gamepad_cursor_speed_far
				end
				
				cur = utils.mapIntoRange (cur, 0, 1, 0, speed)
				curx, cury = vector.normalizeToLen(curx, cury, cur * elapsed)
			end
			
			input.cursor.x, input.cursor.y = vector.add(input.cursor.x, input.cursor.y, curx, cury)

			-- clamp cursor distance
			local dx,dy = vector.fromTo (self.x, self.y, tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y))
			
			if vector.len(dx, dy) > 0 then
				local f = 4/5
				local maxdx,maxdy = the.app.width * f, the.app.height * f
				local l = vector.len(dx,dy)
				
				if math.abs(dx) > maxdx then
					local newL = l * utils.sign(dx) * maxdx / dx
					dx, dy = vector.normalizeToLen (dx, dy, newL)
					l = newL
				end
				
				if math.abs(dy) > maxdy then
					local newL = l * utils.sign(dy) * maxdy / dy
					dx, dy = vector.normalizeToLen (dx, dy, newL)
				end

				input.cursor.x, input.cursor.y = tools.WorldPosToScreenPos(vector.add(self.x, self.y, dx,dy))
			end
			
			-- shoot?
			--doShoot = the.gamepads[1].axes[3] > 0.2
			if the.gamepads[1].axes[3] > 0.2 then shootSkillNr = 1 doShoot = true end
			--if the.gamepads[1].axes[6] > 0.2 then shootSkillNr = 2 doShoot = true end
			if the.gamepads[1]:pressed(1) then shootSkillNr = 3 doShoot = true end
			if the.gamepads[1]:pressed(2) then shootSkillNr = 4 doShoot = true end
			if the.gamepads[1]:pressed(3) then shootSkillNr = 5 doShoot = true end
			if the.gamepads[1]:pressed(4) then shootSkillNr = 6 doShoot = true end
--~ 			if the.gamepads[1]:pressed(5) then shootSkillNr = 7 doShoot = true end
--~ 			if the.gamepads[1]:pressed(6) then shootSkillNr = 8 doShoot = true end
--~ 			if the.gamepads[1]:pressed(7) then shootSkillNr = 9 doShoot = true end
			
-- debugging code for gamepad's missing axis 6 aka shoulder button R			
--~ 			if the.gamepads[1].axes[1] > 0.2 then print("axes 1:  " .. the.gamepads[1].axes[1]) end
--~ 			if the.gamepads[1].axes[2] > 0.2 then print("axes 2:  " .. the.gamepads[1].axes[2]) end
--~ 			if the.gamepads[1].axes[3] > 0.2 then print("axes 3:  " .. the.gamepads[1].axes[3]) end
--~ 			if the.gamepads[1].axes[4] > 0.2 then print("axes 4:  " .. the.gamepads[1].axes[4]) end
--~ 			if the.gamepads[1].axes[5] > 0.2 then print("axes 5:  " .. the.gamepads[1].axes[5]) end		
		--	if the.gamepads[1].axes[6] > 0.2 then print("axes 6:  " .. the.gamepads[1].axes[6]) end
			
			
			
		elseif input.getMode() == input.MODE_MOUSE_KEYBOARD then
			if the.mouse:pressed('l') then shootSkillNr = 1 doShoot = true end
			if the.mouse:pressed('r') then shootSkillNr = 2 doShoot = true end
			if the.keys:pressed('1') then shootSkillNr = 3 doShoot = true end
			if the.keys:pressed('2') then shootSkillNr = 4 doShoot = true end
			if the.keys:pressed('3') then shootSkillNr = 5 doShoot = true end
			if the.keys:pressed('4') then shootSkillNr = 6 doShoot = true end
--~ 			if the.keys:pressed('5') then shootSkillNr = 7 doShoot = true end
--~ 			if the.keys:pressed('6') then shootSkillNr = 8 doShoot = true end
--~ 			if the.keys:pressed('7') then shootSkillNr = 9 doShoot = true end

			if the.keys:pressed('left', 'a') then dirx = -1 end
			if the.keys:pressed('right', 'd') then dirx = 1 end
			if the.keys:pressed('up', 'w') then diry = -1 end
			if the.keys:pressed('down', 's') then diry = 1 end
			
			-- if the.keys:pressed('shift') then speed = 1 else speed = 0 end -- to-do: in eine fähigkeit umwandeln (hotbar)

			input.cursor.x = the.mouse.x
			input.cursor.y = the.mouse.y
		elseif input.getMode() == input.MODE_TOUCH then
			-- TODO
		end
		
		if ((the.gamepads[1]:pressed('left','right','up','down') and input.getMode() == input.MODE_GAMEPAD) or (the.keys:pressed('left', 'a','right', 'd','up', 'w','down', 's') and input.getMode() == input.MODE_MOUSE_KEYBOARD)) and self:footstepsPossible() then 
			local footstep = Footstep:new{ 
				x = self.x+17, y = self.y+15, 
				rotation = self.rotation,
			}
			the.app.view.layers.ground:add(footstep)
			the.footsteps[footstep] = true
			self:makeStep()
		end
		
		-- move into direction?
		if self.freezeMovementCounter == 0 and vector.len(dirx, diry) > 0 then
			-- replace second 0 by a 1 to toggle runspeed to analog
			local s = config.walkspeed -- utils.mapIntoRange (speed, 0, 0, config.walkspeed, config.runspeed)
			
			-- patched speed?
			if self.speedOverride and self.speedOverride > 0 then s = self.speedOverride end
			
			self.velocity.x, self.velocity.y = vector.normalizeToLen(dirx, diry, s)
			
			local animspeed = utils.mapIntoRange (speed, 0, 1, config.animspeed, config.animspeed * config.runspeed / config.walkspeed)
			
			self:play('walk')
		else
			self:freeze(5)
		end
		
		local worldMouseX, worldMouseY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		local cx,cy = self.x + self.width / 2, self.y + self.height / 2
		-- mouse -> player vector
		local dx,dy = cx - (worldMouseX), cy - (worldMouseY)
		
		self.rotation = math.atan2(dy, dx) - math.pi / 2
		
		local isCasting = false
		for k,v in pairs(self.skills) do
			isCasting = isCasting or v:isCasting()
		end
		
		if isCasting == false and doShoot and self.skills[shootSkillNr] and 
			self.skills[shootSkillNr]:isPossibleToUse()
		then
			self.skills[shootSkillNr]:use(cx, cy, self.rotation, self)
		end

		-- energy regeneration
		if self.currentEnergy < 0 then self.currentEnergy = 0 end
		if isCasting == false then self.currentEnergy = self.currentEnergy + config.energyreg end
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

		-- combat music fade in/out 		
		local fadeTime = 3
		
		-- music handling
		local isInCombat = false
		for k,v in pairs(self.skills) do
			isInCombat = isInCombat or (v:isOutOfCombat() == false)
		end
		
		local newLoundness = (isInCombat and 0) or 1
		--~ local newLoundness = 1
		--~ if isInCombat then newLoundness = 0 end
		
		-- not fading and wrong loudness?
		if self.loudness_is_fading == false and math.abs(newLoundness - self.loudness) > 0.01 then
			-- start fade
			self.loudness_is_fading = true
			tween(fadeTime, self, {loudness = newLoundness}, nil, function() self.loudness_is_fading = false end)
		end

		the.peaceMusic:setVolume(self.loudness)
		the.combatMusic:setVolume(1 - self.loudness)
	end,
}

FocusSprite = Sprite:extend 
{
	width = 1,
	height = 1,
	
	onUpdate = function (self)
		local worldCursorX, worldCursorY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		local x,y = 0,0
		-- weighted average
		x,y = vector.add(x,y, vector.mul(worldCursorX, worldCursorY, 0.45))
		x,y = vector.add(x,y, vector.mul(the.player.x, the.player.y, 0.55))
		self.x, self.y = x,y
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}

Cursor = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/cursor.png',
    
	onUpdate = function (self)
		self.x = input.cursor.x - self.width / 2
		self.y = input.cursor.y - self.height / 2
		self.x, self.y = tools.ScreenPosToWorldPos(self.x, self.y)
	end
}

drawDebugWrapper = function (sprite)
	local oldDraw = sprite.draw
	sprite.draw = function(self,x,y)
		if not config.draw_debug_info then oldDraw(self,x,y) return end
	
		x = math.floor(x or self.x)
		y = math.floor(y or self.y)
		local w = self.width or 1
		local h = self.height or 1
		oldDraw(self,x,y)
		
		local c = {love.graphics.getColor()}
		
		love.graphics.setColor(255, 0, 0)
		love.graphics.circle("fill", x, y, 3, 10)
		
		love.graphics.setColor(0, 255, 0)
		love.graphics.circle("fill", x+w/2, y+h/2, 3, 10)

		love.graphics.setColor(0, 0, 255)
		love.graphics.rectangle("line", x, y, w, h )
		 
		love.graphics.setColor(c)
	end
end

Projectile = Tile:extend
{
	width = 32,
	height = 32,
	--~ image = '/assets/graphics/action_projectiles/bow_shot_projectile.png',
    -- target.x target.y start.x start.y

	onCollide = function(self, other, horizOverlap, vertOverlap)
		self:die()
	end,
	
	onUpdate = function (self)
		local totalDistance = vector.lenFromTo(self.start.x, self.start.y, self.target.x, self.target.y)
		local distFromStart = vector.lenFromTo(self.start.x, self.start.y, self.x, self.y)
		
		if distFromStart >= totalDistance then
			self:die()
		end
	end,
	
	onDie = function (self)
		-- not possible to revive them later
		the.app.view.layers.projectiles:remove(self)
		-- will remove the projectile reference from the map
		the.projectiles[self] = nil	
	end,
	
	onNew = function (self)
		the.app.view.layers.projectiles:add(self)
		-- stores an projectile reference, projectiles get stored in the key
		the.projectiles[self] = true
		
		drawDebugWrapper(self)
	end,
}

Footstep = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
}

UiGroup = Group:extend
{
	solid = false,

	onUpdate = function(self)
		local x,y = tools.ScreenPosToWorldPos(0,0)
		self.translate.x = x
		self.translate.y = y
	end,
}

PlayerDetails = Tile:extend
{
	width = 128,
	height = 128,
	image = '/assets/graphics/player_details.png',
    
	onUpdate = function (self)
		self.x = the.player.x - the.player.width / 1.5
		self.y = the.player.y - the.player.height / 1.5
	end
}

--~ DebugPoint = Tile:extend
--~ {
	--~ width = 32,
	--~ height = 32,
	--~ image = '/assets/graphics/debugpoint.png',
--~ }

ControlUI = Tile:extend
{
	width = 212,
	height = 54,
	image = '/assets/graphics/controls_mouse.png',
    
	onUpdate = function (self)
		self.x = love.graphics.getWidth() / 2 - self.width / 2  -- the.app.height
		self.y = love.graphics.getHeight() - self.height  -- the.app.height
		if input.getMode() == 2 then
			self.image = '/assets/graphics/controls_gamepad.png'
			elseif input.getMode() == 1 then
			self.image = '/assets/graphics/controls_mouse.png'
		end
	end
}

EnergyUIBG = Fill:extend
{
	width = 1,
	height = 20,
	fill = {0,128,128,255},	
	border = {0,0,0,255},
	t = Text:new{
				font = 14,
				text = "xxx",
				x = 0,
				y = 0, 
			},
	
	onNew = function(self)
		the.hud:add(self.t)	 --TODO: in der render-reihenfolge nach oben, aktuell nicht sichtbar
	end,	
    
	onUpdate = function (self)
		self.x = love.graphics.getWidth() - self.width 
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.maxEnergy / the.player.maxEnergy * (love.graphics.getWidth() - the.controlUI.width) / 2
		self.t.text = "Fatigue: " .. the.player.currentEnergy .. " / " .. the.player.maxEnergy
		self.t.x = love.graphics.getWidth() / 4 * 3 - self.t.width / 2
		self.t.y = love.graphics.getHeight() - self.height
		self.t.width = 150
	end
}

EnergyUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {0,0,255,255},	
	border = {0,0,0,255},
		
	onUpdate = function (self)
		self.x = love.graphics.getWidth() - self.width 
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.currentEnergy / the.player.maxEnergy * (love.graphics.getWidth() - the.controlUI.width) / 2
		if self.width <= 2 then self.width = 2 end
	end
}

PainUIBG = Fill:extend
{
	width = 1,
	height = 20,
	fill = {0,255,0,255},	
	border = {0,0,0,255},
    
	onUpdate = function (self)
		self.x = 0
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.maxPain / the.player.maxPain * (love.graphics.getWidth() - the.controlUI.width) / 2
	end
}

PainUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {255,0,0,255},	
	border = {0,0,0,255},
	t = Text:new{
				font = 14,
				text = "xxx",
				x = 0,
				y = 0, 
			},
	
	onNew = function(self)
		the.hud:add(self.t)	-- TODO: über die rote pain bar in der rendereihenfolge
	end,
	
	onUpdate = function (self)
		self.x = 0
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.currentPain / the.player.maxPain * (love.graphics.getWidth() - the.controlUI.width) / 2
		if self.width <= 2 then self.width = 2 end
		self.t.text = "Pain: " .. the.player.currentPain .. " / " .. the.player.maxPain
		self.t.x = love.graphics.getWidth() / 4 - self.t.width / 2
		self.t.y = love.graphics.getHeight() - self.height
		self.t.width = 150
	end
}

GameView = View:extend
{
	layers = {
		ground = Group:new(),
		characters = Group:new(),
		projectiles = Group:new(),
		above = Group:new(),
		ui = Group:new(),
	},

    onNew = function (self)
		-- object -> true map for easy remove, key contains projectile reference
		the.projectiles = {}
		
		-- object -> true map for easy remove, key contains projectile reference
		the.targetDummies = {}
		
		-- object -> true map for easy remove, key contains footstep reference
		the.footsteps = {}
		
		self:loadLayers('/assets/maps/desert/desert.lua', true)
		
		self.collision.visible = false
		self.objects.visible = false
		
		-- specify render order
		self:add(self.layers.ground)
		self:add(self.layers.characters)
		self:add(self.layers.projectiles)
		self:add(self.layers.above)
		self:add(self.layers.ui)
		
		-- setup player
		the.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2 }
		--~ the.dummy = TargetDummy:new{ x = the.app.width / 2, y = the.app.height / 2 }
		object_manager.create(the.player)
		--~ object_manager.create(the.dummy)		
		self.layers.characters:add(the.player)
		--~ self.layers.characters:add(the.dummy)		
		self.layers.above:add(self.trees)	
		self.layers.above:add(self.buildings)		
		-- set spawn position
		the.player.x = the.spawnpoint.x
		the.player.y = the.spawnpoint.y
		

		--~ the.dummy.x = the.dummySpawnpoint.x
		--~ the.dummy.y = the.dummySpawnpoint.y
		
		the.cursor = Cursor:new{ x = 0, y = 0 }
		self.layers.ui:add(the.cursor)
		
		--~ self.debugpoint = DebugPoint:new{ x = 0, y = 0 }
		--~ self:add(self.debugpoint)
		
		the.focusSprite = FocusSprite:new{ x = 0, y = 0 }
		self:add(the.focusSprite)
		
		self.focus = the.focusSprite
		
		-- TODO obsolete? use self.layers instead?
		the.hud = UiGroup:new()
		self:add(the.hud)
		
		the.skillbar = SkillBar:new()
		-- set skillbar images
		local skills = {}
		for k,v in pairs(the.player.skills) do
			--print(k, v)
			table.insert(skills, action_definitions[v.id].icon)
		end
		the.skillbar:setSkills(skills)
		
		--the.playerDetails = PlayerDetails:new{ x = 0, y = 0 }
		--self.layers.ui:add(the.playerDetails)
		
		the.controlUI = ControlUI:new{}
		the.hud:add(the.controlUI)
		
		the.energyUIBG = EnergyUIBG:new{}
		the.hud:add(the.energyUIBG)		
		the.energyUI = EnergyUI:new{}
		the.hud:add(the.energyUI)
		
		the.painUIBG = PainUIBG:new{}
		the.hud:add(the.painUIBG)		
		the.painUI = PainUI:new{}
		the.hud:add(the.painUI)					
		
		the.peaceMusic = playSound('/assets/audio/eots.ogg', volume, 'long') -- Shadowbane Soundtrack: Eye of the Storm
		the.peaceMusic:setLooping(true)

		the.combatMusic = playSound('/assets/audio/dos.ogg', 0, 'long') -- Shadowbane Soundtrack: Dance of Steel
		the.combatMusic:setLooping(true)

		
    end,
    
    onUpdate = function (self, elapsed)
		profile.start("update.skillbar")
		the.skillbar:onUpdate(elapsed)
		profile.stop()
		
		profile.start("update.displace")
		
		for dummy,v in pairs(the.targetDummies) do
			self.collision:displace(dummy)
			self.layers.characters:displace(dummy)
			self.landscape:subdisplace(dummy)
			self.water:subdisplace(dummy)		
		end
		
		self.collision:displace(the.player)
		self.layers.characters:displace(the.player)
		self.landscape:subdisplace(the.player)
		self.water:subdisplace(the.player)
		
		profile.stop()
		
		profile.start("update.projectile")
		for projectile,v in pairs(the.projectiles) do
			self.landscape:subcollide(projectile)
			self.collision:collide(projectile)
			self.layers.characters:collide(projectile)
		end
		profile.stop()
		
		if config.show_profile_info then profile.print() end
		profile.clear()
    end,
}

the.app = App:new
{
	numGamepads = love.joystick and 1 or 0,
	name = "Combat Prototype",
	icon = '/graphics/icon.png',

	onUpdate = function (self, elapsed)
		-- set input mode
		if the.keys:justPressed ("f1") then print("input mode: mouse+keyboard") input.setMode (input.MODE_MOUSE_KEYBOARD) end
		if the.keys:justPressed ("f2") and the.gamepads[1].name ~= "NO DEVICE CONNECTED" then print("input mode: gamepad") input.setMode (input.MODE_GAMEPAD) end
		if the.keys:justPressed ("f3") then print("input mode: touch") input.setMode (input.MODE_TOUCH) end	
		
		-- debug cheats
		if the.keys:justPressed ("f5") then the.player.currentPain = the.player.currentPain + 20 end	
					
		-- toggle fullscreen
		if the.keys:justPressed ("f10") then self:toggleFullscreen() end
		
		-- toggle profile
		if the.keys:justPressed ("f11") then config.show_profile_info = not config.show_profile_info end
		-- toggle debug draw
		if the.keys:justPressed ("f12") then config.draw_debug_info = not config.draw_debug_info end

		-- easy exit
		if the.keys:pressed('escape') then 
			--~ profiler.stop()
			os.exit() 
		end
	end,

    onRun = function (self)
		-- disable the hardware cursor
		self:useSysCursor(false)
		
		the.app.console:watch("viewx", "the.view.translate.x")
		the.app.console:watch("viewy", "the.view.translate.y")
		
		-- setup background
		self.view = GameView:new()
    end
}
