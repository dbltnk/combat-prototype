-- PhaseManager

PhaseManager = Sprite:extend
{
	class = "PhaseManager",

	props = {"x", "y", "width", "height", "phase", "round", "round_start_time", "round_end_time"},
	sync_low = {"phase", "round", "round_start_time", "round_end_time"},
	phase = "init_needed", -- "init_needed", "warmup", "playing", "after"
	round = 0,
	owner = 0,
	
	round_start_time = 0,
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
		if self.phase == "init_needed" then
			return "init in progress..."
		elseif self.phase == "warmup" then
			local dt = self.round_start_time - network.time
			return "warmup, " .. self:formatSeconds(dt) .. " remaining"
		elseif self.phase == "playing" then
			local dt = self.round_end_time - network.time
			return "playing, " .. self:formatSeconds(dt) .. " remaining"
		elseif self.phase == "after" then
			local dt = (self.round_end_time + config.afterTime) - network.time
			return "after, " .. self:formatSeconds(dt) .. " remaining"
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
		object_manager.send(self.oid, "set_phase", self.phase)
		self:resetGame()
		print("changePhaseToPlaying", self.phase, self.round)	
	end,
	
	changePhaseToAfter = function (self)
		self.phase = "after"
		object_manager.send(self.oid, "set_phase", self.phase)
		print("changePhaseToAfter", self.phase, self.round)	
	end,
}
