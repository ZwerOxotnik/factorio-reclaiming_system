if not settings.startup["recl_is_add_capsule"].value then return end


local sounds = require ("__base__.prototypes.entity.sounds")


local projectile = lazyAPI.add_prototype("projectile", "reclaim_capsule", {
	flags = {"not-on-map"},
	acceleration = 0.005,
	action =
	{
		{
			type = "direct",
			action_delivery = {
				type = "instant",
				target_effects = {
					{
						type = "script",
						effect_id = "reclaim"
					}
				}
			}
		}
	},
	light = {intensity = 0.5, size = 4},
	animation =
	{
		filename = "__base__/graphics/entity/grenade/grenade.png",
		draw_as_glow = true,
		frame_count = 15,
		line_length = 8,
		animation_speed = 0.250,
		width = 26,
		height = 28,
		shift = util.by_pixel(1, 1),
		priority = "high",
		hr_version =
		{
			filename = "__base__/graphics/entity/grenade/hr-grenade.png",
			draw_as_glow = true,
			frame_count = 15,
			line_length = 8,
			animation_speed = 0.250,
			width = 48,
			height = 54,
			shift = util.by_pixel(0.5, 0.5),
			priority = "high",
			scale = 0.5
		}
	},
	shadow =
	{
		filename = "__base__/graphics/entity/grenade/grenade-shadow.png",
		frame_count = 15,
		line_length = 8,
		animation_speed = 0.250,
		width = 26,
		height = 20,
		shift = util.by_pixel(2, 6),
		priority = "high",
		draw_as_shadow = true,
		hr_version =
		{
			filename = "__base__/graphics/entity/grenade/hr-grenade-shadow.png",
			frame_count = 15,
			line_length = 8,
			animation_speed = 0.250,
			width = 50,
			height = 40,
			shift = util.by_pixel(2, 6),
			priority = "high",
			draw_as_shadow = true,
			scale = 0.5
		}
	}
})


local capsule = lazyAPI.add_prototype("capsule", projectile.name, {
	icon = "__base__/graphics/icons/grenade.png",
	icon_size = 64, icon_mipmaps = 4,
	capsule_action =
	{
		type = "throw",
		attack_parameters =
		{
			type = "projectile",
			activation_type = "throw",
			ammo_category = "grenade",
			cooldown = 60 * 5,
			projectile_creation_distance = 0.6,
			range = 15,
			ammo_type =
			{
				category = "grenade",
				target_type = "position",
				action =
				{
					{
						type = "direct",
						action_delivery =
						{
							type = "projectile",
							projectile = projectile.name,
							starting_speed = 0.3
						}
					},
					{
						type = "direct",
						action_delivery =
						{
							type = "instant",
							target_effects =
							{
								{
									type = "play-sound",
									sound = sounds.throw_projectile
								}
							}
						}
					}
				}
			}
		}
	},
	-- radius_color = { r = 0.25, g = 0.05, b = 0.25, a = 0.25 },
	subgroup = "capsule",
	order = "a[" .. projectile.name .. "]-a[normal]",
	stack_size = 100
})

local recipe = lazyAPI.add_prototype("recipe", capsule.name, {
	enabled = true,
	energy_required = 60,
	ingredients = {
		{"iron-plate", 5},
		{"electronic-circuit", 10}
	},
	result = capsule.name
})
