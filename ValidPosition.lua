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
		table.insert(the.validPositions,self)
	end,
	
	onUpdateLocal = function (self)
		if not the.validPositions[self] then the.validPositions[self] = true end
	end,

	onUpdateBoth = function (self, elapsed)

	end,
	
	onDieBoth = function (self)
		the.validPositions[self] = false
		the.app.view.layers.ground:remove(self)		
	end,
}
