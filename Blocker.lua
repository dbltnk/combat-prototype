-- Blocker

Blocker = Animation:extend
{
	class = "Blocker",

	props = {"x", "y", "rotation", "image", "width", "height", "velocity", "creation_time",
		"maxPain", "animName"},
	sync_high = {"x", "y", "currentPain", "alive"},
	sync_low = {"animName"},
	
	image = '/assets/graphics/blocker.png',
	currentPain = 0,
	maxPain = config.blockerMaxPain,
	alive = true,
	targetable = true,
	
	-- UiBar
	painBar = nil,
	
	animName = nil,
	
	sequences = 
			{
				freeze_down = { frames = {1}, fps = 1 },
			},

	onNew = function (self)
		self:mixin(GameObject)
		self:mixin(FogOfWarObject)
		self:mixin(GameObjectCommons)
		the.blockers[self] = true
		
		self.width = 32
		self.height = 32
		self:updateQuad()
		object_manager.create(self)
		
		the.lineOfSight.dirty = true
		
		--print("NEW BLOCKER", self.x, self.y, self.width, self.height)
		the.app.view.layers.characters:add(self)
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain,
			width = self.width,
		}
		
		drawDebugWrapper(self)
		the.gridIndexCollision:insertAt(self.x,self.y,self)
	end,
	
	gainPain = function (self, str)
		--print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
	end,

	showDamage = function (self, str)
		self:showDamageWithOffset (str, 20)
	end,
	
	receiveBoth = function (self, message_name, ...)
		print(self.oid, "receives message in both", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid  = ...
			self:showDamage(str) 
			print("receiveBoth")
		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
			--~ print("DAMAGE_OVER_TIME", str, duration, ticks, oldDeaths, self.deaths)
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if object_manager.get(self.oid) and self.alive then 
						self:showDamage(str) 
					end
				end)
			end
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		print(self.oid, "receives message in local", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid  = ...
			self:gainPain(str) 
			print("receiveLocal")
		elseif message_name == "moveSelfTo" then
			local x,y = ...
			self.x = x
			self.y = y
		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
		--	print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.alive then 
						self:receiveLocal("damage", str, source_oid)
					end
				end)
			end
		end
	end,
	
	updatePain = function (self)
		if self.currentPain < 0 then self.currentPain = 0 end
		if ((self.currentPain > self.maxPain) and self.alive == true) then 
			self.currentPain = self.maxPain
			self.alive = false
			self:die()
		end	
	end,
	
	onDieLocal = function (self)	
	
	end,
	
	onDieBoth = function (self)
		the.gridIndexCollision:removeObject(self)
		self.painBar:die()
		the.blockers[self] = nil		
		the.app.view.layers.characters:remove(self)
		the.lineOfSight.dirty = true
	end,
	
	onUpdateLocal = function (self, elapsed)
		self:gainPain(config.blockerDecaySpeed)
	end,
	
	onUpdateBoth = function (self)
		self:play(self.anim_name)
		self:updateFogAlpha()
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y	
		self.painBar.bar.alpha = self.alpha
		self.painBar.background.alpha = self.alpha
end,
}
