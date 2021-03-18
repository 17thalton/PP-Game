extends Area2D

#const distance_limit = 2000
const speed = 500

#var distance_travelled = Vector2.ZERO
var vel_offset: Vector2

func _process(delta):
	translate(((get_forward_movement() * speed) + vel_offset) * delta)
#	distance_travelled += ((get_forward_movement() * speed) + vel_offset) * delta
#	if distance_travelled.length() >= distance_limit:
#		queue_free()

func get_forward_movement(offset: float = -PI/2):
	return Vector2(cos(self.rotation + offset), sin(self.rotation + offset))

func get_angle_to_point(point: Vector2):
	return rad2deg(self.global_position.angle_to_point(point)) - 90


func _on_VisibilityNotifier2D_screen_exited():
	self.queue_free()
