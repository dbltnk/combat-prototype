-- Player


Player = Character:extend
{
	readInput = function (self, activeSkillNr)
		-- 0 slowest -> 1 fastest
		local speed = 0
		-- [-1,1], [-1,1]
		local movex, movey = 0,0
		-- view (mouse cursor) position
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

			local skill_keys = {
				[1] = localconfig.skillOne,
				[2] = localconfig.skillTwo,
				[3] = localconfig.skillThree,
				[4] = localconfig.skillFour,
				[5] = localconfig.skillFive,
				[6] = localconfig.skillSix,
				[7] = localconfig.skillSeven,
				[8] = localconfig.skillEight,
			}
			
			-- select a skill
			for k,v in pairs(skill_keys) do
				if the.keys:pressed(v) and not the.ignorePlayerCharacterInputs and the.player.skills[k]:isPossibleToUse() then
					the.player.selectedSkill = k
				end
			end
			
			self.selfTargetingSkill = false 
			-- find out if the currently selected skill targets self
					
			local skillObject = the.player.skills[the.player.selectedSkill]
			if utils.get_by_path(skillObject, "definition.application.target_selection.target_selection_type", false) == "self" then
				self.selfTargetingSkill = true 
			end
			

			for k,v in pairs(skill_keys) do
				if the.keys:pressed(v) and not the.ignorePlayerCharacterInputs then
					-- use the skill if it targets self
					if self.selfTargetingSkill then
						shootSkillNr = k 
						doShoot = true
						self.selfTargetingSkill = false
					end
				end
			end


			-- in all other cases only cast it on click
			if the.mouse:pressed("l") then 
				shootSkillNr = the.player.selectedSkill 
				doShoot = true 
				the.player.selectedSkill = 1 
			end
			if the.mouse:pressed("r") then 
				the.player.selectedSkill = 1 
			end
			
			if not the.ignorePlayerCharacterInputs then
				if the.keys:pressed('left', 'a') then movex = -1 end
				if the.keys:pressed('right', 'd') then movex = 1 end
				if the.keys:pressed('up', 'w') then movey = -1 end
				if the.keys:pressed('down', 's') then movey = 1 end
			end
			
			input.cursor.x = the.mouse.x
			input.cursor.y = the.mouse.y
		elseif input.getMode() == input.MODE_TOUCH then
			-- TODO
		end
		
		local worldMouseX, worldMouseY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		local cx,cy = self.x + self.width / 2, self.y + self.height / 2
		-- mouse -> player vector
		viewx, viewy = worldMouseX, worldMouseY

		if localconfig.is_bot and not the.keys:allPressed() then
			return { speed = speed, 
				movex = math.random(-1,1), movey = math.random(-1,1), 
				viewx = self.x + math.random(-1,1) * 200, viewy = self.y + math.random(-1,1) * 200, 
				doShoot = math.random(-1,1) > 0, shootSkillNr = math.floor(math.random(1,8)), } 
		end

		return { speed = speed, 
			movex = movex, movey = movey, 
			viewx = viewx, viewy = viewy, 
			doShoot = doShoot, shootSkillNr = shootSkillNr, }
	end,
	
	--~ onUpdate = function (self, elapsed)
		--~ self.prototype.prototype.onUpdate(self, elapsed)
		--~ print(self, self.prototype, self.parent, self.lala)
		--~ print(json.encode({x = self.x, y = self.y}))
	--~ end,
}

