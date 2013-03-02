-- debug stuff


drawDebugWrapper = function (sprite)
	local oldDraw = sprite.draw
	sprite.draw = function(self,x,y)
		if not config.draw_debug_info then oldDraw(self,x,y) return end
	
		x = math.floor(x or self.x)
		y = math.floor(y or self.y)
		local w = self.width or 1
		local h = self.height or 1
		oldDraw(self,x,y)
		
		local c = {love.graphics.getColor()}
		
		love.graphics.setColor(255, 0, 0)
		love.graphics.circle("fill", x, y, 3, 10)
		
		love.graphics.setColor(0, 255, 0)
		love.graphics.circle("fill", x+w/2, y+h/2, 3, 10)

		love.graphics.setColor(0, 0, 255)
		love.graphics.rectangle("line", x, y, w, h )
		 
		love.graphics.setColor(c)
	end
end

DebugPoint = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/debugpoint.png',
}


