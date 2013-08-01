-- LineOfSight

LineOfSight = Sprite:extend
{
	class = "LineOfSight",

	x = 0,
	y = 0,
	width = 1,
	height = 1,
	cell = 50,
	
	visibility = {},
	
	lastCalculatedCellSource = {x = -1000, y = -1000},
	
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
	
	calculateVisibility = function (self)
		local px, py = tools.object_center(the.player)
		local pcx, pcy = self:px2cell(px,py)
		
		--~ if pcx == self.lastCalculatedCellSource.x and pcy == self.lastCalculatedCellSource.y then return
		--~ else 
			--~ self.lastCalculatedCellSource.x = pcx
			--~ self.lastCalculatedCellSource.y = pcy
		--~ end

		-- profile.start("calculateVisibility")

		local v = {}
		
		local sx,sy = -the.view.translate.x, -the.view.translate.y
		
		local c0x, c0y = self:px2cell(sx,sy)
		local c1x, c1y = self:px2cell(sx + the.app.width, sy + the.app.height)
		local cell = self.cell
		
		if 
			c0x > -math.huge and c0x < math.huge
		then
			for cx = c0x, c1x do
			for cy = c0y, c1y do
				if cx == c0x or cx == c1x or cy == c0y or cy == c1y then
					--~ print("line from", pcx,pcy,"to",cx,cy)
					local free = true
					local cellsUntilDarkMax = 4
					local cellsUntilDark = cellsUntilDarkMax
					
					-- profile.start("los 1 step")
					
					for x,y,cellNumInLine in geometry.raster_line_it(pcx,pcy,cx,cy) do
						-- profile.start("los 1 sub step " .. cellNumInLine)
						local k = self:cellKey(x,y)
						if (v[k] or 0) <= 1 then 
							if self:isCollisionOnCell(x,y) then free = false end
							if free or cellsUntilDark > 0 then 
								if free then v[k] = 1
								elseif cellsUntilDark >= 0 then 
									v[k] = cellsUntilDark / cellsUntilDarkMax
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
					
					-- profile.stop()
				end
			end
			end
		end
		
		self.visibility = v
		
		-- profile.stop()
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
