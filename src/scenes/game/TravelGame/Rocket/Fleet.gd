extends Node2D

var reached_dest_percentage = 0.95
var drone_deploy_percentage = 0.03

var drone = null

var max_speed = 500
var velocity = 0
var destination_object: Control

enum stages {launchpad, launching, reached_dest}
var stage = stages.launchpad

var starting_distance = null

onready var main: Node2D = get_tree().get_root().get_child(1)  # Top ancestor node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass 

func _physics_process(delta):
	
	match stage:
		stages.launchpad:
			return
		stages.launching:
			
			
			var remaining_distance = self.global_position.distance_to(destination_object.rect_global_position)
			
#			remaining_distance = remain
#			remaining_distance = min(abs(remaining_distance.x), abs(remaining_distance.y))
			
			if starting_distance == null:
				starting_distance = remaining_distance
				
			var percentage = remaining_distance / starting_distance
			
			if percentage > 1:
				percentage = 0
			else:
				percentage = 1 - percentage
			
			if percentage >= 0.95:
				get_parent().success_state()
				return
			
			main.get_node("UI").set_progress(percentage)
			
			if percentage >= reached_dest_percentage:
				stage = stages.reached_dest
				return
			
			for planet in [$PrimaryRocket, $SecondaryRocket]:
				planet.get_node("Sprite").rotation_degrees = lerp(planet.get_node("Sprite").rotation_degrees, get_angle_to_point(destination_object.rect_global_position), 0.15 * delta)
			velocity = lerp(velocity, max_speed, 0.3 * delta)
			
			self.position += get_forward_movement() * velocity * delta
			
		stages.reached_dest:
			pass

func get_forward_movement(offset: float = -PI/2):
	return Vector2(cos($PrimaryRocket/Sprite.rotation + offset), sin($PrimaryRocket/Sprite.rotation + offset))

func get_angle_to_point(point: Vector2):
	return rad2deg(self.global_position.angle_to_point(point)) - 90

func launch(dest: Control):
	
	destination_object = dest
	velocity = 10
	stage = stages.launching
	
	$Camera2D.global_position = Global.active_camera.global_position
	$Camera2D.zoom = Global.active_camera.zoom
	
	$Camera2D.current = true
	Global.active_camera = $Camera2D

	$DroneDeployTimer.start()

#	$Tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, get_angle_to_point(destination_position), 3.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
#	$Tween.start()
	
#	yield($Tween, "tween_all_completed")
#	stage = stages.launchpad


func _on_DroneDeployTimer_timeout():
	drone = $Drone
	yield($Drone.deploy(), "completed")
	
	for asteroid in get_parent().get_node("Asteroids").get_children():
		if not asteroid.get_node("VisibilityNotifier2D").is_on_screen():
			asteroid.visible = true
			asteroid.get_node("Area2D/CollisionShape2D").disabled = false
		else:
			get_parent().get_node("Asteroids").remove_child(asteroid)
			asteroid.queue_free()
