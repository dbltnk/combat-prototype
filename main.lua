STRICT = true
DEBUG = true

config = require 'config'
localconfig = require 'localconfig'

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
utils = require 'utils'
input = require 'input'
profile = require 'profile'
list = require 'list'
json = require 'dkjson'
bson = require 'bson'

action_definitions = require 'action_definitions'
object_manager = require 'object_manager'
action_handling = require 'action_handling'
tools = require 'tools'
require 'actions'
require 'audio'
require 'network'

require 'debug_utils'

require 'GameObject'
require 'MonitorChanges'
require 'Buffs'
require 'Skill'
require 'SkillIcon'
require 'SkillBar'
require 'TargetDummy'
require 'Character'
require 'Player'
require 'Npc'
require 'FocusSprite'
require 'Projectile'
require 'GameView'
require 'TestView'
require 'Footstep'
require 'Barrier'
require 'Ressource'
require 'SyncedObject'
require 'ConnectView'
require 'Effect'
require 'EffectCircle'
require 'ui' 
require 'loveframes'


the.app = App:new
{
	deactivateOnBlur = false,
	numGamepads = love.joystick and 1 or 0,
	name = "Combat Prototype",
	icon = '/graphics/icon.png',
	running = true,

	onUpdate = function (self, elapsed)
		profile.start("network.update")
		network.update(elapsed)
		profile.stop()
		
		-- set input mode
		if the.keys:justPressed ("f1") then print("input mode: mouse+keyboard") input.setMode (input.MODE_MOUSE_KEYBOARD) end
		if the.keys:justPressed ("f2") and the.gamepads[1].name ~= "NO DEVICE CONNECTED" then print("input mode: gamepad") input.setMode (input.MODE_GAMEPAD) end
		if the.keys:justPressed ("f3") then print("input mode: touch") input.setMode (input.MODE_TOUCH) end	
		
		-- show the highscore table 
		if the.keys:justPressed ("f5") then the.barrier:showHighscore() end	

		-- resync
		if the.keys:justPressed ("f7") then the.app.view:resyncAllLocalObjects() end					
		-- show object list
		if the.keys:justPressed ("f8") then config.show_object_list = not config.show_object_list end					
		-- show Fog of War
		if the.keys:justPressed ("f9") then config.show_fog_of_war = true the.app.view:fogOn() end					
		-- toggle fullscreen
		if the.keys:justPressed ("f10") then self:toggleFullscreen() end
		-- toggle profile
		if the.keys:justPressed ("f11") then config.show_profile_info = not config.show_profile_info end
		-- toggle debug draw
		if the.keys:justPressed ("f12") then config.draw_debug_info = not config.draw_debug_info end

		-- easy exit
		if the.keys:pressed('escape') then 
			--~ profiler.stop()
			network.shutdown()
			os.exit() 
		end
		
		-- game ends, players lost
		if love.timer.getTime() >= config.roundTime then 
			if self.running then
				local text = "The players lost, here's how you did:"
				the.barrier:showHighscore(text)
				self.running = false
				self.timeScale = 0
			end
		end
	end,

    onRun = function (self)
		-- disable the hardware cursor
		self:useSysCursor(false)	
		
		network.connect(config.server_hostname, config.server_port)
		
		--~ the.app.console:watch("viewx", "the.app.view.translate.x")
		--~ the.app.console:watch("viewy", "the.app.view.translate.y")
		
		-- setup connect view
		self.view = ConnectView:new()
    end
}
