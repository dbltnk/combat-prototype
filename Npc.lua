-- Npc

Npc = Character:extend
{
	skills = {
		"bow_shot",
		"xbow_piercing_shot",	
		--"scythe_attack",
		--"scythe_pirouette",			
		--"shield_bash",		
		"sprint",		
		"bandage",
		"fireball",
		"life_leech",
	},
	
	activeSkillNr = 1,
	
	width = 64,
	height = 64,
	image = '/assets/graphics/npc.png', -- source: http://www.synapsegaming.com/forums/t/1711.aspx
	
	readInput = function (self, activeSkillNr)
		-- 0 slowest -> 1 fastest
		local speed = 0
		-- [-1,1], [-1,1]
		local movex, movey = 0,0
		-- has an arbitrary length
		local viewx, viewy = 0,0
		
		local shootSkillNr = activeSkillNr
		local doShoot = false	
		
		-- TODO
		doShoot = true
		viewx = 100
		viewy = 100

		return { speed = speed, 
			movex = movex, movey = movey, 
			viewx = viewx, viewy = viewy, 
			doShoot = doShoot, shootSkillNr = shootSkillNr, }
	end,
}

