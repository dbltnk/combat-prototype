-- LineOfSight

LineOfSight = Sprite:extend
{
	class = "LineOfSight",

	x = 0,
	y = 0,
	width = 1,
	height = 1,
	cell = config.cellSize,
	
	visibility = {},
	
	sourceOids = {},
	
	lastCalculatedCellSource = {x = -1000, y = -1000},
	
	allVisible = true,
	
	onNew = function (self)
		self.width = config.map_width
		self.height = config.map_height
	end,
	
	cell2px = function (self, cx, cy)
		return cx * self.cell, cy * self.cell
	end,

	px2cell = function (self, x, y)
		return math.floor(x / self.cell), math.floor(y / self.cell)
	end,
	
	isCollisionOnCell = function (self, cx,cy)
		-- profile.start("los collide")
	
		local collision = false
		local px,py = self:cell2px(cx,cy)
		-- profile.start("los sprite")
		local s = {
			x = px,
			y = py,
			width = self.cell,
			height = self.cell,
			solid = true,
		}
		-- profile.stop()
		
		-- profile.start("los collide landscape")
		if collision == false and the.view.landscape:subcollide(s) then collision = true end
		-- profile.stop()
		
		-- profile.start("los collide collision")
		if collision == false and the.view.collision:collide(s) then collision = true end
		-- profile.stop()
		
		-- profile.stop()
		
		return collision
	end,
	
	calculateVisibilityAddSource = function (self, px,py, range, angle, rotation)
		local pcx, pcy = self:px2cell(px,py)
		
		--~ if pcx == self.lastCalculatedCellSource.x and pcy == self.lastCalculatedCellSource.y then return
		--~ else 
			--~ self.lastCalculatedCellSource.x = pcx
			--~ self.lastCalculatedCellSource.y = pcy
		--~ end

		-- profile.start("calculateVisibility")

		local v = self.visibility
		
		local sx,sy = -the.view.translate.x, -the.view.translate.y
		
		local c0x, c0y = self:px2cell(sx,sy)
		local c1x, c1y = self:px2cell(sx + the.app.width, sy + the.app.height)
		local cell = self.cell
		
		if 
			c0x > -math.huge and c0x < math.huge
		then
			local b = 2
			c0x, c0y = vector.add(c0x, c0y, -b,-b)
			c1x, c1y = vector.add(c1x, c1y, b, b)
		
			-- early out
			if pcx < c0x or c1x < pcx or
				pcy < c0y or c1y < pcy then return end
		
			local range2 = range*range
			local angleHRad = (angle / 2) / 180 * math.pi
			
			local self_cellKey = self.cellKey
			local vector_sqLenFromTo = vector.sqLenFromTo
			local self_isCollisionOnCell = self.isCollisionOnCell
			local cellsUntilDarkMax = config.cellsUntilDark
			
			local srcViewX, srcViewY = vector.fromVisualRotation(rotation, 1)
			
			for cx = c0x, c1x do
			for cy = c0y, c1y do
				if cx == c0x or cx == c1x or cy == c0y or cy == c1y then
					--~ print("line from", pcx,pcy,"to",cx,cy)
					local free = true
					local cellsUntilDark = cellsUntilDarkMax
					
					-- profile.start("los 1 step")

					-- in fov?
					local a = vector.angleFromTo(srcViewX, srcViewY, vector.fromTo(px,py, self:cell2px(cx,cy)))
					
					--~ print(a, angleHRad)
					
					if a <= angleHRad then
						for x,y,cellNumInLine in geometry.raster_line_it(pcx,pcy,cx,cy) do
							-- profile.start("los 1 sub step " .. cellNumInLine)
							local k = self_cellKey(self, x,y)
							if (v[k] or 0) <= 1 then 
								if cellNumInLine > 0 then
									-- view range
									local d = vector_sqLenFromTo(px,py, self:cell2px(x,y))
									--~ print(d,range,px,py,x,y)
									if d > range2 then free = false
									-- collision
									elseif self_isCollisionOnCell(self, x,y) then free = false end
								end
								
								if free or cellsUntilDark > 0 then 
									if free then v[k] = 1
									elseif cellsUntilDark >= 0 then 
										v[k] = math.max(v[k] or 0, cellsUntilDark / cellsUntilDarkMax)
										cellsUntilDark = cellsUntilDark - 1
									else
										-- profile.stop()
										break
									end
								end
							end
							--~ print("free", free, x,y)
							-- profile.stop()
						end
					end
					
					-- profile.stop()
				end
			end
			end
		end
		
		-- profile.stop()
	end,
	
	calculateVisibility = function (self)
		self.visibility = {}
		for _,oid in pairs(self.sourceOids) do
			local o = object_manager.get(oid)
			if o then
				local ox, oy = tools.object_center(o)
				self:calculateVisibilityAddSource(ox,oy, o.viewRange or 0, o.viewAngle or 0, o.rotation)
			end
		end
	end,
	
	cellKey = function (self, cx,cy)
		return cx .. "_" .. cy
	end,
	
	getVisibility = function (self, px, py, cx, cy)
		return self.visibility[self:cellKey(cx,cy)] or 0
		--~ local dx,dy = vector.fromTo(the.player.x, the.player.y, px, py)
		--~ local l = vector.len(dx, dy)
		--~ local vx,vy = vector.fromVisualRotation(the.player.rotation, 1)
		--~ local v = vector.dot(vx,vy, vector.normalize(dx,dy))
		--~ if v < 0.25 then v = 0 end
		--~ v = 1 - v
		--~ return v --math.min(utils.mapIntoRange (l, 100, 300, 0, 1), 1-v)
	end,

	onUpdate = function (self, elapsed)
		self:calculateVisibility()
	end,

	onDraw = function (self, x, y)
		if self.allVisible then return end
		
		love.graphics.setBlendMode( "alpha" )

		local sx,sy = -the.view.translate.x, -the.view.translate.y

		local c0x, c0y = self:px2cell(sx,sy)
		local c1x, c1y = self:px2cell(sx + the.app.width, sy + the.app.height)
		local cell = self.cell
		
		--~ print(sx,sy, c0x, c0y, c1x, c1y, cell)
		
		local gv = self.getVisibility
		
		if 
			c0x > -math.huge and c0x < math.huge
		then
			for cx = c0x, c1x do
			for cy = c0y, c1y do
				local px,py = self:cell2px(cx,cy)
				--~ print(cx, cy, px, py)
				love.graphics.setColor(0,0,0,math.floor(255 * (1 - gv(self,px,py,cx,cy))))
				love.graphics.rectangle("fill", px-sx,py-sy, cell,cell)
			end
			end
		end
	end,
}
