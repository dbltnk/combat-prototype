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

	onDie = function (self)
		the.app.view.layers.ui:remove(self)
	end,
}

local Crescent = Tile:extend
{
	x = 0, 
	y = 0, 
	width = 200, 
	height = 200,
	tint = {0,0,1},
	alpha = .25,
	image = "assets/graphics/melee_radians/90_200.png", -- TODO: remove hard-coded path
	rotation = 0,
	
	onNew = function(self)
		the.app.view.layers.ui:add(self)
	end,
	
	onUpdate = function (self)
		--~ print(self.rotation)
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
	
	onNew = function (self)
		the.app.view.layers.ui:add(self)
		local worldCursorX, worldCursorY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		self.circle = Circle:new{fill = self.fill}
		self.crescent = Crescent:new{}
	end,
	
	onUpdate = function (self)
		if the.player and the.player.class ~= "Ghost" then
	
			local noUsefulRange = 9999
		
			local worldCursorX, worldCursorY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
			
			local skillObject = the.player.skills[the.player.selectedSkill]
			
			self.maxHeight = utils.get_by_path(skillObject, "definition.application.target_selection.range", noUsefulRange)

			if self.maxHeight == noUsefulRange or utils.get_by_path(skillObject, "definition.application.target_selection.target_selection_type") ~= "projectile" then 
				self.maxHeight = 0 
			end
			
			-- arrows line part
			local playerCenterX, playerCenterY = tools.object_center(the.player)
			local distanceToCursor = vector.lenFromTo(worldCursorX, worldCursorY, playerCenterX, playerCenterY)
			self.height = math.min(distanceToCursor, self.maxHeight)
			
			local dx, dy = vector.fromToWithLen(playerCenterX, playerCenterY, worldCursorX, worldCursorY, self.height)
			local rotCenterX, rotCenterY = playerCenterX + dx / 2, playerCenterY + dy / 2
			self.x, self.y = vector.sub(rotCenterX, rotCenterY, self.width/2, self.height/2)
			
			self.rotation = vector.toVisualRotation(dx,dy)
			self.visible = true

			-- circle for PBAEs (at arrow start)
			if utils.get_by_path(skillObject, "definition.application.target_selection.target_selection_type") == "ae" then
				self.visible = false
				self.crescent.visible = false
				self.circle.visible = true				
				local range = utils.get_by_path(skillObject, "definition.application.target_selection.range", 0)
				self.circle.width = range * 2
				self.circle.height = range * 2
				self.circle.x, self.circle.y = playerCenterX - self.circle.width / 2, playerCenterY - self.circle.height / 2
			elseif utils.get_by_path(skillObject, "definition.application.target_selection.target_selection_type") == "cone" then				
				-- crescent for melee attacks
				self.visible = false				
				self.crescent.visible = true
				self.circle.visible = false
				self.crescent.x, self.crescent.y = playerCenterX - self.crescent.width / 2, playerCenterY - self.crescent.height / 2
				self.crescent.rotation = the.player.rotation
				--~ print(self.crescent.x, self.crescent.y,playerCenterX, playerCenterY,self.crescent.visible, self.crescent.alpha, self.crescent.image, self.crescent.width, self.crescent.height)
				--~ utils.vardump(self.crescent.tint)
			elseif utils.get_by_path(skillObject, "definition.application.target_selection.target_selection_type") == "self" then				
				self.visible = false				
				self.crescent.visible = false
				self.circle.visible = false	
			else
				-- circle for projectile AEs (at arrow end)
				self.visible = true			
				self.crescent.visible = false
				self.circle.visible = true				
				local range = utils.get_by_path(skillObject, "definition.application.effects.1.application.target_selection.range", 0)
				self.circle.width = range * 2
				self.circle.height = range * 2
				self.circle.x, self.circle.y = playerCenterX + dx - self.circle.width / 2, playerCenterY + dy - self.circle.height / 2
			end
		end
		
		if not the.player:isCasting() then
			self.visible = false
			self.circle.visible = false
			self.crescent.visible = false
		end
	end,
	
	onDie = function (self)
		the.app.view.layers.ui:remove(self)
		self.circle:die()
		self.crescent:die()
	end,
}
