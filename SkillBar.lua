-- SkillBar

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
		"/assets/graphics/action_icons/unknown.png",
		"/assets/graphics/action_icons/unknown.png",
	},
	
	-- contains references to SkillIcon
	skillIcons = {},
	-- inactive overlay tiles
	skillInactiveIcons = {},
	-- timeout texts
	skillTimerText = {},
	-- inactive overlay tiles
	skillSelectedIcons = {},	
	-- position
	x = love.graphics.getWidth() / 2 - SkillIcon.width / 2 * 8 - 11, -- to-do: erste 6 ersetzen durch table.getn(skills) oder ähnliche zählmethode
	y = love.graphics.getHeight()  - SkillIcon.height,
	
	onNew = function (self)
		for index, skillImage in pairs(self.skills) do
			
			-- telling the skill icon its color
			local myColors = {}
			for k,v in pairs(the.player.skills[index]) do 
				if k == "iconColor" then 
					for key, value in pairs(v) do 
						myColors[key] = utils.mapIntoRange(value, 0, 255, 0, 1) 
					end 
				end 
			end
		
			local icon = SkillIcon:new { x = 0, y = 0, color = myColors}
			the.hud:add(icon)
			
			self.skillIcons[index] = icon
			
			-- black inactive overlay
			local overlay = Tile:new{
				width = 32, height = 32, image = "/assets/graphics/skills_inactive_overlay.png",
			}
			self.skillInactiveIcons[index] = overlay
			the.hud:add(overlay)

			-- yellow overlay for selected skills
			local overlay_selected = Tile:new{
				width = 32, height = 32, image = "/assets/graphics/skills_selected_overlay.png",
			}
			self.skillSelectedIcons[index] = overlay_selected
			the.hud:add(overlay_selected)

			-- timeout text
			local t = Text:new{
				tint = {1,1,0},
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
			if index >=3 and index <=6 then space = 10 end
			if index >=7 then space = 20 end
			
			skillIcon.x = (index - 1) * 32 + self.x + space
			skillIcon.y = self.y
			
			self.skillInactiveIcons[index].x = skillIcon.x
			self.skillInactiveIcons[index].y = skillIcon.y
			
			self.skillSelectedIcons[index].x = skillIcon.x
			self.skillSelectedIcons[index].y = skillIcon.y

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
		
		-- mark selected skill as selected
		for index, overlay in pairs(self.skillSelectedIcons) do
			overlay.visible = false
			if the.player and the.player.skills and the.player.skills[index] then
				local skill = the.player.skills[index]
				--~ overlay.visible = skill:isCasting() == false and skill:isPossibleToUse() == false
				--~ print(skill)
				if index == the.player.selectedSkill then
					--~ overlay.visible = true
				else
					overlay.visible = false
				end
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
