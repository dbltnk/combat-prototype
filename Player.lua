-- Player


Player = Character:extend
{
	readInput = function (self, activeSkillNr)
		-- 0 slowest -> 1 fastest
		local speed = 0
		-- [-1,1], [-1,1]
		local movex, movey = 0,0
		-- has an arbitrary length
		local viewx, viewy = 0,0
		
		local shootSkillNr = activeSkillNr
		local doShoot = false	
		
		if input.getMode() == input.MODE_GAMEPAD then
			-- move player by axes 12
			movex = the.gamepads[1].axes[1]
			movey = the.gamepads[1].axes[2]
			local l = vector.len(movex, movey)
			if l < 0.2 then 
				speed = 0
				movex, movey = 0,0 
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

			if the.keys:pressed('left', 'a') then movex = -1 end
			if the.keys:pressed('right', 'd') then movex = 1 end
			if the.keys:pressed('up', 'w') then movey = -1 end
			if the.keys:pressed('down', 's') then movey = 1 end
			
			-- if the.keys:pressed('shift') then speed = 1 else speed = 0 end -- to-do: in eine fähigkeit umwandeln (hotbar)

			input.cursor.x = the.mouse.x
			input.cursor.y = the.mouse.y
		elseif input.getMode() == input.MODE_TOUCH then
			-- TODO
		end
		
		local worldMouseX, worldMouseY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		local cx,cy = self.x + self.width / 2, self.y + self.height / 2
		-- mouse -> player vector
		viewx, viewy = cx - (worldMouseX), cy - (worldMouseY)

		return { speed = speed, 
			movex = movex, movey = movey, 
			viewx = viewx, viewy = viewy, 
			doShoot = doShoot, shootSkillNr = shootSkillNr, }
	end,
	
	onUpdate = function (self, elapsed)
		self:onUpdateRegeneration(elapsed)
		
		self.velocity.x = 0
		self.velocity.y = 0

		local ipt = self:readInput(self.activeSkillNr)
		
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
		
		local dx,dy = ipt.viewx, ipt.viewy
		
		self.rotation = math.atan2(dy, dx) - math.pi / 2
		
		if self:isCasting() == false and ipt.doShoot and self.skills[ipt.shootSkillNr] and 
			self.skills[ipt.shootSkillNr]:isPossibleToUse()
		then
			local rot = vector.fromVisualRotation(ipt.viewx, ipt.viewy)
			local cx,cy = self.x + self.width / 2, self.y + self.height / 2
			self.skills[ipt.shootSkillNr]:use(cx, cy, rot, self)
		end
		
		-- combat music?
		local isInCombat = false
		for k,v in pairs(self.skills) do
			isInCombat = isInCombat or (v:isOutOfCombat() == false)
		end
		
		audio.isInCombat = isInCombat
	end,
}

