-- Footstep

Footstep = Tile:extend
{
	class = "Footstep",

	props = {"x", "y", "rotation", "image", "width", "height", "alphaWithoutFog"},
	
	width = 32,
	height = 32,
	image = '/assets/graphics/footsteps.png',
	
	duration = config.footStepVisibility,

	owner = 0,
	
	dieAtTime = nil,
	
	onNew = function (self)
		self:mixin(GameObject)
		self:mixin(FogOfWarObject)
		the.app.view.layers.ground:add(self)
		self.dieAtTime = network.time + self.duration
		drawDebugWrapper(self)
		duration = math.min(config.footStepVisibility, config.footStepVisibility * config.minPlayerNumberToDecreaseFootstepsAmount / network.connected_client_count)
		--~ print(duration)
	end,
	
	onUpdateLocal = function (self)
		if network.time > self.dieAtTime then
			self:die()
		end
	end,

	onUpdateBoth = function (self, elapsed)
		self.alphaWithoutFog = utils.mapIntoRange (network.time, self.dieAtTime - self.duration, self.dieAtTime, 1, 0)		
		self:updateFogAlpha()
	end,
	
	onDieBoth = function (self)
		the.app.view.layers.ground:remove(self)
	end,
}
