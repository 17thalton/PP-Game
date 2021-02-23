extends Control




# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Debug
	$Camera2D.queue_free()
	
	Global.overlay_gui = self
	$Visual/Background.modulate = Global.Config["menu_colour"]
	
	$Visual/Buttons/TechTree.connect("pressed", self, "menu_button_pressed", [$Visual/TechTree])
#	$Visual/TechTree/Background.connect("mouse_entered", self, "tech_tree_mouse_changed", [true])
#	$Visual/TechTree/Background.connect("mouse_exited", self, "tech_tree_mouse_changed", [false])


func _exit_tree():
	if Global.overlay_gui == self:
		Global.overlay_gui = null


var mouse_over_objects = []
var currently_open = false

func area_triggered(object, mouse_entered: bool):
	print(mouse_entered)
	if mouse_entered:
		if not object in mouse_over_objects:
			mouse_over_objects.append(object)
	else:
		if object in mouse_over_objects:
			mouse_over_objects.erase(object)
	
	if currently_open:
		if mouse_over_objects == []:
			$AnimationPlayer.play("SlideOut")
			currently_open = false
	else:
		if mouse_over_objects != []:
			$AnimationPlayer.play("SlideIn")
			currently_open = true
			

var menu_open = false
func _process(_delta):
	
	var mouse_in_area = Global.is_point_in_collisionshape("mouse", $TriggerArea)
	if mouse_in_area == menu_open:
		return
	
	if mouse_in_area:
		menu_open = true
		$AnimationPlayer.play("SlideIn")
	else:
		menu_open = false
		$AnimationPlayer.play("SlideOut")



func menu_button_pressed(menu: Control):
	
	$Tween.stop_all()
	var duration = 0.2
	
	if menu.visible:
		
		var final_modulate = menu.modulate
		final_modulate.a = 0
		
		$Tween.interpolate_property(menu, "modulate", menu.modulate, final_modulate, duration)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		menu.visible = false
	else:
		menu.visible = true
		
		var final_modulate = menu.modulate
		final_modulate.a = 1
		
		$Tween.interpolate_property(menu, "modulate", Color.transparent, final_modulate, duration)
		$Tween.start()

#func tech_tree_mouse_changed(mouse_is_over: bool):
#	if mouse_is_over:
#		$Visual/TechTree.modulate.a = 1.0
#	else:
#		$Visual/TechTree.modulate.a = 0.75
