-- GameView

GameView = View:extend
{
	layers = {
		ground = Group:new(),
		particles = Group:new(),
		characters = Group:new(),
		projectiles = Group:new(),
		above = Group:new(),
		ui = Group:new(),
		debug = Group:new(),
	},
	
	game_start_time = 0,
	
	cover = nil,
	on = false,

	loadMap = function (self, file, objectNamesToIgnore)
		local ok, data = pcall(loadstring(Cached:text(file)))

		if ok then
			for _, layer in pairs(data.layers) do
				if layer.name == "objects" and layer.type == 'objectgroup' then

					for _, obj in pairs(layer.objects) do
						-- roll in tile properties if based on a tile

						if obj.gid and tileProtos[obj.gid] then
							local tile = tileProtos[obj.gid]

							obj.name = tile.properties.name
							obj.width = tile.width
							obj.height = tile.height
							
							for key, value in pairs(tile.properties) do
								obj.properties[key] = tovalue(value)
							end
						end

						-- create a new object if the class does exist

						local spr
						
						if not objectNamesToIgnore or not objectNamesToIgnore[obj.name]  then
							
							if obj.name and rawget(_G, obj.name) then
								obj.properties.x = obj.x
								obj.properties.y = obj.y
								obj.properties.width = obj.width
								obj.properties.height = obj.height

								spr = _G[obj.name]:new(obj.properties)
							else
								spr = Class:new{ x = obj.x, y = obj.y, width = obj.width, height = obj.height, fill = { 128, 128, 128 } }
							end

							if obj.properties._the then
								the[obj.properties._the] = spr
							end
							
						end
					end
				end
			end
		else
			error('could not load view data from file: ' .. data)
		end
	end,

    onNew = function (self)
		the.app.view = self
		print("the.app.view", the.app.view)
    
		-- object -> true map for easy remove, key contains projectile references
		the.projectiles = {}
		
		-- object -> true map for easy remove, key contains targetDummy references
		the.targetDummies = {}
		
		-- object -> true map for easy remove, key contains footstep references
		the.footsteps = {}
		
		local mapFile = '/assets/maps/desert/desert.lua'
		self:loadLayers(mapFile, true, {objects = true, })
		
		local is_server = network.is_first and network.connected_client_count == 1
		print("XXXXXXXXX", network.is_first, network.connected_client_count)
		
		local networkSyncedObjects = {
			TargetDummy = true,
			Npc = true,
			Barrier = true,
			Ressource = true,
		}
		self:loadMap(mapFile, not is_server and networkSyncedObjects or nil)
		
		-- first client -> setup "new" world
		if is_server then
			self.game_start_time = network.time
			network.set("game", {
				start_time = self.game_start_time
			})
		else
			network.get("game", function(data)
				self.game_start_time = data and data.start_time or 0
			end)
		end
		
		self.collision.visible = false
		self.collision.static = true
		
		-- specify render order
		self:add(self.layers.ground)
		self:add(self.layers.particles)
		self:add(self.layers.characters)
		self:add(self.layers.projectiles)
		self:add(self.layers.above)		
		self:add(self.layers.ui)
		self:add(self.layers.debug)
		
		-- setup player
		the.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2 }
		
    -- place ontop
		self:remove(self.trees)
		self:remove(self.buildings)
    self:remove(self.vegetation)
    
		self.layers.above:add(self.trees)	
		self.layers.above:add(self.buildings)
		self.layers.above:add(self.vegetation)
		
		-- set spawn position
		the.player.x = the.spawnpoint.x
		the.player.y = the.spawnpoint.y
			
		
		the.cursor = Cursor:new{ x = 0, y = 0 }
		self.layers.ui:add(the.cursor)
		
		the.focusSprite = FocusSprite:new{ x = 0, y = 0 }
		self:add(the.focusSprite)
		
		self.focus = the.focusSprite
		
		-- TODO obsolete? use self.layers instead?
		the.hud = UiGroup:new()
		self:add(the.hud)
		
		the.timerDisplay = TimerDisplay:new{ x = 0, y = 0 }
		the.hud:add(the.timerDisplay)		
		
		the.networkDisplay = NetworkDisplay:new{ x = 0, y = 0 }
		the.hud:add(the.networkDisplay)	
		
		the.skillbar = SkillBar:new()
		-- set skillbar images
		local skills = {}
		for k,v in pairs(the.player.skills) do
			--print(k, v)
			table.insert(skills, action_definitions[v.id].icon)
		end
		the.skillbar:setSkills(skills)
		
		--the.playerDetails = PlayerDetails:new{ x = 0, y = 0 }
		--self.layers.ui:add(the.playerDetails)
		
		the.controlUI = ControlUI:new{}
		the.hud:add(the.controlUI)
		
		the.energyUIBG = EnergyUIBG:new{}
		the.hud:add(the.energyUIBG)		
		the.energyUI = EnergyUI:new{}
		the.hud:add(the.energyUI)
		
		the.painUIBG = PainUIBG:new{}
		the.hud:add(the.painUIBG)		
		the.painUI = PainUI:new{}
		the.hud:add(the.painUI)		
		
		the.experienceUIBG = ExperienceUIBG:new{}
		the.hud:add(the.experienceUIBG)
		the.experienceUI = ExperienceUI:new{}
		the.hud:add(the.experienceUI)	

		for i = 0, config.levelCap - 1 do
			local width = (love.graphics.getWidth() / 2 - the.controlUI.width / 2) / config.levelCap
			if i >= the.player.level then 
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i} 
				the.hud:add(the.levelUI)	
			else
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i, fill = {255,255,0,255}} 
				the.hud:add(the.levelUI)			
			end							
		end
		audio.init()
	
		self.cover = Tile:new{x = the.player.x, y = the.player.y, image = '/assets/graphics/fog_of_war.png', width = 2048, height = 2048,
			onUpdate = function (self)
				local pX, pY = action_handling.get_target_position (the.player)
				self.x = pX - self.width / 2
				self.y = pY - self.height / 2
			end	
		}
	
		if config.show_fog_of_war then	
			self:fogOn()
		end

		self:setupNetworkHandler()
    end,
    
    fogOn = function(self)
		if self.on == false then
			self.layers.ui:add(self.cover)
			self.on = true
		end
	end,

    onUpdate = function (self, elapsed)
		-- show debug geometry?
		self.layers.debug.visible = config.draw_debug_info
    
		profile.start("update.skillbar")
		the.skillbar:onUpdate(elapsed)
		profile.stop()
		
		profile.start("update.displace")
		
		for dummy,v in pairs(the.targetDummies) do
			self.collision:displace(dummy)
			self.layers.characters:displace(dummy)
			self.landscape:subdisplace(dummy)
			self.water:subdisplace(dummy)		
		end
		
		self.collision:displace(the.player)
		self.layers.characters:displace(the.player)
		self.landscape:subdisplace(the.player)
		self.water:subdisplace(the.player)
		
		profile.stop()
		
		profile.start("update.projectile")
		for projectile,v in pairs(the.projectiles) do
			self.landscape:subcollide(projectile)
			self.collision:collide(projectile)
			self.layers.characters:collide(projectile)
		end
		profile.stop()
		
		if config.show_profile_info then profile.print() end
		profile.clear()
		
		-- fog of war
		if config.show_fog_of_war then		
			object_manager.visit(function(oid,obj) 
				local dist = vector.lenFromTo(obj.x, obj.y, the.player.x, the.player.y)

				local limit = config.sightDistanceFar
				local isVis = dist < limit
				local alpha = utils.mapIntoRange(dist, config.sightDistanceNear, limit, 1, 0)
				
				if (obj.alive == nil or obj.alive == true) and obj.oid ~= the.player.oid and obj.hidden == false then
					obj.visible = isVis
					obj.alpha = alpha
					if obj.painBar then 
						obj.painBar.visible = isVis 
						obj.painBar.alpha = alpha
						obj.painBar.bar.visible = isVis 
						obj.painBar.bar.alpha = alpha
						obj.painBar.background.visible = isVis 
						obj.painBar.background.alpha = alpha
					end
				end
			end)	
			for projectile,v in pairs(the.projectiles) do	
				if the.projectiles[projectile] == true then
					local dist_projectiles = vector.lenFromTo(projectile.x, projectile.y, the.player.x, the.player.y)
					local limit_projectiles = config.sightDistanceFar
					local isVis_projectiles = dist_projectiles < limit_projectiles
					local alpha_projectiles = utils.mapIntoRange(dist_projectiles, config.sightDistanceNear, limit_projectiles, 1, 0)
					projectile.visible = isVis_projectiles
					projectile.alpha = alpha_projectiles
				end
			end
			for targetDummy,v in pairs(the.targetDummies) do	
				if the.targetDummies[targetDummy] == true then
					local dist_targetDummies = vector.lenFromTo(targetDummy.x, targetDummy.y, the.player.x, the.player.y)
					local limit_targetDummies = config.sightDistanceFar
					local isVis_targetDummies = dist_targetDummies < limit_targetDummies
					local alpha_targetDummies = utils.mapIntoRange(dist_targetDummies, config.sightDistanceNear, limit_targetDummies, 1, 0)
					targetDummy.visible = isVis_targetDummies
					targetDummy.alpha = alpha_targetDummies
				end
			end			
			for footstep,v in pairs(the.footsteps) do	
				if the.footsteps[footstep] == true then
					local dist_footsteps = vector.lenFromTo(footstep.x, footstep.y, the.player.x, the.player.y)
					local limit_footsteps = config.sightDistanceFar
					local isVis_footsteps = dist_footsteps < limit_footsteps
					local alpha_footsteps = utils.mapIntoRange(dist_footsteps, config.sightDistanceNear, limit_footsteps, 1, 0)
					footstep.visible = isVis_footsteps
					footstep.fogAlpha = alpha_footsteps
				end
			end

		end
		
		audio.update()
    end,	

	resyncAllLocalObjects = function ()
		local s,c = 0,0
		object_manager.visit(function(oid,o)
			if o.sendResync then o:sendResync() s = s + 1 end
			if o.netCreate then o:netCreate() c = c + 1 end
		end)
		print("RESYNC", "sync", s, "create", c)
	end,

	setupNetworkHandler = function ()
		table.insert(network.on_message, function(m) 
			--~ print ("RECEIVED", json.encode(m))
			
			if m.channel == "game" then
				if m.cmd == "create" then
					local o = object_manager.get(m.oid)
					
					if not o then
						print("NEW REMOTE OBJECT", m.oid, m.owner, m.class)
						o = _G[m.class]:new(m)
					end
				elseif m.cmd == "delete" then
					print("DELETE OBJ REQUEST", m.oid)
					local o = object_manager.get(m.oid)
					
					if o then
						if o.active then o:die() end
						object_manager.delete(o)
					end
					
				elseif m.cmd == "request" then
					local o = object_manager.get(m.oid)
					if o and o.netCreate then
						print("NEW OBJECT REQUESTED")
						o:netCreate()
					end
				elseif m.cmd == "msg" then
					object_manager.send(m.oid, m.name, unpack(m.params or {}))
				elseif m.cmd == "sync" then
					local o = object_manager.get(m.oid)
					if o then
						-- sync
						for k,v in pairs(m) do o[k] = v end
						if m.nils then
							for _,v in pairs(m.nils) do o[v] = nil end
						end
						print("SYNC REMOTE OBJECT", o.oid)
					else
						print("SYNC REQUEST REMOTE OBJECT", m.oid)
						network.send ({ channel = "game", cmd = "request", oid = m.oid })
					end
				end
			elseif m.channel == "server" then
				if m.cmd == "join" then
					-- new player so send obj create messages
					print("new player send objects#############")
					for oid,obj in pairs(object_manager.objects) do
						print("send net create", oid)
						if obj.netCreate then
							obj:netCreate()
						end
					end
					print("DONE new player send objects#############")
				elseif m.cmd == "left" then
					-- player left so kill all objects from the player
					for oid,obj in pairs(object_manager.objects) do
						--~ print("LEFT", oid, obj.owner, m.id)
						if obj.owner == m.id then
							if obj.active then obj:die() end
							object_manager.delete(obj)
						end
					end
				end
			end
		end)	
	end,
}
