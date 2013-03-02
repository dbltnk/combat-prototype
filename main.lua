STRICT = true
DEBUG = true

-- local profiler = require 'profiler'
--~ profiler.start('profile.out')
require 'zoetrope'

vector = require 'vector'
utils = require 'utils'
config = require 'config'
input = require 'input'
profile = require 'profile'
list = require 'list'

action_definitions = require 'action_definitions'
object_manager = require 'object_manager'
action_handling = require 'action_handling'
tools = require 'tools'
require 'actions'

require 'debug_utils'

require 'Skill'
require 'SkillIcon'
require 'SkillBar'
require 'TargetDummy'
require 'Player'
require 'FocusSprite'
require 'Projectile'
require 'Particles'
require 'GameView'
require 'Footstep'

require 'ui'


the.app = App:new
{
	numGamepads = love.joystick and 1 or 0,
	name = "Combat Prototype",
	icon = '/graphics/icon.png',

	onUpdate = function (self, elapsed)
		-- set input mode
		if the.keys:justPressed ("f1") then print("input mode: mouse+keyboard") input.setMode (input.MODE_MOUSE_KEYBOARD) end
		if the.keys:justPressed ("f2") and the.gamepads[1].name ~= "NO DEVICE CONNECTED" then print("input mode: gamepad") input.setMode (input.MODE_GAMEPAD) end
		if the.keys:justPressed ("f3") then print("input mode: touch") input.setMode (input.MODE_TOUCH) end	
		
		-- toggle fullscreen
		if the.keys:justPressed ("f10") then self:toggleFullscreen() end
		
		-- toggle profile
		if the.keys:justPressed ("f11") then config.show_profile_info = not config.show_profile_info end
		-- toggle debug draw
		if the.keys:justPressed ("f12") then config.draw_debug_info = not config.draw_debug_info end

		-- easy exit
		if the.keys:pressed('escape') then 
			--~ profiler.stop()
			os.exit() 
		end
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
