extends Node2D

var sd = null
var random_seed = null
var difficulty = null
var planets: Array = []
var sun
var starting_planet: Node2D

var developed_technology: Array = []
var undeployed_technology: Array = []

var current_planet = null

var resources = {}
var resource_cap: int

func load_from_global_data():
	
	planets = []
	
	# Generate sun node
	sun = load("res://src/scenes/game/Sun/Sun.tscn").instance()
	sun.sd = Global.current_world_data["sun"]["seed"]
	
	# --- Generate planets --- #
	
	var planet_object = load("res://src/scenes/game/Planet/Planet.tscn")
	for planet in Global.current_world_data["planets"]:
		var new_planet = planet_object.instance()
		new_planet.type = planet["type"]
		new_planet.name = planet["name"]
		new_planet.resources = planet["resources"]
		new_planet.orbit_distance = planet["orbit_distance"]
		new_planet.orbit_speed = planet["orbit_speed"]
		new_planet.orbit_position = planet["orbit_position"]
		new_planet.sprite_name = planet["sprite_name"]
		new_planet.sd = planet["seed"]
		
		planets.append(new_planet)
		
	starting_planet = planets[Global.current_world_data["starting_planet_index"]]
	current_planet = planets[Global.current_world_data["current_planet_index"]]
	
	# Set player resources
	resources = Global.current_world_data["resources"]
	resource_cap = Global.current_world_data["resource_cap"]
	

func _init(w_name: String, w_seed: int, w_random_seed: bool, w_difficulty: String, skip_rng: bool = false):
	if skip_rng:
		load_from_global_data()
		return
	
	var data = {"planets": [], "resources": {}, "developed_technology": [], "developing_technology": {}, "discovered_planets_indices": []}
	
	name = w_name
	sd = w_seed
	random_seed = w_random_seed
	difficulty = w_difficulty
	planets = []
	
	Global.rng = RandomNumberGenerator.new()
	if random_seed:
		Global.rng.randomize()
		sd = Global.rng.seed
	else:
		Global.rng.seed = sd
	
	data["seed"] = Global.rng.seed
	data["sun"] = {"seed": Global.rng.randi()}
	
	# --- Generate planets --- #
	
	# Randomise the amount of planets within the min and max of the difficulty
	var planet_amount = Global.randi_range_array(Global.rng, Global.generation_data["p_amount_range"][difficulty])

	# Balance type selection probability based on weight
	var planet_types = []
	for type in Global.generation_data["p_types"].keys():
		for _i in range(Global.generation_data["p_types"][type]["weight"]):
			planet_types.append(type)
	
	# Used names will be recorded here so that they aren't used again
	var used_planet_names = []
	
	# Set player starting planet
	data["starting_planet_index"] = planet_amount/2 + Global.rng.randi_range(1, 1) - 1
	data["current_planet_index"] = data["starting_planet_index"]
	
	var starting_planet_preset = Global.random_item(Global.rng, Global.generation_data["starting_planet_presets"])
	for resource in starting_planet_preset["resources"].keys():
		data["resources"][resource] = starting_planet_preset["resources"][resource]
	data["developed_technology"] = starting_planet_preset["technologies"]
	
	for i in range(planet_amount):
		var new_planet = {"resources": [], "constructed_technology": []}
		
		var is_starting_planet = data["starting_planet_index"] == i
		
		# Reset type list if all planet types have been used
		if planet_types == []:
			
			for type in Global.generation_data["p_types"].keys():
				for __i in range(Global.generation_data["p_types"][type]["weight"]):
					planet_types.append(type)
		
		# Set random planet type
		if is_starting_planet:
			new_planet["type"] = starting_planet_preset["type"]
		else:
			new_planet["type"] = Global.random_item(Global.rng, planet_types)
			# Entirely remove that type from the list
			while new_planet["type"] in planet_types:
				planet_types.erase(new_planet["type"])
		
		# Set name
		var names = Global.generation_data["p_names"] + Global.generation_data["p_types"][new_planet["type"]]["names"]
		
		for name in used_planet_names:
			names.erase(name)
			
		# DEBUG
		if len(names) == 0:
			push_error("Not enough planet names, reusing")
			names = Global.generation_data["p_names"] + Global.generation_data["p_types"][new_planet["type"]]["names"]
		
		new_planet["name"] = Global.random_item(Global.rng, names)
		used_planet_names.append(new_planet["name"])
		new_planet["name"] = tr(new_planet["name"])
		
		# Set resources
		if is_starting_planet:
			new_planet["resources"] = starting_planet_preset["resources"].keys()
		else:
			var resources = Global.generation_data["p_types"][new_planet["type"]]["resources"].keys()
			var resource_amount = Global.randi_range_array(Global.rng, Global.generation_data["resource_amount_range"][difficulty])
			for __i in range(resource_amount):
				
				# Get generic resources if the type's own resources have all been used
				if len(resources) == 0:
					for resource in Global.generation_data["resources"].keys():
						if not resource in new_planet["resources"]:
							resources.append(resource)
				
				var new_resource = Global.random_item(Global.rng, resources)
				new_planet["resources"].append(new_resource)
				resources.erase(new_resource)
		
		var prev_orbit_distance = 50
		var prev_orbit_speed = 30
		if data["planets"] != []:
			prev_orbit_distance = data["planets"][len(data["planets"]) - 1]["orbit_distance"]
			prev_orbit_speed = data["planets"][len(data["planets"]) - 1]["orbit_speed"]
		new_planet["orbit_distance"] = prev_orbit_distance + Global.rng.randi_range(90, 105)
		new_planet["orbit_speed"] = prev_orbit_speed - Global.rng.randi_range(2, 5)
		new_planet["orbit_position"] = Global.rng.randi_range(0, 359)
	
		# Set sprite
		new_planet["sprite_name"] = Global.random_item(Global.rng, Global.generation_data["p_types"][new_planet.type]["sprites"])
		
		# Set seed
		new_planet["seed"] = Global.rng.randi()
		
		data["planets"].append(new_planet)

	for resource in Global.generation_data["resources"].keys():
		if not resource in data["resources"].keys():
			data["resources"][resource] = 0
	data["developed_technology"].append(Global.techtree_data["columns"]["storage"][0]["id"])
	data["resource_cap"] = Global.techtree_data["columns"]["storage"][0]["resource_cap"]
	
	Global.current_world_data = data
	load_from_global_data()