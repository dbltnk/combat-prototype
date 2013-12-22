-- Barrier

Barrier = Animation:extend
{
	class = "Barrier",

	props = {"x", "y", "rotation", "image", "width", "height", "currentPain", "alive", "focused_target", "rooted", "stunned", "mezzed", "snared", "powerblocked", "dmgModified", "stage", "maxPain", "deaths", "animName" },	
	
	sync_low = {"focused_target", "maxPain", "width", "height", "deaths", "animName"},
	sync_high = {"x", "y", "currentPain", "alive", "rooted", "stunned", "mezzed", "snared", "powerblocked", "dmgModified", "stage"},

	image = '/assets/graphics/boss_1.png',
	currentPain = 0,
	maxPain = 0,
	deaths = 0,
	owner = 0,
	targetable = true,
	
	frame = nil,

	-- UiBar
	painBar = nil,
	
	movable = false,
	
	-- oid that this mob is focused on
	focused_target = 0,
	last_refocus_time = 0,
	refocus_timeout = 1,
	
	animName = nil,
	
	attackPossible = true,
	snared = false,
	rooted = false,
	stunned = false,
	mezzed = false,
	powerblocked = false,
	dmgModified = config.dmgUnmodified,
	
	spawnX = 0,
	spawnY = 0,
	
	stage = 1,
		
	xyMonitor = nil,
	
	sequences = 
			{
				walk_down = { frames = {1,2,3,4}, fps = config.bossAnimSpeed },
				walk_left = { frames = {5,6,7,8}, fps = config.bossAnimSpeed },
				walk_right = { frames = {9,10,11,12}, fps = config.bossAnimSpeed },
				walk_up = { frames = {13,14,15,16}, fps = config.bossAnimSpeed },
				freeze_down = { frames = {1}, fps = config.bossAnimSpeed },
				freeze_left = { frames = {5}, fps = config.bossAnimSpeed },
				freeze_right = { frames = {9}, fps = config.bossAnimSpeed },
				freeze_up = { frames = {13}, fps = config.bossAnimSpeed },
			},
			
	setStageVariables = function (self)
		
		if self.stage == 1 or self.stage == 2 then
			self.width = 64
			self.height = 96
		elseif self.stage == 3 then
			self.width = 80
			self.height = 112
		elseif self.stage == 4 then
			self.width = 96
			self.height = 128		
		else
			self.width = 160
			self.height = 160	
		end
		
		self.image = "/assets/graphics/boss_" .. self.stage .. ".png"
		self.maxPain = config["bossHealth_" .. self.stage]
	end,
	
	onNew = function (self)		
	
		self.width = 64
		self.height = 96

		self.image = "/assets/graphics/boss_1.png"
		self.maxPain = config.bossHealth_1
		
		the.barrier = self
		
		self:mixin(GameObject)
		self:mixin(GameObjectCommons)
		self:mixin(FogOfWarObject)
		
		
		self:updateQuad()
		--print("NEW BARRIER", self.x, self.y, self.width, self.height)
		the.app.view.layers.characters:add(self)
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
			width = self.width
		}
		
		drawDebugWrapper(self)
		
		-- over time tracking
		self:every(config.trackingOverTimeTimeout, function() 
			if self:isLocal() and the.phaseManager and the.phaseManager.phase == "playing" then
				track("barrier_ot", self.currentPain)
			end
		end)
		
		self.charDebuffDisplay = CharDebuffDisplay:new{
			x = self.x, y = self.y
		}
		
		self.spawnX, self.spawnY = self.x, self.y
		
		-- keep character index in sync		
		the.gridIndexMovable:insertAt(self.x,self.y,self)
		print("INSERT INTO GRID", self.oid, self.x, self.y)
		self.xyMonitor = XYMonitor:new{
			obj = self,
			onChangeFunction = function(ox,oy, nx,ny)
				the.gridIndexMovable:moveFromTo(self, ox,oy, nx,ny)
			end,
		}
	end,
	
	gainPain = function (self, str, source_oid)
	--	print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain(source_oid)
	end,
	
	showDamage = function (self, str)
		self:showDamageWithOffset (str, 0)
	end,
	
	receiveBoth = function (self, message_name, ...)
		if message_name == "damage" then
			local str, source_oid = ...
			self:showDamage(str)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			local oldDeaths = self.deaths			
			--print("BARRIER DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then 
						self:showDamage(str)
					end
				end)
			end
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid = ...
			--print("BARRIER DAMANGE", str)
			self:gainPain(str, source_oid)
			self:updateHighscore(source_oid,str)
			self.mezzed = false
			self.rooted = false	
		elseif message_name == "moveSelfTo" then
			local x,y = ...
			self.x = x
			self.y = y	
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("BARRIER DAMAGE_OVER_TIME", str, duration, ticks)
			local oldDeaths = self.deaths			
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then 
						self:gainPain(str, source_oid)
						self:updateHighscore(source_oid,str)
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
	
	updatePain = function (self, source_oid)
		if self.currentPain >= self.maxPain and self.stage == 5 then 
			--~ print("died")
			local str = config["bossHealth_" .. self.stage]   
			self:updateTeamscore(source_oid, str)
			if the.score then
			    object_manager.send(the.score.oid, "show") 
			end
			self:die()
		end	
		if self.currentPain > self.maxPain and self.stage < 5 then 
			local str = config["bossHealth_" .. self.stage]
			self:updateTeamscore(source_oid, str)
			self:callNextBoss()
		end	
		--~ print(self.currentPain, self.maxPain, self.stage)
	end,
	
	callNextBoss = function (self)
		self.deaths = self.deaths + 1
		self.stage = self.stage + 1
		self.x, self.y = self.spawnX, self.spawnY	
		self.focused_target = 0
		self.currentPain = 0	
		self.snared = false
		self.rooted = false
		self.mezzed = false
		self.stunned = false
		self.powerblocked = false
		self.dmgModified = config.dmgUnmodified
		self:setStageVariables()
		
		-- animation fix
		self.anim_name = "freeze_down"
	end,
	
	updateTeamscore = function(self,source_oid,score)
		-- team highscore
		the.score:updateTeamscore(source_oid, score)
	end,	
	
	updateHighscore = function(self,source_oid,score)
		-- solo highscore
		the.score:updateHighscore(source_oid, score)
		-- dmg tracking
		object_manager.send(source_oid, "inc", "barrier_dmg", score)
	end,	
	
	onDieBoth = function (self)
		the.gridIndexMovable:removeObject(self)
		self.painBar:die()
		self.charDebuffDisplay:die()
	end,
	
	onDieLocal = function (self)
		
	end,
	
	onUpdateLocal = function (self, elapsed)
	
		-- move back into map if outside
		local px,py = self.x+self.width/2, self.y+self.height/2
		if px < 0 or px > config.map_width or py < 0 or py > config.map_height then
			local dx,dy = vector.fromToWithLen(px,py,config.map_width/2,config.map_height/2,200)
			self.x, self.y = self.x+dx,self.y+dy
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
						return (dist <= config.bossSightRange or self.currentPain > 0) and obj.name and not obj.hidden and not obj.incapacitated
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
				speed = config["bossMovementSpeed_" .. self.stage] / 2 
			else 
				speed = config["bossMovementSpeed_" .. self.stage]
			end
			
			-- make mobs move towards the player
			if (dist <= config.bossSightRange or self.currentPain > 0) and obj.class == "Character" and not obj.hidden then 
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
					if dist <= self.height / 2 + 20 and obj.class == "Character" and not obj.hidden then 
						-- really hurt someone
						object_manager.send(obj.oid, "damage", config["bossDamage_" .. self.stage])
						
						-- visual
						local rotation = vector.toVisualRotation(vector.fromTo(cx, cy, ox, oy))
						
						local img = "assets/graphics/melee_radians/90_120.png"
						EffectImage:new{ x = cx, y = cy, r = 60, image = img, 
							rotation = rotation, color = {0.5,0.5,0.5,0.5}, }
						
						-- reset
						self.attackPossible = false
						self:after(config.bossAttackTimer, function()
							self.attackPossible = true
						end)
					end	
				end
			end	
		end	
	end,
	
	onUpdateBoth = function (self)	
		self.painBar.currentValue = self.currentPain
		self.painBar.maxValue = self.maxPain
		self.painBar.width = self.width
		self.painBar.x = self.x
		self.painBar.y = self.y
		self.painBar:updateBar()
		self:updateFogAlpha()
		self.painBar.bar.alpha = self.alpha
		self.painBar.background.alpha = self.alpha
		
		self.charDebuffDisplay.alpha = self.alpha
		self.charDebuffDisplay.x = self.x + self.width / 2
		self.charDebuffDisplay.y = self.y + self.height / 2 + 20

		self:play(self.anim_name)
		
		-- look at current focus
		local obj = object_manager.get(self.focused_target)
		if obj then
			local dist = vector.lenFromTo(obj.x, obj.y, self.x, self.y)

			-- make mobs move towards the player
			local rot = vector.toVisualRotation(vector.fromTo (self.x ,self.y, obj.x, obj.y))
			local ddx,ddy = vector.fromVisualRotation(rot, 1)
			local dir = vector.dirFromVisualRotation(ddx,ddy)

			if (dist <= config.bossSightRange or self.currentPain > 0) and obj.name then 
				-- set rotation and animation
				self.anim_name = "walk_" .. dir	
			else
				self.anim_name = "freeze_" .. dir
			end
		end
		
		if self.rooted then self.charDebuffDisplay.rooted = "rooted" else self.charDebuffDisplay.rooted = "" end
		if self.stunned then self.charDebuffDisplay.stunned = "stunned" else self.charDebuffDisplay.stunned = "" end		
		if self.mezzed then self.charDebuffDisplay.mezzed = "mezzed" else self.charDebuffDisplay.mezzed = "" end	
		if self.snared then self.charDebuffDisplay.snared = "snared" else self.charDebuffDisplay.snared = "" end			
		if self.powerblocked then self.charDebuffDisplay.powerblocked = "pb'ed" else self.charDebuffDisplay.powerblocked = "" end	
		if self.dmgModified > config.dmgUnmodified then self.charDebuffDisplay.exposed = "exposed" else self.charDebuffDisplay.exposed = "" end	
		
		self.xyMonitor:checkAndCall()
	end,	
}
