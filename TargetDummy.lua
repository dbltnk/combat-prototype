-- TargetDummy

TargetDummy = Tile:extend
{
	image = '/assets/graphics/dummy.png',
	currentPain = 0,
	maxPain = 100,
	pb = nil,
	pbb = nil,
	wFactor = 0.30,
	movable = false,
	
	onNew = function (self)
		the.targetDummies[self] = true
		
		self.width = 32
		self.height = 64
		self:updateQuad()
		object_manager.create(self)
		--print("NEW DUMMY", self.x, self.y, self.width, self.height)
		the.view.layers.characters:add(self)
		self.pb = PainBar:new{x = self.x, y = self.y, width = self.currentPain * self.wFactor}
		self.pbb = PainBarBG:new{x = self.x, y = self.y, width = self.maxPain * self.wFactor}
		the.view.layers.ui:add(self.pbb)
		the.view.layers.ui:add(self.pb)
		self:updateBarPositions()
		drawDebugWrapper(self)
		if (math.random(-1, 1) > 0) then self.movable = true end
	end,
	
	updateBarPositions = function (self)
		self.pb.x = self.x
		self.pb.y = self.y + 64
		self.pbb.x = self.x
		self.pbb.y = self.y + 64
	end,
	
	gainPain = function (self, str)
		print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
	end,
	
	receive = function (self, message_name, ...)
		print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "heal" then
			local str = ...
			print("DUMMY HEAL", str)
		elseif message_name == "damage" then
			local str = ...
			print("DUMMY DAMANGE", str)
			self:gainPain(str)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks = ...
			print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(str)
				end)
			end
		elseif message_name == "runspeed" then
			local str, duration = ...
			print("DUMMY SPEED", str, duration)
		end
	end,
	
	updatePain = function (self)
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			self:die()
		else
			self.pb.width = self.currentPain * self.wFactor
		end	
	end,
	
	onDie = function (self)
		self.pb:die()
		self.pbb:die()		
		
		the.targetDummies[self] = nil
	end,
	
	onUpdate = function (self)
		if ((math.random(-1, 1) > 0) and self.movable == true) then
			self.dx = math.random(-10, 10)
			self.dy = math.random(-10, 10)
			self.x = self.x + self.dx
			self.y = self.y + self.dy
		end
		
		self:updateBarPositions()
	end,	
}
