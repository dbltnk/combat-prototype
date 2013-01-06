STRICT = true
DEBUG = true

require 'zoetrope'
local vector = require 'vector'
local utils = require 'utils'
local config = require 'config'
local input = require 'input'

-- returns x,y
function ScreenPosToWorldPos(x,y)
	local vx,vy = vector.mul(the.view.translate.x, the.view.translate.y, -1)
	return vector.add(vx,vy, x,y)
end

-- returns x,y
function WorldPosToScreenPos(x,y)
	local vx,vy = vector.mul(the.view.translate.x, the.view.translate.y, 1)
	return vector.add(vx,vy, x,y)
end

Player = Animation:extend
{
	shootTimeout = 0.2,
	timeSinceLastShoot = 0,
	
	width = 50,
	height = 50,
	image = '/assets/graphics/player.png', -- source: http://www.synapsegaming.com/forums/t/1711.aspx

	  sequences = 
	  {
		walk = { frames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, fps = config.animspeed },
	   },
	
	onUpdate = function (self, elapsed)
		self.timeSinceLastShoot = self.timeSinceLastShoot + elapsed
		
		self.velocity.x = 0
		self.velocity.y = 0

		-- 0 slowest -> 1 fastest
		local speed = 0
		-- -1->1, -1->1
		local dirx, diry = 0,0
		
		local doShoot = false
		
		if input.getMode() == input.MODE_GAMEPAD then
			-- move player by axes 12
			dirx = the.gamepads[1].axes[1]
			diry = the.gamepads[1].axes[2]
			local l = vector.len(dirx, diry)
			if l < 0.2 then 
				speed = 0
				dirx, diry = 0,0 
			else
				speed = utils.mapIntoRange (l, 0, 1, 0,1)
			end
			
			-- move cursor by axes 34
			local curx = the.gamepads[1].axes[3]
			local cury = the.gamepads[1].axes[4]
			local cur = vector.len(curx, cury)
			if cur < 0.2 then 
				curx, cury = 0,0 
			else
				cur = utils.mapIntoRange (cur, 0, 1, 0, config.gamepad_cursor_speed)
				curx, cury = vector.normalizeToLen(curx, cury, cur * elapsed)
			end
			
			input.cursor.x, input.cursor.y = vector.add(input.cursor.x, input.cursor.y, curx, cury)

			-- clamp cursor distance
			local dx,dy = vector.fromTo (self.x, self.y, ScreenPosToWorldPos(input.cursor.x, input.cursor.y))
			
			if vector.len(dx, dy) > config.gamepad_cursor_max_distance then
				dx, dy = vector.normalizeToLen (dx, dy, config.gamepad_cursor_max_distance)
				input.cursor.x, input.cursor.y = WorldPosToScreenPos(vector.add(self.x, self.y, dx,dy))
			end
			
			-- shoot?
			doShoot = the.gamepads[1].axes[5] > 0.2
		elseif input.getMode() == input.MODE_MOUSE_KEYBOARD then
			if the.mouse:pressed('l') then doShoot = true end
		
			if the.keys:pressed('shift') then speed = 1 else speed = 0 end
			
			if the.keys:pressed('left', 'a') then dirx = -1 end
			if the.keys:pressed('right', 'd') then dirx = 1 end
			if the.keys:pressed('up', 'w') then diry = -1 end
			if the.keys:pressed('down', 's') then diry = 1 end

			input.cursor.x = the.mouse.x
			input.cursor.y = the.mouse.y
		elseif input.getMode() == input.MODE_TOUCH then
			-- TODO
		end
		
		-- move into direction?
		if vector.len(dirx, diry) > 0 then
			local s = utils.mapIntoRange (speed, 0, 1, config.walkspeed, config.runspeed)
			self.velocity.x, self.velocity.y = vector.normalizeToLen(dirx, diry, s)
			
			local animspeed = utils.mapIntoRange (speed, 0, 1, config.animspeed, config.animspeed * config.runspeed / config.walkspeed)
			
			self:play('walk')
		else
			self:freeze(5)
		end
		
		
		local worldMouseX, worldMouseY = ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		
		local cx,cy = self.x + self.width / 2, self.y + self.height / 2
		-- mouse -> player vector
		local dx,dy = cx - (worldMouseX), cy - (worldMouseY)
		
		self.rotation = math.atan2(dy, dx) - math.pi / 2
		
		local arrowvx, arrowvy = -dx, -dy
		local l = vector.len(arrowvx, arrowvy)
		arrowvx, arrowvy = vector.normalizeToLen(arrowvx, arrowvy, config.arrowspeed)
		
		if doShoot and self.timeSinceLastShoot > self.shootTimeout then
			self.timeSinceLastShoot = 0
		
			-- assert: arrow size == player size
			local arrow = Arrow:new{ 
				x = self.x, y = self.y, 
				rotation = self.rotation,
				velocity = { x = arrowvx, y = arrowvy },
				start = { x = self.x, y = self.y },
				target = { x = worldMouseX, y = worldMouseY},
			}
			the.app:add(arrow)
		end
		
	end,
}

FocusSprite = Sprite:extend 
{
	width = 1,
	height = 1,
	
	onUpdate = function (self)
		local worldMouseX, worldMouseY = ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		local x,y = vector.add(worldMouseX, worldMouseY, the.player.x, the.player.y)
		self.x, self.y = vector.mul(x, y, 0.5)
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}

Cursor = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/cursor.png',
    
	onUpdate = function (self)
		self.x = input.cursor.x - self.width / 2
		self.y = input.cursor.y - self.height / 2
		self.x, self.y = ScreenPosToWorldPos(self.x, self.y)
	end
}

Arrow = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/arrow.png',
    -- target.x target.y start.x start.y
    
	onUpdate = function (self)
		local totalDistance = vector.lenFromTo(self.start.x, self.start.y, self.target.x, self.target.y)
		local distFromStart = vector.lenFromTo(self.start.x, self.start.y, self.x, self.y)
		
		if distFromStart >= totalDistance then
			self:die()
			-- not possible to revive them later
			the.app:remove(self)
		end
	end,
}

--~ DebugPoint = Tile:extend
--~ {
	--~ width = 32,
	--~ height = 32,
	--~ image = '/assets/graphics/debugpoint.png',
--~ }

GameView = View:extend
{
    onNew = function (self)
		self:loadLayers('/assets/tilemap/map.lua')
		--~ self.focus = the.focusSprite
		
		--~ for x=-1,1 do
		--~ for y=-1,1 do
			--~ self:add(Tile:new{
				--~ width = 2239,
				--~ height = 2235,
				--~ x = 0 + x * 2239, y = 0 + y * 2235,
				--~ image = '/assets/graphics/bg.png', -- source: http://opengameart.org/content/castle-tiles-for-rpgs
			--~ })
		--~ end
		--~ end
		
		-- setup player
		the.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2 }
		self:add(the.player)
		
		the.cursor = Cursor:new{ x = 0, y = 0 }
		self:add(the.cursor)
		
		--~ self.debugpoint = DebugPoint:new{ x = 0, y = 0 }
		--~ self:add(self.debugpoint)
		
		the.focusSprite = FocusSprite:new{ x = 0, y = 0 }
		self:add(the.focusSprite)
		
		self.focus = the.focusSprite
    end
}

the.app = App:new
{
	numGamepads = 1,

	onUpdate = function (self, elapsed)
		-- set input mode
		if the.keys:justPressed ("f1") then print("input mode: mouse+keyboard") input.setMode (input.MODE_MOUSE_KEYBOARD) end
		if the.keys:justPressed ("f2") then print("input mode: gamepad") input.setMode (input.MODE_GAMEPAD) end
		if the.keys:justPressed ("f3") then print("input mode: touch") input.setMode (input.MODE_TOUCH) end	
		
		-- toggle fullscreen
		if the.keys:justPressed ("f10") then self:toggleFullscreen() end

		-- easy exit
		if the.keys:pressed('escape') then os.exit() end
	end,

    onRun = function (self)
		--the.app.width, the.app.height = 1680, 1050
		--self:enterFullscreen()
    
		self:useSysCursor(false)
		
		the.app.console:watch("viewx", "the.view.translate.x")
		the.app.console:watch("viewy", "the.view.translate.y")
		
		-- setup background
		self.view = GameView:new()
    end
}
