-- Barrier

Barrier = Tile:extend
{
	class = "Barrier",

	props = {"x", "y", "rotation", "image", "width", "height", "currentPain", "alive" },	
	
	sync_high = {"currentPain", "alive"},

	image = '/assets/graphics/barrier.png',
	currentPain = 0,
	maxPain = config.barrierHealth,
	wFactor = 0,
	highscore = {},

	-- UiBar
	painBar = nil,
	
	movable = false,
	
	onNew = function (self)		
		self:mixin(GameObject)
		
		self.width = 96
		self.height = 192
		self:updateQuad()
		--print("NEW BARRIER", self.x, self.y, self.width, self.height)
		the.app.view.layers.characters:add(self)
		self.wFactor = self.width / self.maxPain
		
		self.painBar = UiBar:new{
			x = self.x, y = self.y, 
			dx = 0, dy = self.height,
			currentValue = self.currentPain, maxValue = self.maxPain, 
			wFactor = self.wFactor,
		}
		
		drawDebugWrapper(self)
	end,
	
	gainPain = function (self, str)
	--	print(self.oid, "gain pain", str)
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
		if message_name == "damage" then
			local str, source_oid = ...
			self:showDamage(str)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("BARRIER DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:showDamage(str)
				end)
			end
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		--print(self.oid, "receives message", message_name, "with", ...)
		if message_name == "damage" then
			local str, source_oid = ...
			--print("BARRIER DAMANGE", str)
			self:gainPain(str)
			self:updateHighscore(source_oid,str)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("BARRIER DAMAGE_OVER_TIME", str, duration, ticks)
			for i=1,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					self:gainPain(str)
					self:updateHighscore(source_oid,str)
				end)
			end
		end
	end,
	
	updatePain = function (self)
		if self.currentPain > self.maxPain then 
			self.currentPain = self.maxPain
			self:die()
		end	
	end,
	
	updateHighscore = function(self,source_oid,score)
		if not self.highscore[source_oid] then self.highscore[source_oid] = 0 end
		self.highscore[source_oid] = self.highscore[source_oid] + score
	end,	
	
	showHighscore = function (self)
		if loveframes.GetState() == "none" then loveframes.SetState("highscore") else loveframes.SetState("none") end
		
		local l2 = list.process_keys(self.highscore)       -- holt alle keys (oids)
        :orderby(function(a,b) return self.highscore[a] > self.highscore[b] end)      -- sortiert diese nach werten aus map
        :select(function (a) return {k=a, v=self.highscore[a]} end)        -- und gibt eine liste zurück mit k und v einträge
        :done() -- l2 ist nun sortiert und hat alle relevanten daten in den elementen k,v gespeichert
		
		local frame = loveframes.Create("frame")
		frame:SetSize(350, 300)
		frame:Center()
		frame:SetName("Highscore")
		frame:SetState("highscore")

		local list = loveframes.Create("list", frame)
		list:SetPos(5, 30)
		list:SetSize(340, 265)
		list:SetDisplayType("vertical")
		list:SetPadding(5)
		list:SetSpacing(5)
		
		local i = 1
		local textList = {}
		for _,x in pairs(l2) do
		
			local name = "nobody"
			if x.k ~= 0 then 
				name = x.k
				local o = object_manager.get(x.k)
				if o and o.name then
					name = o.name
				end
			end	
		
			local txt = i .. ". " .. name .. " with " .. x.v .. " damage to the barrier"
			textList[i]= txt
			i = i + 1
		end

		for k,v in pairs(textList) do
			local text = loveframes.Create("text")
			text:SetText(v) 
			list:AddItem(text)
		end
				
	end,
	
	onDieBoth = function (self)
		self.painBar:die()
		os.exit()
		print("THE GAME JUST ENDED") -- TODO: call end screen
	end,
	
	onUpdateBoth = function (self)	
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y
	end,	
}
