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

    onNew = function (self)
    
    
		-- object -> true map for easy remove, key contains projectile reference
		the.projectiles = {}
		
		-- object -> true map for easy remove, key contains projectile reference
		the.targetDummies = {}
		
		the.barrier = Barrier:new{}
		self:add(the.barrier)
		
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
				--the.hud:add(the.levelUI)	
			else
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i, fill = {255,255,0,255}} 
			--	the.hud:add(the.levelUI)			
			end							
		end
		audio.init()
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
    
    updateLevel = function (self, elapsed)
 		the.character = Character:new{}   
		print("update reveived! character level = ",  the.character.level)
		for i = 0, config.levelCap - 1 do
			local width = (love.graphics.getWidth() + the.controlUI.width) / 3.5 / 10
			if the.character.level > i then  -- TODO: fix it so that the.character.level gets recognized
				the.levelUI = LevelUI:new{width = width, x = (love.graphics.getWidth() + the.controlUI.width) / 2 + width * i, fill = {255,255,0,255}} 
				the.hud:add(the.levelUI)			
			end							
		end
	end,	
}
