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
json = require 'dkjson'

action_definitions = require 'action_definitions'
object_manager = require 'object_manager'
action_handling = require 'action_handling'
tools = require 'tools'
require 'actions'
require 'audio'
require 'network'

require 'debug_utils'

require 'MonitorChanges'
require 'Skill'
require 'SkillIcon'
require 'SkillBar'
require 'TargetDummy'
require 'Character'
require 'Player'
require 'Npc'
require 'FocusSprite'
require 'Projectile'
require 'Particles'
require 'GameView'
require 'Footstep'
require 'Barrier'
require 'Ressource'
require 'SyncedObject'
require 'ConnectView'

require 'ui'
    

the.app = App:new
{
	deactivateOnBlur = false,
	numGamepads = love.joystick and 1 or 0,
	name = "Combat Prototype",
	icon = '/graphics/icon.png',

	onUpdate = function (self, elapsed)
		network.update()
		
		-- set input mode
		if the.keys:justPressed ("f1") then print("input mode: mouse+keyboard") input.setMode (input.MODE_MOUSE_KEYBOARD) end
		if the.keys:justPressed ("f2") and the.gamepads[1].name ~= "NO DEVICE CONNECTED" then print("input mode: gamepad") input.setMode (input.MODE_GAMEPAD) end
		if the.keys:justPressed ("f3") then print("input mode: touch") input.setMode (input.MODE_TOUCH) end	
		
		-- debug cheats
		if the.keys:justPressed ("f5") then the.player.currentPain = the.player.currentPain + 20 end	
					
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
		if love.timer.getTime() >= config.roundTime then print("THE GAME IS OVER") os.exit() end -- TODO: switch to end screen
	end,

    onRun = function (self)
		-- disable the hardware cursor
		self:useSysCursor(false)
		
		network.connect("localhost", 9999)
		table.insert(network.on_message, function(m) 
			print ("RECEIVED", json.encode(m))
			if m.channel == "game" then
				if m.cmd == "sync" then
					local o = object_manager.get(m.oid)
					
					if not o then
						-- request detail infos
						-- TODO
						-- create
						o = object_manager.create_remote(SyncedObject:new(), m.oid, m.owner)
						print("NEW REMOTE OBJECT", o.oid)
					end
					
					-- sync
					o.x = m.x or o.x
					o.y = m.y or o.y
					o.rotation = m.rotation or o.rotation
					o.currentEnergy = m.currentEnergy or o.currentEnergy
					o.currentPain = m.currentPain or o.currentPain
					print("SYNC REMOTE OBEJCT", o.oid)
				end
			end
		end)

		--~ the.app.console:watch("viewx", "the.view.translate.x")
		--~ the.app.console:watch("viewy", "the.view.translate.y")
		
		-- setup connect view
		self.view = ConnectView:new()
    end
}
