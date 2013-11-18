-- https://github.com/dbltnk/combat-prototype/wiki/Action-Specification

local color_bow = {128,0,0}
local color_scythe = {128,128,128}
local color_staff = {255,64,0}
local color_robe = {0,0,255}
local color_hide_armor = {0,255,64}
local color_splint_mail = {128,0,255}

action_definitions = {
	-- -----------------------------------------------------------------------------------
	noskill = {
		name = "no skill",
		description = "This is no skill.",
		icon = nil,
		sound = nil,
		cast_time = 0,
		timeout = 999,
		energy = 999,
		on_the_run = true,
		cast_particle_color = color_bow,
		
		application = {
		},	
	},
	-- -----------------------------------------------------------------------------------
	bow_shot = {
		name = "Shot",
		description = "Shoot a projectile that damages one target.",
		icon = nil,
		sound = nil,
		cast_time = 0,
		timeout = 1.5,
		energy = 6,
		on_the_run =  true,
		cast_particle_color = color_bow,
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 800, speed = 700, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/bow_shot.png"},
			effects = {
				{effect_type = "damage", str = 15},
			},
		},	
	},
	-- -----------------------------------------------------------------------------------
	bow_puncture = {
		name = "Puncture",
		description = "Shoot a fast projectile that pierces several targets and makes them bleed.",
		icon = nil,
		sound = nil,
		cast_time = 1.5,
		timeout = 12,
		energy = 30,
		on_the_run =  false,
		cast_particle_color = color_bow,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 700, ae_size = 0, ae_targets = 0, piercing_number = 5,  gfx = "/assets/graphics/action_projectiles/bow_puncture.png"},
			effects = {
				{effect_type = "damage", str = 65},
				{effect_type = "damage_over_time", ticks = 4, duration = 20, str = 5},	
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	bow_snare = {
		name = "Snare",
		description = "Shoot a projectile that slows down up to two targets.",
		icon = nil,
		sound = nil,				
		cast_time = 0.5,
		timeout = 15,
		energy = 45,
		on_the_run = true,
		cast_particle_color = color_bow,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 600, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/bow_snare.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 50, piercing_number = 1, explosion_color = color_bow},
					effects = {
						{effect_type = "damage_only_others", str = 15},
						{effect_type = "snare_only_others", duration = 15, str = config.walkspeed / 2},	
					},
				}},	
			},
		},			
	},		
	-- -----------------------------------------------------------------------------------
	bow_mark_target = {
		name = "Mark Target",
		description = "Shoot a projectile that hightlights one target and exposes it so it receives more damage.",
		icon = nil,
		sound = nil,				
		cast_time = .5,
		timeout = 9,
		energy = 12,
		on_the_run = false,
		cast_particle_color = color_bow,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 600, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/bow_mark_target.png"},
			effects = {
				{effect_type = "damage", str = 45},						
				{effect_type = "dmgModifier", str = 125, duration = 30},
				{effect_type = "mark", duration = 30},
			},
		},		
	},	
	-- -----------------------------------------------------------------------------------
	bow_root = {
		name = "Root",
		description = "Roots a small number of targets in front of you.",
		icon = nil,
		sound = nil,				
		cast_time = 0.5,
		timeout = 15,
		energy = 10,
		on_the_run = true,
		cast_particle_color = color_bow,		
		
		application = {
			target_selection = {target_selection_type = "cone", 
				gfx_radius = 200, gfx = "assets/graphics/melee_radians/90_400.png",
				range = 200, cone = 90, piercing_number = 3, explosion_color = color_bow},
			effects = {
				{effect_type = "root_only_others", duration = 5},
			},
		},
		
		
	},	
	-- -----------------------------------------------------------------------------------
	bow_blunt_arrow = {
		name = "Blunt Arrow",
		description = "Shoot a projectile that pushes one target away from you.",
		icon = nil,
		sound = nil,				
		cast_time = 1.5,
		timeout = 6,
		energy = 36,
		on_the_run = true,
		cast_particle_color = color_bow,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 300, speed = 400, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/bow_blunt_arrow.png"},
			effects = {
				{effect_type = "moveAwayFromMe", str = 200},
				{effect_type = "damage", str = 45},
			},
		},
	},		
	-- -----------------------------------------------------------------------------------
	scythe_sweep = {
		name = "Sweep",
		description = "Sweeping blow that hits several targets in front of you.",
		icon = nil,
		sound = nil,
		cast_time = 0,
		timeout = 1.5,
		energy = 5,
		on_the_run =  true,
		cast_particle_color = color_scythe,			
		
		application = {
			target_selection = {target_selection_type = "cone", 
				gfx_radius = 100, gfx = "assets/graphics/melee_radians/90_200.png",
				range = 100, cone = 90, piercing_number = 6},
			effects = {
				{effect_type = "damageOnlyOthers", str = 12},
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	scythe_pirouette = {
		name = "Pirouette",
		description = "Sweeping blow that hits a lot of targets all around you.",
		icon = nil,
		sound = nil,
		cast_time = 1,
		timeout = 5,
		energy = 30,
		on_the_run =  true,
		cast_particle_color = color_scythe,			
		
		application = {
			target_selection = {target_selection_type = "ae", 
				range = 100, piercing_number = 12},
			effects = {
				{effect_type = "damageOnlyOthers", str = 50},
				{effect_type = "moveAwayFromMe", str = 20},				
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	scythe_jump = {
		name = "Jump",
		description = "Jump to your target location.",
		icon = nil,
		sound = nil,
		cast_time = 1.5,
		timeout = 12,
		energy = 40,
		on_the_run = true,
		cast_particle_color = color_scythe,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 300, speed = 1200, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/scythe_jump.png"},
			effects = {
				{effect_type = "moveSelfTo"},	
			},
		},	

	},	
	-- -----------------------------------------------------------------------------------
	scythe_harpoon = {
		name = "Harpoon",
		description = "Shoots a projectile that pulls one target to your location.",
		icon = nil,
		sound = nil,				
		cast_time = 1.5,
		timeout = 9,
		energy = 50,
		on_the_run = true,
		cast_particle_color = color_scythe,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 400, speed = 600, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/scythe_harpoon.png"},
			effects = {
				{effect_type = "damage", str = 25},
				{effect_type = "stun", duration = 0.2},
				{effect_type = "runspeed", duration = 6, str = config.walkspeed / 2},						
				{effect_type = "moveToMe"},	
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------	
	scythe_stun = {
		name = "Stun",
		description = "Stun one target in front of you.",
		icon = nil,
		sound = nil,
		cast_time = 0.1,
		timeout = 12,
		energy = 24,
		on_the_run =  true,
		cast_particle_color = color_scythe,			
		
		application = {
			target_selection = {target_selection_type = "cone", 
				gfx_radius = 100, gfx = "assets/graphics/melee_radians/90_200.png",
				range = 100, cone = 90, piercing_number = 3},
			effects = {
				{effect_type = "damageOnlyOthers", str = 15},
				{effect_type = "stunOnlyOthers", duration = 2},
			},
		},	
	},	
-- -----------------------------------------------------------------------------------
	scythe_gank = {
		name = "Gank",
		description = "Gank one target in front of you.",
		icon = nil,
		sound = nil,
		cast_time = 4,
		timeout = 0,
		energy = 0,
		on_the_run = false,
		cast_particle_color = color_scythe,		
		
		application = {
			target_selection = {target_selection_type = "cone", 
				gfx_radius = 100, gfx = "assets/graphics/melee_radians/120_200.png",
				range = 100, cone = 120, piercing_number = 3},
			effects = {
				{effect_type = "gank"},
			},
		},		
	},		
-- -----------------------------------------------------------------------------------
	staff_magic_bolt = {
		name = "Magic Bolt",
		description = "Shoot a small projectile that explodes on impact and damages a few targets in a small area.",
		icon = nil,
		sound = nil,
		cast_time = 0,
		timeout = 1.5,
		energy = 4,
		on_the_run = true,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 300, speed = 500, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_magic_bolt.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 75, piercing_number = 3, explosion_color = color_staff},
					effects = {
						{effect_type = "damage", str = 10},
					},
				}},	
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	staff_poison = {
		name = "Poison",
		description = "Shoot a projectile that slowly decreases one targets life.",
		icon = nil,
		sound = nil,				
		cast_time = 1,
		timeout = 5,
		energy = 30,
		on_the_run = true,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 300, speed = 500, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_poison.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 50, piercing_number = 1, explosion_color = color_staff},
					effects = {
						{effect_type = "damage_over_time", ticks = 3, duration = 15, str = 20}
					},
				}},	
			},
		},	
	},	
-- -----------------------------------------------------------------------------------	
	staff_life_leech = {
		name = "Life Leech",
		description = "Shoot a projectile that drains one targets life while healing you.",
		icon = nil,
		sound = nil,
		cast_time = 0.5,
		timeout = 9,
		energy = 36,
		on_the_run =  true,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 300, speed = 500, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_life_leech.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 50, piercing_number = 6, explosion_color = color_staff},
					effects = {
						{effect_type = "transfer", eff = 1, ticks = 6, duration = 30, str = 10}
					},
				}},	
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	staff_fireball = {
		name = "Fireball",
		description = "Shoot a projectile that explodes on impact and damages a lot of targets in the area.",
		icon = nil,
		sound = nil,
		cast_time = 1.5,
		timeout = 9,
		energy = 40,
		on_the_run =  false,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 400, speed = 400, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_fireball.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 150, piercing_number = 20, explosion_color = color_staff},
					effects = {
						{effect_type = "damage", str = 75, },
					},
				}},
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	staff_healing_orb = {
		name = "Healing Orb",
		description = "Shoot a projectile that heals one target.",
		icon = nil,
		sound = nil,				
		cast_time = .5,
		timeout = 6,
		energy = 20,
		on_the_run = false,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 700, speed = 600, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_healing_orb.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 75, piercing_number = 1, explosion_color = color_staff},
					effects = {
						{effect_type = "heal", str = 50, },
					},
				}},
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	staff_healing_breeze = {
		name = "Healing Breeze",
		description = "Shoot a projectile that heals one target slowly over time.",
		icon = nil,
		sound = nil,				
		cast_time = .5,
		timeout = 10,
		energy = 50,
		on_the_run = false,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 700, speed = 600, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_healing_breeze.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 75, piercing_number = 3, explosion_color = color_staff},
					effects = {
						{effect_type = "heal_over_time", ticks = 6, duration = 30, str = 25},
					},
				}},
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	staff_mezz = {
		name = "Mezz",
		description = "Shoot a projectile that mesmerizes one target for some time. Breaks on damage.",
		icon = nil,
		sound = nil,				
		cast_time = .1,
		timeout = 20,
		energy = 40,
		on_the_run = true,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 400, speed = 600, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_mezz.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 50, piercing_number = 1, explosion_color = color_staff},
					effects = {
						{effect_type = "mezz", duration = 7},
					},
				}},
			},
		},	
	},		
	
	-- -----------------------------------------------------------------------------------
		staff_wall = {
		name = "Wall",
		description = "Creates a wall at the target location.",
		icon = nil,
		sound = nil,
		cast_time = 1,
		timeout = 12,
		energy = 20,
		on_the_run = true,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 500, speed = 1200, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/scythe_jump.png"},
			effects = {
				{effect_type = "createWallAt"},	
			},
		},	

	},	
	-- -----------------------------------------------------------------------------------	
	robe_bandage = {
		name = "Bandage",
		description = "Heal yourself instantly.",
		icon = nil,
		sound = nil,
		cast_time = 2,
		timeout = 5,
		energy = 30,
		on_the_run =  false,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "heal", str = 60},
			},
		},
	},
	-- -----------------------------------------------------------------------------------
	robe_shrink = {
		name = "Shrink",
		description = "Decrease your body size for some time but makes you take more damage.",
		icon = nil,
		sound = nil,				
		cast_time = .1,
		timeout = 30,
		energy = 30,
		on_the_run = true,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "changeSize", str = 66, duration = 15},
				{effect_type = "dmgModifier", str = 125, duration = 15},
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	robe_sonic_boom = {
		name = "Sonic Boom",
		description = "Stuns a lot of targets in the area around you for a brief time.",
		icon =  nil,
		sound = nil,				
		cast_time = 0.1,
		timeout = 12,
		energy = 20,
		on_the_run = true,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "ae", range = 150, piercing_number = 20, explosion_color = color_robe},
				effects = {
					{effect_type = "stunOnlyOthers", duration = 1 },
				},
		},		
	},		
	-- -----------------------------------------------------------------------------------
	robe_fade = {
		name = "Fade",
		description = "Renders you invisible and invulnerable for a very short time.",
		icon = nil,
		sound = nil,				
		cast_time = .1,
		timeout = 30,
		energy = 30,
		on_the_run = true,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "invul", duration = 3},			
				{effect_type = "sneak", duration = 3, speedPenalty = 0.5},
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	robe_quake = {
		name = "Quake",
		description = "Damages a lot of targets in the area around you.",
		icon = nil,
		sound = nil,				
		cast_time = 3,
		timeout = 15,
		energy = 70,
		on_the_run = false,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "ae", range = 100, piercing_number = 20, explosion_color = color_robe},
				effects = {
					{effect_type = "damageOnlyOthers", str = 90, },
				},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	robe_gust = {
		name = "Gust",
		description = "Push away a lot of targets in the area around you.",
		icon = nil,
		sound = nil,				
		cast_time = .1,
		timeout = 15,
		energy = 60,
		on_the_run = false,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "ae", range = 200, piercing_number = 20, explosion_color = color_robe},
				effects = {
					{effect_type = "moveAwayFromMe", str = 200},
					{effect_type = "damageOnlyOthers", str = 15},
				},
		},	
	},		
	-- -----------------------------------------------------------------------------------	
	hide_armor_sprint = {
		name = "Sprint",
		description = "Increases your movement speed for a short time.",
		icon = nil,
		sound = nil,
		cast_time = 0.1,
		timeout = 30,
		energy = 50,
		on_the_run =  true,
		cast_particle_color = color_hide_armor,			
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "runspeed", str = config.runspeed, duration = 5},
			},
		},	
	},
	-- -----------------------------------------------------------------------------------
	hide_armor_sneak = {
		name = "Sneak",
		description = "Renders you invisible for a short time even when moving.",
		icon = nil,
		sound = nil,
		cast_time = 0.1,
		timeout = 60,
		energy = 100,
		on_the_run =  true,
		cast_particle_color = color_hide_armor,				
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "sneak", duration = 30, speedPenalty = 0.75},
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	hide_armor_freedom = {
		name = "Freedom",
		description = "Break all root and snare effects.",
		icon = nil,
		sound = nil,				
		cast_time = 0.1,
		timeout = 6,
		energy = 25,
		on_the_run = true,
		cast_particle_color = color_hide_armor,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "root_break"},
				{effect_type = "snare_break"},
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	hide_armor_mend_wounds = {
		name = "Mend Wounds",
		description = "Break all damage-over-time effects.",
		icon = nil,
		sound = nil,				
		cast_time = 0.1,
		timeout = 6,
		energy = 25,
		on_the_run = true,
		cast_particle_color = color_hide_armor,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "stop_dots"},
				{effect_type = "heal", str = 20},
			},
		},		
	},		
	-- -----------------------------------------------------------------------------------
	hide_armor_regenerate = {
		name = "Regenerate",
		description = "Decreases your pain slowly over time.",
		icon = nil,
		sound = nil,				
		cast_time = 2,
		timeout = 15,
		energy = 35,
		on_the_run = false,
		cast_particle_color = color_hide_armor,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "heal_over_time", ticks = 3, duration = 15, str = 15},
			},
		},		
	},		
	-- -----------------------------------------------------------------------------------
	hide_armor_second_wind = {
		name = "Second Wind",
		description = "Instantly decreases your fatigue a little.",
		icon = nil,
		sound = nil,				
		cast_time = 1.5,
		timeout = 60,
		energy = 0,
		on_the_run = false,
		cast_particle_color = color_hide_armor,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "stamHeal", str = 100},
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	splint_mail_absorb = {
		name = "Absorb",
		description = "Drains the health of a lot of targets around you.",
		icon = nil,
		sound = nil,				
		cast_time = 2,
		timeout = 20,
		energy = 50,
		on_the_run = false,
		cast_particle_color = color_splint_mail,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 150, piercing_number = 20, explosion_color = color_splint_mail},
					effects = {
						{effect_type = "transfer", eff = 1, ticks = 1, duration = .1, str = 100}
					},
				}},
			},	
		},				
	},		
	-- -----------------------------------------------------------------------------------
	splint_mail_ignore_pain = {
		name = "Ignore Pain",
		description = "Increases your pain resistance for some time.",
		icon = nil,
		sound = nil,				
		cast_time = 0.1,
		timeout = 60,
		energy = 15,
		on_the_run = false,
		cast_particle_color = color_splint_mail,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "buff_max_pain", str = 150, duration = 30},
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	splint_mail_clarity = {
		name = "Clarity",
		description = "Break all stun, mezz and powerblock effects in a large area around you.",
		icon = nil,
		sound = nil,				
		cast_time = 0.1,
		timeout = 6,
		energy = 25,
		on_the_run = true,
		cast_particle_color = color_splint_mail,		
		
		application = {
			target_selection = {target_selection_type = "ae", range = 400, piercing_number = 20, explosion_color = color_splint_mail},
				effects = {
					{effect_type = "clarity"},
					{effect_type = "heal_only_others", str = 20}
				},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	splint_mail_grow = {
		name = "Grow",
		description = "Increase your body size for some time and decreases the damage you take.",
		icon = nil,
		sound = nil,				
		cast_time = .1,
		timeout = 60,
		energy = 20,
		on_the_run = true,
		cast_particle_color = color_splint_mail,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "changeSize", str = 200, duration = 30},
				{effect_type = "dmgModifier", str = 75, duration = 30},
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	splint_mail_shout = {
		name = "Shout",
		description = "Makes a lot of targets in the area around you unable to use actions for a brief time.",
		icon = nil,
		sound = nil,				
		cast_time = .1,
		timeout = 15,
		energy = 30,
		on_the_run = true,
		cast_particle_color = color_splint_mail,		
		
		application = {
			target_selection = {target_selection_type = "ae", range = 150, piercing_number = 20, explosion_color = color_splint_mail},
				effects = {
					{effect_type = "powerblockOnlyOthers", duration = 3},
					{effect_type = "damageOnlyOthers", str = 15},
				},
		},		
	},
	-- -----------------------------------------------------------------------------------
	splint_mail_invulnerability = {
		name = "Invulnerability",
		description = "Renders you invulnerable to damage for a short amount of time.",
		icon = nil,
		sound = nil,				
		cast_time = .1,
		timeout = 30,
		energy = 40,
		on_the_run = true,
		cast_particle_color = color_splint_mail,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "invul", duration = 5},
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------		
		splint_mail_bulwark = {
		name = "Bulwark",
		description = "Creates a bulwark at your location.",
		icon = nil,
		sound = nil,
		cast_time = 0.1,
		timeout = 30,
		energy = 30,
		on_the_run = false,
		cast_particle_color = color_splint_mail,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "createBollwerkAt", radius = 50},
			},
		},	

	},
	-- -----------------------------------------------------------------------------------

}

-- fill up asset names with identifiers
for k,v in pairs(action_definitions) do
	if not v.icon then v.icon = "/assets/graphics/action_icons/" .. k ..".png" end
	if not v.sound then v.sound = "/assets/audio/sfx/" .. k .. ".wav" end
	if not love.filesystem.exists(v.sound) then v.sound = "/assets/audio/sfx/missing.wav" end
	if not v.key then v.key = k end
end		

return action_definitions
