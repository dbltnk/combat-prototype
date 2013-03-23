-- Class: Grid
-- A Grid is a spatial index structure for a set of sprites.
--
-- Extends:
--		<Class>

Grid = Class:extend
{
	-- sprite -> {x0,y0,x1,y1}
	storedSpritesMap = {},

	-- Property: gridSize
	-- The size, in pixels, of the grid used for collision detection.
	-- This partitions off space so that collision checks only need to do real
	-- checks against a few sprites at a time. If you notice collision detection
	-- taking a long time, changing this number may help.
	gridSize = 50,

	grid = {},

	-- Method: add
	-- Adds a sprite to the Grid.
	--
	-- Arguments:
	--		sprite - <Sprite> to add
	--
	-- Returns:
	--		nothing

	add = function (self, sprite)
		assert(sprite, 'asked to add nil to a Grid')
		assert(sprite ~= self, "can't add a Grid to itself")
	
		if not self.storedSpritesMap[sprite] then
			local x0,y0,x1,y1 = self:getCells(sprite)
			self.storedSpritesMap[sprite] = {x0,y0,x1,y1}
			local grid = self.grid
			for x = x0, x1 do
				if not grid[x] then grid[x] = {} end
				for y = y0, y1 do
					if not grid[x][y] then grid[x][y] = {} end
					grid[x][y][sprite] = true
				end
			end
		end
	end,

	getCells = function (self, sprite)
		local gridSize = self.gridSize
		local startX = math.floor(sprite.x / gridSize)
		local endX = math.floor((sprite.x + sprite.width) / gridSize)
		local startY = math.floor(sprite.y / gridSize)
		local endY = math.floor((sprite.y + sprite.height) / gridSize)
		return startX, startY, endX, endY
	end,

	-- Method: remove
	-- Removes a sprite from the Grid. If the sprite is
	-- not in the Grid, this does nothing.
	-- 
	-- Arguments:
	-- 		sprite - <Sprite> to remove
	-- 
	-- Returns:
	-- 		nothing

	remove = function (self, sprite)
		if not self.storedSpritesMap[sprite] then return end
		
		local x0,y0,x1,y1 = unpack(self.storedSpritesMap[sprite])
		local grid = self.grid
		
		for x = x0, x1 do
			for y = y0, y1 do
				grid[x][y][sprite] = nil
			end
		end
		
		self.storedSpritesMap[sprite] = nil
	end,

	query = function (self, x, y, width, height)
		local gridSize = self.gridSize
		local x0 = math.floor(x / gridSize)
		local x1 = math.floor((x + width) / gridSize)
		local y0 = math.floor(y / gridSize)
		local y1 = math.floor((y + height) / gridSize)
		local grid = self.grid
		
		local iterate = function ()		
			for x = x0, x1 do
				if grid[x] then
					local gx = grid[x]
					for y = y0, y1 do
						if gx[y] then 
							for sprite, _ in pairs(gx[y]) do
								coroutine.yield(sprite)
							end
						end
					end
				end
			end
		end
		
		return coroutine.wrap(function() iterate() end)
	end,
	
	notifyChange = function (self, sprite)
		self:remove(sprite)
		self:add(sprite)
	end,

	__tostring = function (self)
		local result = 'Grid ('

		return result .. ')'
	end
}
