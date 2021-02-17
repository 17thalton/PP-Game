extends Node

var p_name: String
var p_type: String

var primary_resources: Array = []

func get_json():
	return {
		"name": p_name,
		"type": p_type,
		"primary_resources": primary_resources
	}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
