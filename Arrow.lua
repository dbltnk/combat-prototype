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
		--~ local x,y = 0,0
		--~ -- weighted average
		--~ x,y = vector.add(x,y, vector.mul(worldCursorX, worldCursorY, 0.45))
		--~ x,y = vector.add(x,y, vector.mul(the.player.x, the.player.y, 0.55))
		--~ self.x = utils.clamp(x,love.graphics.getWidth() / 2, 3200 - love.graphics.getWidth() / 2) -- TODO: make this dynamic, map size currently 3200x3200
		--~ self.y = utils.clamp(y,love.graphics.getHeight() / 2, 3200 - love.graphics.getHeight() / 2) -- TODO: make this dynamic, map size currently 3200x3200 
		
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
		
		--~  erster versuch
		--~ local playerCenterX = the.player.x - the.player.width / 2
		--~ local playerCenterY = the.player.y - the.player.height / 2
		--~ local dx, dy = vector.fromToWithLen(the.player.x, the.player.y, worldCursorX, worldCursorY, self.height)
		--~ self.x, self.y = the.player.x + dx, the.player.y + dy

		--~ zweiter versuch
		--~ self.x = the.player.x + (the.player.x - worldCursorX) / 2 -- - self.width / 2
		--~ self.y = the.player.y + (the.player.y - worldCursorY) / 2 -- - self.height / 2		
		
		--~ notlösung
		self.x = the.focusSprite.x - self.width / 2
		self.y = the.focusSprite.y - self.height / 2
		
		--~ print(the.player.x, worldCursorX, self.x, the.player.y, worldCursorY, self.y)
		
		self.rotation = the.player.rotation
	end,
	
	onNew = function (self)
		the.app.view.layers.ui:add(self)
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}
