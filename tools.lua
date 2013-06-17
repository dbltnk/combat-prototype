
local vector = require 'vector'

local tools = {}

-- returns x,y
function tools.ScreenPosToWorldPos(x,y)
	local vx,vy = vector.mul(the.app.view.translate.x, the.app.view.translate.y, -1)
	return vector.add(vx,vy, x,y)
end

-- returns x,y
function tools.WorldPosToScreenPos(x,y)
	local vx,vy = vector.mul(the.app.view.translate.x, the.app.view.translate.y, 1)
	return vector.add(vx,vy, x,y)
end

-- returns width,height
function tools.object_size (obj)
	return 
		obj and obj.width or 0, obj and obj.height or 0
end

-- returns x,y
function tools.object_center (obj)
	local w,h = tools.object_size(obj)
	return 
		(obj and obj.x or 0) + w/2, (obj and obj.y or 0) + h/2
end

-- 432.345345 -> 432.3
function tools.floor1 (x)
	return math.floor(x * 10) / 10
end

return tools
