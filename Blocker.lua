-- Blocker

function SpawnMobAt (x,y)
	Blocker:new{x=x, y=y}
end

Blocker = Animation:extend
{
	class = "Blocker",

	props = {"x", "y", "rotation", "image", "width", "height", "velocity", "creation_time",
		"maxPain", "xpWorth", "finalDamage", "focused_target", "deaths", "animName"},
	sync_high = {"x", "y", "currentPain", "alive", "rooted", "stunned", "mezzed", "snared", "powerblocked", "dmgModified"},
	sync_low = {"focused_target", "animName"},
	
	image = '/assets/graphics/dummy_full.png',
	currentPain = 0,
	maxPain = config.dummyMaxPain,
	xpWorth = config.dummyXPWorth,
	dmgReceived = {},
	damagerTable = {},	
	finalDamage = 0,
	alive = true,
	deaths = 0,
	owner = 0,
	targetable = true,
	attackPossible = true,
	snared = false,
	rooted = false,
	stunned = false,
	mezzed = false,
	powerblocked = false,
	dmgModified = config.dmgUnmodified,
	spawnX = 0,
	spawnY = 0,
	
	-- oid that this mob is focused on
	focused_target = 0,
	last_refocus_time = 0,
	refocus_timeout = 1,
	
	-- UiBar
	painBar = nil,
	
	lastFootstepTime = 0,
	
	footstepsPossible = function (self)
		return love.timer.getTime() - self.lastFootstepTime >= .75
	end,
	
	makeFootstep = function (self)
		self.lastFootstepTime = love.timer.getTime()
	end,
	
	animName = nil,
	
	sequences = 
			{
				walk_down = { frames = {1,2,3,4}, fps = config.mobAnimSpeed },
				walk_left = { frames = {5,6,7,8}, fps = config.mobAnimSpeed },
				walk_right = { frames = {9,10,11,12}, fps = config.mobAnimSpeed },
				walk_up = { frames = {13,14,15,16}, fps = config.mobAnimSpeed },
				freeze_down = { frames = {1}, fps = config.mobAnimSpeed },
				freeze_left = { frames = {5}, fps = config.mobAnimSpeed },
				freeze_right = { frames = {9}, fps = config.mobAnimSpeed },
				freeze_up = { frames = {13}, fps = config.mobAnimSpeed },
			},

	onNew = function (self)
		self:mixin(GameObject)
		self:mixin(FogOfWarObject)
		self:mixin(GameObjectCommons)
		
		the.targetDummies[self] = true
		
		self.width = 40
		self.height = 56
		self:updateQuad()
		object_manager.create(self)
		--print("NEW DUMMY", self.x, self.y, self.width, self.height)
		the.app.view.layers.characters:add(self)
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain,
			width = self.width,
		}
		
		drawDebugWrapper(self)

		self.charDebuffDisplay = CharDebuffDisplay:new{
			x = self.x, y = self.y
		}
		
		self.spawnX, self.spawnY = 0, 0
	end,
	
	gainPain = function (self, str)
		--print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
	end,

	showDamage = function (self, str)
		self:showDamageWithOffset (str, 20)
	end,
	
	trackDamage = function (self, source_oid, str)
		-- zero values
		if not self.dmgReceived[source_oid] then self.dmgReceived[source_oid] = 0 end
		
		-- interesting case
		self.dmgReceived[source_oid] = self.dmgReceived[source_oid] + str
	end,
	
	receiveBoth = function (self, message_name, ...)
		if message_name == "damage" then
			local str, source_oid  = ...
			self:showDamage(str / 100 * self.dmgModified) 
		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
			local oldDeaths = self.deaths
			--~ print("DAMAGE_OVER_TIME", str, duration, ticks, oldDeaths, self.deaths)
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if object_manager.get(self.oid) and self.alive and self.deaths == oldDeaths then 
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
			self.rooted = false
		elseif message_name == "moveSelfTo" then
			local x,y = ...
			self.x = x
			self.y = y
		elseif message_name == "damage_over_time" then 
			local str, duration, ticks, source_oid = ...
			local oldDeaths = self.deaths
		--	print("DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.alive and self.deaths == oldDeaths then 
						self:receiveLocal("damage", str, source_oid)
						self.mezzed = false
						self.rooted = false	
					end
				end)
			end
		elseif message_name == "runspeed" then
			local str, duration = ...
			self.snared = true
			self:after(duration, function()
				self.snared = false
			end)	
		elseif message_name == "root" then
			local duration = ...
			self.rooted = true
			self:after(duration, function()
				self.rooted = false
			end)	
		elseif message_name == "stun" then
			local duration = ...
			self.stunned = true
			self:after(duration, function()
				self.stunned = false
			end)
		elseif message_name == "mezz" then
			local duration = ...
			self.mezzed = true
			self:after(duration, function()
				self.mezzed = false
			end)
		elseif message_name == "powerblock" then
			local duration = ...
			self.powerblocked = true
			self:after(duration, function()
				self.powerblocked = false
			end)	
		elseif message_name == "dmgModifier" then
			local str, duration, source_oid = ...
			--print("dmgModifier", str, duration)
			self.dmgModified = str
			self:after(duration, function() 
				self.dmgModified = config.dmgUnmodified
			end)
		end
	end,
	
	updatePain = function (self)
		if self.currentPain < 0 then self.currentPain = 0 end
		if ((self.currentPain > self.maxPain) and self.alive == true) then 
			self.currentPain = self.maxPain
			self.alive = false
			local x,y = self.x, self.y
			the.app.view.timer:after(config.dummyRespawn, function() SpawnMobAt(self.spawnX, self.spawnY) end)
			self:die()
		end	
	end,
	
	onDieLocal = function (self)	
		-- find out how much xp which player gets and tell him
		for damager, value in pairs(self.dmgReceived) do
			self.finalDamage = self.finalDamage + value
		end

		for damager, value in pairs(self.dmgReceived) do
			object_manager.send(damager, "xp", self.xpWorth / self.finalDamage * value, CHARACTER_XP_CREEPS)
		end
	
		self.deaths = self.deaths + 1
		self.dmgReceived = {}
	end,
	
	onDieBoth = function (self)
		self.painBar:die()
		self.charDebuffDisplay:die()
		the.targetDummies[self] = nil		
		the.app.view.layers.characters:remove(self)
	end,
	
	onUpdateLocal = function (self, elapsed)

		if self.spawnX == 0 and self.spawnY == 0 then
			local amount = #the.validPositions
			local randomNumber = math.random(1,amount)
			self.x, self.y = the.validPositions[randomNumber].x, the.validPositions[randomNumber].y	
			self.spawnX, self.spawnY = self.x, self.y
		end	

		-- refocus needed?
		if love.timer.getTime() - self.last_refocus_time > self.refocus_timeout then
			-- find a player close by
			local l = list.process_values(object_manager.objects)
					:select(function(obj) 
						local dist = vector.lenFromTo(obj.x, obj.y, self.x, self.y)
						return {
							obj=obj, 
							dist=dist,
						} end)
					:where(function(p) 
						local obj = p.obj
						local dist = p.dist
						return (dist <= config.mobSightRange or self.currentPain > 0) and obj.name and not obj.hidden and not obj.incapacitated
					end)
					:orderby(function(a,b) return a.dist < b.dist end)
					:take(1)
					:select(function(a) return a.obj end)
					:done()
			local nearestObj = l[1]
			
			self.focused_target = nearestObj and nearestObj.oid or 0
			--~ if nearestObj then print("NEAREST", nearestObj, self.focused_target,  self.last_refocus_time) end
			self.last_refocus_time = love.timer.getTime()
		end

		local obj = object_manager.get(self.focused_target)
		
		-- lets act
		if obj then	
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
			if (dist <= config.mobSightRange or self.currentPain > 0) and obj.class == "Character" and not obj.hidden then 
				local cx,cy = tools.object_center(self)
				local px,py = tools.object_center(obj)
				
				local dx,dy = vector.fromToWithLen(cx,cy, px,py, speed * elapsed)
				
				self.x, self.y = vector.add(self.x, self.y, dx,dy)
				
				--~ -- let them set some footsteps
				--~ if self:footstepsPossible() then 
					--~ local footstep = Footstep:new{ 
						--~ x = self.x+self.width/2-16, y = self.y+self.height/2-16, 
						--~ rotation = self.rotation, -- todo: fix rotation of the footsteps
					--~ }
					--~ the.footsteps[footstep] = true
					--~ self:makeFootstep()	
				--~ end	
			end
			
			-- let's attack the player here
			self:attack()
		end
	end,
	
	attack = function(self)
		if not self.stunned and not self.mezzed and not self.powerblocked then 
			if self.attackPossible then
				local obj = object_manager.get(self.focused_target)
				if obj then
					local cx,cy = tools.object_center(self)
					local ox,oy = tools.object_center(obj)
					
					local dist = vector.lenFromTo(ox, oy, cx, cy)
					if dist <= config.mobAttackRange and obj.class == "Character" and not obj.hidden then 
						-- really hurt someone
						object_manager.send(obj.oid, "damage", config.mobDamage)
						
						-- visual
						local rotation = vector.toVisualRotation(vector.fromTo(cx, cy, ox, oy))
						
						local img = "assets/graphics/melee_radians/90_120.png"
						EffectImage:new{ x = cx, y = cy, r = 60, image = img, 
							rotation = rotation, color = {0.5,0.5,0.5,0.5}, }
						
						-- reset
						self.attackPossible = false
						self:after(config.mobAttackTimer, function()
							self.attackPossible = true
						end)
					end	
				end
			end	
		end	
	end,
	
	onUpdateBoth = function (self)
		self:play(self.anim_name)
		
		-- look at current focus
		local obj = object_manager.get(self.focused_target)
		if obj then
			local dist = vector.lenFromTo(obj.x, obj.y, self.x, self.y)

			-- make mobs move towards the player
			local rot = vector.toVisualRotation(vector.fromTo (self.x ,self.y, obj.x, obj.y))
			local ddx,ddy = vector.fromVisualRotation(rot, 1)
			local dir = vector.dirFromVisualRotation(ddx,ddy)

			if (dist <= config.mobSightRange or self.currentPain > 0) and obj.name then 
				-- set rotation and animation
				self.anim_name = "walk_" .. dir	
			else
				self.anim_name = "freeze_" .. dir
			end
		end
		
		self:updateFogAlpha()
		
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y	
		self.painBar.bar.alpha = self.alpha
		self.painBar.background.alpha = self.alpha
		
		self.charDebuffDisplay.alpha = self.alpha
		self.charDebuffDisplay.x = self.x
		self.charDebuffDisplay.y = self.y
		
		if self.rooted then self.charDebuffDisplay.rooted = "rooted" else self.charDebuffDisplay.rooted = "" end
		if self.stunned then self.charDebuffDisplay.stunned = "stunned" else self.charDebuffDisplay.stunned = "" end		
		if self.mezzed then self.charDebuffDisplay.mezzed = "mezzed" else self.charDebuffDisplay.mezzed = "" end	
		if self.snared then self.charDebuffDisplay.snared = "snared" else self.charDebuffDisplay.snared = "" end			
		if self.powerblocked then self.charDebuffDisplay.powerblocked = "pb'ed" else self.charDebuffDisplay.powerblocked = "" end	
		if self.dmgModified > config.dmgUnmodified then self.charDebuffDisplay.exposed = "exposed" else self.charDebuffDisplay.exposed = "" end	
	end,
}
