extends Node

# Set to the sprite node on ready
var sprite: Control

var sd: int

onready var main: Node2D = get_tree().get_root().get_child(1)  # Top ancestor node
onready var camera: Camera2D = main.get_node("Camera2D")  # Camera node of main

# Returns planet data in a JSON format so that it can be saved
func get_json():
	return {
		"name": name,
		"sprite": sprite,
		"seed": sd
	}

func _ready():
	
	# DEBUG
	$Visual/Star.queue_free()
#	$Visual/Menu.visible = false

	# Get sprite and configure it, then add it to the scene
	sprite = Global.get_planet_sprite("star", sd)
	$Visual/InteractButton.rect_position = sprite.rect_position
	$Visual/InteractButton.rect_scale = sprite.rect_scale
	$Visual.add_child(sprite)
	
	$Visual/InteractButton.connect("pressed", self, "on_interact")
	
	self.global_position = Vector2(960, 540)


func on_interact():
	if main.focused_planet == self:
		if $AnimationPlayer.current_animation == "":
			main.reset_camera()
	else:
		focus_self()

#func _process(delta):
#	if not orbit_stopped:
#		self.global_rotation_degrees += delta * self.orbit_speed
#		$Visual.global_rotation_degrees = 0

func focus_self():
	
	var zoom = Vector2(0.5, 0.5)/2
	var duration = 0.5 / Global.Config["animation_speed"]
	
	main.focused_planet = self
	
	$Visual/Camera2D.global_position = Global.active_camera.global_position
	$Visual/Camera2D.zoom = Global.active_camera.zoom
	$Visual/Camera2D.offset = Global.camera_offset
	$Visual/Camera2D.current = true
	Global.active_camera = $Visual/Camera2D
	
	# Camera position
	$Tween.interpolate_property($Visual/Camera2D, "global_position", $Visual/Camera2D.global_position, self.global_position - Global.camera_offset, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	# Camera zoom
	$Tween.interpolate_property($Visual/Camera2D, "zoom", $Visual/Camera2D.zoom, zoom * Global.zoom_modifier, duration,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	$Tween.start()
	
	main.fade_planets(false, [self], true, Global.Config["snappy_animations"])
	
#func focus_self():
#
#	var position_offset = Vector2(352, 160)/2 - Global.camera_offset
#	var zoom = Vector2(0.5, 0.5)/2
#	var duration = 0.5 / Global.Config["animation_speed"]
#
#	main.focused_planet = self
#
#	$Visual/Camera2D.global_position = Global.active_camera.global_position
#	$Visual/Camera2D.zoom = Global.active_camera.zoom
#	$Visual/Camera2D.offset = Global.camera_offset
#	$Visual/Camera2D.current = true
#	Global.active_camera = $Visual/Camera2D
#
#	var destination: Vector2
#
#	self.global_rotation_degrees += duration * self.orbit_speed  # Rotate the planet by the duration
#	destination = $Visual.global_position  # Get the sprite's position at that rotation
#	self.global_rotation_degrees -= duration * self.orbit_speed  # Revert the planet rotation to the original
#	# This is a somewhat hacky solution, but doing this with a trig function instead wasn't accurate for some reason
#
#	$Tween.interpolate_property($Visual/Camera2D, "global_position", $Visual/Camera2D.global_position, destination + position_offset, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
#	$Tween.interpolate_property($Visual/Camera2D, "zoom", $Visual/Camera2D.zoom, zoom * Global.zoom_modifier, duration,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
#	$Tween.start()
#
#	main.fade_planets(false, [self], true, Global.Config["snappy_animations"])
