extends Node2D

var backgrounds = [
	[
		"res://assets/Sprites/TravelMinigame/BG/Blue Nebula/1.png",
		"res://assets/Sprites/TravelMinigame/BG/Blue Nebula/2.png",
		"res://assets/Sprites/TravelMinigame/BG/Blue Nebula/3.png",
		"res://assets/Sprites/TravelMinigame/BG/Blue Nebula/4.png",
		"res://assets/Sprites/TravelMinigame/BG/Blue Nebula/5.png",
		"res://assets/Sprites/TravelMinigame/BG/Blue Nebula/6.png",
	],
	[
		"res://assets/Sprites/TravelMinigame/BG/Green Nebula/1.png",
		"res://assets/Sprites/TravelMinigame/BG/Green Nebula/2.png",
		"res://assets/Sprites/TravelMinigame/BG/Green Nebula/3.png",
		"res://assets/Sprites/TravelMinigame/BG/Green Nebula/4.png"
	],
	[
		"res://assets/Sprites/TravelMinigame/BG/Purple Nebula/1.png",
		"res://assets/Sprites/TravelMinigame/BG/Purple Nebula/2.png",
		"res://assets/Sprites/TravelMinigame/BG/Purple Nebula/3.png",
		"res://assets/Sprites/TravelMinigame/BG/Purple Nebula/4.png",
		"res://assets/Sprites/TravelMinigame/BG/Purple Nebula/5.png",
	],
	[
		"res://assets/Sprites/TravelMinigame/BG/Starfields/1.png",
		"res://assets/Sprites/TravelMinigame/BG/Starfields/2.png"
	]
	
]

onready var asteroid_scene = preload("res://src/scenes/game/TravelGame/Asteroid/Asteroid.tscn")
var asteroids = []
var asteroid_separation = 500

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#DEBUG
	$Planet.queue_free()
	$Planet2.queue_free()
	
	Global.active_camera = $Camera2D
	
	var rng = Global.current_world.rng
	
	# Set random background
	$Background/TextureRect.texture = load(Global.random_item(rng, Global.random_item(rng, backgrounds)))
	
	# Init starting planet
	var starting_planet = Global.get_planet_sprite(Global.minigame_start["sprite"], rng.randi())
	self.add_child(starting_planet)
	starting_planet.rect_scale = Vector2(7, 7)
	starting_planet.rect_position = Vector2(-360, -360)
	
	# Init destination planet
	var dest_planet = Global.get_planet_sprite(Global.minigame_destination["sprite"], rng.randi())
	self.add_child(dest_planet)
	dest_planet.rect_scale = Vector2(7, 7)
	
	dest_planet.rect_global_position = Vector2(rng.randi_range(9000, 12000), rng.randi_range(9000, 12000))
	match rng.randi_range(1, 4):
		1: dest_planet.rect_global_position.x *= -1
		2: dest_planet.rect_global_position.y *= -1
		3: dest_planet.rect_global_position *= -1
		4: pass

	for _i in range(700):
		while generate_asteroid(rng, [dest_planet, starting_planet]) == -1:
			pass

	$Timer.start(1)
	yield($Timer, "timeout")

	var animation_time = 3.0

	# Zoom in on planet
	$Tween.interpolate_property($Camera2D, "zoom", $Camera2D.zoom, Vector2(1, 1), animation_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Camera2D, "position", $Camera2D.position, Vector2(0, -496 -100), animation_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	# Gradually stop planet rotation
	$Tween.interpolate_property(starting_planet, "speed_modifier", starting_planet.speed_modifier, 0, animation_time + 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	$Timer.start(1)
	yield($Timer, "timeout")
	
	$Fleet.launch(dest_planet)
	
func generate_asteroid(rng: RandomNumberGenerator, separation_objects: Array):
	
	var asteroid = asteroid_scene.instance()
	asteroid.init(rng)
	$Asteroids.add_child(asteroid)
	match rng.randi_range(1, 4):
		1: asteroid.global_position.x *= -1
		2: asteroid.global_position.y *= -1
		3: asteroid.global_position *= -1
		4: pass
	
	var ret = 0
	for object in $Asteroids.get_children() + separation_objects:
		
		if object == asteroid:
			continue
		
		if object is Control:
			if asteroid.global_position.distance_to(object.rect_global_position) <= asteroid_separation:
				ret = -1
				break
		else:
			if asteroid.global_position.distance_to(object.global_position) <= asteroid_separation:
				ret = -1
				break
		
	if ret == -1:
		$Asteroids.remove_child(asteroid)
		asteroid.queue_free()
	
	return ret

func fail_state():
	yield(Global.display_confirmation_dialog("[center]Game over[/center]", "[center]The mission failed because a rocket was destroyed[/center]", "Quit", "Retry"), "completed")
	
#	while Global.last_dialog_confirmed == null:
#		pass
	
	if Global.last_dialog_confirmed:
		Global.reload_world(Global.minigame_destination["index"])
	else:
		get_tree().quit()
	
func success_state():
	Global.reload_world(Global.minigame_destination["index"])
