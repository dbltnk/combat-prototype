-- Score

Score = Animation:extend
{
	class = "Score",

	props = {"x", "y", "rotation", "image", "width", "height", "highscore", "teamscore" },	
	
	sync_low = {"highscore", "teamscore"},

	highscore = {},
	teamscore = {},
	
	onNew = function (self)		
	
		self.x = -1000
		self.y = -1000
		self.visible = false
		self:mixin(GameObject)
		the.score = self
		the.app.view.layers.management:add(self)

		self:every(1, function() 
		    self:redrawHighscore()
		end)
	end,
	
	receiveBoth = function (self, message_name, ...)
		if message_name == "show" then
		    self:showHighscore()
		elseif message_name == "hide" then
		    self:hideHighscore()
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		if message_name == "reset_game" then
		    self.highscore = {}
		    self.teamscore = {}
		end
	end,
	
	updateTeamscore = function(self,source_oid,score)
		-- team highscore
		local src = object_manager.get(source_oid)
		if src then
			if not self.teamscore[src.team] then self.teamscore[src.team] = 0 end
			self.teamscore[src.team] = self.teamscore[src.team] + score
		end
	end,	
	
	updateHighscore = function(self,source_oid,score)
		-- solo highscore
		local src = object_manager.get(source_oid)
		if src then
			if not self.teamscore[src.team] then self.teamscore[src.team] = 0 end
			self.teamscore[src.team] = self.teamscore[src.team] + score
			if not self.highscore[source_oid] then self.highscore[source_oid] = 0 end
			self.highscore[source_oid] = self.highscore[source_oid] + score
		end
	end,	
	
	hideHighscore = function (self)
		loveframes.SetState("none")
	end,

	toggleHighscore = function(self)
	    if loveframes.GetState() == "none" then
		self:showHighscore()
	    else
		self:hideHighscore()
	    end
	end,

	redrawHighscore = function (self)
	    if loveframes.GetState() == "none" then return end
	
	    print("REDRAW")

	    if self.frame then self.frame:Remove() end

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
	    
		    local txt = j .. ". Team " .. name .. " with " .. x.v .. " points"
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
	    
		    local txt = i .. ". " .. name .. " [" .. team .. "] with " .. x.v .. " damage to the jailers"
		    textList[i]= txt
		    i = i + 1

	    end

	    for k,v in pairs(textList) do
		    local text = loveframes.Create("text")
		    text:SetText(v) 
		    lowerList:AddItem(text)
	    end
	end,
	
	showHighscore = function (self, title)
	    if loveframes.GetState() == "none" then 
		loveframes.SetState("highscore")
	    end
	
	    self:redrawHighscore()
	end,
	
	onDieBoth = function (self)
		the.app.view.layers.management:remove(self)
	end,
}
