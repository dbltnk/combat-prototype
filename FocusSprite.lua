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
		
		-- don't go beyond the map borders
		self.x = utils.clamp(x,love.graphics.getWidth() / 2, 3200 - love.graphics.getWidth() / 2) -- TODO: make this dynamic, map size currently 3200x3200
		self.y = utils.clamp(y,love.graphics.getHeight() / 2, 3200 - love.graphics.getHeight() / 2) -- TODO: make this dynamic, map size currently 3200x3200 
		
		-- equal sight range in both x and y directions
		local px, py = tools.object_center (the.player)
		local cap = math.min(love.graphics.getWidth(), love.graphics.getHeight()) / config.focusSpriteMaxRange
		local widthToHeightRatio = love.graphics.getWidth() / love.graphics.getHeight()
		if widthToHeightRatio >= 1 then
			-- widescreen monitor
			self.x = utils.clamp(self.x, px - cap / widthToHeightRatio, px + cap / widthToHeightRatio)
			self.y = utils.clamp(self.y, py - cap, py + cap)
		else
			-- you turned your monitor by 90 degrees
			self.x = utils.clamp(self.x, px - cap, px + cap)
			self.y = utils.clamp(self.y, py - cap * widthToHeightRatio, py + cap * widthToHeightRatio)
		end
		
		-- dirty hack to prevent the camera from leaving the map
		w = love.graphics.getWidth()
		h = love.graphics.getHeight()
		if self.x < w/2 then self.x = w/2 end
		if self.y < h/2 then self.y = h/2 end
		if self.x > 3200 - w/2 then self.x = 3200 - w/2 end
		if self.y > 3200 - h/2 then self.y = 3200 - h/2 end
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}
