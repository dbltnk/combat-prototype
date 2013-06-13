-- Arrow

local Circle = Fill:extend
{ 
	shape="circle", 
	x = 0, 
	y = 0, 
	width = 0, 
	height = 0,
	border = {0,0,0,0}, 
	fill = {0,0,0,0},
	
	onNew = function(self)
		the.app.view.layers.ui:add(self)
	end,
	
	onUpdate = function (self)
	
	end,
}

local Crescent = Sprite:extend
{
	x = 0, 
	y = 0, 
	width = 0, 
	height = 0,
	tint = {0,0,0,0},
	image = nil,
	rotation = 0,
	
	onNew = function(self)
		the.app.view.layers.ui:add(self)
	end,
	
	onUpdate = function (self)
	
	end,
	
	onDie = function(self)
		the.app.view.layers.ui:remove(self)
	end,
}

Arrow = Fill:extend 
{
	width = 6,
	height = 100,
	fill = {0,0,255,64},	
	border = {0,0,0,0},	
	maxHeight = 9999,
	circle = nil,
	
	onUpdate = function (self)
		local worldCursorX, worldCursorY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		local skillObject = the.player.skills[the.player.selectedSkill]
		
		self.maxHeight = utils.get_by_path(skillObject, "definition.application.target_selection.range", 9999)

		if self.maxHeight == 9999 or utils.get_by_path(skillObject, "definition.application.target_selection.target_selection_type", 9999) ~= "projectile" then self.maxHeight = 0 end
		local distanceToCursor = vector.lenFromTo(worldCursorX, worldCursorY,the.player.x, the.player.y)
		self.height = math.min(distanceToCursor, self.maxHeight)
		
		local playerCenterX = the.player.x + the.player.width / 2
		local playerCenterY = the.player.y + the.player.height / 2
		local dx, dy = vector.fromToWithLen(playerCenterX, playerCenterY, worldCursorX, worldCursorY, self.height)
		local rx,ry = playerCenterX + dx / 2, playerCenterY + dy / 2
		self.x, self.y = vector.sub(rx,ry, self.width/2, self.height/2)
		
		self.rotation = vector.toVisualRotation(dx,dy)

		-- circle for PBAEs
		if utils.get_by_path(skillObject, "definition.application.target_selection.target_selection_type", "") == "ae" then
			self.circle.width = utils.get_by_path(skillObject, "definition.application.target_selection.range", 0) * 2
			self.circle.height = utils.get_by_path(skillObject, "definition.application.target_selection.range", 0) * 2
			self.circle.x, self.circle.y = playerCenterX - self.circle.width / 2, playerCenterY - self.circle.height / 2
		else
			-- circle for projectile AEs
			self.circle.width = utils.get_by_path(skillObject, "definition.application.effects.1.application.target_selection.range", 0) * 2
			self.circle.height = utils.get_by_path(skillObject, "definition.application.effects.1.application.target_selection.range", 0) * 2
			self.circle.x, self.circle.y = playerCenterX + dx - self.circle.width / 2, playerCenterY + dy - self.circle.height / 2
		end
	end,
	
	onNew = function (self)
		the.app.view.layers.ui:add(self)
		local worldCursorX, worldCursorY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		self.circle = Circle:new{fill = self.fill}
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}
