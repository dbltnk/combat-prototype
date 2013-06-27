-- PhaseManager

PhaseManager = Sprite:extend
{
	class = "PhaseManager",

	props = {"gameId", "x", "y", "width", "height", "phase", "round", "round_start_time", "round_end_time", "next_xp_reset_time"},
	sync_low = {"gameId", "phase", "round", "round_start_time", "round_end_time", "next_xp_reset_time"},
	phase = "init_needed", -- "init_needed", "warmup", "playing", "after"
	round = 0,
	owner = 0,
	
	gameId = 0,
	
	round_start_time = 0,
	next_xp_reset_time = 0,
	round_end_time = 0,
	highscore_displayed = false,

	width = 1,
	height = 1,
	
	onNew = function (self)
		self.x = -1000
		self.y = -1000
		self.visible = false
		self:mixin(GameObject)
		the.phaseManager = self
		the.app.view.layers.management:add(self)
		
		if self.phase == "warmup" and localconfig.spectator == false then switchToPlayer() end
		
		-- rejoin?
		if self:isLocal() == false and self.phase == "playing" then
			network.get("gameId", function(gameId)
				print("REJOIN", gameId)
				
				local lastState = storage.load("game.json")
				
				if lastState and lastState.gameId == gameId then
				
					if the.player then
						if the.player.class == "Ghost" then
							the.player:die()
							the.player = Player:new(lastState.props)
							the.app.view:setFogEnabled(true)
						end
					end
					
				end
			end)
		end
		
		self:every(1, function() 
			self:storePlayerState()
		end)
	end,
	
	storePlayerState = function (self)
		if the.player and the.player.props and self.gameId and self.phase == "playing" then
			local lastState = { gameId = self.gameId, props = {} }
			
			local propsToStore = {"x", "y", "rotation", "image", "width", "height", "currentPain", "maxPain", "level", "anim_name", 
				"anim_speed", "velocity", "alive", "incapacitated", "name", "weapon", "armor", "team", "deaths"}
			
			for _,v in pairs(propsToStore) do
				lastState.props[v] = the.player[v]
			end
			lastState.props["oid"] = the.player.oid
			storage.save("game.json", lastState)
		end
	end,
	
	forceNextPhase = function (self)
		if self.phase == "warmup" then
			self.round_start_time = network.time
			self.round_end_time = network.time + config.roundTime
		elseif self.phase == "playing" then
			self.round_end_time = network.time
		elseif self.phase == "after" then
			self.round_end_time = network.time - config.afterTime
		end
	end,
	
	onUpdateLocal = function (self)
		--~ print("onUpdateLocal", self.phase)
		if self.phase == "init_needed" then
			self:changePhaseToWarmup()
		elseif self.phase == "warmup" then
			if network.time > self.round_start_time then
				self:changePhaseToPlaying()
			end
		elseif self.phase == "playing" then
			if the.barrier and the.barrier.alive == false then
				object_manager.send(self.oid, "barrier_died")
			end

			if network.time > self.round_end_time then
				self:changePhaseToAfter()
			end	
			
			-- reset xp
			if network.time > self.next_xp_reset_time then
				self.next_xp_reset_time = self.next_xp_reset_time + config.xpCapTimer
				object_manager.visit(function(oid,o)
					if o.class == "Character" then
						object_manager.send(oid, "reset_xp")
					end
				end)
			end
		elseif self.phase == "after" then
			if network.time > self.round_end_time + config.afterTime then
				self:changePhaseToWarmup()
			end
		end
	end,

	onUpdateBoth = function (self, elapsed)
		the.app.view.game_start_time = self.round_start_time
		
		if self.phase == "after" then
			if self.highscore_displayed == false then
				local text = "The players lost, here's how you did:"
				the.barrier:showHighscore(text)
				self.highscore_displayed = true
			end
		end
	end,
	
	onDieBoth = function (self)
		the.app.view.layers.management:remove(self)
	end,
	
	formatSeconds = function (self, deltaTime)
		deltaTime = math.floor(deltaTime)
		if deltaTime < 0 then deltaTime = 0 end
		local minutes = math.floor(deltaTime / 60)
		local seconds = (deltaTime - minutes * 60)
		if seconds >= 10 then 
			return minutes .. ":" .. seconds
		elseif seconds < 10 then
			return minutes .. ":0" .. seconds
		else
			return math.floor(deltaTime) .. ""
		end
	end,
		
	getTimeText = function (self)
		local addendum = ""
		if the.player.class == "Ghost" or localconfig.spectator then addendum = "\n You are spectating. Wait for the next game to start to join." else addendum = "" end
		if self.phase == "init_needed" then
			return "init in progress..."
		elseif self.phase == "warmup" then
			local dt = self.round_start_time - network.time
			return "The game starts in " .. self:formatSeconds(dt) .. "." .. addendum
		elseif self.phase == "playing" then
			local dt = self.round_end_time - network.time
			return self:formatSeconds(dt) .. " until the game ends." .. addendum
		elseif self.phase == "after" then
			local dt = (self.round_end_time + config.afterTime) - network.time
			return "Game over. Restart in " .. self:formatSeconds(dt) .. "." .. addendum
		end
	end,
	
	receiveBoth = function (self, message_name, ...)
		print("############ receiveBoth", message_name)
		if message_name == "barrier_died" then
			if self.highscore_displayed == false then
				local text = "The players won, here's how you did:"
				the.barrier:showHighscore(text)
				self.highscore_displayed = true
			end
		elseif message_name == "reset_game" then
			switchToGhost()
			if localconfig.spectator == false then switchToPlayer() end
		elseif message_name == "set_phase" then
			local phase_name = ...
			if the.barrier and phase_name == "warmup" then the.barrier:hideHighscore() end
		elseif message_name == "ghost_all_players" then
			switchToGhost()
		end
	end,
	
	receiveLocal = function (self, message_name, ...)
		print("############ receiveLocal", message_name)
		if message_name == "reset_game" then
			-- destroy non player stuff
			local l = object_manager.find_where(function(oid, o) 
				return o.class and NetworkSyncedObjects[o.class]
			end)
			for _,o in pairs(l) do o:die() end
			
			-- recreate map objects
			local mapFile = '/assets/maps/desert/desert.lua'
			the.app.view:loadMap(mapFile, function (o) return o.name and NetworkSyncedObjects[o.name] end)
		elseif message_name == "force_next_phase" then
			self:forceNextPhase()
		end
	end,
	
	resetGame = function (self)
		object_manager.send(self.oid, "reset_game")
	end,
	
	ghostAllPlayers = function (self)
		object_manager.send(self.oid, "ghost_all_players")
	end,
	
	changePhaseToWarmup = function (self)
		self.round_start_time = network.time + config.warmupTime
		self.round_end_time = self.round_start_time  + config.roundTime
		self.highscore_displayed = false
		self.phase = "warmup"
		object_manager.send(self.oid, "set_phase", self.phase)
		self.round = self.round + 1
		print("changePhaseToWarmup", self.phase, self.round)	
		self:resetGame()
	end,
	
	changePhaseToPlaying = function (self)
		self.phase = "playing"	
		self.next_xp_reset_time = network.time + config.xpCapTimer
		object_manager.send(self.oid, "set_phase", self.phase)
		self:resetGame()
		print("changePhaseToPlaying", self.phase, self.round)	
		
		self.gameId = tonumber(math.random(1,1000000))
		network.set("gameId", self.gameId)
	end,
	
	changePhaseToAfter = function (self)
		self.phase = "after"
		object_manager.send(self.oid, "set_phase", self.phase)
		print("changePhaseToAfter", self.phase, self.round)	
	end,
}
