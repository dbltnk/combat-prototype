-- Barrier

Barrier = Tile:extend
{
	image = '/assets/graphics/barrier.png',
	currentPain = 0,
	maxPain = config.barrierHealth,
	wFactor = 0,
	
	-- UiBar
	painBar = nil,
	
	movable = false,
	
	onNew = function (self)		
		self.width = 96
		self.height = 192
		self:updateQuad()
		object_manager.create(self)
		--print("NEW BARRIER", self.x, self.y, self.width, self.height)
		the.view.layers.characters:add(self)
		self.wFactor = 0.1 / self.maxPain * 1000
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
			wFactor = self.wFactor,
		}
		
		drawDebugWrapper(self)
		if (math.random(-1, 1) > 0) then self.movable = true end
	end,
	
	gainPain = function (self, str)
		print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
		if str >= 0 then
			self.scrollingText  = ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {1,0,0}}
			GameView.layers.ui:add(self.scrollingText)	
		else
			self.scrollingText  = ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {0,0,1}}
			GameView.layers.ui:add(self.scrollingText)	
		end
	end,
	
	receive = function (self, message_name, ...)
		print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str = ...
			--print("BARRIER HEAL", str)
		elseif message_name == "damage" then
			local str = ...
			--print("BARRIER DAMANGE", str)
			self:gainPain(str)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks = ...
			--print("BARRIER DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(str)
				end)
			end
		elseif message_name == "runspeed" then
			local str, duration = ...
			--print("BARRIER SPEED", str, duration)
		end
	end,
	
	updatePain = function (self)
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			self:die()
		end	
	end,
	
	onDie = function (self)
		self.painBar:die()
		os.exit()
		print("THE GAME JUST ENDED") -- TODO: call end screen
	end,
	
	onUpdate = function (self)	
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y
	end,	
}
