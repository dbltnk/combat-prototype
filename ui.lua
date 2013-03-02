-- 


ControlUI = Tile:extend
{
	width = 212,
	height = 54,
	image = '/assets/graphics/controls_mouse.png',
    
	onUpdate = function (self)
		self.x = love.graphics.getWidth() / 2 - self.width / 2  -- the.app.height
		self.y = love.graphics.getHeight() - self.height  -- the.app.height
		if input.getMode() == 2 then
			self.image = '/assets/graphics/controls_gamepad.png'
			elseif input.getMode() == 1 then
			self.image = '/assets/graphics/controls_mouse.png'
		end
	end
}

EnergyUIBG = Fill:extend
{
	width = 1,
	height = 20,
	fill = {0,0,128,255},	
	border = {0,0,0,255},
    
	onUpdate = function (self)
		self.x = love.graphics.getWidth() / 2 - self.width / 2 + 4
		self.y = love.graphics.getHeight() - self.height - 64
		self.width = the.player.maxEnergy / the.player.maxEnergy * the.controlUI.width
	end
}

EnergyUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {0,0,255,255},	
	border = {0,0,0,255},
	
	onUpdate = function (self)
		self.x = love.graphics.getWidth() / 2 - the.energyUIBG.width / 2
		self.y = love.graphics.getHeight() - self.height - 64
		self.width = the.player.currentEnergy / the.player.maxEnergy * the.controlUI.width
		if self.width <= 2 then self.width = 2 end
	end
}

PainUIBG = Fill:extend
{
	width = 1,
	height = 20,
	fill = {0,255,0,255},	
	border = {0,0,0,255},
    
	onUpdate = function (self)
		self.x = love.graphics.getWidth() / 2 - self.width / 2 + 4
		self.y = love.graphics.getHeight() - self.height - 64 - self.height
		self.width = the.player.maxPain / the.player.maxPain * the.controlUI.width
	end
}

PainUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {255,0,0,255},	
	border = {0,0,0,255},
	
	onUpdate = function (self)
		self.x = love.graphics.getWidth() / 2 - the.painUIBG.width / 2
		self.y = love.graphics.getHeight() - self.height - 64 - self.height
		self.width = the.player.currentPain / the.player.maxPain * the.controlUI.width
		if self.width <= 2 then self.width = 2 end
	end
}


PainBar = Fill:extend
{
	width = 0,
	height = 5,
	fill = {255,0,0,255},
	border = {0,0,0,255}	
}

PainBarBG = Fill:extend
{
	width = 0,
	height = 5,
	fill = {0,255,0,255},
	border = {0,0,0,255}
}


Cursor = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/cursor.png',
    
	onUpdate = function (self)
		self.x = input.cursor.x - self.width / 2
		self.y = input.cursor.y - self.height / 2
		self.x, self.y = tools.ScreenPosToWorldPos(self.x, self.y)
	end
}


UiGroup = Group:extend
{
	solid = false,

	onUpdate = function(self)
		local x,y = tools.ScreenPosToWorldPos(0,0)
		self.translate.x = x
		self.translate.y = y
	end,
}


PlayerDetails = Tile:extend
{
	width = 128,
	height = 128,
	image = '/assets/graphics/player_details.png',
    
	onUpdate = function (self)
		self.x = the.player.x - the.player.width / 1.5
		self.y = the.player.y - the.player.height / 1.5
	end
}
