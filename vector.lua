
local vector = {}

vector.len = function(x,y)
	return math.sqrt(x*x + y*y)
end

-- returns dx,dy
vector.fromTo = function(x0,y0, x1,y1)
	return x1-x0, y1-y0
end

vector.lenFromTo = function(x0,y0, x1,y1)
	return vector.len(vector.fromTo(x0,y0, x1,y1))
end

-- returns x,y
vector.normalize = function(x,y)
	local l = vector.len(x,y)
	return x/l, y/l
end

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
