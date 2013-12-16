GridIndex = Class:extend{
	grid = {},
	cellSize = 100,
	cellLine = 10000,
	
	onNew = function (self)
		
	end,
	
	cellIndex = function (self, x,y)
		local cx = math.floor(x / self.cellSize)
		local cy = math.floor(y / self.cellSize)
		return cy * self.cellLine + cx
	end,
	
	clear = function (self)
		for k,v in pairs(self.grid) do
			for kk,vv in pairs(v) do v[kk] = nil end
		end
	end,

	moveFromTo = function (self, o, ox,oy, nx,ny)
	    if not o then return end

	    local oi = self:cellIndex(ox,oy)
	    local ni = self:cellIndex(nx,ny)

	    if oi == ni then return end

	    -- print("MOVE OBJ", o.oid, "FROM", oi, "TO", ni)
	    self:removeAt(ox,oy,o)
	    self:insertAt(nx,ny,o)
	end,
	
	insertAt = function (self, x,y, o)
		local grid = self.grid
		local index = self:cellIndex(x,y)
		if not grid[index] then grid[index] = {} end
		grid[index][o] = true
	end,
	
	removeAt = function (self, x,y, o)
		local grid = self.grid
		local index = self:cellIndex(x,y)
		if grid[index] then
			grid[index][o] = nil
		end
	end,
	
	-- fun (o)
	visitInRange = function (self, x,y, r, fun)
		self:visitInAABB(x-r,y-r,x+r,y+r, fun)
	end,

	drawDebug = function (self, r,g,b)
	    local ax, ay = tools.ScreenPosToWorldPos(0,0)
	    local bx, by = tools.ScreenPosToWorldPos(love.graphics.getWidth(), love.graphics.getHeight())
	    local cs = self.cellSize
	    local d = cs / 2
	    local gr = self.grid

	    love.graphics.setColor( r, g, b )

	    for x = ax, bx, d do
	    for y = ay, by, d do
		local idx = self:cellIndex(x,y)
		local cx, cy = math.floor(x / cs) * cs, math.floor(y / cs) * cs
		local cell = gr[idx]
		if cell then
		    for o,_ in pairs(cell) do
			local ox,oy,ow,oh = o.x, o.y, o.width, o.height
			if vector.lenFromTo(ox,oy,cx,cy) < cs*2 then
			    --print("CELL", cx, cy, "OBJ", ox,oy,ow,oh, o.class)
			    love.graphics.setColor( r, g, b )
			    love.graphics.rectangle("line", cx - ax, cy - ay, cs, cs)
			    
			    love.graphics.setColor( 100, 100, 100 )
			    love.graphics.rectangle("line", ox - ax, oy - ay, ow, oh)
			    
			end
		    end
		end
	    end
	    end
	    
	    love.graphics.setColor(255,255,255)
	end,
	
	-- fun (o)
	visitInAABB = function (self, x0,y0, x1,y1, fun)
		local grid = self.grid
		local cx0 = math.floor(x0 / self.cellSize)
		local cy0 = math.floor(y0 / self.cellSize)
		
		local cx1 = math.ceil(x1 / self.cellSize)
		local cy1 = math.ceil(y1 / self.cellSize)
		
		local d = 2

		for cy = cy0-d,cy1+d do
			for cx = cx0-d,cx1+d do
				local i = cy * self.cellLine + cx
				if grid[i] then
					for k,_ in pairs(grid[i]) do fun(k) end
				end
			end
		end
	end,
	
	-- slow
	removeObject = function (self, o)
		local grid = self.grid
		for _,v in pairs(self.grid) do
			v[o] = nil
		end
	end,
}
