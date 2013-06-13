-- Arrow

Arrow = Fill:extend 
{
	width = 6,
	height = 100,
	fill = {0,0,255,64},	
	border = {0,0,0,0},	
	maxHeight = 9999,
	
	onUpdate = function (self)
		local worldCursorX, worldCursorY = tools.ScreenPosToWorldPos(input.cursor.x, input.cursor.y)

		for k,v in pairs(the.player.skills[the.player.selectedSkill]) do 
			if k == "definition" then
				for key, value in pairs(v) do
					if key == "application" then
						for o, p in pairs(value) do
							if o == "target_selection" then
								for k,l in pairs(p) do
									self.maxHeight = p.range
								end
							end
						end
					end
				end
			end 
		end
		
		if self.maxHeight == 9999 then self.maxHeight = 0 end
		local distanceToCursor = vector.lenFromTo(worldCursorX, worldCursorY,the.player.x, the.player.y)
		self.height = math.min(distanceToCursor, self.maxHeight)
		
		local playerCenterX = the.player.x + the.player.width / 2
		local playerCenterY = the.player.y + the.player.height / 2
		local dx, dy = vector.fromToWithLen(playerCenterX, playerCenterY, worldCursorX, worldCursorY, self.height)
		local rx,ry = playerCenterX + dx / 2, playerCenterY + dy / 2
		self.x, self.y = vector.sub(rx,ry, self.width/2, self.height/2)
		
		self.rotation = vector.toVisualRotation(dx,dy)
	end,
	
	onNew = function (self)
		the.app.view.layers.ui:add(self)
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}
