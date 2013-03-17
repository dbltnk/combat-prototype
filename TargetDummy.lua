-- TargetDummy

TargetDummy = Tile:extend
{
	image = '/assets/graphics/dummy.png',
	currentPain = 0,
	maxPain = 100,
	xpWorth = config.dummyXPWorth,
	dmgReceived = {},
	damagerTable = {},	
	finalDamage = 0,
	alive = true,
	wFactor = 0,	
	timeOfDeath = 0,	
	
	-- UiBar
	painBar = nil,
	
	movable = false,
	
	onNew = function (self)
		the.targetDummies[self] = true
		
		self.width = 32
		self.height = 64
		self:updateQuad()
		object_manager.create(self)
		--print("NEW DUMMY", self.x, self.y, self.width, self.height)
		the.view.layers.characters:add(self)
		self.wFactor = self.width / self.maxPain			
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, wFactor = self.wFactor
		}
		
		drawDebugWrapper(self)
		--if (math.random(-1, 1) > 0) then self.movable = true end
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
	
	trackDamage = function (self, source_oid, str)
		-- zero values
		if not self.dmgReceived[self.oid] then self.dmgReceived[self.oid] = {} end
		local myDmgReceived = self.dmgReceived[self.oid]
		if not myDmgReceived[source_oid] then myDmgReceived[source_oid] = 0 end
		
		-- interesting case
		myDmgReceived[source_oid] = myDmgReceived[source_oid] + str
	end,
	
	receive = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str = ...
		--	print("DUMMY HEAL", str)
		elseif message_name == "damage" then
			local str, source_oid  = ...
			--print("DUMMY DAMANGE", str)
			self:gainPain(str)
		--	print("start ", start_target)
			-- damage handling for xp distribution	
			self:trackDamage(source_oid, str)

		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
		--	print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if self.alive then 
						self:gainPain(str)
						self:trackDamage(source_oid, str)
					end
				end)
			end
		elseif message_name == "runspeed" then
			local str, duration = ...
		--	print("DUMMY SPEED", str, duration)
		end
	end,
	
	updatePain = function (self)
		if ((self.currentPain > self.maxPain) and self.alive == true) then 
			self.currentPain = self.maxPain
			self.alive = false					
			self:die()
		end	
	end,
	
	onDie = function (self)
		self.painBar:die()
		the.targetDummies[self] = nil
		-- find out how much xp which player gets and tell him
		local myDmgReceived = self.dmgReceived[self.oid]
		
		for damager, value in pairs(myDmgReceived) do
			self.finalDamage = self.finalDamage + value
		end
		
		for damager, value in pairs(myDmgReceived) do
			object_manager.send(damager, "xp", self.xpWorth / self.finalDamage * value)
		end
		
		self.timeOfDeath = love.timer.getTime()
		the.app.view.timer:after(config.dummyRespawn,function() self:revive() self:respawn() end)
	end,
	
	onUpdate = function (self)
		if ((math.random(-1, 1) > 0) and self.movable == true) then
			self.dx = math.random(-10, 10)
			self.dy = math.random(-10, 10)
			self.x = self.x + self.dx
			self.y = self.y + self.dy
		end
		
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y	
	end,	
	
	respawn = function (self)
		self.currentPain = 0
		self.alive = true
		self.timeOfDeath = 0
		self.finalDamage = 0
		self.painBar:revive()	
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, wFactor = self.wFactor
		}			
		for k,v in pairs(self.dmgReceived) do k = nil v = nil end
		for k,v in pairs(self.damagerTable) do  k = nil v = nil end		
	end,
}
