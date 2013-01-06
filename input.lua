
local input = {}

input.MODE_MOUSE_KEYBOARD = 1
input.MODE_GAMEPAD = 2
input.MODE_TOUCH = 3

input.cursor = {x = 0, y = 0}

input.mode = input.MODE_MOUSE_KEYBOARD

function input.setMode (mode)
	input.mode = mode
end

function input.getMode ()
	return input.mode
end

return input
