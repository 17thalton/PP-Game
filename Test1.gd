extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var test2 = get_parent().get_node("Test2")
	print(test2.getUnassignedWorldgenVars())
	test2.worldgen_params["world_name"] = "Hello world"
	test2.worldgen_params["world_seed"] = 12345
	test2.worldgen_params["planet_amount_range"] = [5, 10]
	print(test2.getUnassignedWorldgenVars())
	test2.generateWorld()
