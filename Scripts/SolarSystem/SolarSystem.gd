extends Node2D

var sd = null
var random_seed = null
var difficulty = null
var planets = []
var sun

func _init(w_name: String, w_seed: int, w_random_seed: bool, w_difficulty: String):
	name = w_name
	sd = w_seed
	random_seed = w_random_seed
	difficulty = w_difficulty
	planets = []
	
	var rng = RandomNumberGenerator.new()
	if random_seed:
		rng.randomize()
		sd = rng.seed
	else:
		rng.seed = sd
	
	var gen_data = Global.load_json("res://Scripts/SolarSystem/generationData.json")
	
	# Generate sun node
	sun = load("res://Objects/Sun/Sun.tscn").instance()
	sun.sd = rng.randi()
	
	# --- Generate planets --- #
	
	# Randomise the amount of planets within the min and max of the difficulty
	var planet_amount = Global.randi_range_array(rng, gen_data["p_amount_range"][difficulty])

	# Balance type selection probability based on weight
	var planet_types = []
	for type in gen_data["p_types"].keys():
		for _i in range(gen_data["p_types"][type]["weight"]):
			planet_types.append(type)
	
	# Used names will be recorded here so that they aren't used again
	var used_planet_names = []
	var planet = load("res://Objects/Planet/Planet.tscn")
	
	for _i in range(planet_amount):
		var new_planet = planet.instance()
		
		# Set type
		
		# Reset type list if all planet types have been used
		if planet_types == []:
			
			for type in gen_data["p_types"].keys():
				for __i in range(gen_data["p_types"][type]["weight"]):
					planet_types.append(type)
		
		# Set random planet type
		new_planet.type = Global.random_item(rng, planet_types)
		
		# Entirely remove that type from the list
		while new_planet.type in planet_types:
			planet_types.erase(new_planet.type)
		
		# Set name
		var names = gen_data["p_names"] + gen_data["p_types"][new_planet.type]["names"]
		
		for name in used_planet_names:
			names.erase(name)
			
		if len(names) == 0:
			push_error("Not enough planet names, reusing")
			names = gen_data["p_names"] + gen_data["p_types"][new_planet.type]["names"]
		
		new_planet.name = Global.random_item(rng, names)
		used_planet_names.append(new_planet.name)
		new_planet.name = tr(new_planet.name)
		
		# Set resources
		var resources = gen_data["p_types"][new_planet.type]["resources"].keys()
		var resource_amount = Global.randi_range_array(rng, gen_data["resource_amount_range"][difficulty])
		for __i in range(resource_amount):
			
			# Get generic resources if the type's own resources have all been used
			if len(resources) == 0:
				for resource in gen_data["resources"].keys():
					if not resource in new_planet.resources:
						resources.append(resource)
			
			var new_resource = Global.random_item(rng, resources)
			new_planet.resources.append(new_resource)
			resources.erase(new_resource)
		
		var prev_orbit_distance = 50
		if planets != []:
			prev_orbit_distance = planets[len(planets) - 1].orbit_distance
			
		new_planet.orbit_distance = prev_orbit_distance + rng.randi_range(50, 90)
	
		# Set sprite
		new_planet.sprite = Global.random_item(rng, gen_data["p_types"][new_planet.type]["sprites"])
		
		# Set seed
		new_planet.sd = rng.randi()
		
		planets.append(new_planet)
