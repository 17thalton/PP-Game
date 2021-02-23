extends Control

var current_resource = null
var current_planet = null

func _ready():
	self.visible = false
	$Background.modulate = Global.Config["menu_colour"]

func close():
	pass

func resource_clicked(resource: String, planet: Node2D):
	if $AnimationPlayer.current_animation == "":
		
		if current_resource == null:
			$AnimationPlayer.play("FadeIn", -1, Global.Config["animation_speed"])
			current_resource = resource
			current_planet = planet
			
		else:
			if resource == current_resource:
				$AnimationPlayer.play("FadeOut", -1, Global.Config["animation_speed"])
				current_resource = null
			elif resource != current_resource:
				current_resource = resource
				
				$AnimationPlayer.play("InfoFadeOut", -1, Global.Config["animation_speed"])
				yield($AnimationPlayer, "animation_finished")
				
				# Change information
				
				$AnimationPlayer.play("InfoFadeIn", -1, Global.Config["animation_speed"])
