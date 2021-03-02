extends Node

# -- Debug -- #
var quickstart: Dictionary = {"is_quickstart": false}
# ----------- #

signal next_frame

# Load each planet from the PixelPlanets library
# Distributed by get_planet()
onready var planets = {
	"terran wet": preload("res://lib/PixelPlanets/Planets/Rivers/Rivers.tscn"),
	"terran dry": preload("res://lib/PixelPlanets/Planets/DryTerran/DryTerran.tscn"),	
	"islands": preload("res://lib/PixelPlanets/Planets/LandMasses/LandMasses.tscn"),
	"no atmosphere": preload("res://lib/PixelPlanets/Planets/NoAtmosphere/NoAtmosphere.tscn"),
	"gas giant 1": preload("res://lib/PixelPlanets/Planets/GasPlanet/GasPlanet.tscn"),
	"gas giant 2": preload("res://lib/PixelPlanets/Planets/GasPlanetLayers/GasPlanetLayers.tscn"),
	"ice world": preload("res://lib/PixelPlanets/Planets/IceWorld/IceWorld.tscn"),
	"lava world": preload("res://lib/PixelPlanets/Planets/LavaWorld/LavaWorld.tscn"),
	"asteroid": preload("res://lib/PixelPlanets/Planets/Asteroids/Asteroid.tscn"),
	"star": preload("res://lib/PixelPlanets/Planets/Star/Star.tscn"),
}

var generation_data: Dictionary

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

var current_discord_activity = null

# Default config data
var Config: Dictionary = {
	
	"text_speed": 1, # Increases/decreases text reveal speed
	
	"tooltip_wait_time": 0.25,  # Time in seconds before tooltips appear
	
	"planet_quality": 100, # Planet/sun resolution (1 ~ 100) | Set to below 1 for static sprite
	
	"menu_colour": "ff24263d", # HTML colour code used for menu backgrounds
	
	"animation_speed": 1, # Increases/decreases animation speed
	
	"snappy_animations": true, # Toggles hardcoded snappy animations
	
	"discord_rich_presence": false, # Enables Discord rich presence integration
	
	"language": "en",
	
	}

# Specifies config entries that use special types
const config_types = {"menu_colour": "colour"}

func _ready():

	# DEBUG
#	OS.window_fullscreen = true
	# Load config file, or save it if it doesn't exist
	var file = File.new()
#	if not file.file_exists("user://config.json"):
#		save_config()
#	else:
#		load_config(file)

	generation_data = load_json("res://src/data/generation_data.json")

	save_config()
	load_config(file)

	if Config["discord_rich_presence"]:
		Godotcord.init(813775934712840203, 0)
		var activity = GodotcordActivity.new()
		activity.state = "TEST"
		activity.large_image = "large_main"
		discord_status(activity)
	
	TranslationServer.set_locale(Config["language"])

# Check for global hotleys such as toggle_fullscreen
# Emit next_frame signal for use in functions such as text_fade_in()
func _process(_delta):
	
	emit_signal("next_frame")
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Config["discord_rich_presence"]:
		Godotcord.run_callbacks();
	

# Load config file from user://config.json and write it to the Config var
func load_config(file: File):
	# Read the config and parse it
	file.open("user://config.json", File.READ)
	var data = parse_json(file.get_line())
	file.close()
	
	# DEBUG
	for key in Config.keys():
		if not key in data.keys():
			push_warning("Default config contains keys not found in the saved config JSON")
			break
	
	Config = data
	
	# Set config values to their proper types
	for key in data.keys():
		if key in config_types.keys():
			match config_types[key]:
				"colour": Config[key] = Color(Config[key])

# Save config data to JSON file from the Config variable or the passed dict
func save_config(data: Dictionary = Config):
	var file = File.new()
	file.open("user://config.json", File.WRITE)
	file.store_line(to_json(data))
	file.close()

# Set a project settings value and then save it to file
func change_project_setting(key, value):
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save_custom("user://settings_override.godot")

# Gradually reveal text each frame using the visible_characters property
func text_fade_in(text_node, frames_to_wait: int = 1, resume: bool = true):
	
	if not resume:
		text_node.visible_characters = 0
	
	var length
	if text_node is RichTextLabel and text_node.bbcode_enabled:
		length = len(text_node.bbcode_text)
		if text_node.bbcode_text.begins_with("[center]") and text_node.bbcode_text.ends_with("[/center]"):
			length -= 17
	else:
		length = len(text_node.text)
	var set_to = text_node.visible_characters
	while text_node.visible_characters < length:
		
		if set_to != text_node.visible_characters:
			return
		
		text_node.visible_characters += 1
		set_to = text_node.visible_characters
		for _i in range(frames_to_wait / Global.Config["text_speed"]):
			yield(self, "next_frame")
			
func text_fade_out(text_node, frames_to_wait: int = 1):
	
	while text_node.visible_characters > 0:
		text_node.visible_characters -= 1
		for _i in range(frames_to_wait / Global.Config["text_speed"]):
			yield(self, "next_frame")

func discord_status(activity: GodotcordActivity):
	current_discord_activity = activity
	GodotcordActivityManager.set_activity(activity)

# Correct the camera zoom and offset based on screen resolution
func correct_camera(camera: Camera2D = active_camera):
	camera.zoom *= zoom_modifier
	camera.offset = camera_offset

func is_point_in_area(point: Vector2, area_position: Vector2, area_size: Vector2):
	
	var distance_x = point.x - area_position.x
	var distance_y = point.y - area_position.y
		
	if distance_x < 0:
		distance_x *= -1
	if distance_y < 0:
		distance_y *= -1
	
	return distance_x < area_size.x and distance_y < area_size.y

# Instance and prepare a PixelPlanets planet node, and return it 
func get_planet_sprite(type, sd):
	var sprite = planets[type.to_lower()].instance()
	
	sprite.set_seed(sd)
	sprite.rect_position = Vector2(0,0)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.name = "Sprite"
	
	if type.to_lower() == "star":
		sprite.rect_position = Vector2(-50, -50)
		sprite.rect_scale = Vector2(1, 1)
	else:
		var resolution = Global.Config["planet_quality"]
		if resolution < 1:
			sprite.static_texture = true
			resolution = 100
		sprite.set_pixels(resolution)
			
		sprite.rect_position = Vector2(-25, -25)
		sprite.rect_scale = Vector2(50/resolution, 50/resolution)
	
	for child in sprite.get_children():
		if child is ColorRect:
			child.material.resource_local_to_scene = true
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	return sprite
	
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

