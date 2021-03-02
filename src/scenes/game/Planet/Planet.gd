extends Node

var type: String
var sd: int
var resources: Array = []

var sprite = null

var orbit_speed = 50  # Degrees to rotate per second
var orbit_stopped = false  # Stops orbit if true
var orbit_distance: float  # Distance from sun
var orbit_starting_position: float

var hover_fading = false
var waiting_for_hover = false

onready var main: Node2D = get_tree().get_root().get_child(1)  # Top ancestor node
onready var camera: Camera2D = main.get_node("Camera2D")  # Camera node of main

# Returns planet data in a JSON format so that it can be saved
func get_json():
	return {
		"name": name,
		"type": type,
		"resources": resources,
		"sprite": sprite,
		"seed": sd
	}

func _ready():
	
	# DEBUG
	$Visual/Planet.queue_free()
	$Visual/Menu.visible = false

	# Get sprite and configure it, then add it to the scene
	set_sprite(sprite)
	
	$Visual/InteractButton.connect("pressed", self, "on_interact")
	$Visual/Menu/InteractButton.connect("pressed", self, "on_interact")
	
	$Visual/HoverLabel.visible_characters = 0
	$Visual/HoverLabel.bbcode_text = "[center]" + self.name + "[/center]"
	
	$Visual.position.y -= orbit_distance  # Apply orbit distance to the sprite position
	self.global_position = Vector2(960, 540)
	
	self.global_rotation_degrees = orbit_starting_position
	
	if self == Global.current_world.starting_planet:
		set_sprite("no atmosphere")
		sprite.modulate = Color(0.1, 0.1, 0.1, 1.0)
		
		$Visual/Menu/PlanetInfo/PlanetName.bbcode_text = "[center]Undiscovered planet[/center]"
		$Visual/Menu/PlanetInfo/PlanetType.bbcode_text = "[center]Distance from sun: " + str(orbit_distance/Global.current_world.starting_planet.orbit_distance) + " AU[/center]"
		$Visual/Menu/PlanetInfo/PlanetType.hint_tooltip = "TOOLTIP"
	
	# DEBUG
	if self == Global.current_world.starting_planet:
		print(self.name)

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
		

	if Global.is_point_in_area($Visual.get_global_mouse_position(), $Visual.global_position, Vector2(35, 35)) and main.focused_planet == null:
		if $Visual/HoverLabel.visible_characters == 0 and not hover_fading and not waiting_for_hover:
			waiting_for_hover = true
			var wait_time = Global.Config["tooltip_wait_time"]
			while wait_time > 0:
				yield(Global, "next_frame")
				wait_time -= delta
				if not ($Visual/HoverLabel.visible_characters == 0 and not hover_fading):
					waiting_for_hover = false
					return
			Global.text_fade_in($Visual/HoverLabel, 3)
			waiting_for_hover = false

	else:
		if main.focused_planet != null:
			$Visual/HoverLabel.visible_characters = 0
		elif $Visual/HoverLabel.visible_characters != 0 and not hover_fading:
			hover_fading = true
			print("fade out")
			yield(Global.text_fade_out($Visual/HoverLabel, 3), "completed")
			hover_fading = false


func focus_self():
	
	var position_offset = Vector2(352, 160)/2 - Global.camera_offset
	var zoom = Vector2(0.5, 0.5)/2
	var duration = 0.5 / Global.Config["animation_speed"]
	
	main.focused_planet = self
	
	$Visual/Camera2D.global_position = Global.active_camera.global_position
	$Visual/Camera2D.zoom = Global.active_camera.zoom
	$Visual/Camera2D.offset = Global.camera_offset
	$Visual/Camera2D.current = true
	Global.active_camera = $Visual/Camera2D
	
	var destination: Vector2

	self.global_rotation_degrees += duration * self.orbit_speed  # Rotate the planet by the duration
	destination = $Visual.global_position  # Get the sprite's position at that rotation
	self.global_rotation_degrees -= duration * self.orbit_speed  # Revert the planet rotation to the original
	# This is a somewhat hacky solution, but doing this with a trig function instead wasn't accurate for some reason
	
	$Tween.interpolate_property($Visual/Camera2D, "global_position", $Visual/Camera2D.global_position, destination + position_offset, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Visual/Camera2D, "zoom", $Visual/Camera2D.zoom, zoom * Global.zoom_modifier, duration,Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()
	
	main.fade_planets(false, [self], true, Global.Config["snappy_animations"])
	
func set_sprite(sprite_name: String):
	var new_sprite = Global.get_planet_sprite(sprite_name, sd)
	$Visual/InteractButton.rect_position = new_sprite.rect_position
	$Visual/InteractButton.rect_scale = new_sprite.rect_scale
	
	if sprite is Control:
		sprite.queue_free()
	
	sprite = new_sprite
	$Visual.add_child(new_sprite)
	$Visual.move_child(sprite, $Visual/HoverLabel.get_index())

