-- TargetDummy

TargetDummy = Animation:extend
{
	class = "TargetDummy",

	props = {"x", "y", "rotation", "image", "width", "height", "velocity", "creation_time",
		"maxPain", "xpWorth", "finalDamage", },			
	sync_high = {"x", "y", "currentPain", "alive"},
	
	image = '/assets/graphics/dummy_full.png',
	currentPain = 0,
	maxPain = 90,
	xpWorth = config.dummyXPWorth,
	dmgReceived = {},
	damagerTable = {},	
	finalDamage = 0,
	alive = true,
	wFactor = 0,	
	timeOfDeath = 0,	
	owner = 0,
	targetable = true,
	attackPossible = true,
	snared = false,
	rooted = false,
	stunned = false,
	mezzed = false,
	powerblocked = false,
	dmgModified = 100,
	
	-- UiBar
	painBar = nil,
	
	movable = false,
	
	lastFootstep = 0,
	
	footstepsPossible = function (self)
		return love.timer.getTime() - self.lastFootstep >= .75
	end,
	
	makeFootstep = function (self)
		self.lastFootstep = love.timer.getTime()
	end,
	
	animName = nil,
	
	sequences = 
			{
				walk_down = { frames = {1,2,3,4}, fps = config.mobAnimSpeed },
				walk_left = { frames = {5,6,7,8}, fps = config.mobAnimSpeed },
				walk_right = { frames = {9,10,11,12}, fps = config.mobAnimSpeed },
				walk_up = { frames = {13,14,15,16}, fps = config.mobAnimSpeed },
			},

	onNew = function (self)
		self:mixin(GameObject)
		
		the.targetDummies[self] = true
		
		self.width = 40
		self.height = 56
		self:updateQuad()
		object_manager.create(self)
		--print("NEW DUMMY", self.x, self.y, self.width, self.height)
		the.app.view.layers.characters:add(self)
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
	end,

	showDamage = function (self, str)
		str = math.floor(str * 10) / 10
		if str >= 0 then
			ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {1,0,0}}
		else
			ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {0,0,1}}
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
	
	receiveBoth = function (self, message_name, ...)
		if message_name == "damage" then
			local str, source_oid  = ...
			self:trackDamage(source_oid, str / 100 * self.dmgModified) 
			self:showDamage(str / 100 * self.dmgModified) 
		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if self.alive then 
						self:trackDamage(source_oid, str / 100 * self.dmgModified) 
						self:showDamage(str / 100 * self.dmgModified) 
					end
				end)
			end
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid  = ...
			-- damage handling for xp distribution	
			self:trackDamage(source_oid, str / 100 * self.dmgModified) 
			--print("DUMMY DAMANGE", str)
			self:gainPain(str / 100 * self.dmgModified) 
			self.mezzed = false
		elseif message_name == "moveSelfTo" then
			local x,y = ...
			self.x = x
			self.y = y
		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
		--	print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if self.alive then 
						self:trackDamage(source_oid, str / 100 * self.dmgModified) 
						self:gainPain(str / 100 * self.dmgModified) 
						self.mezzed = false	
					end
				end)
			end
		elseif message_name == "runspeed" then
			local str, duration = ...
			self.snared = true
			the.app.view.timer:after(duration, function()
				self.snared = false
			end)	
		elseif message_name == "root" then
			local duration = ...
			self.rooted = true
			the.app.view.timer:after(duration, function()
				self.rooted = false
			end)	
		elseif message_name == "stun" then
			local duration = ...
			self.stunned = true
			the.app.view.timer:after(duration, function()
				self.stunned = false
			end)
		elseif message_name == "mezz" then
			local duration = ...
			self.mezzed = true
			the.app.view.timer:after(duration, function()
				self.mezzed = false
			end)
		elseif message_name == "powerblock" then
			local duration = ...
			self.powerblocked = true
			the.app.view.timer:after(duration, function()
				self.powerblocked = false
			end)	
		elseif message_name == "dmgModifier" then
			local str, duration, source_oid = ...
			--print("dmgModifier", str, duration)
			self.dmgModified = str
			the.app.view.timer:after(duration, function() 
					self.dmgModified = 100
			end)					
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
		-- find out how much xp which player gets and tell him
		local myDmgReceived = self.dmgReceived[self.oid]
		if myDmgReceived then
		  for damager, value in pairs(myDmgReceived) do
			self.finalDamage = self.finalDamage + value
		  end
		  
		  for damager, value in pairs(myDmgReceived) do
			object_manager.send(damager, "xp", self.xpWorth / self.finalDamage * value)
		  end
		end
	
		self.timeOfDeath = love.timer.getTime()
		the.app.view.timer:after(config.dummyRespawn,function() self:revive() self:respawn() end)
	end,
	
	onDieBoth = function (self)
		self.painBar:die()
		the.targetDummies[self] = nil		
	end,
	
	onUpdateLocal = function (self, elapsed)
		-- find a player close by
		object_manager.visit(function(oid,obj) 
			local dist = vector.lenFromTo(obj.x, obj.y, self.x, self.y)
			
			local speed = 0
			if self.rooted or self.stunned or self.mezzed then 
				speed = 0 
			elseif self.snared then 
				speed = config.mobMovementSpeed / 2 
			else 
				speed = config.mobMovementSpeed 
			end
			
			-- make mobs move towards the player
			if (dist <= config.mobSightRange or self.currentPain > 0) and obj.name and not obj.hidden then 
				if self.x < obj.x then -- todo: find better movement code for this
					self.x = self.x + speed* elapsed
				else
					self.x = self.x - speed * elapsed
				end	
				
				if self.y < obj.y then
					self.y = self.y + speed * elapsed
				else
					self.y = self.y - speed * elapsed
				end	
				
				-- let them set some footsteps
				if self:footstepsPossible() then 
					local footstep = Footstep:new{ 
						x = self.x+self.width/2-16, y = self.y+self.height/2-16, 
						rotation = self.rotation, -- todo: fix rotation of the footsteps
					}
					the.footsteps[footstep] = true
					self:makeFootstep()	
				end	
			end
		end)	
		-- let's attack the player here
		self:attack()
	end,
	
	attack = function(self)
		if not self.stunned and not self.mezzed and not self.powerblocked then 
			if self.attackPossible then
				object_manager.visit(function(oid,obj)
					local dist = vector.lenFromTo(obj.x, obj.y, self.x, self.y)
					if dist <= config.mobAttackRange and obj.name and not obj.hidden then 
						object_manager.send(obj.oid, "damage", config.mobDamage) 	
						self.attackPossible = false					
						the.app.view.timer:after(config.mobAttackTimer, function()
							self.attackPossible = true
						end)
					end	
				end)
			end	
		end	
	end,
	
	onUpdateBoth = function (self)
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y	
		self.painBar.bar.alpha = self.alpha
		self.painBar.background.alpha = self.alpha		
		
		self:play(self.anim_name)
		
		-- find a player close by
		object_manager.visit(function(oid,obj) 
			local dist = vector.lenFromTo(obj.x, obj.y, self.x, self.y)
			-- make mobs move towards the player
			if (dist <= config.mobSightRange or self.currentPain > 0) and obj.name then 
				-- set rotation and animation
				self.rotation = vector.toVisualRotation(vector.fromTo (self.x ,self.y, obj.x, obj.y))	
				local ddx,ddy = vector.fromVisualRotation(self.rotation, 1)
				local dir = vector.dirFromVisualRotation(ddx,ddy)
				self.anim_name = "walk_" .. dir	
				self.rotation = 0
			else
				--~ self:freeze() -- todo: freeze animation
			end
		end)
	end,	
	
	respawn = function (self)
		self:mixin(GameObject)
		the.targetDummies[self] = true	
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
