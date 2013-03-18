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
	
	cover = nil,
	on = false,

    onNew = function (self)
    
    
    
		-- object -> true map for easy remove, key contains projectile reference
		the.projectiles = {}
		
		-- object -> true map for easy remove, key contains projectile reference
		the.targetDummies = {}
		
		-- object -> true map for easy remove, key contains footstep reference
		the.footsteps = {}
		
		self:loadLayers('/assets/maps/desert/desert.lua', true)
		
		self.collision.visible = false
		self.objects.visible = false
		
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
    end,
    
    fogOn = function(self)
		if self.on == false then
			the.view.layers.ui:add(self.cover)
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
			-- TODO optimize!!!
			self.collision:displace(dummy)
			-- TODO optimize!!!
			self.layers.characters:displace(dummy)
			self.landscape:subdisplace(dummy)
			self.water:subdisplace(dummy)		
		end
		
		-- TODO optimize!!!
		self.collision:displace(the.player)
		-- TODO optimize!!!
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
				
				if obj.alive == nil or obj.alive == true then
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
		end
		
		audio.update()
    end,	
}
