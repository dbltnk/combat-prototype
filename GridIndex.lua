GridIndex = Class:extend{
	grid = {},
	cellSize = 50,
	cellLine = 1000,
	
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
	
	-- fun (o)
	visitInAABB = function (self, x0,y0, x1,y1, fun)
		local grid = self.grid
		local cx0 = math.floor(x0 / self.cellSize)
		local cy0 = math.floor(y0 / self.cellSize)
		
		local cx1 = math.ceil(x1 / self.cellSize)
		local cy1 = math.ceil(y1 / self.cellSize)
		
		for cy = cy0,cy1 do
			for cx = cx0,cx1 do
				local i = cy * self.cellLine + cx
				if grid[i] then
					for k,v in pairs(grid[i]) do fun(k) end
				end
			end
		end
	end,
	
	-- slow
	removeObject = function (self, o)
		local grid = self.grid
		for k,v in pairs(self.grid) do
			grid[o] = nil
		end
	end,
}
