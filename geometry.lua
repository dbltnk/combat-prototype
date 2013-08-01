
local geometry = {}

-- http://en.wikipedia.org/wiki/Bresenham's_line_algorithm
-- rasterize a line and calls fun(x,y) for each point
function geometry.raster_line(x0,y0, x1,y1, fun)
	local dx = math.abs(x1-x0)
	local dy = math.abs(y1-y0) 
	if x0 < x1 then sx = 1 else sx = -1 end
	if y0 < y1 then sy = 1 else sy = -1 end
	local err = dx-dy

	while true do
		fun(x0,y0)
		if x0 == x1 and y0 == y1 then return end
		local e2 = 2*err
		if e2 > -dy then 
			err = err - dy
			x0 = x0 + sx
		end
		if x0 == x1 and y0 == y1 then 
			fun(x0,y0)
			return
		end
		if e2 < dx then 
			err = err + dx
			y0 = y0 + sy 
		end
	end
end


-- x,y,numInLine
function geometry.raster_line_it(x0,y0, x1,y1)
	return coroutine.wrap(function () 
		local numInLine = 0
		local dx = math.abs(x1-x0)
		local dy = math.abs(y1-y0) 
		if x0 < x1 then sx = 1 else sx = -1 end
		if y0 < y1 then sy = 1 else sy = -1 end
		local err = dx-dy

		while true do
			coroutine.yield(x0,y0,numInLine) numInLine = numInLine + 1
			if x0 == x1 and y0 == y1 then return end
			local e2 = 2*err
			if e2 > -dy then 
				err = err - dy
				x0 = x0 + sx
			end
			if x0 == x1 and y0 == y1 then 
				coroutine.yield(x0,y0,numInLine) numInLine = numInLine + 1
				return
			end
			if e2 < dx then 
				err = err + dx
				y0 = y0 + sy 
			end
		end
	end)
end
    
--~ geometry.raster_line(0,0, 10,0, function(x,y) print(x,y) end)
--~ print("---")
--~ for x,y in geometry.raster_line_it(0,0, 10,0) do print(x,y) end

return geometry
