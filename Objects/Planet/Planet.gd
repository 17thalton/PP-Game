extends Node

# Planet type
var type: String

# Initially the string name of the sprite
# Gets set to the sprite node on ready
var sprite

# Seed unique to this planet
var sd: int

# Degrees to rotate per second
var orbit_speed = 50

# If true, the planet will stop orbiting the sun
var orbit_stopped = false

# Distance from sun
var orbit_distance: int

# List of resources
var resources: Array = []

# Top ancestor node
var main: Node2D

# Camera node of main
var camera: Camera2D

func get_json():
	return {
		"name": name,
		"type": type,
		"resources": resources,
		"sprite": sprite,
		"seed": sd
	}


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# DEBUG
	$Visual/Planet.queue_free()
	$Visual/Menu.visible = false
	
	main = get_tree().get_root().get_child(1)
	camera = main.get_node("Camera2D")
	
	var resolution = 100
	if OS.get_name() in Global.Config["planet_quality"].keys():
		resolution = Global.Config["planet_quality"][OS.get_name()]
	
	if resolution < 1:
		sprite = Global.get_planet(sprite, sd, true)
		resolution = 100
	else:
		sprite = Global.get_planet(sprite, sd, false)
	
	sprite.set_pixels(resolution)
	
#	sprite.rect_pivot_offset = Vector2(-100, -100)
#	sprite.rect_scale = Vector2(50, 50) / resolution
#	$Visual/InteractButton.rect_scale =  Vector2(50, 50) / resolution
	
	sprite.rect_position = Vector2(-25, -25)
	$Visual/InteractButton.rect_position = sprite.rect_position
	sprite.rect_scale = Vector2(50/resolution, 50/resolution)
	$Visual/InteractButton.rect_scale = sprite.rect_scale
	
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for child in sprite.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	$Visual.add_child(sprite)
	sprite.name = "Sprite"

	$Visual/InteractButton.connect("pressed", self, "on_interact")
	$Visual/Menu/InteractButton.connect("pressed", self, "on_interact")
	
	$Visual.position.y -= orbit_distance
	self.global_position = Vector2(960, 540)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = self.sd
	self.global_rotation_degrees = rng.randi_range(0, 364)

func on_interact():
	if main.focused_planet == self:
		if main.get_node("Planets").get_child(0).get_node("AnimationPlayer").current_animation == "":
			$Visual/Menu.process_hide(main)
	else:
		$Visual/Menu.process_display()

func _process(delta):
	if not orbit_stopped:
		self.global_rotation_degrees += delta * self.orbit_speed
		$Visual.global_rotation_degrees = 0

func focus_self():
	
	var position_offset = Vector2(352, 144)/2 - Global.camera_offset
	var zoom = Vector2(0.5, 0.5)/2
	var duration = 0.5 / Global.Config["animation_speed"]
	
	main.focused_planet = self
	
	$Visual/Camera2D.global_position = Global.active_camera.global_position
	$Visual/Camera2D.zoom = Global.active_camera.zoom
	$Visual/Camera2D.offset = Global.camera_offset
	$Visual/Camera2D.current = true
	Global.active_camera = $Visual/Camera2D
	
#	var rot = node_to_focus.global_rotation + deg2rad(duration * node_to_focus.orbit_speed)
#	var a = node_to_focus.orbit_distance
#
#	var dest_y = -(a*cos((2*PI)/6*(rot))) + 540
#	var dest_x = a*sin((2*PI)/6*(rot)) + 960

#	var destination_position = Vector2(dest_x, dest_y)
	
	var destination: Vector2

	self.global_rotation_degrees += duration * self.orbit_speed
	destination = $Visual.global_position
	self.global_rotation_degrees -= duration * self.orbit_speed
	
	# Camera position
	$Tween.interpolate_property($Visual/Camera2D, "global_position", $Visual/Camera2D.global_position, destination + position_offset, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	# Camera zoom
	$Tween.interpolate_property($Visual/Camera2D, "zoom", $Visual/Camera2D.zoom, zoom * Global.zoom_modifier, duration,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	# Sprite scale
#	$Tween.interpolate_property(sprite, "rect_scale", sprite.rect_scale, Vector2(1, 1), duration, Tween.TRANS_SINE, Tween.EASE_OUT)
#	$Tween.interpolate_property($Visual/InteractButton, "rect_scale", $Visual/InteractButton.rect_scale, Vector2(1, 1), duration, Tween.TRANS_SINE, Tween.EASE_OUT)
#
	# Sprite relative position
#	$Tween.interpolate_property(sprite, "rect_position", sprite.rect_position, Vector2(-50, -50), duration, Tween.TRANS_SINE, Tween.EASE_OUT)
#	$Tween.interpolate_property($Visual/InteractButton, "rect_position", $Visual/InteractButton.rect_position, Vector2(-50, -50), duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	
	$Tween.start()
	
	var ret = null
	for planet in Global.current_world.planets:
		if planet != self and planet.visible:
			planet.get_node("AnimationPlayer").play("FadeOut", -1, Global.Config["animation_speed"])
			if ret == null:
				ret = planet.get_node("AnimationPlayer")
	if main.get_node("Sun").visible:
		main.get_node("Sun/AnimationPlayer").play("FadeOut", -1, Global.Config["animation_speed"])
	return ret
