-- Ghost

Ghost = Sprite:extend
{
	class = "Ghost",
	skills = {},
	x = 0,
	y = 0,
	width = 0,
	height = 0,
	speed = 1000,
	
	maxPain = 1,
	maxPainOverdrive = 1,
	currentPain = 1,
	maxEnergy = 1,
	currentEnergy = 1,
	xp = 0,
	xpCap = 0,
	level = 0,
	levelCap = 0,
	
	onNew = function (self)
		--~ print(debug.traceback())
	end,

	jumpToPlayer = function (self, number)
		print("jump to character", number)
		local index = 0
		object_manager.visit(function(oid,o)
			if o.class == "Character" then
				index = index + 1
				if index == number then
					self.x = o.x + localconfig.screenWidth / 2
					self.y = o.y + localconfig.screenHeight / 2
				end
			end
		end)
	end,
	
	onUpdate = function (self, elapsed)
		local movex, movey = 0,0
	
		if not the.ignorePlayerCharacterInputs then
			if the.keys:pressed('left', 'a') then movex = -1 end
			if the.keys:pressed('right', 'd') then movex = 1 end
			if the.keys:pressed('up', 'w') then movey = -1 end
			if the.keys:pressed('down', 's') then movey = 1 end
		end
		
		self.x = self.x + movex * self.speed * elapsed
		self.y = self.y + movey * self.speed * elapsed

		if not the.ignorePlayerCharacterInputs then
			for i=1,9 do 
				if the.keys:justPressed ("" .. i) then self:jumpToPlayer(i) end
			end
			if the.keys:justPressed ("0") then self:jumpToPlayer(10) end
		end
	end,
}
