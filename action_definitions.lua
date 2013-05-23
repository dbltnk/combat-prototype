-- https://github.com/dbltnk/combat-prototype/wiki/Action-Specification

local color_bow = {128,0,0}
local color_scythe = {128,128,128}
local color_staff = {255,64,0}
local color_robe = {0,0,255}
local color_hide_armor = {0,255,64}
local color_splint_mail = {255,255,0}

action_definitions = {
	-- -----------------------------------------------------------------------------------
	bow_shot = {
		name = "Shot",
		description = "Shoot a projectile that damages one target.",
		icon = nil,
		sound = nil,
		cast_time = .5,
		timeout = 1,
		energy = 10,
		on_the_run =  false,
		cast_particle_color = color_bow,
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 800, speed = 400, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/bow_shot.png"},
			effects = {
				{effect_type = "damage", str = 25},
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
			target_selection = {target_selection_type = "projectile", range = 600, speed = 600, ae_size = 0, ae_targets = 0, piercing_number = 5,  gfx = "/assets/graphics/action_projectiles/bow_puncture.png"},
			effects = {
				{effect_type = "damage", str = 65},
				{effect_type = "damage_over_time", ticks = 4, duration = 20, str = 5},	
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	--~ bow_snare = {
		--~ name = "Snare",
		--~ description = "Shoot a projectile that slows down one target.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------
	bow_expose = {
		name = "Expose",
		description = "Shoot a projectile that exposes a target so it receives more damage.",
		icon = nil,
		sound = nil,				
		cast_time = 1,
		timeout = 9,
		energy = 12,
		on_the_run = false,
		cast_particle_color = color_bow,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 600, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/bow_expose.png"},
			effects = {
				{effect_type = "expose", duration = 30},
			},
		},		
	},	
	-- -----------------------------------------------------------------------------------
	bow_root = {
		name = "Root",
		description = "Shoot a projectile that roots one target.",
		icon = nil,
		sound = nil,				
		cast_time = 0.5,
		timeout = 15,
		energy = 10,
		on_the_run = false,
		cast_particle_color = color_bow,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 400, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/bow_root.png"},
			effects = {
				{effect_type = "root", duration = 5},
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	--~ bow_mark_target = {
		--~ name = "Mark Target",
		--~ description = "Shoot a projectile that hightlights one target.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------
	scythe_sweep = {
		name = "Sweep",
		description = "Sweeping blow that hits several targets in front of you.",
		icon = nil,
		sound = nil,
		cast_time = .75,
		timeout = 3,
		energy = 30,
		on_the_run =  true,
		cast_particle_color = color_scythe,			
		
		application = {
			target_selection = {target_selection_type = "ae", range = 100, cone = 180, piercing_number = 6},
			effects = {
				{effect_type = "damageOnlyOthers", str = 62},
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
		timeout = 15,
		energy = 20,
		on_the_run =  true,
		cast_particle_color = color_scythe,			
		
		application = {
			target_selection = {target_selection_type = "ae", range = 100, cone = 360, piercing_number = 12},
			effects = {
				{effect_type = "damageOnlyOthers", str = 21},
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
		on_the_run = false,
		cast_particle_color = color_scythe,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 1200, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/scythe_jump.png"},
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
		cast_time = 1,
		timeout = 9,
		energy = 50,
		on_the_run = false,
		cast_particle_color = color_scythe,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 400, speed = 600, ae_size = 0, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/scythe_harpoon.png"},
			effects = {
				{effect_type = "moveToMe"},	
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------	
	scythe_stun = {
		name = "Stun",
		description = "Stun one target in close to you.",
		icon = nil,
		sound = nil,
		cast_time = 0.1,
		timeout = 9,
		energy = 12,
		on_the_run =  true,
		cast_particle_color = color_scythe,			
		
		application = {
			target_selection = {target_selection_type = "ae", range = 100, cone = 60, piercing_number = 3},
			effects = {
				{effect_type = "damageOnlyOthers", str = 50},
				{effect_type = "stunOnlyOthers", duration = 3},
			},
		},	
	},	
-- -----------------------------------------------------------------------------------
	scythe_gank = {
		name = "Gank",
		description = "Gank one target close to you.",
		icon = nil,
		sound = nil,
		cast_time = 5,
		timeout = 0,
		energy = 50,
		on_the_run = false,
		cast_particle_color = color_scythe,			
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 100, speed = 100, ae_size = 50, ae_targets = 0, piercing_number = 1,  gfx = "/assets/graphics/action_projectiles/scythe_gank.png"},
			effects = {
				{effect_type = "gank"},
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
		timeout = 6,
		energy = 36,
		on_the_run =  false,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 300, speed = 300, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_life_leech.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 50, piercing_number = 2, explosion_color = {0, 255 ,0, 128}},
					effects = {
						{effect_type = "transfer", eff = 0.5, ticks = 6, duration = 30, str = 10}
					},
				}},	
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	--~ staff_poison = {
		--~ name = "Poison",
		--~ description = "Shoot a projectile that slowly decreases one targets life.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },	
	-- -----------------------------------------------------------------------------------
	staff_fireball = {
		name = "Fireball",
		description = "Shoot a projectile that explodes on impact and damages a lot of targets in the area.",
		icon = nil,
		sound = nil,
		cast_time = 3,
		timeout = 9,
		energy = 60,
		on_the_run =  false,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 400, speed = 200, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_fireball.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 150, piercing_number = 20, explosion_color = {255, 57, 17, 128}},
					effects = {
						{effect_type = "damage", str = 38, },
					},
				}},
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	staff_heal_other = {
		name = "Heal Other",
		description = "Shoot a projectile that heals one target.",
		icon = nil,
		sound = nil,				
		cast_time = 1.5,
		timeout = 3,
		energy = 20,
		on_the_run = false,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 400, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_heal_other.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 50, piercing_number = 1, explosion_color = color_staff},
					effects = {
						{effect_type = "healOnlyOthers", str = 50, },
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
		cast_time = 2,
		timeout = 9,
		energy = 50,
		on_the_run = false,
		cast_particle_color = color_staff,		
		
		application = {
			target_selection = {target_selection_type = "projectile", range = 600, speed = 400, piercing_number = 1, gfx = "/assets/graphics/action_projectiles/staff_healing_breeze.png"},
			effects = {
				{effect_type = "spawn", application = {
					target_selection = {target_selection_type = "ae", range = 50, piercing_number = 1, explosion_color = color_staff},
					effects = {
						{effect_type = "heal_over_time", ticks = 12, duration = 60, str = 20},
					},
				}},
			},
		},
	},	
	-- -----------------------------------------------------------------------------------
	--~ staff_mezz = {
		--~ name = "Mezz",
		--~ description = "Shoot a projectile that mesmerizes one target for some time.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------	
	robe_bandage = {
		name = "Bandage",
		description = "Heal yourself instantly.",
		icon = nil,
		sound = nil,
		cast_time = 2,
		timeout = 5,
		energy = 20,
		on_the_run =  false,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "heal", str = 100},
			},
		},
	},
	-- -----------------------------------------------------------------------------------
	--~ robe_shrink = {
		--~ name = "Shrink",
		--~ description = "Decrease your body size for some time.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------
	robe_sonic_boom = {
		name = "Sonic Boom",
		description = "Stuns a lot of targets in the area around you for a brief time.",
		icon =  nil,
		sound = nil,				
		cast_time = 0.1,
		timeout = 6,
		energy = 20,
		on_the_run = true,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "ae", range = 300, piercing_number = 20, explosion_color = color_robe},
				effects = {
					{effect_type = "stunOnlyOthers", duration = 1 },
				},
		},		
	},		
	-- -----------------------------------------------------------------------------------
	robe_hide = {
		name = "Hide",
		description = "Renders you invisible if you stand still.",
		icon = nil,
		sound = nil,				
		cast_time = 3,
		timeout = 60,
		energy = 30,
		on_the_run = false,
		cast_particle_color = color_robe,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "hide"},
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	robe_quake = {
		name = "Quake",
		description = "Damages a lot of targets in the area around you.",
		icon = nil,
		sound = nil,				
		cast_time = 4,
		timeout = 15,
		energy = 90,
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
	--~ robe_gust = {
		--~ name = "Gust",
		--~ description = "Push away a lot of targets in the area around you.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
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
				{effect_type = "sneak", duration = 30, speedPenalty = 0.5},
			},
		},	
	},	
	-- -----------------------------------------------------------------------------------
	hide_armor_root_break = {
		name = "Root Break",
		description = "Break all root effects.",
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
			},
		},	
	},		
	-- -----------------------------------------------------------------------------------
	--~ hide_armor_snare_break = {
		--~ name = "Snare Break",
		--~ description = "Break all snare effects.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------
	hide_armor_regenerate = {
		name = "Regenerate",
		description = "Decreases your pain slowly over time.",
		icon = nil,
		sound = nil,				
		cast_time = 2,
		timeout = 12,
		energy = 25,
		on_the_run = false,
		cast_particle_color = color_hide_armor,		
		
		application = {
			target_selection = {target_selection_type = "self"},
			effects = {
				{effect_type = "heal_over_time", ticks = 12, duration = 60, str = 10},
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
	--~ splint_mail_absorb = {
		--~ name = "Absorb",
		--~ description = "Aborbs incoming damage for some time.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------
	--~ splint_mail_ignore_pain = {
		--~ name = "Ignore Pain",
		--~ description = "Increases your pain resistance for some time.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------
	--~ splint_mail_mezz_break = {
		--~ name = "Mezz Break",
		--~ description = "Break all mezz effects.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },		
	-- -----------------------------------------------------------------------------------
	--~ splint_mail_grow = {
		--~ name = "Grow",
		--~ description = "Increase your body size for some time.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },	
	-- -----------------------------------------------------------------------------------
	--~ splint_mail_rage = {
		--~ name = "Rage",
		--~ description = "Increase your melee damage for some time.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },
	-- -----------------------------------------------------------------------------------
	--~ splint_mail_invulnerability = {
		--~ name = "Invulnerability",
		--~ description = "Renders you invulnerable to damage for a short amount of time.",
		--~ icon = "/assets/graphics/action_icons/.png",
		--~ sound = "/assets/audio/sfx/.wav",				
		--~ cast_time = 0,
		--~ timeout = 0,
		--~ energy = 0,
		--~ on_the_run = false,
		--~ cast_particle_color = color_,		
		--~ 
		--~ application = {
		--~ },	
	--~ },			
}

-- fill up asset names with identifiers
for k,v in pairs(action_definitions) do
	if not v.icon then v.icon = "/assets/graphics/action_icons/" .. k ..".png" end
	if not v.sound then v.sound = "/assets/audio/sfx/" .. k .. ".wav" end
	if not love.filesystem.exists(v.sound) then v.sound = "/assets/audio/sfx/missing.wav" end
end		

return action_definitions
