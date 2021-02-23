extends Node

var sd: int

var mouse_is_over_sprite = false

var main: Node2D
var camera: Camera2D

func get_json():
	return {
		"name": name,
		"seed": sd
	}


# Called when the node enters the scene tree for the first time.
func _ready():
	
	main = get_tree().get_root().get_child(1)
	for child in main.get_children():
		if child is Camera2D:
			camera = child
			break
	
	$Visual/Star.queue_free()
	
	var resolution = 100
	if OS.get_name() in Global.Config["planet_quality"].keys():
		resolution = Global.Config["planet_quality"][OS.get_name()]
	
	var sprite
	if resolution < 1:
		sprite = Global.get_planet("star", sd, true)
		resolution = 100
	else:
		sprite = Global.get_planet("star", sd, false)
	
	sprite.set_pixels(resolution)
	sprite.rect_position = Vector2(-50, -50)
	sprite.rect_scale = Vector2(100/resolution, 100/resolution)

	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for child in sprite.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	$Visual.add_child(sprite)
	
	$Visual/InteractButton.connect("pressed", self, "on_interact")
	$Visual/InteractButton.connect("mouse_exited", self, "set_mouse_status", [false])
	$Visual/InteractButton.connect("mouse_entered", self, "set_mouse_status", [true])

func on_interact():
	if main.focused_planet == self:
		if main.get_node("Planets").get_child(0).get_node("AnimationPlayer").current_animation == "":
			main.reset_camera()
	else:
		main.focus_object(self)
	
func set_mouse_status(status: bool):
	mouse_is_over_sprite = status
	
