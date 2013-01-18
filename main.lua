STRICT = true
DEBUG = true

require 'zoetrope'
local vector = require 'vector'
local utils = require 'utils'
local config = require 'config'
local input = require 'input'

-- returns x,y
function ScreenPosToWorldPos(x,y)
	local vx,vy = vector.mul(the.view.translate.x, the.view.translate.y, -1)
	return vector.add(vx,vy, x,y)
end

-- returns x,y
function WorldPosToScreenPos(x,y)
	local vx,vy = vector.mul(the.view.translate.x, the.view.translate.y, 1)
	return vector.add(vx,vy, x,y)
end

Skill = Class:extend
{
	nr = 0,	
	timeout = 0,
	combatTimer = 10,
	
	lastUsed = 0,
	
	isPossibleToUse = function (self)
		return love.timer.getTime() - self.lastUsed >= self.timeout
	end,
	
	timeTillPossibleToUse = function (self)
		return math.max(0, self.lastUsed + self.timeout - love.timer.getTime())
	end,
	
	use = function (self)
		self.lastUsed = love.timer.getTime()
		if self.onUse then self:onUse() end
	end,
	
	isOutOfCombat = function (self)
		return love.timer.getTime() - self.lastUsed >= self.combatTimer
	end,	
}

SkillIcon = Animation:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/skills.png', -- source: http://opengameart.org/content/powers-icons
	sequences = 
	{
		skill_1 = { frames = {1}, fps = 1 },
		skill_2 = { frames = {2}, fps = 1 },
		skill_3 = { frames = {3}, fps = 1 },
		skill_4 = { frames = {4}, fps = 1 },
		skill_5 = { frames = {6}, fps = 1 },
		
		skill_6 = { frames = {7}, fps = 1 },
		skill_7 = { frames = {8}, fps = 1 },
		skill_8 = { frames = {10}, fps = 1 },
		skill_9 = { frames = {11}, fps = 1 },
		
		skill_10 = { frames = {12}, fps = 1 },
		skill_11 = { frames = {14}, fps = 1 },
		skill_12 = { frames = {15}, fps = 1 },
		skill_13 = { frames = {16}, fps = 1 },
	},
	
	onNew = function (self)
		self:setSkill(1)
	end,
	
	setSkill = function (self, skill_nr)
		self:play("skill_" .. skill_nr)
	end,
}

SkillBar = Class:extend
{
	-- skill nrs
	skills = {1,2,3,4,5,6},
	
	-- contains references to SkillIcon
	skillIcons = {},
	-- inactive overlay tiles
	skillInactiveIcons = {},
	-- timeout texts
	skillTimerText = {},
	
	-- position
	x = 400 - SkillIcon.width / 2 * 6, -- to-do: 6 ersetzen durch table.getn(skills) oder ähnliche zählmethode
	y = 600 - SkillIcon.height,
	
	onNew = function (self)
		for index, skillNr in pairs(self.skills) do
			local icon = SkillIcon:new { x = 0, y = 0 }
			the.ui:add(icon)
			
			self.skillIcons[index] = icon
			
			-- black inactive overlay
			local overlay = Tile:new{
				width = 32, height = 32, image = "/assets/graphics/skills_inactive_overlay.png",
			}
			self.skillInactiveIcons[index] = overlay
			the.ui:add(overlay)

			-- timeout text
			local t = Text:new{
				font = 14,
				text = "X",
			}
			self.skillTimerText[index] = t
			the.ui:add(t)
		end
		
		self:setPosition (self.x, self.y)
		self:setSkills (self.skills)
	end,
	
	setPosition = function (self, x, y)
		self.x = x
		self.y = y
		
		for index, skillIcon in pairs(self.skillIcons) do
			skillIcon.x = (index - 1) * 32 + self.x
			skillIcon.y = self.y
			
			self.skillInactiveIcons[index].x = skillIcon.x
			self.skillInactiveIcons[index].y = skillIcon.y

			self.skillTimerText[index].x = skillIcon.x + 8
			self.skillTimerText[index].y = skillIcon.y + 8
		end
	end,
	
	setSkills = function (self, skills)
		self.skills = skills
		
		for index, skillNr in pairs(self.skills) do
			self.skillIcons[index]:setSkill(skillNr)
		end
	end,
	
	onUpdate = function (self, elapsed)
		-- mark inactive skill as inactive
		for index, overlay in pairs(self.skillInactiveIcons) do
			if the.player and the.player.skills and the.player.skills[index] then
				local skill = the.player.skills[index]
				overlay.visible = skill:isPossibleToUse () == false
			end
		end
		
		-- show timeout
		for index, timeout in pairs(self.skillTimerText) do
			if the.player and the.player.skills and the.player.skills[index] then
				local skill = the.player.skills[index]
				timeout.visible = skill:isPossibleToUse () == false
				
				local t = skill:timeTillPossibleToUse()
				if t >= 10 then
					timeout.text = string.format("%0.0f", t)
				else
					timeout.text = string.format("%0.1f", t)
				end
			end
		end
	end,
}

TargetDummy = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/icon.png',
	
	onNew = function (self)
		self.width = 32
		self.height = 32
		
		print(self)
	end,
	
	__tostring = function (self)
		return Tile.__tostring(self)
	end,
}

Player = Animation:extend
{
	-- list of Skill
	skills = {},
	
	width = 64,
	height = 64,
	image = '/assets/graphics/player.png', -- source: http://www.synapsegaming.com/forums/t/1711.aspx

	sequences = 
	{
		walk = { frames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}, fps = config.animspeed },
	},
	
	
	lastFootstep = 0,
	
	footstepsPossible = function (self)
		return love.timer.getTime() - self.lastFootstep >= .25
	end,
	
	makeStep = function (self)
		self.lastFootstep = love.timer.getTime()
	end,
	
	
	onNew = function (self)
		self.skills[1] = Skill:new { timeout = 2, nr = 1, }
		self.skills[2] = Skill:new { timeout = 0.1, nr = 2, }
		self.skills[3] = Skill:new { timeout = 0.1, nr = 3, }
		self.skills[4] = Skill:new { timeout = 0.1, nr = 4, }
		self.skills[5] = Skill:new { timeout = 0.1, nr = 5, }
		self.skills[6] = Skill:new { timeout = 0.1, nr = 6, }
	end,
	
	onUpdate = function (self, elapsed)
		self.velocity.x = 0
		self.velocity.y = 0

		-- 0 slowest -> 1 fastest
		local speed = 0
		-- -1->1, -1->1
		local dirx, diry = 0,0
		
		local doShoot = false
		
		if input.getMode() == input.MODE_GAMEPAD then
			-- move player by axes 12
			dirx = the.gamepads[1].axes[1]
			diry = the.gamepads[1].axes[2]
			local l = vector.len(dirx, diry)
			if l < 0.2 then 
				speed = 0
				dirx, diry = 0,0 
			else
				speed = utils.mapIntoRange (l, 0, 1, 0,1)
			end
			
			-- move cursor by axes 34
			local curx = the.gamepads[1].axes[3]
			local cury = the.gamepads[1].axes[4]
			local cur = vector.len(curx, cury)
			if cur < 0.2 then 
				curx, cury = 0,0 
			else
				-- adjust speed depending on cursor-player-distance
				local speed = 0
				local len = vector.lenFromTo (self.x, self.y, ScreenPosToWorldPos(input.cursor.x, input.cursor.y))
				
				if len < config.gamepad_cursor_near_distance - config.gamepad_cursor_near_border / 2 then
					-- near
					speed = config.gamepad_cursor_speed_near
				elseif len < config.gamepad_cursor_near_distance + config.gamepad_cursor_near_border / 2 then
					-- blend
					local border = len - (config.gamepad_cursor_near_distance - config.gamepad_cursor_near_border / 2)
					speed = utils.mapIntoRange (border, 0, config.gamepad_cursor_near_border, 
						config.gamepad_cursor_speed_near, config.gamepad_cursor_speed_far)
				else
					-- far
					speed = config.gamepad_cursor_speed_far
				end
				
				cur = utils.mapIntoRange (cur, 0, 1, 0, speed)
				curx, cury = vector.normalizeToLen(curx, cury, cur * elapsed)
			end
			
			input.cursor.x, input.cursor.y = vector.add(input.cursor.x, input.cursor.y, curx, cury)

			-- clamp cursor distance
			local dx,dy = vector.fromTo (self.x, self.y, ScreenPosToWorldPos(input.cursor.x, input.cursor.y))
			
			if vector.len(dx, dy) > 0 then
				local f = 4/5
				local maxdx,maxdy = the.app.width * f, the.app.height * f
				local l = vector.len(dx,dy)
				
				if math.abs(dx) > maxdx then
					local newL = l * utils.sign(dx) * maxdx / dx
					dx, dy = vector.normalizeToLen (dx, dy, newL)
					l = newL
				end
				
				if math.abs(dy) > maxdy then
					local newL = l * utils.sign(dy) * maxdy / dy
					dx, dy = vector.normalizeToLen (dx, dy, newL)
				end

				input.cursor.x, input.cursor.y = WorldPosToScreenPos(vector.add(self.x, self.y, dx,dy))
			end
			
			-- shoot?
			doShoot = the.gamepads[1].axes[5] > 0.2
		elseif input.getMode() == input.MODE_MOUSE_KEYBOARD then
			if the.mouse:pressed('l') then doShoot = true end
		
			if the.keys:pressed('shift') then speed = 1 else speed = 0 end -- to-do: in eine fähigkeit umwandeln (hotbar)
			
			if the.keys:pressed('left', 'a') then dirx = -1 end
			if the.keys:pressed('right', 'd') then dirx = 1 end
			if the.keys:pressed('up', 'w') then diry = -1 end
			if the.keys:pressed('down', 's') then diry = 1 end
			
			if the.keys:pressed('left', 'a','right', 'd','up', 'w','down', 's') and self:footstepsPossible()  then 
			local footstep = Footstep:new{ 
				x = self.x+17, y = self.y+15, 
				rotation = self.rotation,
			}
			the.app.view.layers.ground:add(footstep)
			the.footsteps[footstep] = true
			self:makeStep()
			end

			input.cursor.x = the.mouse.x
			input.cursor.y = the.mouse.y
		elseif input.getMode() == input.MODE_TOUCH then
			-- TODO
		end
		
		-- move into direction?
		if vector.len(dirx, diry) > 0 then
			local s = utils.mapIntoRange (speed, 0, 1, config.walkspeed, config.runspeed)
			self.velocity.x, self.velocity.y = vector.normalizeToLen(dirx, diry, s)
			
			local animspeed = utils.mapIntoRange (speed, 0, 1, config.animspeed, config.animspeed * config.runspeed / config.walkspeed)
			
			self:play('walk')
		else
			self:freeze(5)
		end
		
		
		local worldMouseX, worldMouseY = ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		
		local cx,cy = self.x + self.width / 2, self.y + self.height / 2
		-- mouse -> player vector
		local dx,dy = cx - (worldMouseX), cy - (worldMouseY)
		
		self.rotation = math.atan2(dy, dx) - math.pi / 2
		
		local arrowvx, arrowvy = -dx, -dy
		local l = vector.len(arrowvx, arrowvy)
		arrowvx, arrowvy = vector.normalizeToLen(arrowvx, arrowvy, config.arrowspeed)
		
		local activeSkillNr = 1
		
		if doShoot and self.skills[activeSkillNr]:isPossibleToUse()  then
			self.skills[activeSkillNr]:use()
		
			-- assert: arrow size == player size
			local arrow = Arrow:new{ 
				x = self.x, y = self.y, 
				rotation = self.rotation,
				velocity = { x = arrowvx, y = arrowvy },
				start = { x = self.x, y = self.y },
				target = { x = worldMouseX, y = worldMouseY },
			}
			
			the.app.view.layers.projectiles:add(arrow)
			-- stores an arrow reference, arrows get stored in the key
			the.arrows[arrow] = true
			
			the.peaceMusic:setVolume(0)	
			the.combatMusic:setVolume(1)	
		end
		
		if self.skills[activeSkillNr]:isOutOfCombat() then
			the.peaceMusic:setVolume(1)	
			the.combatMusic:setVolume(0)
		end
	end,
}

FocusSprite = Sprite:extend 
{
	width = 1,
	height = 1,
	
	onUpdate = function (self)
		local worldCursorX, worldCursorY = ScreenPosToWorldPos(input.cursor.x, input.cursor.y)
		local x,y = 0,0
		-- weighted average
		x,y = vector.add(x,y, vector.mul(worldCursorX, worldCursorY, 0.45))
		x,y = vector.add(x,y, vector.mul(the.player.x, the.player.y, 0.55))
		self.x, self.y = x,y
	end,
	
	__tostring = function (self)
		return Sprite.__tostring(self)
	end,
}

Cursor = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/cursor.png',
    
	onUpdate = function (self)
		self.x = input.cursor.x - self.width / 2
		self.y = input.cursor.y - self.height / 2
		self.x, self.y = ScreenPosToWorldPos(self.x, self.y)
	end
}

Arrow = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/arrow.png',
    -- target.x target.y start.x start.y

	onCollide = function(self, other, horizOverlap, vertOverlap)
		self:die()
		-- not possible to revive them later
		the.app.view.layers.projectiles:remove(self)
		-- will remove the arrow reference from the map
		the.arrows[self] = nil
	end,	
	
	onUpdate = function (self)
		local totalDistance = vector.lenFromTo(self.start.x, self.start.y, self.target.x, self.target.y)
		local distFromStart = vector.lenFromTo(self.start.x, self.start.y, self.x, self.y)
		
		if distFromStart >= totalDistance then
			self:die()
			-- not possible to revive them later
			the.app.view.layers.projectiles:remove(self)
			-- will remove the arrow reference from the map
			the.arrows[self] = nil
		end
	end,
}

Footstep = Tile:extend
{
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
}

UiGroup = Group:extend
{
	solid = false,

	onUpdate = function(self)
		local x,y = ScreenPosToWorldPos(0,0)
		self.translate.x = x
		self.translate.y = y
	end,
}

PlayerDetails = Tile:extend
{
	width = 128,
	height = 128,
	image = '/assets/graphics/player_details.png',
    
	onUpdate = function (self)
		self.x = the.player.x - the.player.width / 1.5
		self.y = the.player.y - the.player.height / 1.5
	end
}

--~ DebugPoint = Tile:extend
--~ {
	--~ width = 32,
	--~ height = 32,
	--~ image = '/assets/graphics/debugpoint.png',
--~ }

GameView = View:extend
{
	layers = {
		ground = Group:new(),
		characters = Group:new(),
		projectiles = Group:new(),
		ui = Group:new(),
	},

    onNew = function (self)
		self:loadLayers('/assets/maps/desert/desert.lua')
		
		-- specifiy render order
		self:add(self.layers.ground)
		self:add(self.layers.characters)
		self:add(self.layers.projectiles)
		self:add(self.layers.ui)
		
		-- setup player
		the.player = Player:new{ x = the.app.width / 2, y = the.app.height / 2 }
		self.layers.characters:add(the.player)
		self.layers.projectiles:add(self.trees)		
		-- set spawn position
		the.player.x = the.spawnpoint.x
		the.player.y = the.spawnpoint.y
		
		the.cursor = Cursor:new{ x = 0, y = 0 }
		self.layers.ui:add(the.cursor)
		
		-- object -> true map for easy remove, key contains arrow reference
		the.arrows = {}
		
		-- object -> true map for easy remove, key contains footstep reference
		the.footsteps = {}
		
		--~ self.debugpoint = DebugPoint:new{ x = 0, y = 0 }
		--~ self:add(self.debugpoint)
		
		the.focusSprite = FocusSprite:new{ x = 0, y = 0 }
		self:add(the.focusSprite)
		
		self.focus = the.focusSprite
		
		-- TODO obsolete? use self.layers instead?
		the.ui = UiGroup:new()
		self:add(the.ui)
		
		the.skillbar = SkillBar:new()
		
		the.playerDetails = PlayerDetails:new{ x = 0, y = 0 }
		self.layers.ui:add(the.playerDetails)
		
		the.peaceMusic = playSound('/assets/audio/eots.ogg',1,long)
		the.peaceMusic:setLooping(true)	

		the.combatMusic = playSound('/assets/audio/dos.mp3',0,long)
		the.combatMusic:setLooping(true)	

		
    end,
    
    onUpdate = function (self, elapsed)
		the.skillbar:onUpdate(elapsed)
		
		self.collision:displace(the.player)
		self.buildings:subdisplace(the.player)
		self.water:subdisplace(the.player)
		
		for arrow,v in pairs(the.arrows) do
			self.buildings:subcollide(arrow)
			self.collision:collide(arrow)			
		end
    end,
}

the.app = App:new
{
	numGamepads = love.joystick and 1 or 0,
	name = "Combat Prototype",
	icon = '/graphics/icon.png',

	onUpdate = function (self, elapsed)
		-- set input mode
		if the.keys:justPressed ("f1") then print("input mode: mouse+keyboard") input.setMode (input.MODE_MOUSE_KEYBOARD) end
		if the.keys:justPressed ("f2") then print("input mode: gamepad") input.setMode (input.MODE_GAMEPAD) end
		if the.keys:justPressed ("f3") then print("input mode: touch") input.setMode (input.MODE_TOUCH) end	
		
		-- toggle fullscreen
		if the.keys:justPressed ("f10") then self:toggleFullscreen() end

		-- easy exit
		if the.keys:pressed('escape') then os.exit() end
	end,

    onRun = function (self)
		-- disable the hardware cursor
		self:useSysCursor(false)
		
		the.app.console:watch("viewx", "the.view.translate.x")
		the.app.console:watch("viewy", "the.view.translate.y")
		
		-- setup background
		self.view = GameView:new()
		
    end
}
