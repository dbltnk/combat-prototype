-- TargetDummy

TargetDummy = Tile:extend
{
	image = '/assets/graphics/dummy.png',
	currentPain = 0,
	maxPain = 100,
	hardCodedTarget = 23,  --TODO: exchange hardCodedTarget for damager (target.oid?)
	xpWorth = 130,
	dmgReceived = {},
	
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
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
		}
		
		drawDebugWrapper(self)
		if (math.random(-1, 1) > 0) then self.movable = true end
	end,
	
	gainPain = function (self, str)
		--print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
		self.damageUI = DamageUI:new{x = self.x + self.width / 2, y = self.y, text = str}
		GameView.layers.ui:add(self.damageUI)	
	end,
	
	receive = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str = ...
		--	print("DUMMY HEAL", str)
		elseif message_name == "damage" then
			local str = ...
		--	print("DUMMY DAMANGE", str)
			self:gainPain(str)
			-- damage handling for xp distribution
			local damagerTable = {}
			if self.dmgReceived[self.oid] then
				for k,v in pairs(self.dmgReceived) do
					print("existing oid dummy = " .. k .. " with ", v)				
					v[self.hardCodedTarget] = v[self.hardCodedTarget] + str
					print("damage = " .. v[self.hardCodedTarget])
					for key, value in pairs(v) do
						print("damager oid = " .. key,value)
					end
				end
			else 
				self.dmgReceived[self.oid] = damagerTable
				for k,v in pairs(self.dmgReceived) do
					--print("new oid dummy = " .. k .. " with ", v)
					v[self.hardCodedTarget] = str
					--print("damage = " .. v[self.hardCodedTarget])
					for key, value in pairs(v) do
						--print("damager oid = " .. key,value)
					end
				end
			end
		elseif message_name == "damage_over_time" then
			local str, duration, ticks = ...
		--	print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(str)
				end)
			end
		elseif message_name == "runspeed" then
			local str, duration = ...
		--	print("DUMMY SPEED", str, duration)
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
}
