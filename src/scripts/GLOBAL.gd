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

onready var SolarSystem = preload("res://src/scripts/SolarSystem/SolarSystem.gd")
var generation_data = load_json("res://src/data/generation_data.json")
onready var techtree_data = load_json("res://src/data/tech_tree.json")

# SolarSystem class containing all world data such as planets and seed
var current_world = null
var current_world_data = {}

var rng = null

# The currently active camera (set manually)
var active_camera: Camera2D

var overlay_gui = null

# Camera zoom modifier used to account for non-standard resolutions
onready var zoom_modifier = (OS.get_screen_size() / Vector2(
	ProjectSettings.get_setting("display/window/size/width"), 
	ProjectSettings.get_setting("display/window/size/height")))
	
const camera_offset = Vector2(960, 540)

var rotation_speed_modifier: float = 1.0

var last_dialog_confirmed = null

# Default config data
var Config: Dictionary = {
	
	"text_speed": 1, # Increases/decreases text reveal speed
	
	"tooltip_wait_time": 0.25,  # Time in seconds before tooltips appear
	
	"planet_quality": 100, # Planet/sun resolution (1 ~ 100) | Set to below 1 for static sprite
	
	"menu_colour": "ff24263d", # HTML colour code used for menu backgrounds
	
	"animation_speed": 1, # Increases/decreases animation speed
	
	"snappy_animations": true, # Toggles hardcoded snappy animations
	
	"language": "en",
	
	}

onready var confirmation_dialog = preload("res://src/scenes/ui/ConfirmationDialog/ConfirmationDialog.tscn")

var minigame_destination = null
var minigame_start = null

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

	pause_mode = Node.PAUSE_MODE_PROCESS

	# Init confirmation dialog
	confirmation_dialog = confirmation_dialog.instance()
	
	confirmation_dialog.visible = false
	confirmation_dialog.scale = Vector2(0.7, 0.7)
	confirmation_dialog.position = Vector2(370, 150)
	
	var canvas = CanvasLayer.new()
	self.add_child(canvas)
	canvas.layer = 9999
	canvas.add_child(confirmation_dialog)

	for column in techtree_data["columns"].keys():
		var i = 0
		for technology in techtree_data["columns"][column]:
			var current = null
			var to_replace = []
			for character in technology["text"]:
				if character == "$":
					if current == null:
						current = "$"
					else:
						to_replace.append(current + "$")
						current = null
				elif current != null:
					current = current + character
			for item in to_replace:
				techtree_data["columns"][column][i]["text"] = technology["text"].replace(item, technology[item.replace("$", "")])
			i += 1

	save_config()
	load_config(file)
	
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
	if Input.is_action_just_pressed("screenshot"):
		
		var dir = Directory.new()
		dir.open("user://")
		if not dir.dir_exists("screenshots"):
			dir.make_dir("screenshots")
		
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		var date = OS.get_datetime()
		image.save_png("user://screenshots/" + str(date["year"]) + "-" + str(date["month"]) + "-" + str(date["day"]) + "_" + str(date["hour"]) + "." + str(date["minute"]) + "." + str(date["second"]) + ".png")

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
func get_planet_sprite(type, sd, apply_adjustments: bool = true) -> Control:
	var sprite = planets[type.to_lower()].instance()
	
	sprite.set_seed(sd)
	sprite.set_pixels(100)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.name = "Sprite"
	
	if not apply_adjustments:
		return sprite
		
	sprite.rect_position = Vector2(0,0)

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
	
	return sprite
	
# Load JSON file at the specified path and returns data as dict
func load_json(path: String) -> Dictionary:
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

func start_technology_development(technology: Dictionary):
	print("started " + technology["id"])
	var timer = Timer.new()
	current_world_data["developing_technology"][technology["id"]] = technology
	current_world_data["developing_technology"][technology["id"]]["timer"] = timer
	current_world_data["developing_technology"][technology["id"]]["node"] = null
	timer.connect("timeout", self, "technology_development_completed", [technology["id"]])
	timer.one_shot = true
	timer.name = technology["id"]
	self.add_child(timer)
	timer.start(technology["develop_time"])
	
func technology_development_completed(technology_id: String):
	Global.current_world_data["developed_technology"].append(technology_id)
	current_world_data["developing_technology"][technology_id]["timer"].queue_free()
	current_world_data["developing_technology"][technology_id]["node"].queue_free()
	current_world_data["developing_technology"].erase(technology_id)
	
	apply_technology(technology_id)
	
func apply_technology(technology_id: String):
	if "storage" in technology_id:
		for technology in Global.techtree_data["columns"]["storage"]:
			if technology["id"] == technology_id:
				set_resource("max", technology["resource_cap"], false)
	
	
func display_confirmation_dialog(title: String, description: String, cancel_option, confirm_option):
	for i in range(1):
		yield(self, "next_frame")
	if confirmation_dialog.get_node("AnimationPlayer").current_animation != "":
		yield(confirmation_dialog.get_node("AnimationPlayer"), "animation_finished")
	
	if confirmation_dialog.visible:
		yield(self, "next_frame")
		return
	
	confirmation_dialog.show_popup(title, description, cancel_option, confirm_option, 1.0)
	
	yield(confirmation_dialog, "button_pressed")
	
	last_dialog_confirmed = confirmation_dialog.right_button_last_pressed
	
func reload_world(current_planet_index: int):
	current_world = SolarSystem.new("", 0, false, "", true)
	current_world.current_planet = current_world.planets[current_planet_index]
	get_tree().change_scene("res://src/scenes/game/Main.tscn")
			

func set_resource(key: String, value: int, addition: bool):
	
	if key == "max":
		if addition:
			current_world.resource_cap += value
		else:
			current_world.resource_cap = value
	else:
		if addition:
			current_world.resources[key] += value
		else:
			current_world.resources[key] = value
			
		current_world.resources[key] = min(current_world.resources[key], current_world.resource_cap)

	overlay_gui.update_resource(key)

