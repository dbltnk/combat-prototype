-- TargetDummy

TargetDummy = Tile:extend
{
	image = '/assets/graphics/dummy.png',
	currentPain = 0,
	maxPain = 100,
	xpWorth = config.dummyXPWorth,
	dmgReceived = {},
	alive = true,
	wFactor = 0,		
	
	-- UiBar
	painBar = nil,
	
	movable = false,

	changeMonitor = nil,
	
	onNew = function (self)
		the.targetDummies[self] = true
		
		self.changeMonitor = MonitorChanges:new{ obj = self, keys = {"x", "y", 
			"currentEnergy", "currentPain", "rotation", "alive" } }
		
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
		
		network.send(self:netCreate())
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
		local damagerTable = {}
		if message_name == "heal" then
			local str = ...
		--	print("DUMMY HEAL", str)
		elseif message_name == "damage" then
			local str, source_oid  = ...
			--print("DUMMY DAMANGE", str)
			self:gainPain(str)
		--	print("start ", start_target)
			-- damage handling for xp distribution	
			if self.dmgReceived[self.oid] then
				for k,v in pairs(self.dmgReceived) do
				--	print("existing oid dummy = " .. k .. " with ", v)				
					v[source_oid] = v[source_oid] + str
				--	print("damage = " .. v[source_oid])
					for key, value in pairs(v) do
				--		print("damager oid = " .. key,value)
					end
				end
			else 
				self.dmgReceived[self.oid] = damagerTable
				for k,v in pairs(self.dmgReceived) do
					--print("new oid dummy = " .. k .. " with ", v)
					v[source_oid] = str
					--print("damage = " .. v[source_oid])
					for key, value in pairs(v) do
						--print("damager oid = " .. key,value)
					end
				end
			end
		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
		--	print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if self.alive then 
						self:gainPain(str)
					end
				end)
				-- damage handling for xp distribution	
			if self.dmgReceived[self.oid] then
				for k,v in pairs(self.dmgReceived) do
					--print("existing oid dummy = " .. k .. " with ", v)				
					v[source_oid] = v[source_oid] + str
				--	print("damage = " .. v[source_oid])
					for key, value in pairs(v) do
					--	print("damager oid = " .. key,value)
					end
				end
			else 
				self.dmgReceived[self.oid] = damagerTable
				for k,v in pairs(self.dmgReceived) do
					--print("new oid dummy = " .. k .. " with ", v)
					v[source_oid] = str
					--print("damage = " .. v[source_oid])
					for key, value in pairs(v) do
						--print("damager oid = " .. key,value)
					end
				end
			end
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
		for k,v in pairs(self.dmgReceived) do 
			for damager, value in pairs(v) do
				if self.finalDamage then 
					self.finalDamage = self.finalDamage + value				
				else 	
					self.finalDamage = value
				end
				object_manager.send(damager, "xp", self.xpWorth / self.finalDamage * value)
			end
		end
		
		network.send({channel = "game", cmd = "delete", oid = self.oid, })
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
		
		self.changeMonitor:checkAndSend()
	end,	
	
	netCreate = function (self)
		return { 
			channel = "game", cmd = "create", class = "TargetDummy", oid = self.oid, 
			x = self.x, y = self.y, owner = self.owner, 
			currentPain = self.currentPain, currentEnergy = self.currentEnergy, rotation = self.rotation,
			image = self.image, width = self.width, height = self.height, 
		}
	end,
}
