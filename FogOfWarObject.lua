-- FogOfWarObject

-- mixin
-- one need to call updateFogAlpha manually
FogOfWarObject = {
	--~ alphaWithoutFog,
	
	updateFogAlpha = function (self)
		local fogAlpha = 1
		
		--~ if the.player and the.player.class ~= "Ghost" then
			--~ local p = the.player
			--~ local cx,cy = p.x+p.width/2, p.y+p.height/2
			--~ local dist = vector.lenFromTo(self.x, self.y, cx, cy)
			--~ fogAlpha = utils.mapIntoRange(dist, config.sightDistanceNear, config.sightDistanceFar, 1, 0)
		--~ end
		
		if the.lineOfSight and the.lineOfSight:isObjectVisible(self) == false then
			fogAlpha = 0
		end

		self.alpha = fogAlpha * (self.alphaWithoutFog or 1)
	end,
	
	onMixin = function (self)
		self.alphaWithoutFog = 1
	end,
}
