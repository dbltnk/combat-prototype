STRICT = true
DEBUG = true

require 'zoetrope'

Player= Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/player.png',
--	rotation = 1,
	
	onUpdate = function (self, elapsed)
                if the.keys:pressed('left', 'a') then
			self.velocity.x = -200
                elseif the.keys:pressed('right', 'd') then
			self.velocity.x = 200
                elseif the.keys:pressed('up', 'w') then
			self.velocity.y = -200
                elseif the.keys:pressed('down', 's') then
			self.velocity.y = 200			
                else
			self.velocity.x = 0
			self.velocity.y = 0
		end
		rotation = math.atan2((self.y-the.mouse.y),(self.x-the.mouse.x))
--		print(rotation)
	end
}

Cursor= Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/cursor.png',
    
        onUpdate = function (self)
		self.x = the.mouse.x - 16
		self.y = the.mouse.y - 16
	end
}

the.app = App:new
{
    onRun = function (self)
        self.player = Player:new{ x = 300, y = 300 }
        self:add(self.player)
	self.cursor = Cursor:new{ x = 0, y = 0 }
        self:add(self.cursor)
	self:useSysCursor(false)
    end
}