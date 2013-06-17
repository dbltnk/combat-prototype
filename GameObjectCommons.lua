-- GameObjectCommons

-- mixin
GameObjectCommons = {
	
	onMixin = function (self)
		
	end,
	
	showDamageWithOffset = function (self, str, offset)
		str = tools.floor1(str)
		
		local color = {1,0,0}
		if str < 0 then color = {0,0,1} end
		
		ScrollingText:new{x = self.x + self.width / 2, y = self.y, text = str, tint = color, yOffset = offset}
	end,
	
}
