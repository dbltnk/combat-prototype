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
	alreadySeen = {},
	collision = {},
	rebuildCollision = false,
	dirty = false,
	
	scanline = 0,
	
	sourceOids = {},
	
	lastCalculatedCellSource = {x = -1000, y = -1000},
	
	updateEachNFrames = config.cellUpdateEachNFrames,
	framesUntilUpdate = 0,
	
	allVisible = true,
	
	onNew = function (self)
		self.width = config.map_width
		self.height = config.map_height
		self.scanline = math.floor(config.map_width / self.cell) + 200
		
		the.app.view.timer:every(0.5, function()
			--~ print("tick")
			if self.dirty == true then
				--~ print("dirty")
				self.dirty = false
				self.rebuildCollision = true
			end
		end)
	end,
	
	cell2px = function (self, cx, cy)
		return cx * self.cell, cy * self.cell
	end,

	px2cell = function (self, x, y)
		return math.floor(x / self.cell), math.floor(y / self.cell)
	end,
	
	calculateCollision = function (self)
		this.rebuildCollision = false

		-- clear
		for k,v in pairs(self.collision) do self.collision[k] = nil end
		local c = self.collision

		local c0x, c0y = self:px2cell(0,0)
		local c1x, c1y = self:px2cell(config.map_width, config.map_height)
		local cell = self.cell
		
		if c0x < -math.huge or c0x > math.huge then return end
		
		local b = 2
		c0x, c0y = vector.add(c0x, c0y, -b,-b)
		c1x, c1y = vector.add(c1x, c1y, b, b)
		
		--~ print("build collision cache")
		
		local count = 0
		
		for cx = c0x, c1x do
		for cy = c0y, c1y do
			if self:isCollisionOnCell(cx,cy) then 
				count = count + 1
				c[self:cellKey(cx,cy)] = true 
			end
		end
		end
		
		--~ print("found", count, "collision cells")
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
		
		-- resources
		for obj,_ in pairs(the.ressourceObjects) do
			if collision == false and obj:collide(s) then collision = true end
		end
		
		-- blockers
		for obj,_ in pairs(the.blockers) do
			if collision == false and obj:collide(s) then collision = true end
		end		
		
		-- profile.stop()
		
		return collision
	end,

	rasterResult = {},
	
	calculateVisibilityAddSource = function (self, px,py, range, angle, rotation, feelRange)
		local self_cellKey = self.cellKey
		local vector_sqLenFromTo = vector.sqLenFromTo
		local self_isCollisionOnCellUseCache = self.isCollisionOnCellUseCache
		local cellsUntilDarkMax = config.cellsUntilDark
		local self_cell2px = self.cell2px
		local self_collision = self.collision
		
		local colFun = nil

		if self.rebuildCollision then 
		    profile.start("onupdate.los.calculate.rebuild")
		    self:calculateCollision()
		    profile.stop()
		    colFun = function(k,cx,cy) return self:isCollisionOnCell(cx,cy) end
		else
		    colFun = function(k,cx,cy) return self_collision[k] end
		end
		
		
		local pcx, pcy = self:px2cell(px,py)
		
		--~ if pcx == self.lastCalculatedCellSource.x and pcy == self.lastCalculatedCellSource.y then return
		--~ else 
			--~ self.lastCalculatedCellSource.x = pcx
			--~ self.lastCalculatedCellSource.y = pcy
		--~ end

		-- profile.start("calculateVisibility")

		local v = self.visibility
		local as = self.alreadySeen
		
		-- feel range
		local f0x, f0y = self:px2cell(px-feelRange,py-feelRange)
		local f1x, f1y = self:px2cell(px+feelRange,py+feelRange)
		for fx = f0x, f1x do
		for fy = f0y, f1y do
			local k = self_cellKey(self, fx,fy)
			v[k] = 1
			as[k] = 1
		end
		end
		
		
		
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
			
			local srcViewX, srcViewY = vector.fromVisualRotation(rotation, 1)
		
			local rasterResult = self.rasterResult

			for cx = c0x, c1x do
			for cy = c0y, c1y do
				if cx == c0x or cx == c1x or cy == c0y or cy == c1y then
					--~ print("line from", pcx,pcy,"to",cx,cy)
					local free = true
					local cellsUntilDark = cellsUntilDarkMax
					
					--profile.start("los 1 step")

					-- in fov?
					local a = vector.angleFromTo(srcViewX, srcViewY, vector.fromTo(px,py, self_cell2px(self,cx,cy)))
					
					--~ print(a, angleHRad)
					
					if a <= angleHRad then
						--profile.start("los 1 raster")
						-- clear raster result
						for k,v in pairs(rasterResult) do rasterResult[k] = nil end
						-- and run a new raster run
						geometry.raster_line_it(pcx,pcy,cx,cy,rasterResult)
						for i=1,#rasterResult,3 do
							local x,y,cellNumInLine = rasterResult[i], rasterResult[i+1], rasterResult[i+2]
							--profile.start("los 1 sub step")
							local k = self_cellKey(self, x,y)
							if (v[k] or 0) <= 1 then 
								if cellNumInLine > 0 then
									-- view range
									local d = vector_sqLenFromTo(px,py, self_cell2px(self,x,y))
									--~ print(d,range,px,py,x,y)
									if d > range2 then free = false
									-- collision
									elseif colFun(k, x,y) then free = false end
								end
								
								if free or cellsUntilDark > 0 then 
									if free then 
										as[k] = 1
										v[k] = 1 
									elseif cellsUntilDark > 0 then 
										as[k] = 1
										v[k] = 1
										cellsUntilDark = cellsUntilDark - 1
									else
										--profile.stop()
										break
									end
								end
							end
							--~ print("free", free, x,y)
							--profile.stop()
						end
						--profile.stop()
					end
					
					--profile.stop()
				end
			end
			end
		end
		
		-- profile.stop()
	end,
	
	calculateVisibility = function (self)
		-- clear visibility
		for k,v in pairs(self.visibility) do self.visibility[k] = nil end
		
		for _,oid in pairs(self.sourceOids) do
			local o = object_manager.get(oid)
			if o then
				local ox, oy = tools.object_center(o)
				profile.start("onupdate.los.calculate")
				self:calculateVisibilityAddSource(ox,oy, o.viewRange or 0, o.viewAngle or 0, o.rotation, o.feelRange or 0)
				profile.stop()
			end
		end
	end,
	
	cellKey = function (self, cx,cy)
		-- "int" for faster array table access
		return self.scanline + cx + self.scanline * cy
	end,
	
	isObjectVisible = function (self, o)
		local c0x, c0y = self:px2cell(o.x,o.y)
		local c1x, c1y = self:px2cell(o.x + o.width, o.y + o.height)
		
		if 
			c0x > -math.huge and c0x < math.huge
		then
			for cx = c0x, c1x do
			for cy = c0y, c1y do
				local k = self:cellKey(cx,cy)
				local f = self.visibility[k] or 0
				if f > 0 then return true end
			end
			end
		end
		
		return false
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
		profile.start("onupdate.los")
	
		if self.framesUntilUpdate <= 0 then
			--~ print("UPDATE")
			self:calculateVisibility()
			self.framesUntilUpdate = self.updateEachNFrames
		else
			--~ print("SKIP")
			self.framesUntilUpdate = self.framesUntilUpdate - 1
		end		
		
		profile.stop()
	end,

	reset = function (self)
		self.visibility = {}
		self.alreadySeen = {}
		self.collision = nil
	end,
	
	screenCellMap = {},

	onDraw = function (self, x, y)
		if self.allVisible then return end
		
		-- profile.start("fos draw")
		
		love.graphics.setBlendMode( "alpha" )

		local sx,sy = -the.view.translate.x, -the.view.translate.y

		local c0x, c0y = self:px2cell(sx,sy)
		local c1x, c1y = self:px2cell(sx + the.app.width, sy + the.app.height)
		local cell = self.cell
		
		--~ print(sx,sy, c0x, c0y, c1x, c1y, cell)
		
		local m = self.screenCellMap
		local mv = self.visibility
		local mas = self.alreadySeen
		
		local r,g,b = unpack(config.lineOfSightColor)
		
		if 
			c0x > -math.huge and c0x < math.huge
		then
			for cx = c0x, c1x do
			for cy = c0y, c1y do
				local k = self:cellKey(cx,cy)
				local px,py = self:cell2px(cx,cy)
				local vb = mv[k] or 0
				local as = mas[k] or 0
				local f = math.max(vb, as / 2)
				
				if vb > 0 then f = config.lineOfSightInSight
				elseif as > 0 then f = config.lineOfSightOutOfSight
				else f = config.lineOfSightUnknown end
				
				local of = m[k] or 0
				
				f = 0.4 * f + 0.6 * of
				m[k] = f
				
				--~ print(cx, cy, px, py)
				love.graphics.setColor(r,g,b, math.floor(255 * (1 - f)))
				love.graphics.rectangle("fill", px-sx,py-sy, cell,cell)
			end
			end
		end
		
		-- profile.stop()
	end,
}
