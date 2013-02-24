
local vector = require 'vector'

local tools = {}

-- returns x,y
function tools.ScreenPosToWorldPos(x,y)
	local vx,vy = vector.mul(the.view.translate.x, the.view.translate.y, -1)
	return vector.add(vx,vy, x,y)
end

-- returns x,y
function tools.WorldPosToScreenPos(x,y)
	local vx,vy = vector.mul(the.view.translate.x, the.view.translate.y, 1)
	return vector.add(vx,vy, x,y)
end

return tools
