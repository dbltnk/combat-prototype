
local Ressource_usedIndex = {}


Ressource = Tile:extend
{
	class = "Ressource",

	props = {"x", "y", "rotation", "image", "width", "height", "currentPain", "controller", "description", "deaths", "quality"},	
	
	sync_high = {"currentPain"},
	sync_low = {"controller", "deaths", "quality"},

	owner = 0,

	image = '/assets/graphics/ressource.png',
	currentPain = 0,
	maxPain = config.ressourceHealth,
	t = Text:new{
		font = 12,
		text = "",
		x = 0,
		y = 0, 
		tint = {0,0,0},
	},	
	controller = "",
	nextController = "",
	targetable = true,
	deaths = 0,
	quality = 0,
	
	-- UiBar
	painBar = nil,
	
	movable = false,
	
	onDraw = function(self)
		if the.app.view.layers.ui:contains(self.t) == false then the.app.view.layers.ui:add(self.t) end	
	end,		
	
	onNew = function (self)
		self:mixin(GameObject)
		self:mixin(GameObjectCommons)
		self:mixin(FogOfWarObject)
		self.width = 64
		self.height = 64
		self:updateQuad()
		object_manager.create(self)
		--print("NEW RESSOURCE", self.x, self.y, self.width, self.height)
		the.app.view.layers.characters:add(self)
				
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
			width = self.width,
		}
		drawDebugWrapper(self)
		
		self:every(config.xpGainsEachNSeconds, function() 
			if self:isLocal() then self:giveXP() end
		end)
		
		-- over time tracking
		self:every(config.trackingOverTimeTimeout, function() 
			if self:isLocal() and the.phaseManager and the.phaseManager.phase == "playing" then
				track("resource_ot", self.oid, self.description, self.currentPain, self.controller)
			end
		end)

                local amount = #config.ressourceQualityTable

                local count = 0
                for k,v in pairs(Ressource_usedIndex) do count = count + 1 end
                if count == amount then Ressource_usedIndex = {} end
                
                local randomNumber = nil
                while true do
                    randomNumber = math.random(1,amount)
                    if not Ressource_usedIndex[randomNumber] then break end
                end
                Ressource_usedIndex[randomNumber] = true
		self.quality = config.ressourceQualityTable[randomNumber]

		the.ressourceObjects[self] = true
		
		the.gridIndexCollision:insertAt(self.x,self.y,self)
	end,
	
	gainPain = function (self, str, source_oid)
		--print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
		
		-- dmg tracking
		object_manager.send(source_oid, "inc", "resource_dmg", str)
	end,
	
	showDamage = function (self, str)
		self:showDamageWithOffset (str, 30)
	end,	
	
	receiveBoth = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid = ...
			--print("RESSOURCE DAMAGE", str)
			self:showDamage(str)
		elseif message_name == "heal" then
			local str, source_oid = ...
			--print("RESSOURCE HEAL", -str)
			self:showDamage(-str)	
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--~ print("RESSOURCE DAMAGE_OVER_TIME", str, duration, ticks, source_oid)
			local oldDeaths = self.deaths
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then
						self:showDamage(str)
					end
				end)
			end
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			local oldDeaths = self.deaths			
			--print("RESSOURCE HEAL_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then
						self:showDamage(-str)
					end
				end)
			end	
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid = ...
			--~ print("RESSOURCE DAMANGE", str, source_oid)
			self:controllerChanger(source_oid)
			self:gainPain(str, source_oid)
		elseif message_name == "heal" then
			local str, source_oid = ...
			--print("RESSOURCE HEAL", -str)
			self:controllerChanger(source_oid)
			self:gainPain(-str, source_oid)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--~ print("RESSOURCE DAMAGE_OVER_TIME", str, duration, ticks, source_oid)
			local oldDeaths = self.deaths
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then
						self:controllerChanger(source_oid)
						self:gainPain(str, source_oid)
					end
				end)
			end
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("RESSOURCE HEAL_OVER_TIME", str, duration, ticks)
			local oldDeaths = self.deaths
			for i=0,ticks do
				self:after(duration / ticks * i, function()
					if self.deaths == oldDeaths then
						self:controllerChanger(source_oid)
						self:gainPain(-str, source_oid)
					end
				end)
			end	
		end
	end,
	
	controllerChanger = function (self, source_oid)
		local source = object_manager.get(source_oid)
		if source then
			self.nextController = source.team
		else 
			self.nextController = "unknown"
		end
		--~ print("CONTROLLER CHANGE", source_oid, self.nextController)
	end,
	
	updatePain = function (self)
		if self.currentPain < 0 then self.currentPain = 0 end
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			--self:die()
			self:changeController()
		end	
	end,
	
	changeController = function(self)
		--~ print("REALLY CHANGE CONTROLLER", self.nextController)
		self.controller = self.nextController
		self.currentPain = 0
		self.deaths = self.deaths + 1
	end,
	
	giveXP = function(self)
		if self.controller then 
			object_manager.visit(function(oid,obj) 
				if obj.team and obj.team == self.controller then
					object_manager.send(oid, "xp", config.xpPerRessourceTick * self.quality, CHARACTER_XP_RESOURCE)
				end
			end)
		end
	end,	
	
	onUpdateBoth = function (self)	
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.bar.alpha = self.alpha
		self.painBar.background.alpha = self.alpha		
		self.painBar.x = self.x
		self.painBar.y = self.y
		
		local name = "nobody"
		if self.controller ~= "" then 
			name = self.controller
		end	
		self.t.text = "Lvl " .. self.quality .. " ressource \nOwned by: " .. name
		self.t.x = self.x - self.width /4
		self.t.y = self.y - self.t.height - 20
		self.t.alpha = self.alpha
		self.t.width = 120	
		the.ressources[self.description] = name or "none"
		self:updateFogAlpha()
	end,
	
	onDieBoth = function (self)
		the.gridIndexCollision:removeObject(self)
		self.painBar:die()
		self.painBar = nil
		
		self.t:die()
		self.t = nil
		
		the.ressourceObjects[self] = nil
	end,
}
