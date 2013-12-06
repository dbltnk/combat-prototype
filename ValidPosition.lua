-- ValidPosition

ValidPosition = Tile:extend
{
	class = "ValidPosition",

	props = {"x", "y"},
	
	width = 0,
	height = 0,
	
	onNew = function (self)
		self:mixin(GameObject)
		the.app.view.layers.ground:add(self)		
		drawDebugWrapper(self)
		the.validPositions[self] = true
	end,
	
	onUpdateLocal = function (self)
	
	end,

	onUpdateBoth = function (self, elapsed)
	
	end,
	
	onDieBoth = function (self)
		the.validPositions[self] = nil
		the.app.view.layers.ground:remove(self)		
	end,
}
