extends Node2D

var sprite: Control
var health = 0

var explosion_variant = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	$Asteroid.queue_free()
	self.visible = false
	$Area2D/CollisionShape2D.disabled = true

func init(rng: RandomNumberGenerator):
	sprite = Global.get_planet_sprite("asteroid", rng.randi(), false)
	self.add_child(sprite)
	self.scale = Vector2(3, 3)
	self.global_position = Vector2(rng.randi_range(0, 15000), rng.randi_range(0, 15000))
	
	health = rng.randi_range(3, 7)
	
	explosion_variant = Global.random_item(rng, ["1", "2", "3"])

func _on_Area2D_area_entered(area):
	
	if not "Laser" in area.name:
		return
	area.queue_free()
	
	health -= 1
	
	if health == 0:
		$Area2D.queue_free()
		sprite.queue_free()
		$AnimatedSprite.visible = true
		$AnimatedSprite.play(explosion_variant)
		
		yield($AnimatedSprite, "animation_finished")
		self.queue_free()
