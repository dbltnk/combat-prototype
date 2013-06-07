-- PhaseManager

PhaseManager = Sprite:extend
{
	class = "PhaseManager",

	props = {"x", "y", "width", "height"},
	
	width = 1,
	height = 1,
	
	onNew = function (self)
		self.x = -1000
		self.y = -1000
		self.visible = false
		self:mixin(GameObject)
		the.phaseManager = self
	end,
	
	onUpdateLocal = function (self)
	end,

	onUpdateBoth = function (self, elapsed)
	end,
	
	onDieBoth = function (self)
	end,
}
