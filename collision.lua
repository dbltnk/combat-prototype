
local collision = {}

collision.minDistPointToSegment = function(x,y, x0,y0,x1,y1)
	-- http://www.exaflop.org/docs/cgafaq/cga1.html
	local l = vector.lenFromTo(x0,y0,x1,y1)
	local r = ((y0-y)*(y0-y1)-(x0-x)*(x1-x0)) / (l*l)
	
	--~ print(x,y, x0,y0,x1,y1,"r",r)
	
	-- clamp to end points
	if r < 0 then r = 0 end
	if r > 1 then r = 1 end
	
	local px = x0 + r * (x1 - x0)
	local py = y0 + r * (y1 - y0)
    
    return vector.lenFromTo(x,y,px,py)
end

-- returns dist
collision.minDistPointToAABB = function(x,y, x0,y0,x1,y1)
	-- inside?
	if x0 < x and x < x1 and y0 < y and y < y1 then return 0 end
	
	local l = math.min(
		vector.lenFromTo(x,y,x0,y0),
		vector.lenFromTo(x,y,x1,y0),
		vector.lenFromTo(x,y,x0,y1),
		vector.lenFromTo(x,y,x1,y1),
		collision.minDistPointToSegment(x,y,x0,y0,x1,y0),
		collision.minDistPointToSegment(x,y,x0,y1,x1,y1),
		collision.minDistPointToSegment(x,y,x0,y0,x0,y1),
		collision.minDistPointToSegment(x,y,x1,y0,x1,y1)
	)
	
	--~ print(x,y, x0,y0,x1,y1,"->",l)
	
	return l
end

return collision

