-- 


ControlUI = Tile:extend
{
	width = 212,
	height = 54,
	image = '/assets/graphics/controls_mouse.png',
    
	onUpdate = function (self)
		self.x = love.graphics.getWidth() / 2 - self.width / 2 - 6 --TODO: dummen hack (-7) entfernen
		self.y = love.graphics.getHeight() - self.height 
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
	fill = {0,128,128,255},	
	border = {0,0,0,255},
	t = Text:new{
				font = 14,
				text = "xxx",
				x = 0,
				y = 0, 
			},
	
	onDraw = function(self)
		if the.hud:contains(self.t) == false then the.hud:add(self.t) end	
	end,	
    
	onUpdate = function (self)
		self.x = love.graphics.getWidth() - self.width 
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.maxEnergy / the.player.maxEnergy * (love.graphics.getWidth() - the.controlUI.width) / 2
		self.t.text = "Fatigue: " .. math.floor(300 - the.player.currentEnergy) .. " / " .. math.floor(the.player.maxEnergy)
		self.t.x = love.graphics.getWidth() / 4 * 3 
		self.t.y = love.graphics.getHeight() - self.height
		self.t.width = 150
	end
}

EnergyUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {0,0,255,255},	
	border = {0,0,0,255},
		
	onUpdate = function (self)
		self.x = love.graphics.getWidth() - self.width 
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.currentEnergy / the.player.maxEnergy * (love.graphics.getWidth() - the.controlUI.width) / 2
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
		self.x = 0
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.maxPain / the.player.maxPain * (love.graphics.getWidth() - the.controlUI.width) / 2
	end
}

PainUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {255,0,0,255},	
	border = {0,0,0,255},
	t = Text:new{
				font = 14,
				text = "xxx",
				x = 0,
				y = 0, 
			},
	
	onDraw = function(self)
		if the.hud:contains(self.t) == false then the.hud:add(self.t) end
	end,
	
	onUpdate = function (self)
		self.x = 0
		self.y = love.graphics.getHeight() - self.height
		self.width = the.player.currentPain / the.player.maxPain * (love.graphics.getWidth() - the.controlUI.width) / 2
		if self.width <= 2 then self.width = 2 end
		self.t.text = "Pain: " .. math.floor(the.player.currentPain) .. " / " .. math.floor(the.player.maxPain)
		self.t.x = love.graphics.getWidth() / 4 - self.t.width / 2
		self.t.y = love.graphics.getHeight() - self.height
		self.t.width = 150
	end
}

ExperienceUIBG = Fill:extend
{
	width = 1,
	height = 20,
	fill = {128,128,128,255},	
	border = {0,0,0,255},
    
	onUpdate = function (self)
		self.x = 0
		self.y = love.graphics.getHeight() - self.height * 2 - 10
		self.width = the.player.xpCap / the.player.xpCap * (love.graphics.getWidth() - the.controlUI.width) / 2
	end
}

ExperienceUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {255,255,0,255},	
	border = {0,0,0,255},
	t = Text:new{
				font = 14,
				text = "xxx",
				x = 0,
				y = 0, 
				tint = {0,0,0},
			},
	
	onDraw = function(self)
		if the.hud:contains(self.t) == false then the.hud:add(self.t) end
	end,
	
	onUpdate = function (self)
		self.x = 0
		self.y = love.graphics.getHeight() - self.height * 2 - 10
		self.width = the.player.xp / the.player.xpCap * (love.graphics.getWidth() - the.controlUI.width) / 2
		if self.width <= 2 then self.width = 2 end
		self.t.text = "Current level xp: " .. math.floor(the.player.xp) .. " / " .. math.floor(the.player.xpCap)
		self.t.x = love.graphics.getWidth() / 4 - self.t.width / 2
		self.t.y = love.graphics.getHeight() - self.height * 2 - 10
		self.t.width = 300
	end
}

LevelUI = Fill:extend
{
	width = 1,
	height = 20,
	fill = {128,128,128,255},	
	border = {0,0,0,255},
    
	onUpdate = function (self)
		--self.x = (love.graphics.getWidth() + the.controlUI.width) / 2
		self.y = love.graphics.getHeight() - self.height * 2 - 10
		--self.width = (love.graphics.getWidth() + the.controlUI.width) / 3.5 / 10
	end
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

UiBar = Sprite:extend
{
	pb = nil,
	pbb = nil,
	wFactor = 0.30,
	dx = 0,
	dy = 0,
	inc = false,
	
	currentValue = 0,
	maxValue = 100,

	onNew = function (self)
		self.bar = Fill:new{
			x = self.x, y = self.y, 
			width = self.currentValue * self.wFactor,
			height = 5,
			fill = {255,0,0,255},
			border = {0,0,0,255}	
		}
		self.background = Fill:new{
			x = self.x, y = self.y, 
			width = self.maxValue * self.wFactor,
			height = 5,
			fill = {0,255,0,255},
			border = {0,0,0,255},
		}
		the.view.layers.ui:add(self)
		the.view.layers.ui:add(self.background)
		the.view.layers.ui:add(self.bar)
	end,
	
	onUpdate = function (self, elapsed)
		self.bar.x = self.x + self.dx
		self.bar.y = self.y + self.dy
		self.background.x = self.x + self.dx
		self.background.y = self.y + self.dy	
		if self.inc then
			self.background.fill = {127,127,127,255}
			self.bar.fill = {255,40,244,255}			
		else
			self.background.fill = {0,255,0,255}
			self.bar.fill = {255,0,0,255}
		end
	end,
	
	updateBar = function (self)
		if self.currentValue > self.maxValue then 
			self.currentValue = self.maxValue
		else
			self.bar.width = self.currentValue * self.wFactor
		end	
	end,
	
	onDie = function (self)
		self.bar:die()
		self.background:die()		

		the.view.layers.ui:remove(self)
		the.view.layers.ui:remove(self.background)
		the.view.layers.ui:remove(self.bar)
	end,
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

TimerDisplay = Text:extend
{
	font = 20,
	text = "xxx",
	x = 0,
	y = 0, 
	time = 0,
	width = 200,
	tint = {0.1,0.1,0.1},
	
	onUpdate = function (self)
		self.x = (love.graphics.getWidth() - self.width) / 2
		self.time = config.roundTime - (math.floor(love.timer.getTime()))
		local minutes = math.floor(self.time / 60)
		local seconds = (self.time - minutes * 60)
		if seconds >= 10 then 
			self.text = minutes .. ":" .. seconds .. " remaining"
		elseif seconds < 10 then
			self.text = minutes .. ":0" .. seconds .. " remaining"
		end
	end
}

ScrollingText = Text:extend
{
	font = 20,
	text = "xxx",
	x = 0,
	y = 0, 
	width = 6,
	tint = {1,1,1},
	
	onNew = function (self)
		self.x = self.x - self.width / 2
	end,
	
	onUpdate = function (self)
		self.y = self.y - 1
		self.font = self.font - 0.1
		if self.font <= 10 then self:die() end
	end
}

NetworkDisplay = Text:extend
{
	pingTime = 0,
	playerOnline = 0,
	font = 12,
	text = "xxx",
	x = 0,
	y = 0, 
	tint = {0,0,0},
	time = 0,
	width = 200,
	
	requestPing = function (self)
		local t = love.timer.getTime()
		network.send_request({channel = "server", cmd = "ping", time = t}, function(fin, result)
			self.pingTime = love.timer.getTime() - t
		end)
	end,
	
	requestOnline = function (self)
		network.send_request({channel = "server", cmd = "who"}, function(fin, result)
			self.playerOnline = #result.ids
		end)
	end,
	
	onNew = function (self)
		the.view.timer:every(5, function()
			self:requestOnline()
			self:requestPing()
		end)
	end,
	
	onUpdate = function (self)
		self.y = 5
		self.x = 10
		    
		self.text = "id: " .. (network.client_id or "?") .. " ping: " .. math.floor(self.pingTime * 1000) .. " ms online: " .. self.playerOnline
	end
}
