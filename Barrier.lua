-- Barrier

Barrier = Tile:extend
{
	class = "Barrier",

	props = {"x", "y", "rotation", "image", "width", "height", "currentPain", "alive", "highscore", "teamscore" },	
	
	sync_low = {"highscore", "teamscore"},
	sync_high = {"currentPain", "alive"},

	image = '/assets/graphics/barrier.png',
	currentPain = 0,
	maxPain = config.barrierHealth,
	highscore = {},
	teamscore = {},
	owner = 0,
	targetable = true,
	
	frame = nil,

	-- UiBar
	painBar = nil,
	
	movable = false,
	
	onNew = function (self)		
		the.barrier = self
		
		self:mixin(GameObject)
		self:mixin(FogOfWarObject)
		
		self.width = 96
		self.height = 192
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
	end,
	
	gainPain = function (self, str)
	--	print(self.oid, "gain pain", str)
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
	
	receiveBoth = function (self, message_name, ...)
		if message_name == "damage" then
			local str, source_oid = ...
			self:showDamage(str)
		elseif message_name == "damage_over_time" then
			local str, duration, ticks, source_oid = ...
			--print("BARRIER DAMAGE_OVER_TIME", str, duration, ticks)
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if self.alive then self:showDamage(str) end
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
			for i=0,ticks do
				the.app.view.timer:after(duration / ticks * i, function()
					if self.alive then
						self:gainPain(str)
						self:updateHighscore(source_oid,str)
					end
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
		-- solo highscore
		if not self.highscore[source_oid] then self.highscore[source_oid] = 0 end
		self.highscore[source_oid] = self.highscore[source_oid] + score
		-- team highscore
		if not self.teamscore[object_manager.get(source_oid).team] then self.teamscore[object_manager.get(source_oid).team] = 0 end
		self.teamscore[object_manager.get(source_oid).team] = self.teamscore[object_manager.get(source_oid).team] + score
	end,	
	
	showHighscore = function (self, title)
		if self.frame then self.frame:Remove() self.frame = nil end
	
		if loveframes.GetState() == "none" then 
			loveframes.SetState("highscore")
		else 
			loveframes.SetState("none")
		end
		
		local frm = loveframes.Create("frame")
		self.frame = frm
		frm:SetSize(400, 400)
		frm:Center()
		frm:SetName(title or "Highscore")
		frm:SetState("highscore")
		
        for _,v in pairs(self.teamscore) do
			v = math.floor(v * 10000) / 10000
		end
				
		--show the team highscores
		local l3 = list.process_keys(self.teamscore)       -- holt alle keys (oids)
        :orderby(function(a,b) return self.teamscore[a] > self.teamscore[b] end)      -- sortiert diese nach werten aus map
        :select(function (a) return {k=a, v=self.teamscore[a]} end)        -- und gibt eine liste zurück mit k und v einträge
        :done() -- l3 ist nun sortiert und hat alle relevanten daten in den elementen k,v gespeichert
		
		local upperList = loveframes.Create("list", frm)
		upperList:SetPos(5, 30)
		upperList:SetSize(390, 85)
		upperList:SetDisplayType("vertical")
		upperList:SetPadding(5)
		upperList:SetSpacing(5)
		
		local j = 1
		local textListTeam = {}
		for _,x in pairs(l3) do
		
			local name = "nobody"
			if x.k ~= 0 then 
				name = x.k
				local o = object_manager.get(x.k)
				if o and o.name then
					name = o.name
				end
			end	
		
			local txt = j .. ". Team " .. name .. " with " .. x.v .. " damage to the barrier"
			textListTeam[j]= txt	
			j = j + 1

		end

		for k,v in pairs(textListTeam) do
			local text = loveframes.Create("text")
			text:SetText(v) 
			upperList:AddItem(text)
		end
		
        for _,v in pairs(self.highscore) do
			v = math.floor(v * 10000) / 10000
		end
		
		--~ -- show the player highscores 
		local l2 = list.process_keys(self.highscore)       -- holt alle keys (oids)
        :orderby(function(a,b) return self.highscore[a] > self.highscore[b] end)      -- sortiert diese nach werten aus map
        :select(function (a) return {k=a, v=self.highscore[a]} end)        -- und gibt eine liste zurück mit k und v einträge
        :done() -- l2 ist nun sortiert und hat alle relevanten daten in den elementen k,v gespeichert

		local lowerList = loveframes.Create("list", frm)
		lowerList:SetPos(5, 120)
		lowerList:SetSize(390, 275)
		lowerList:SetDisplayType("vertical")
		lowerList:SetPadding(5)
		lowerList:SetSpacing(5)
		
		local i = 1
		local textList = {}
		for _,x in pairs(l2) do
		
			local name = "nobody"
			local team = "no team"
			if x.k ~= 0 then 
				name = x.k
				local o = object_manager.get(x.k)
				if o and o.name then
					name = o.name
				end
				if o and o.team then
					team = o.team
				end
			end	
		
			local txt = i .. ". " .. name .. " [" .. team .. "] with " .. x.v .. " damage to the barrier"
			textList[i]= txt
			i = i + 1

		end

		for k,v in pairs(textList) do
			local text = loveframes.Create("text")
			text:SetText(v) 
			lowerList:AddItem(text)
		end

	end,
	
	onDieBoth = function (self)
		self.painBar:die()
	end,
	
	onDieLocal = function (self)
		
	end,
	
	onUpdateBoth = function (self)	
		self.painBar.currentValue = self.currentPain
		self.painBar:updateBar()
		self.painBar.x = self.x
		self.painBar.y = self.y
		self:updateFogAlpha()
		self.painBar.bar.alpha = self.alpha
		self.painBar.background.alpha = self.alpha
	end,	
}
