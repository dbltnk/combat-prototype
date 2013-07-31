-- LineOfSight

LineOfSight = Sprite:extend
{
	class = "LineOfSight",

	x = 0,
	y = 0,
	width = 1,
	height = 1,
	cell = 100,
	
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

	getVisibility = function (self, px, py, cx, cy)
		local l = vector.lenFromTo(the.player.x, the.player.y, px, py)
		return utils.mapIntoRange (l, 100, 300, 0, 1)
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
				love.graphics.setColor(0,0,0,255*gv(self,px,py,cx,cy))
				love.graphics.rectangle("fill", px-sx,py-sy, cell,cell)
			end
			end
		end
	end,
}
