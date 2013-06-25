-- GameView
NetworkSyncedObjects = {
	TargetDummy = true,
	Npc = true,
	Barrier = true,
	Ressource = true,
}
		
		
GameView = View:extend
{
	layers = {
		management = Group:new(),
		ground = Group:new(),
		particles = Group:new(),
		characters = Group:new(),
		projectiles = Group:new(),
		above = Group:new(),
		ui = Group:new(),
		debug = Group:new(),
	},
	
	game_start_time = 0,
	
	fogEnabled = nil,

	loadMap = function (self, file, filter)
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
						
						if not filter or filter(obj) then
							
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
		print("startup", network.is_first, network.connected_client_count)

		self:loadMap(mapFile, function (o) return not (o.name and NetworkSyncedObjects[o.name]) end)
		
		-- first client -> setup "new" world
		if is_server then
			PhaseManager:new{}
		end
		
		self.collision.visible = false
		self.collision.static = true
		
		-- specify render order
		self:add(self.layers.management)
		self:add(self.layers.ground)
		self:add(self.layers.particles)
		self:add(self.layers.characters)
		self:add(self.layers.projectiles)
		self:add(self.layers.above)		
		self:add(self.layers.ui)
		self:add(self.layers.debug)
		
		-- setup player
		the.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2, 
			name = localconfig.playerName, 
			armor = localconfig.armor, 
			weapon = localconfig.weapon,
			team = localconfig.team,
		}
		
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
		
		the.arrow = Arrow:new{ x = 0, y = 0 }
		
		if the.player and the.player.class ~= "Ghost" then
			self.focus = the.focusSprite
		else
			self.focus = the.player
		end
		
		-- TODO obsolete? use self.layers instead?
		the.hud = UiGroup:new()
		self:add(the.hud)
		
		-- object -> true map for easy remove, key contains ressource references
		the.ressources = {}
		the.ressourceDisplay = RessourceDisplay:new{ x = 0, y = 0, text = "ressources uninitialized" }
		the.hud:add(the.ressourceDisplay) 
		
		the.timerDisplay = TimerDisplay:new{ x = 0, y = 0 }
		the.hud:add(the.timerDisplay)		
		
		the.xpTimerDisplay = XpTimerDisplay:new{ x = 0, y = 0 }
		the.hud:add(the.xpTimerDisplay)	
		
		the.networkDisplay = NetworkDisplay:new{ x = 0, y = 0 }
		the.hud:add(the.networkDisplay)	
		
		--~ the.debuffDisplay = DebuffDisplay:new{}
		--~ the.hud:add(the.debuffDisplay)
		
		the.ignorePlayerCharacterInputs = false
		
		the.chatText = ChatText:new{}
		the.hud:add(the.chatText)
		the.chatText.x = 10
		the.chatText.y = love.graphics.getHeight() - 120
		
		the.skillbar = SkillBar:new()
		-- set skillbar images
		local skills = {}
		for k,v in pairs(the.player.skills) do
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

		the.levelUI = {}

		for i = 0, config.levelCap - 1 do
			local width = (love.graphics.getWidth() / 2 - the.controlUI.width / 2) / config.levelCap
			local ui = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i} 
			ui.level = i + 1
			the.hud:add(ui)	
			table.insert(the.levelUI, ui)
		end
		
		audio.init()
	
		self.covers = {}
		table.insert(self.covers,Tile:new{x = the.player.x, y = the.player.y, image = '/assets/graphics/fog_of_war.png', width = 2048, height = 2048,
			onUpdate = function (self)
				local pX, pY = action_handling.get_target_position (the.player)
				self.x = pX - self.width / 2
				self.y = pY - self.height / 2
			end	
		})
		table.insert(self.covers,Tile:new{x = the.player.x, y = the.player.y, image = '/assets/graphics/fog_of_war_extension.png', width = 1024, height = 1024,
			onUpdate = function (self)
				local pX, pY = action_handling.get_target_position (the.player)
				self.x = pX - 2048
				self.y = pY
			end	
		})
		table.insert(self.covers,Tile:new{x = the.player.x, y = the.player.y, image = '/assets/graphics/fog_of_war_extension.png', width = 1024, height = 1024,
			onUpdate = function (self)
				local pX, pY = action_handling.get_target_position (the.player)
				self.x = pX - 2048
				self.y = pY - 1024
			end	
		})
		table.insert(self.covers,Tile:new{x = the.player.x, y = the.player.y, image = '/assets/graphics/fog_of_war_extension.png', width = 1024, height = 1024,
			onUpdate = function (self)
				local pX, pY = action_handling.get_target_position (the.player)
				self.x = pX + 1024
				self.y = pY
			end	
		})
		table.insert(self.covers,Tile:new{x = the.player.x, y = the.player.y, image = '/assets/graphics/fog_of_war_extension.png', width = 1024, height = 1024,
			onUpdate = function (self)
				local pX, pY = action_handling.get_target_position (the.player)
				self.x = pX + 1024
				self.y = pY - 1024
			end	
		})
	
		if config.show_fog_of_war then	
			self:setupFog()
		end

		self:setupNetworkHandler()
		
		local chatInfo = Text:new{
			x = 5, y = love.graphics.getHeight() - 90, width = 500, tint = {0,0,0}, 
			text = "Press enter to chat",
		}
		the.hud:add(chatInfo)
		
		
		-- text chat input
		the.frameChatInput = loveframes.Create("textinput")
		the.frameChatInput:SetPos(5, love.graphics.getHeight() - 90)
		the.frameChatInput:SetWidth(love.graphics.getWidth() - 10)
		the.frameChatInput:SetVisible(false)
		the.frameChatInput:SetFocus(false)
		the.frameChatInput.OnEnter = function (self, text)
			if text:len() > 0 then
				--~ print("CHAT", self.visible, text)
				network.send({channel = "chat", cmd = "text", from = localconfig.playerName, text = text, time = network.time})
				showChatText(localconfig.playerName, text, network.time)
			end
			the.app.view.timer:after(0.1, function() 
				self:SetVisible(false)
				self:SetFocus(false)
				self:SetText("")
				the.ignorePlayerCharacterInputs = false
				-- TODO keep focus if one clicks of close on click on screen
			end)
		end

		switchToGhost()
    end,
    
    setFogEnabled = function (self, enabled)
		if self.fogEnabled ~= enabled then
			self.fogEnabled = enabled
			
			for _,v in pairs(self.covers) do
				v.visible = enabled
			end
			
			self.fogEnabled = enabled
		end
	end,
	
	setupFog = function(self)
		for _,v in pairs(self.covers) do
			self.layers.ui:add(v)
		end
    end,

    onUpdate = function (self, elapsed)
		-- handle chat
		if the.keys:justPressed("return") then
			print(the.frameChatInput.visible, the.frameChatInput.focus)
			if not the.frameChatInput.visible then
				the.frameChatInput:SetVisible(true)
				the.frameChatInput:SetFocus(true)
				the.ignorePlayerCharacterInputs = true
			end
		end
    
		-- show debug geometry?
		self.layers.debug.visible = config.draw_debug_info
    
		if the.player and the.player.class ~= "Ghost" then
			profile.start("update.skillbar")
			the.skillbar:onUpdate(elapsed)
			profile.stop()
		else
			the.player:onUpdate(elapsed)
		end
		
		profile.start("update.displace")
		
		for dummy,v in pairs(the.targetDummies) do
			self.collision:displace(dummy)
			self.layers.characters:displace(dummy)
			self.landscape:subdisplace(dummy)
			self.water:subdisplace(dummy)		
		end
		
		if the.player and the.player.class ~= "Ghost" then
			self.collision:displace(the.player)
			self.layers.characters:displace(the.player)
			self.landscape:subdisplace(the.player)
			self.water:subdisplace(the.player)
		end
		
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
		
		local s = ""
		for k, v in pairs(the.ressources) do
			s = s .. k .. ": " .. v .. "\n"
		end
		the.ressourceDisplay.text = s
		
		audio.update()
    end,	

	resyncAllLocalObjects = function (self)
		local s,c = 0,0
		object_manager.visit(function(oid,o)
			if o.sendResync then o:sendResync() s = s + 1 end
			if o.netCreate then o:netCreate() c = c + 1 end
		end)
		print("RESYNC", "sync", s, "create", c)
	end,

	setupNetworkHandler = function (self)
		table.insert(network.on_message, function(m) 
			--~ print ("RECEIVED", json.encode(m))
			
			if m.channel == "chat" then
				if m.cmd == "text" then
					showChatText(m.from, m.text, m.time)					
				end
			end
			
			if m.channel == "game" then
				if m.cmd == "create" then
					local o = object_manager.get(m.oid)
					
					if not o then
						--~ print("NEW REMOTE OBJECT", m.oid, m.owner, m.class)
						m.created_via_network = true
						o = _G[m.class]:new(m)
					end
				elseif m.cmd == "delete" then
					--~ print("DELETE OBJ REQUEST", m.oid)
					local o = object_manager.get(m.oid)
					
					if o then
						if o.active then o:die() end
						object_manager.delete(o)
					end
					
				elseif m.cmd == "request" then
					local o = object_manager.get(m.oid)
					if o and o.netCreate then
						--~ print("NEW OBJECT REQUESTED")
						o:netCreate()
					end
				elseif m.cmd == "msg" then
					local o = object_manager.get(m.oid)
					if o and o.receiveWithoutResendingToNet then
						o:receiveWithoutResendingToNet(m.name, unpack(m.params or {}))
					end
				elseif m.cmd == "sync" then
					local o = object_manager.get(m.oid)
					if o then
						-- sync
						for k,v in pairs(m) do o[k] = v end
						if m.nils then
							for _,v in pairs(m.nils) do o[v] = nil end
						end
						--~ print("SYNC REMOTE OBJECT", o.oid)
					else
						--~ print("SYNC REQUEST REMOTE OBJECT", m.oid)
						network.send ({ channel = "game", cmd = "request", oid = m.oid })
					end
				end
			elseif m.channel == "server" then
				if m.cmd == "join" then
					-- new player so send obj create messages
					print("new player send objects#############")
					self:resyncAllLocalObjects();
					print("DONE new player send objects#############")
				elseif m.cmd == "disconnect" then
					print("DISCONNECTED BY SERVER")
					os.exit()
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


function switchToPlayer()
	if the.player then
		if the.player.class == "Ghost" then
			the.player:die()
			the.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2, 
				name = localconfig.playerName, 
				armor = localconfig.armor, 
				weapon = localconfig.weapon,
				team = localconfig.team,
			}
			-- set spawn position
			the.player.x = the.spawnpoint.x
			the.player.y = the.spawnpoint.y
			the.app.view:setFogEnabled(true)
		end
	end
end

function switchToGhost()
	if the.player then the.player:die() end
	the.player.deaths = (the.player.deaths or 0) + 1
	the.player = Ghost:new{}
	the.player.x = the.spawnpoint.x
	the.player.y = the.spawnpoint.y
	the.app.view:setFogEnabled(false)
end

function switchBetweenGhostAndPlayer()
	if the.player then
		if the.player.class == "Ghost" then
			switchToPlayer()			
		else
			switchToGhost()
		end
	end
end
