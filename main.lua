STRICT = true
DEBUG = true

require 'zoetrope'

Vector = {
	len = function(x,y)
		return math.sqrt(x*x + y*y)
	end,
	
	-- returns dx,dy
	fromTo = function(x0,y0, x1,y1)
		return x1-x0, y1-y0
	end,
	
	lenFromTo = function(x0,y0, x1,y1)
		return Vector.len(Vector.fromTo(x0,y0, x1,y1))
	end,
	
	-- returns x,y
	normalize = function(x,y)
		local l = Vector.len(x,y)
		return x/l, y/l
	end,
	
	normalizeToLen = function(x,y,l)
		local nx,ny = Vector.normalize (x,y)
		return nx*l, ny*l
	end,
	
	-- returns x,y
	add = function(x0,y0, x1,y1)
		return x0+x1, y0+y1
	end,
	
	-- returns x,y
	sub = function(x0,y0, x1,y1)
		return x0-x1, y0-y1
	end,
	
	-- returns x,y
	mul = function(x,y,s)
		return x*s,y*s
	end,
}

-- returns x,y
function ScreenPosToWorldPos(x,y)
	local vx,vy = Vector.mul(the.view.translate.x, the.view.translate.y, -1)
	return Vector.add(vx,vy, x,y)
end

Player = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/player.png',
	
	onUpdate = function (self, elapsed)
		self.velocity.x = 0
		self.velocity.y = 0

		if the.keys:pressed('left', 'a') then self.velocity.x = -200 end
		if the.keys:pressed('right', 'd') then self.velocity.x = 200 end
		if the.keys:pressed('up', 'w') then self.velocity.y = -200 end
		if the.keys:pressed('down', 's') then self.velocity.y = 200	end	
		
		local worldMouseX, worldMouseY = ScreenPosToWorldPos(the.mouse.x, the.mouse.y)
		
		local cx,cy = self.x + self.width / 2, self.y + self.height / 2
		-- mouse -> player vector
		local dx,dy = cx - (worldMouseX), cy - (worldMouseY)
		
		self.rotation = math.atan2(dy, dx) - math.pi / 2
		
		local bulletvx, bulletvy = -dx, -dy
		local l = Vector.len(bulletvx, bulletvy)
		local bulletspeed = 800
		bulletvx, bulletvy = Vector.normalizeToLen(bulletvx, bulletvy, bulletspeed)
		
		if the.mouse:justPressed('l') then
			-- assert: bullet size == player size
			local bullet = Bullet:new{ 
				x = self.x, y = self.y, 
				rotation = self.rotation,
				velocity = { x = bulletvx, y = bulletvy },
				start = { x = self.x, y = self.y },
				target = { x = worldMouseX, y = worldMouseY},
			}
			the.app:add(bullet)
		end
		
		-- easy exit
		if the.keys:pressed('escape') then os.exit() end
	end,
}

FocusSprite = Sprite:extend 
{
	width = 1,
	height = 1,
	
	onUpdate = function (self)
		local worldMouseX, worldMouseY = ScreenPosToWorldPos(the.mouse.x, the.mouse.y)
		local x,y = Vector.add(worldMouseX, worldMouseY, the.app.player.x, the.app.player.y)
		self.x, self.y = Vector.mul(x, y, 0.5)
	end
}

Cursor = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/cursor.png',
    
	onUpdate = function (self)
		self.x = the.mouse.x - self.width / 2
		self.y = the.mouse.y - self.height / 2
		self.x, self.y = ScreenPosToWorldPos(self.x, self.y)
	end
}

Bullet = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/bullet.png',
    -- target.x target.y start.x start.y
    
	onUpdate = function (self)
		local totalDistance = Vector.lenFromTo(self.start.x, self.start.y, self.target.x, self.target.y)
		local distFromStart = Vector.lenFromTo(self.start.x, self.start.y, self.x, self.y)
		
		if distFromStart >= totalDistance then
			self:die()
		end
	end,
}

--~ DebugPoint = Tile:extend
--~ {
	--~ width = 32,
	--~ height = 32,
	--~ image = '/assets/graphics/debugpoint.png',
--~ }

the.app = App:new
{
    onRun = function (self)
		self:enterFullscreen()
    
		-- setup background
    
		for x=-1,1 do
		for y=-1,1 do
			self:add(Tile:new{
				width = 800,
				height = 600,
				x = 0 + x * 800, y = 0 + y * 600,
				image = '/assets/graphics/bg.png',
			})
		end
		end
		
		-- setup player
		self.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2 }
		self:add(self.player)
		
		self.cursor = Cursor:new{ x = 0, y = 0 }
		self:add(self.cursor)
		
		--~ self.debugpoint = DebugPoint:new{ x = 0, y = 0 }
		--~ self:add(self.debugpoint)
		
		self:useSysCursor(false)
		
		the.app.console:watch("viewx", "the.view.translate.x")
		the.app.console:watch("viewy", "the.view.translate.y")
		
		self.focusSprite = FocusSprite:new{ x = 0, y = 0 }
		self:add(self.focusSprite)
		
		the.view.focus = self.focusSprite
    end
}