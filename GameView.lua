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
    
    
		-- object -> true map for easy remove, key contains projectile references
		the.projectiles = {}
		
		-- object -> true map for easy remove, key contains targetDummy references
		the.targetDummies = {}
		
		the.barrier = Barrier:new{}
		self:add(the.barrier)
		
		-- object -> true map for easy remove, key contains footstep references
		the.footsteps = {}
		
		local mapFile = '/assets/maps/desert/desert.lua'
		self:loadLayers(mapFile, true, {objects = true, })
		
		local networkSyncedObjects = {
			TargetDummy = true,
			Npc = true,
		}
		self:loadMap(mapFile, not network.is_first and networkSyncedObjects or nil)
		
		self.collision.visible = false
		
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
		
		self.layers.above:add(self.trees)	
		self.layers.above:add(self.buildings)		
		-- set spawn position
		the.player.x = the.spawnpoint.x
		the.player.y = the.spawnpoint.y
		

		--~ the.dummy.x = the.dummySpawnpoint.x
		--~ the.dummy.y = the.dummySpawnpoint.y
			
		
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

		the.character = Character:new{}
		for i = 0, config.levelCap - 1 do
			local width = (love.graphics.getWidth() + the.controlUI.width) / 3.5 / 10
			if i >= the.character.level then 
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i} 
				the.hud:add(the.levelUI)	
			else
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i, fill = {255,255,0,255}} 
				the.hud:add(the.levelUI)			
			end							
		end
		audio.init()
		
		self:setupNetworkHandler()
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
		
		audio.update()
    end,	

	setupNetworkHandler = function ()
		table.insert(network.on_message, function(m) 
			print ("RECEIVED", json.encode(m))
			if m.channel == "game" then
				if m.cmd == "create" then
					local o = object_manager.get(m.oid)
					
					if not o then
						print("NEW REMOTE OBJECT", m.oid, m.owner, m.class)
						o = object_manager.create_remote(SyncedObject:new(m), m.oid, m.owner)
					end
				elseif m.cmd == "delete" then
					print("DELETE OBJ REQUEST", m.oid)
					local o = object_manager.get(m.oid)
					
					if o then
						o:die()
						object_manager.delete(o)
					end
					
				elseif m.cmd == "request" then
					local o = object_manager.get(m.oid)
					if o and o.netCreate then
						print("NEW OBJECT REQUESTED")
						local msg = o:netCreate()
						network.send (msg)
					end
				elseif m.cmd == "sync" then
					local o = object_manager.get(m.oid)
					if o then
						-- sync
						for k,v in pairs(m) do o[k] = v end
						print("SYNC REMOTE OBEJECT", o.oid)
					else
						print("SYNC REQUEST REMOTE OBEJECT", m.oid)
						network.send ({ channel = "game", cmd = "request", oid = m.oid })
					end
				end
			elseif m.channel == "server" then
				if m.cmd == "join" then
					-- new player so send obj create messages
					for oid,obj in pairs(object_manager.objects) do
						if obj.netCreate then
							local msg = obj:netCreate()
							network.send (msg)
						end
					end
				elseif m.cmd == "left" then
					
				end
			end
		end)	
	end,
}
