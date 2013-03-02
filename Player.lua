-- Player


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
	
	loudness = config.volume,	
	loudness_is_fading = false,
	
	onNew = function (self)
		for k,v in pairs(self.skills) do
			self.skills[k] = Skill:new { nr = k, id = v }
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
		
		-- not fading and wrong loudness?
		if self.loudness_is_fading == false and math.abs(newLoundness - self.loudness) > 0.01 then
			-- start fade
			self.loudness_is_fading = true
			the.view.tween:start(self, "loudness", newLoundness, fadeTime)
				:andThen(function() self.loudness_is_fading = false end)
		end

		the.peaceMusic:setVolume(self.loudness)
		the.combatMusic:setVolume(1 - self.loudness)
	end,
}

