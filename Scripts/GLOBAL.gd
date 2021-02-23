extends Node

# -- Debug -- #
var quickstart: Dictionary = {"is_quickstart": false}
# ----------- #

# This signal is emitted every frame from _process()
# Used for things like gradually revealing text or nodes
signal next_frame

# Load each planet from the PixelPlanets library
# Distributed by get_planet()
onready var planets = {
	"terran wet": preload("res://Libraries/PixelPlanets/Planets/Rivers/Rivers.tscn"),
	"terran dry": preload("res://Libraries/PixelPlanets/Planets/DryTerran/DryTerran.tscn"),	
	"islands": preload("res://Libraries/PixelPlanets/Planets/LandMasses/LandMasses.tscn"),
	"no atmosphere": preload("res://Libraries/PixelPlanets/Planets/NoAtmosphere/NoAtmosphere.tscn"),
	"gas giant 1": preload("res://Libraries/PixelPlanets/Planets/GasPlanet/GasPlanet.tscn"),
	"gas giant 2": preload("res://Libraries/PixelPlanets/Planets/GasPlanetLayers/GasPlanetLayers.tscn"),
	"ice world": preload("res://Libraries/PixelPlanets/Planets/IceWorld/IceWorld.tscn"),
	"lava world": preload("res://Libraries/PixelPlanets/Planets/LavaWorld/LavaWorld.tscn"),
	"asteroid": preload("res://Libraries/PixelPlanets/Planets/Asteroids/Asteroid.tscn"),
	"star": preload("res://Libraries/PixelPlanets/Planets/Star/Star.tscn"),
}

# SolarSystem class containing all world data such as planets and seed
var current_world = null

# The currently active camera (set manually)
var active_camera: Camera2D

var overlay_gui = null

# Camera zoom modifier used to account for non-standard resolutions
onready var zoom_modifier = (OS.get_screen_size() / Vector2(
	ProjectSettings.get_setting("display/window/size/width"), 
	ProjectSettings.get_setting("display/window/size/height")))
	
const camera_offset = Vector2(960, 540)

var rotation_speed_modifier: float = 1.0

# Default config data
var Config: Dictionary = {
	# Increases/decreases text reveal speed
	"text_speed": 2, 
	
	# Per-platform planet/sun resolution (1 ~ 100)
	"planet_quality": {"Android": 100, "X11": 100},
	
	# HTML colour code used for menu backgrounds
	"menu_colour": "ff24263d",
	
	# Increases/decreases animations
	"animation_speed": 1,
	
	# Toggles hardcoded snappy animations
	"snappy_animations": false,
	}

# Specifies config entries that use special types
const config_types = {"menu_colour": "colour"}

func _ready():

	TranslationServer.set_locale("en")
	
#	change_project_setting("display/window/size/width", 1920)
#	change_project_setting("display/window/size/height", 1080)
	
	# Load config file, or save it if it doesn't exist
	var file = File.new()
	if not file.file_exists("user://config.json"):
		
		# Save the default configuration if config.json doesn't exist
		file.open("user://config.json", File.WRITE)
		file.store_line(to_json(Config))
		file.close()
	else:
		load_config(file)

# Check for global hotleys such as toggle_fullscreen
# Emit next_frame signal for use in functions such as text_fade_in()
func _process(_delta):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("next_frame")

# Load config file from user://config.json and write it to the Config var
func load_config(file: File):
	# Read the config and parse it
	file.open("user://config.json", File.READ)
	var loaded_config = parse_json(file.get_line())
	file.close()
	
	var save = false
	for key in Config.keys():
		if not key in loaded_config.keys():
			save = true
			break
	
	# Load config data without overwriting unique keys
	for key in loaded_config.keys():
		Config[key] = loaded_config[key]
		
		# Set config values to their proper types
		if key in config_types.keys():
			match config_types[key]:
				"colour": Config[key] = Color(Config[key])
				
	if save:
		file.open("user://config.json", File.WRITE)
		file.store_line(to_json(Config))
		file.close()
	
# Set a project settings value and then save it to file
func change_project_setting(key, value):
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save_custom("user://settings_override.godot")

# Gradually reveal text each frame using the visible_characters property
func text_fade_in(text_node):
	
	text_node.visible_characters = 0
	
	var length
	if text_node is RichTextLabel and text_node.bbcode_enabled:
		length = len(text_node.bbcode_text)
		if text_node.bbcode_text.begins_with("[center]") and text_node.bbcode_text.ends_with("[/center]"):
			length -= 17
		
	else:
		length = len(text_node.text)
	
	while text_node.visible_characters < length:
		for _i in range(2 / Global.Config["text_speed"]):
			yield(self, "next_frame")
		text_node.visible_characters += 1

# Correct the camera zoom and offset based on screen resolution
func correct_camera(camera: Camera2D = active_camera):
	camera.zoom *= zoom_modifier
	camera.offset = camera_offset

func is_point_in_collisionshape(point, shape: CollisionShape2D):
	
	if point == "mouse":
		point = shape.get_global_mouse_position()
		
	var distance_x = point.x - shape.global_position.x
	var distance_y = point.y - shape.global_position.y
		
	if distance_x < 0:
		distance_x *= -1
	if distance_y < 0:
		distance_y *= -1
	
	return distance_x < shape.shape.extents.x and distance_y < shape.shape.extents.y

# Instance and prepare a PixelPlanets planet node and return it 
func get_planet(type, sd, static_texture):
	var planet = planets[type.to_lower()].instance()
	planet.set_seed(sd)
	planet.static_texture = static_texture
	
	planet.rect_position = Vector2(0,0)
	
	for node in planet.get_children():
		if node is ColorRect:
			node.material.resource_local_to_scene = true
	
	return planet
	
# Load JSON file at the specified path and returns data as dict
func load_json(path: String):
	var f = File.new()
	f.open(path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data).result

# Returns a random item from the passed array
func random_item(rng: RandomNumberGenerator, array: Array):
	return array[rng.randi_range(0, len(array) - 1)]

# Returns an random integer within a range defined by a single array
func randi_range_array(rng, array: Array):
	return rng.randi_range(array[0], array[1])

