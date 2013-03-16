-- Barrier

Ressource = Tile:extend
{
	image = '/assets/graphics/ressource.png',
	currentPain = 0,
	maxPain = config.ressourceHealth,
	wFactor = 0,
	t = Text:new{
		font = 12,
		text = "xxx",
		x = 0,
		y = 0, 
		tint = {0,0,0},
	},	
	owner = 0,
	nextOwner = 0,
	
	-- UiBar
	painBar = nil,
	
	movable = false,
	
	onDraw = function(self)
		if the.view.layers.ui:contains(self.t) == false then the.view.layers.ui:add(self.t) end	
	end,		
	
	onNew = function (self)		
		self.width = 64
		self.height = 64
		self:updateQuad()
		object_manager.create(self)
		--print("NEW RESSOURCE", self.x, self.y, self.width, self.height)
		the.view.layers.characters:add(self)
		self.wFactor = self.width / self.maxPain
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
			wFactor = self.wFactor,
		}
		
		drawDebugWrapper(self)
	end,
	
	gainPain = function (self, str)
		--print(self.oid, "gain pain", str)
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
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str, source_oid = ...
			--print("RESSOURCE HEAL", str)
		elseif message_name == "damage" then
			local str, source_oid = ...
			--print("RESSOURCE DAMANGE", str)
			self:gainPain(str)
			self.nextOwner = source_oid
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("RESSOURCE DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(str)
					self.nextOwner = source_oid
				end)
			end
		end
	end,
	
	updatePain = function (self)
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			--self:die()
			self:changeOwner()
		end	
	end,
	
	onDie = function (self)
		-- TODO: player-owned
	end,
	
	changeOwner = function(self)
		self.owner = self.nextOwner
		self.currentPain = 0
	end,
	
	onUpdate = function (self)	
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y
		
		if self.owner == 0 then self.t.text = "Owned by: none" else self.t.text = "Owned by: " .. self.owner end
		self.t.x = self.x - self.width /4
		self.t.y = self.y - self.t.height
		self.t.width = 120		
	
		local done = {}		
		for i = 1, config.roundTime / config.xpGainsEachNSeconds do 
			if (math.floor(love.timer.getTime()) == config.xpGainsEachNSeconds * i) and done[i] ~= true and self.owner ~= 0 then
				object_manager.send(self.owner, "xp", config.xpPerRessourceTick)	-- TODO: fix that this gets called every frame instead of once
				done[i] = true	
			end
		end		
	end,	
}
