extends Node2D

var sd = null
var random_seed = null
var difficulty = null
var planets: Array = []
var sun
var rng: RandomNumberGenerator
var starting_planet: Node2D

var resources = {}
var resource_cap: int

func _init(w_name: String, w_seed: int, w_random_seed: bool, w_difficulty: String, save_path = "res://saves/test.json"):
	name = w_name
	sd = w_seed
	random_seed = w_random_seed
	difficulty = w_difficulty
	planets = []
	
	var save = null
	if save_path != null:
		save = Global.load_json(save_path)
	
	rng = RandomNumberGenerator.new()
	if random_seed:
		rng.randomize()
		sd = rng.seed
	else:
		rng.seed = sd
	
	# Generate sun node
	sun = load("res://src/scenes/game/Sun/Sun.tscn").instance()
	sun.sd = rng.randi()
	
	# --- Generate planets --- #
	
	# Randomise the amount of planets within the min and max of the difficulty
	var planet_amount = Global.randi_range_array(rng, Global.generation_data["p_amount_range"][difficulty])

	# Balance type selection probability based on weight
	var planet_types = []
	for type in Global.generation_data["p_types"].keys():
		for _i in range(Global.generation_data["p_types"][type]["weight"]):
			planet_types.append(type)
	
	# Used names will be recorded here so that they aren't used again
	var used_planet_names = []
	var planet = load("res://src/scenes/game/Planet/Planet.tscn")
	
	for _i in range(planet_amount):
		var new_planet = planet.instance()
		
		# Set type
		
		# Reset type list if all planet types have been used
		if planet_types == []:
			
			for type in Global.generation_data["p_types"].keys():
				for __i in range(Global.generation_data["p_types"][type]["weight"]):
					planet_types.append(type)
		
		# Set random planet type
		new_planet.type = Global.random_item(rng, planet_types)
		
		# Entirely remove that type from the list
		while new_planet.type in planet_types:
			planet_types.erase(new_planet.type)
		
		# Set name
		var names = Global.generation_data["p_names"] + Global.generation_data["p_types"][new_planet.type]["names"]
		
		for name in used_planet_names:
			names.erase(name)
			
		if len(names) == 0:
			push_error("Not enough planet names, reusing")
			names = Global.generation_data["p_names"] + Global.generation_data["p_types"][new_planet.type]["names"]
		
		new_planet.name = Global.random_item(rng, names)
		used_planet_names.append(new_planet.name)
		new_planet.name = tr(new_planet.name)
		
		# Set resources
		var resources = Global.generation_data["p_types"][new_planet.type]["resources"].keys()
		var resource_amount = Global.randi_range_array(rng, Global.generation_data["resource_amount_range"][difficulty])
		for __i in range(resource_amount):
			
			# Get generic resources if the type's own resources have all been used
			if len(resources) == 0:
				for resource in Global.generation_data["resources"].keys():
					if not resource in new_planet.resources:
						resources.append(resource)
			
			var new_resource = Global.random_item(rng, resources)
			new_planet.resources.append(new_resource)
			resources.erase(new_resource)
		
		var prev_orbit_distance = 50
		var prev_orbit_speed = 30
		if planets != []:
			prev_orbit_distance = planets[len(planets) - 1].orbit_distance
			prev_orbit_speed = planets[len(planets) - 1].orbit_speed
		new_planet.orbit_distance = prev_orbit_distance + rng.randi_range(90, 105)
		new_planet.orbit_speed = prev_orbit_speed - rng.randi_range(2, 5)
		new_planet.orbit_starting_position = rng.randi_range(0, 359)
	
		# Set sprite
		new_planet.sprite = Global.random_item(rng, Global.generation_data["p_types"][new_planet.type]["sprites"])
		
		# Set seed
		new_planet.sd = rng.randi()
		
		planets.append(new_planet)
		
	# Set player starting planet
	starting_planet = planets[len(planets)/2 + rng.randi_range(-1, 1) - 1]
	
	# Set player resources
	for resource in Global.generation_data["resources"]:
		resources[resource] = save["resources"][resource]
#	resources = save["resources"]
	resource_cap = save["resource_cap"]
	
