extends Node2D

# The planet currently focused on
var focused_planet = null

var test: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$Star.queue_free()
	
	# Add sun and planets to scene
	add_child(Global.current_world.sun)
	Global.current_world.sun.position = Vector2(1920/2, 1080/2)
#	Global.current_world.sun.scale = Vector2(2, 2)
	
	for planet in Global.current_world.planets:
		$Planets.add_child(planet)
	
	Global.active_camera = $Camera2D
	Global.correct_camera()
	
func reset_camera(duration: float = 0.75):
	
	focused_planet = null
	
	duration /= Global.Config["animation_speed"]
	
	$Camera2D.global_position = Global.active_camera.global_position
	$Camera2D.zoom = Global.active_camera.zoom
	$Camera2D.offset = Global.camera_offset
	$Camera2D.current = true
	Global.active_camera = $Camera2D
	
	$Tween.interpolate_property($Camera2D, "global_position", $Camera2D.global_position, Vector2(0, 0), duration, $Tween.TRANS_SINE, $Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Camera2D, "zoom", $Camera2D.zoom, Vector2(1, 1) * Global.zoom_modifier, duration, $Tween.TRANS_SINE, $Tween.EASE_IN_OUT)
	$Tween.start()
	
	for planet in $Planets.get_children():
		if not planet.visible:
			planet.get_node("AnimationPlayer").play("FadeIn", -1, Global.Config["animation_speed"])
	
	if not $Sun.visible:
		$Sun.get_node("AnimationPlayer").play("FadeIn", -1, Global.Config["animation_speed"])
