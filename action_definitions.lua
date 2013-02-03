-- https://github.com/dbltnk/combat-prototype/wiki/Action-Specification

action_definitions = {
	-- -----------------------------------------------------------------------------------
	heal_self = {
		name = "Heal self",
		description = "Reduce your pain by STR.",
		icon = "heal_icon.png",
		timeout = 10,
		energy = 10,
		cast_time = 1,
		
		application = {
			target_selection = {target_selection_type = "self", gfx = "heal_particle.png"},
			effects = {
				{effect_type = "heal", str = 60},
			},
		},	
	},
	-- -----------------------------------------------------------------------------------
	fireball = {
		name = "Fireball",
		description = "...",
		icon = "skill_fireball.png",
		timeout = 10,
		energy = 10,
		cast_time = 1,
		
		application = {
			target_selection = {target_selection_type = "projectile", 
				range = 200, speed = 100, target_number = 1, stray = 0, ..., gfx = "fireball.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 10, 
						target_number = 2, gfx = "big_fireball_area.png"},
					effects = {
						{effect_type = "damage", str = 10, },
					},
				}},
			},
		},
	},
	
	
}
