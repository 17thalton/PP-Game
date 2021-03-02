extends "res://lib/PixelPlanets/Planets/Planet.gd"

func set_pixels(amount):
	$PlanetUnder.material.set_shader_param("pixels", amount)
	$Craters.material.set_shader_param("pixels", amount)
	$LavaRivers.material.set_shader_param("pixels", amount)
	
	$PlanetUnder.rect_size = Vector2(amount, amount)
	$Craters.rect_size = Vector2(amount, amount)
	$LavaRivers.rect_size = Vector2(amount, amount)
	
func set_light(pos):
	$PlanetUnder.material.set_shader_param("light_origin", pos)
	$Craters.material.set_shader_param("light_origin", pos)
	$LavaRivers.material.set_shader_param("light_origin", pos)

func set_seed(sd):
	var converted_seed = sd%1000/100.0
	$PlanetUnder.material.set_shader_param("seed", converted_seed)
	$Craters.material.set_shader_param("seed", converted_seed)
	$LavaRivers.material.set_shader_param("seed", converted_seed)

func set_rotate(r):
	$PlanetUnder.material.set_shader_param("rotation", r)
	$Craters.material.set_shader_param("rotation", r)
	$LavaRivers.material.set_shader_param("rotation", r)

func update_time(t):	
	$PlanetUnder.material.set_shader_param("time", t * get_multiplier($PlanetUnder.material) * 0.02)
	$Craters.material.set_shader_param("time", t * get_multiplier($Craters.material) * 0.02)
	$LavaRivers.material.set_shader_param("time", t * get_multiplier($LavaRivers.material) * 0.02)

func set_custom_time(t):
	$PlanetUnder.material.set_shader_param("time", t * get_multiplier($PlanetUnder.material))
	$Craters.material.set_shader_param("time", t * get_multiplier($Craters.material))
	$LavaRivers.material.set_shader_param("time", t * get_multiplier($LavaRivers.material))
