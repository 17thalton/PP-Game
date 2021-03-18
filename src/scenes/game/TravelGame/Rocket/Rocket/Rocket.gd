extends Area2D

var points_damaged = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


onready var explosion_animations = preload("res://assets/Sprites/Effects/PixelSimulations/RocketExplosions.tres")
onready var flame_animations = preload("res://assets/Sprites/Effects/PixelSimulations/RocketFlames.tres")

func _on_MainRocket_area_entered(area):
	
	if not "Asteroid" in area.get_parent().name:
		return
	
	points_damaged += 1
	
	if points_damaged == len($Sprite/ExplosionPoints.get_children()):
		get_parent().get_parent().fail_state()
		return
	else:
		explode_point($Sprite/ExplosionPoints.get_child(points_damaged - 1))
	
#	if points_damaged == 1:
#		get_parent().get_parent().fail_state()
#		return
#	else:
#		explode_point($Sprite/ExplosionPoints.get_child(points_damaged - 1))
		
func explode_point(point: Position2D):
	
	var initial_explosion = AnimatedSprite.new()
	initial_explosion.frames = explosion_animations
	initial_explosion.position = point.position
	
	self.add_child(initial_explosion)
	initial_explosion.z_index = 99
	initial_explosion.play(Global.random_item(Global.current_world.rng, initial_explosion.frames.get_animation_names()))
	
	var flame = AnimatedSprite.new()
	flame.frames = flame_animations
	flame.position = point.position
	flame.visible = false
	flame.modulate = Color.transparent

	self.add_child(flame)
	initial_explosion.z_index = 99
	flame.play(Global.random_item(Global.current_world.rng, flame.frames.get_animation_names()))
	
	yield(initial_explosion, "animation_finished")
	initial_explosion.queue_free()
	flame.visible = true
	$Tween.interpolate_property(flame, "modulate", Color.transparent, Color.white, 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
