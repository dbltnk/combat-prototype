Ressource = Tile:extend
{
	class = "Ressource",

	props = {"x", "y", "rotation", "image", "width", "height", "currentPain", "controller", "description" },	
	
	sync_high = {"currentPain"},
	sync_low = {"controller"},

	owner = 0,

	image = '/assets/graphics/ressource.png',
	currentPain = 0,
	maxPain = config.ressourceHealth,
	wFactor = 0,
	t = Text:new{
		font = 12,
		text = "",
		x = 0,
		y = 0, 
		tint = {0,0,0},
	},	
	controller = 0,
	nextController = 0,
	targetable = true,
	
	-- UiBar
	painBar = nil,
	
	movable = false,
	
	onDraw = function(self)
		if the.app.view.layers.ui:contains(self.t) == false then the.app.view.layers.ui:add(self.t) end	
	end,		
	
	onNew = function (self)
		self:mixin(GameObject)
		self.width = 64
		self.height = 64
		self:updateQuad()
		object_manager.create(self)
		--print("NEW RESSOURCE", self.x, self.y, self.width, self.height)
		the.app.view.layers.characters:add(self)
				
		self.wFactor = self.width / self.maxPain
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
			wFactor = self.wFactor,
		}
		drawDebugWrapper(self)
		
		the.app.view.timer:every(config.xpGainsEachNSeconds, function() self:giveXP() end)
	end,
	
	gainPain = function (self, str)
		--print(self.oid, "gain pain", str)
		self.currentPain = self.currentPain + str
		self:updatePain()
	end,
	
	showDamage = function (self, str)
		if str >= 0 then
			ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {1,0,0}}
		else
			ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = {0,0,1}}
		end
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
			--print("RESSOURCE DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:showDamage(str)
				end)
			end
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("RESSOURCE HEAL_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:showDamage(-str)
				end)
			end	
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid = ...
			--print("RESSOURCE DAMANGE", str)
			self:gainPain(str)
			self.nextController = source_oid
		elseif message_name == "heal" then
			local str, source_oid = ...
			--print("RESSOURCE HEAL", -str)
			self:gainPain(-str)
			self.nextController = source_oid
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("RESSOURCE DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(str)
					self.nextController = source_oid
				end)
			end
		elseif message_name == "heal_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("RESSOURCE HEAL_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(-str)
					self.nextController = source_oid
				end)
			end	
		end
	end,
	
	updatePain = function (self)
		if self.currentPain < 0 then self.currentPain = 0 end
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			--self:die()
			self:changeController()
		end	
	end,
	
	onDie = function (self)
		-- TODO: player-owned
	end,
	
	changeController = function(self)
		self.controller = self.nextController
		self.currentPain = 0
	end,
	
	giveXP = function(self)
		if self.controller ~= 0 then 
			if object_manager.get(self.controller).team then		
				object_manager.visit(function(oid,obj) 
					if obj.team == object_manager.get(self.controller).team then
						object_manager.send(obj, "xp", config.xpPerRessourceTick)
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
		
		local name = "nobody"
		if self.controller ~= 0 then 
			name = self.controller
			local o = object_manager.get(self.controller)
			if o and o.name then
				name = o.name
			end
		end	
		self.t.text = "Owned by: " .. name
		self.t.x = self.x - self.width /4
		self.t.y = self.y - self.t.height
		self.t.width = 120	
		the.ressources[self.description] = name or "none"
	end,	
}
