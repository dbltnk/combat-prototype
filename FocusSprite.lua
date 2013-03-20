-- FocusSprite


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
		self.x = utils.clamp(x,love.graphics.getWidth() / 2, 3200 - love.graphics.getWidth() / 2) -- TODO: make this dynamic, map size currently 3200x3200
		self.y = utils.clamp(y,love.graphics.getHeight() / 2, 3200 - love.graphics.getHeight() / 2) -- TODO: make this dynamic, map size currently 3200x3200 
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}
