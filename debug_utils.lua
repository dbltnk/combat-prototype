-- debug stuff

local spawnedDebugThings = {}

local defaultTime = 5
local defaultColor = {255,0,255,150}

-- x,y centered
spawnDebugCircle = function (x,y,r,t,color)
	t = t or defaultTime
	color = color or defaultColor
	local d = Fill:new{ shape="circle", x = x-r, y = y-r, width = r*2, height = r*2, border = color, fill = {0,0,0,0} }
	the.app.view.layers.debug:add(d)
	the.app.view.timer:after(t, function() 
		the.app.view.layers.debug:remove(d)
	end)
end

-- x,y centered
spawnDebugPoint = function (x,y,r,t,color)
	t = t or defaultTime
	color = color or defaultColor
	r = r or 3
	local d = Fill:new{ shape="circle", x = x-r, y = y-r, width = r*2, height = r*2, fill = color }
	the.app.view.layers.debug:add(d)
	the.app.view.timer:after(t, function() 
		the.app.view.layers.debug:remove(d)
	end)
end

-- x,y left-top
spawnDebugRect = function (x,y,w,h,t,color)
	t = t or defaultTime
	color = color or defaultColor
	local d = Fill:new{ x = x, y = y-r, width = w, height = h, border = color, fill = {0,0,0,0} }
	the.app.view.layers.debug:add(d)
	the.app.view.timer:after(t, function() 
		the.app.view.layers.debug:remove(d)
	end)
end

drawDebugThings = function()
	local drawCount = 0
	
	for k,v in pairs(spawnedDebugThings) do
		if v.shape == "circle" then
			love.graphics.setColor(v.color)
			love.graphics.circle("line", v.x, v.y, v.radius, 10)
		end
		if v.shape == "point" then
			love.graphics.setColor(v.color)
			love.graphics.circle("fill", v.x, v.y, v.radius, 10)
		end
	end
	
	if drawCount == 0 then spawnedDebugThings = {} end
end

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


