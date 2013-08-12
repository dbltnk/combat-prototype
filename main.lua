STRICT = false
DEBUG = false

config = require 'config'

configBaseDir = {}
table.insert(configBaseDir, "./");
table.insert(configBaseDir, love.filesystem.getSaveDirectory() .. "/");

--assert(false, love.filesystem.getSaveDirectory())

function findFile(file, dirs)
    if file then
        for k,v in pairs(dirs) do
            local f = v .. file
            if f then
                local h = io.open(f)
                if h then
                    io.close(h)
                    return f
                end
            end
        end
    end

    return nil
end

function readConfig(file)
        local f = findFile(file, configBaseDir)
        if not f then f = findFile("localconfig.lua", configBaseDir) end

        assert(f, "no config found, please place your config at:\n" .. love.filesystem.getSaveDirectory() .. "/localconfig.lua")

        print("using config file", f)

        local h = io.open(f)
        local s = h:read("*a")
        io.close(h)
        return loadstring(s)()
end

localconfig = readConfig(arg[2])

--require "enet"

love.graphics.setMode(localconfig.screenWidth, localconfig.screenHeight, localconfig.fullscreen)

local luaPrint = print
print = function (...)
    if not config or config.show_prints then
        luaPrint(...)
    end
end

if arg[#arg] == "-debug" then require("mobdebug").start() end

-- local profiler = require 'profiler'
--~ profiler.start('profile.out')
require 'zoetrope'

vector = require 'vector'
str = require 'str'
storage = require 'storage'
collision = require 'collision'
utils = require 'utils'
input = require 'input'
profile = require 'profile'
list = require 'list'
json = require 'dkjson'
bson = require 'bson'
geometry = require 'geometry'

action_definitions = require 'action_definitions'
object_manager = require 'object_manager'
action_handling = require 'action_handling'
tools = require 'tools'
require 'actions'
require 'audio'
require 'network'

require 'debug_utils'

require 'GameObject'
require 'GameObjectCommons'
require 'FogOfWarObject'
require 'MonitorChanges'
require 'Buffs'
require 'Skill'
require 'SkillIcon'
require 'SkillBar'
require 'TargetDummy'
require 'Character'
require 'Ghost'
require 'Player'
require 'Npc'
require 'FocusSprite'
require 'Projectile'
require 'GameView'
require 'TestView'
require 'PhaseManager'
require 'Footstep'
require 'Barrier'
require 'Ressource'
require 'ConnectView'
require 'Effect'
require 'EffectCircle'
require 'EffectImage'
require 'LoveFramesCaller'
require 'Arrow'
require 'ui' 
require 'loveframes'
require 'ValidPosition' 
require 'Cover' 

-- stats ----------------------------
gameStats = storage.load("stats.json") or {}

gameStatsInc = function (key, inc)
	inc = inc or 1
	gameStats[key] = (gameStats[key] or 0) + inc
end

gameStatsSet = function (key, val)
	gameStats[key] = val
end

gameStatsInc("times_started")
-- ------------------------------------

function track(event, ...)
	network.send({channel = "server", cmd = "track", event = event, params = list.concat({network.client_id}, {...})})
end

the.app = App:new
{
	deactivateOnBlur = false,
	numGamepads = love.joystick and 1 or 0,
	name = "Combat Prototype",
	icon = '/graphics/icon.png',
	running = true,

	onUpdate = function (self, elapsed)
		collectgarbage("step", 1)
		profile.start("network.update")
		network.update(elapsed)
		profile.stop()
		
		-- set input mode
		if the.keys:justPressed ("f1") then print("input mode: mouse+keyboard") input.setMode (input.MODE_MOUSE_KEYBOARD) end
		--~ if the.keys:justPressed ("f2") then
			--~ switchBetweenGhostAndPlayer()
		--~ end
		--~ if the.keys:justPressed ("f3") then 
			--~ local l = object_manager.find_where(function(oid, o) 
				--~ return o.class and NetworkSyncedObjects[o.class]
			--~ end)
			--~ for _,o in pairs(l) do o:die() end
		--~ end	
		
		-- show the highscore table 
		if loveframes.GetState() == "none" then
			if the.player and the.barrier then
				if vector.lenFromTo(the.player.x, the.player.y, the.barrier.x, the.barrier.y) <= 1000 then
					if the.keys:justPressed (localconfig.showHighscore) then the.barrier:showHighscore() end			
				end
			end
		else
			if the.keys:justPressed (localconfig.showHighscore) then the.barrier:showHighscore() end			
		end

		-- resync
		if the.keys:justPressed ("f7") then the.app.view:resyncAllLocalObjects() end					
		-- show object list
		if the.keys:justPressed ("f8") then config.show_object_list = not config.show_object_list end					
		-- show Fog of War
		--~ if the.keys:justPressed ("f9") then config.show_fog_of_war = true the.app.view:fogOn() end					
		-- toggle fullscreen
		if the.keys:justPressed (localconfig.toggleFullscreen) then self:toggleFullscreen() end
		-- toggle profile
		if not the.keys:pressed("lctrl") and the.keys:justPressed ("f11") then config.show_profile_info = not config.show_profile_info end
		-- toggle debug draw
		if not the.keys:pressed("lctrl") and the.keys:justPressed ("f12") then config.draw_debug_info = not config.draw_debug_info end
		
		-- admin
		if the.keys:pressed("lctrl") and the.keys:justPressed ("f11") and network.is_admin then 
			if the.phaseManager then object_manager.send(the.phaseManager.oid, "force_next_phase") end
		end
		if the.keys:pressed("lctrl") and the.keys:justPressed ("f12") then
			network.send({channel = "server", cmd = "restart", password = localconfig.adminPassword })
		end

		-- easy exit
		if the.keys:justPressed(localconfig.quitGame) then 
			
			if not the.quitGameButton then
				-- make me a frame
				the.buttonFrame = loveframes.Create("frame")
				the.buttonFrame:SetSize(200, 50)
				the.buttonFrame:Center()
				the.buttonFrame:SetName("Do you really want to quit?")
				-- make me a quit button			
				the.quitGameButton = loveframes.Create("button")
				the.quitGameButton:SetSize(100, 25)
				the.quitGameButton:SetPos(love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2)
				the.quitGameButton:SetText("Yes, quit the game")
				the.quitGameButton.OnClick = function(object)
					--~ profiler.stop()
					quitClient()					
				end
				-- make me a cancel button
				the.cancelButton = loveframes.Create("button")
				the.cancelButton:SetSize(100, 25)
				the.cancelButton:SetPos(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
				the.cancelButton:SetText("Nope")
				the.cancelButton.OnClick = function(object)
					the.buttonFrame:Remove() 
					the.buttonFrame = nil 
					the.quitGameButton:Remove() 
					the.quitGameButton = nil 
					the.cancelButton:Remove() 
					the.cancelButton = nil 
				end
			else 
				the.buttonFrame:Remove() 
				the.buttonFrame = nil 			
				the.quitGameButton:Remove() 
				the.quitGameButton = nil 
				the.cancelButton:Remove() 
				the.cancelButton = nil 
			end
		end
		
		--~ if the.player then
			--~ print("ZONE", the.player.zone, "ZONES", json.encode(the.player.zones))
		--~ end
	end,

    onRun = function (self)
		-- disable the hardware cursor
		self:useSysCursor(false)	
		
		network.connect(config.server_hostname, config.server_port)
		
		--~ the.app.console:watch("viewx", "the.app.view.translate.x")
		--~ the.app.console:watch("viewy", "the.app.view.translate.y")
		
		-- setup connect view
		self.view = ConnectView:new()
		
		-- overload to disable drawing
		local oldDraw = self.draw 
		self.draw = function()
			if localconfig.is_bot and not config.draw_debug_info then 
				-- nop
			else
				oldDraw(self)
			end
		end		
    end,
}



function quitClient()
	track("client_quit")
	network.send({channel = "server", cmd = "bye"})
	-- wait a little bit to ensure bye delivery
	local t = love.timer.getTime()
	while love.timer.getTime() - t < 1 do
		network.update(1)
	end
	network.shutdown()
	if the.phaseManager and the.phaseManager.storePlayerState then
		print("STORE STATE")
		the.phaseManager:storePlayerState()
	end
	if gameStats then storage.save("stats.json", gameStats) end
	os.exit() 
end
