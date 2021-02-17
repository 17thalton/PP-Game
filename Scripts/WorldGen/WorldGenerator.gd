extends Node

# PLanet types source
# https://www.youtube.com/watch?v=pQ-dE_5el5Q

# Generate and save world based on set variables
func generateWorld(world_name: String, world_seed: int, random_seed: bool, difficulty: String):

	# Data to be set by the generateWorld() function
	var world = {
		"planets": [],
		"seed": null
	}

	# Initialise RNG using seed parameter, or a random seed
	var rng = RandomNumberGenerator.new()
	if random_seed:
		rng.randomize()
		world["seed"] = rng.seed
	else:
		rng.seed = world_seed
		world["seed"] = world_seed
	
	# Read data.json containing data needed for world generation
	var f = File.new()
	f.open("res://Scripts/WorldGen/data.json", File.READ)
	var data = f.get_as_text()
	f.close()
	data = JSON.parse(data).result
	
	# Generate planets
	var amount_of_planets = rng.randi_range(data["planet_amount_range"][difficulty.to_lower()][0], data["planet_amount_range"][difficulty.to_lower()][0])
	var planet_scene = load("res://Objects/Game/Planet/Planet.tscn")
	var used_planet_names = []
	
	# Balance type likelyhoods based on weight
	var planet_types = []
	for type in data["planet_types"].keys():
		for _i in range(data["planet_types"][type]["weight"]):
			planet_types.append(type)
	
	for _i in range(amount_of_planets):
		var planet = planet_scene.instance()

		# Set planet name
		var planet_name: String
		while true:
			planet_name = data["planet_names"][rng.randi_range(0, len(data["planet_names"]) - 1)]
			if planet_name in used_planet_names:
				if len(used_planet_names) == len(data["planet_names"]):
					push_warning("Not enough planet names, reusing existing ones")
					used_planet_names = []
					break
			else:
				break
		planet.p_name = planet_name
		used_planet_names.append(planet.p_name)
		
		# Set planet type
		if planet_types == []:
			push_warning("Not enough planet type weight, reusing existing ones")
			for type in data["planet_types"].keys():
				for _i in range(data["planet_types"][type]["weight"]):
					planet_types.append(type)
		
		var type_index = rng.randi_range(0, len(planet_types) - 1)
		planet.p_type = planet_types[type_index]
		planet_types.remove(type_index)
		
		
		# Set primary resources
		var amount_of_primary_resources = rng.randi_range(data["primary_resource_amount_range"][difficulty][0], data["primary_resource_amount_range"][difficulty][1])
		for _i in range(amount_of_primary_resources):
			planet.primary_resources.append(data["planet_types"][planet.p_type]["primary_resources"].keys()[rng.randi_range(0, len(data["planet_types"][planet.p_type]["primary_resources"].keys()) - 1)])
		
		world["planets"].append(planet)
		
	return world
