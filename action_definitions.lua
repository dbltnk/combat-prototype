-- https://github.com/dbltnk/combat-prototype/wiki/Action-Specification

action_definitions = {
	-- -----------------------------------------------------------------------------------
	bow_shot = {
		name = "Bow shot",
		description = "Hits something with the pointy end of an arrow.",
		icon = "/assets/graphics/action_icons/bow_shot_icon.png",
		cast_time = .5,
		timeout = 1,
		energy = 10,
		on_the_run =  false,
		cast_particle_color = { 127,21,0 },
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 800, speed = 400, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/bow_shot_projectile.png"},
			effects = {
				{effect_type = "damage", str = 25},
			},
		},	
	},
	-- -----------------------------------------------------------------------------------
	scythe_attack = {
		name = "Scythe attack",
		description = "Hits something with the razor sharp edge of your scythe.",
		icon = "/assets/graphics/action_icons/scythe_attack_icon.png",
		cast_time = .75,
		timeout = 3,
		energy = 30,
		on_the_run =  true,
		
		application = {
			target_selection = {target_selection_type = "ae", range = 100, cone = 180, piercing_number = 6, gfx = "/assets/graphics/action_projectiles/scythe_attack_projectile.png"},
			effects = {
				{effect_type = "damage", str = 62},
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	bandage = {
		name = "Bandage yourself",
		description = "Reduces your pain.",
		icon = "/assets/graphics/action_icons/bandage_icon.png",
		cast_time = 2,
		timeout = 5,
		energy = 20,
		on_the_run =  false,
		cast_particle_color = { 0,0,255 },		
		
		application = {
			target_selection = {target_selection_type = "self", gfx = "/assets/graphics/action_particles/bandage_particle.png"},
			effects = {
				{effect_type = "xp", str = 100},
			},
		},
	},
	-- -----------------------------------------------------------------------------------
	sprint = {
		name = "Sprint",
		description = "Increases your run speed for a time.",
		icon = "/assets/graphics/action_icons/sprint_icon.png",
		cast_time = 0.1,
		timeout = 20,
		energy = 100,
		on_the_run =  true,
		
		application = {
			target_selection = {target_selection_type = "self", gfx = "/assets/graphics/action_particles/sprint_particle.png"},
			effects = {
				{effect_type = "runspeed", str = 200, duration = 10},
			},
		},	
	},
	-- -----------------------------------------------------------------------------------
	fireball = {
		name = "Fireball",
		description = "Hurl a ball of fiery, glowing pain that explodes on impact.",
		icon = "/assets/graphics/action_icons/fireball_icon.png",
		cast_time = 3,
		timeout = 9,
		energy = 60,
		on_the_run =  false,
		cast_particle_color = { 255,57,17 },		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 400, speed = 200, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/fireball_projectile.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 150, piercing_number = 20, gfx = "/assets/graphics/action_particles/fireball_particle.png"},
					effects = {
						{effect_type = "damage", str = 38, },
					},
				}},
			},
		},
	},
	-- -----------------------------------------------------------------------------------
	shield_bash = {
		name = "Shield bash",
		description = "Daze your opponents by smashing their faces with your shield.",
		icon = "/assets/graphics/action_icons/shield_bash_icon.png",
		cast_time = 0.1,
		timeout = 10,
		energy = 12,
		on_the_run =  true,
		
		application = {
			target_selection = {target_selection_type = "ae", range = 100, cone = 60, piercing_number = 3, gfx = "/assets/graphics/action_projectiles/shield_bash_projectile.png"},
			effects = {
				{effect_type = "damage", str = 50},
				{effect_type = "stun", duration = 3},
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	life_leech = {
		name = "Life leech",
		description = "Drain your target's health to make it yours.",
		icon = "/assets/graphics/action_icons/life_leech_icon.png",
		cast_time = 1.8,
		timeout = 15,
		energy = 36,
		on_the_run =  false,
		cast_particle_color = { 0,255,0 },		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 300, speed = 300, piercing_number = 1, ae_size = 50, ae_targets = 1, gfx = "/assets/graphics/action_projectiles/life_leech_projectile.png"},
			effects = {
				{effect_type = "transfer", from = "targets", to = "self", eff = 0.5, attribute = "hp", ticks = 5, duration = 30, str = 10}
			},
		},
	},
	-- -----------------------------------------------------------------------------------
	scythe_pirouette = {
		name = "Scythe pirouettek",
		description = "Spin your scythe around you, hitting everything in your vicinity.",
		icon = "/assets/graphics/action_icons/scythe_pirouette_icon.png",
		cast_time = 1,
		timeout = 15,
		energy = 20,
		on_the_run =  true,
		
		application = {
			target_selection = {target_selection_type = "ae", range = 100, cone = 360, piercing_number = 12, gfx = "/assets/graphics/action_projectiles/scythe_pirouette_projectile.png"},
			effects = {
				{effect_type = "damage", str = 21},
			},
		},	
	},
	-- -----------------------------------------------------------------------------------
	xbow_piercing_shot = {
		name = "Piercing bolt",
		description = "Pierce through a number of targets, bleeding them all.",
		icon = "/assets/graphics/action_icons/xbow_piercing_shot_icon.png",
		cast_time = 1.5,
		timeout = 12,
		energy = 30,
		on_the_run =  false,
		cast_particle_color = { 127,21,0 },		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 600, ae_size = 0, ae_targets = 0, piercing_number = 5,  gfx = "/assets/graphics/action_projectiles/xbow_piercing_shot_projectile.png"},
			effects = {
				{effect_type = "damage", str = 65},
				{effect_type = "damage_over_time", ticks = 5, duration = 20, str = 5},	
			},
		},	
	},	
}


return action_definitions
