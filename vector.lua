
local vector = {}

vector.len = function(x,y)
	return math.sqrt(x*x + y*y)
end

-- returns dx,dy
vector.fromTo = function(x0,y0, x1,y1)
	return x1-x0, y1-y0
end

-- returns dx,dy with given len (starting at x0/y0)
vector.fromToWithLen = function(x0,y0, x1,y1, len)
	return vector.normalizeToLen(x1-x0, y1-y0, len)
end

vector.lenFromTo = function(x0,y0, x1,y1)
	return vector.len(vector.fromTo(x0,y0, x1,y1))
end

-- returns x,y
vector.normalize = function(x,y)
	local l = vector.len(x,y)
	return x/l, y/l
end

-- 0|-1 -> -1/2 pi, 1|0 -> 0 pi, 0|1 -> 1/2 pi, -1|0 -> 1 pi
-- returns radians
vector.toRotation = function(x,y)
	local radians = math.atan2(y,x)
	return radians
end

-- 0 points upwards, adjusted for love gfx rotation
-- 0|-1 -> 0, 1|0 -> 1/2 pi, 0|1 -> 1 pi, -1|0 -> -1/2 pi
vector.toVisualRotation = function(x,y)
	return vector.toRotation(x,y) + math.pi * 0.5
end

-- return x,y
vector.fromRotation = function (radians, len)
	len = len or 1
	return len * math.cos(radians), len * math.sin(radians)
end

-- return x,y
vector.fromVisualRotation = function (radians, len)
	len = len or 1
	local r = radians - 0.5 * math.pi
	return len * math.cos(r), len * math.sin(r)
end

--[[
for x=-1,1 do
for y=-1,1 do
	if math.abs(x) + math.abs(y) == 1 then
		print(x,y, "vis", vector.toVisualRotation(x,y), vector.fromVisualRotation(vector.toVisualRotation(x,y)))
		print(x,y, "math", vector.toRotation(x,y), vector.fromRotation(vector.toRotation(x,y)))
	end
end
end
]]

vector.normalizeToLen = function(x,y,l)
	local nx,ny = vector.normalize (x,y)
	return nx*l, ny*l
end

-- returns x,y
vector.add = function(x0,y0, x1,y1)
	return x0+x1, y0+y1
end

-- returns x,y
vector.sub = function(x0,y0, x1,y1)
	return x0-x1, y0-y1
end

-- returns x,y
vector.mul = function(x,y,s)
	return x*s,y*s
end

return vector
