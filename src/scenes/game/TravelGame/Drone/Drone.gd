extends Node2D

var default_laser_cooldown = 0.1 # Laser cooldown in seconds
var current_laser_cooldown = 0
var next_laser_cannon = 0
var controllable = false
var velocity = Vector2.ZERO

var zoom_tween_running = false
var zoom_level = 7
var zoom_steps = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2]

onready var rocket: Node2D = get_parent()
onready var sprites = [
	preload("res://assets/Sprites/TravelMinigame/Drones/drone_1.png"),
	preload("res://assets/Sprites/TravelMinigame/Drones/drone_2.png"),
	preload("res://assets/Sprites/TravelMinigame/Drones/drone_3.png")
]

var sprite: Resource
onready var laser = preload("res://src/scenes/game/TravelGame/Drone/Laser/Laser.tscn")
var laser_positions = []

# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible = false
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	sprite = Global.random_item(rng, sprites)
	$Sprite.texture = sprite
	
	if sprite == sprites[0]:
		for position in $LaserCannons1.get_children():
			laser_positions.append(position)
	elif sprite == sprites[1]:
		for position in $LaserCannons2.get_children():
			laser_positions.append(position)
	else:
		for position in $LaserCannons3.get_children():
			laser_positions.append(position)

func _physics_process(delta):
	
	if not controllable:
		return
		
	if Input.is_action_just_released("drone_zoomin"):
		zoom(true)
	elif Input.is_action_just_released("drone_zoomout"):
		zoom(false)
		
	var dest_velocity = Vector2.ZERO
	if Input.is_action_pressed("drone_left"):
		dest_velocity.x = -150
	elif Input.is_action_pressed("drone_right"):
		dest_velocity.x = 150
	
	if Input.is_action_pressed("drone_up"):
		dest_velocity.y = -150
	elif Input.is_action_pressed("drone_down"):
		dest_velocity.y = 150
	
	velocity = lerp(velocity, dest_velocity, 0.02)
	self.rotation = lerp_angle(self.rotation, self.global_position.angle_to_point(self.get_global_mouse_position()) - PI/2, 0.1)
	translate(velocity*delta)
	
	current_laser_cooldown = max(0, current_laser_cooldown - delta)
	if Input.is_action_pressed("drone_fire") and current_laser_cooldown == 0:
		current_laser_cooldown = default_laser_cooldown
		
		var laser_obj = laser.instance()
		rocket.add_child(laser_obj)
		laser_obj.global_position = laser_positions[next_laser_cannon].global_position
		laser_obj.rotation = self.global_position.angle_to_point(self.get_global_mouse_position()) - PI/2
		laser_obj.vel_offset = self.velocity / 2
		next_laser_cannon += 1
		if next_laser_cannon >= len(laser_positions):
			next_laser_cannon = 0
	
		
func zoom(zoom_in: bool):
	
	if zoom_tween_running:
		return
		
	if zoom_in:
		zoom_level -= 1
	else:
		zoom_level += 1
		
	if zoom_level < 0 or zoom_level >= len(zoom_steps):
		return 
		
	$ZoomTween.interpolate_property($Camera2D, "zoom", $Camera2D.zoom, Vector2(zoom_steps[zoom_level], zoom_steps[zoom_level]), 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$ZoomTween.start()
	zoom_tween_running = true
	yield($ZoomTween, "tween_all_completed")
	zoom_tween_running = false

func deploy():
	
	var deploying_left = rocket.rotation_degrees < 0
	print(deploying_left)
	
	self.rotation_degrees = rocket.get_node("PrimaryRocket/Sprite").rotation_degrees
	if deploying_left:
		self.rotation_degrees -= 90
	else:
		self.rotation_degrees += 90
		
	self.global_position = rocket.get_node("PrimaryRocket/Sprite").global_position
	
	var final_position = self.position + rocket.get_forward_movement(0) * 150
	if deploying_left:
		final_position *= -1
	
	self.visible = true
	
	rocket.get_node("Tween").interpolate_property(self, "position", self.position, final_position, 3.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	rocket.get_node("Tween").start()
	
	$Timer.start(1.0)
	yield($Timer, "timeout")
	
	var camera_dest_pos = $Camera2D.position
	
	$Camera2D.global_position = Global.active_camera.global_position
	$Camera2D.zoom = Global.active_camera.zoom
	Global.active_camera = $Camera2D
	$Camera2D.current = true
	rocket.get_node("Tween").interpolate_property($Camera2D, "position", $Camera2D.position, camera_dest_pos, 2.0, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	rocket.get_node("Tween").interpolate_property($Camera2D, "zoom", $Camera2D.zoom, Vector2(zoom_steps[zoom_level], zoom_steps[zoom_level]), 2.0, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	rocket.get_node("Tween").start()
	
	yield(rocket.get_node("Tween"), "tween_all_completed")
	controllable = true
	
