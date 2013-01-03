STRICT = true
DEBUG = true

require 'zoetrope'

Player= Tile:extend
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
		
		local cx,cy = self.x + self.width / 2, self.y + self.height / 2
		
		self.rotation = math.atan2((cy - (the.mouse.y)), (cx - (the.mouse.x))) - math.pi / 2
		
		-- easy exit
		if the.keys:pressed('escape') then os.exit() end
	end,
}

Cursor= Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/cursor.png',
    
	onUpdate = function (self)
		self.x = the.mouse.x - self.width / 2
		self.y = the.mouse.y - self.height / 2
	end
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
		self.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2 }
		self:add(self.player)
		
		self.cursor = Cursor:new{ x = 0, y = 0 }
		self:add(self.cursor)
		
		--~ self.debugpoint = DebugPoint:new{ x = 0, y = 0 }
		--~ self:add(self.debugpoint)
		
		self:useSysCursor(true)
		the.app.console:watch("rotation", "the.app.player.rotation")
    end
}