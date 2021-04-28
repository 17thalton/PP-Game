extends Control

onready var textboxes_before_resources = [$PlanetInfo/PlanetName, $PlanetInfo/PlanetType, $PlanetInfo/Resources/Label]
onready var textboxes_after_resources = [$PlanetInfo/TravelButton/Label]
onready var planet = get_parent().get_parent()

var tween_running = false

func _ready():
	
	$PlanetInfo/Background.modulate = Global.Config["menu_colour"]
	$ResourceMenu.modulate = Color.transparent
	$PlanetInfo/Resources/Label.bbcode_text = "[center]" + tr("TEXT_RESOURCES") + ":[/center]"
	
	$PlanetInfo/TravelButton.connect("pressed", planet.get_parent().get_parent(), "travel_to_planet", [planet])
	
	var ClickableResource = load("res://src/scenes/ui/ResourceMenu/ClickableResource.tscn")
	for resource in planet.resources:
		var new_resource: Button = ClickableResource.instance()
		new_resource.text = tr("RESOURCE_" + resource.to_upper())
		new_resource.name = resource
		$PlanetInfo/Resources/ResourceList/Container.add_child(new_resource)
		new_resource.connect("pressed", self, "resource_clicked", [resource])
		
	if Global.current_world.current_planet == planet:
		$PlanetInfo/TravelButton/Info.bbcode_text = "[center]You are already on this planet[/center]"
	else:
		$PlanetInfo/TravelButton/Info.bbcode_text = ""
	

func process_display():
	
	planet.z_index = 100
	
	planet.focus_self()
	
	planet.get_node("Visual/InteractButton").rect_scale = Vector2(0.5, 0.5)
	planet.get_node("AnimationPlayer").play("MenuFadeIn", -1, Global.Config["animation_speed"])
	
	# Don't animate text at all if text_speed is lower than 1
	if Global.Config["text_speed"] < 1:
		return
	
	for resource in $PlanetInfo/Resources/ResourceList/Container.get_children():
		resource.text = ""
	
	for textbox in textboxes_before_resources + textboxes_after_resources:
		textbox.visible_characters = 0
	
	for textbox in textboxes_before_resources:
		yield(Global.text_fade_in(textbox), "completed")
		
	for resource in $PlanetInfo/Resources/ResourceList/Container.get_children():
		for _i in range(10 / Global.Config["text_speed"]):
			yield(Global, "next_frame")
		resource.text = tr("RESOURCE_" + resource.name.to_upper())

	for textbox in textboxes_after_resources:
		yield(Global.text_fade_in(textbox), "completed")

func process_hide(main: Node2D):
	
	if $ResourceMenu.visible:
		resource_clicked($ResourceMenu.current_resource)
	
	for planet in Global.current_world.planets:
		planet.orbit_stopped = false
	
	planet.z_index = 0
	
	planet.get_node("AnimationPlayer").play("MenuFadeOut", -1, Global.Config["animation_speed"])
	if not Global.Config["snappy_animations"]:
		yield(planet.get_node("AnimationPlayer"), "animation_finished")
		
	main.reset_camera()
	
	planet.get_node("Visual/InteractButton").rect_scale = Vector2(1, 1)

func resource_clicked(resource: String):
	
	if tween_running:
		return
	
	var duration = 0.2
	
	if $ResourceMenu.visible:
		
		if $ResourceMenu.current_resource != resource:
			duration *= 0.75
		
		$Tween.interpolate_property($ResourceMenu, "modulate", Color.white, Color.transparent, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()
		
		self.tween_running = true
		yield($Tween, "tween_all_completed")
		self.tween_running = false
		
		if $ResourceMenu.current_resource != resource:
			$ResourceMenu.visible = true
			$ResourceMenu.set_resource(resource)
			
			$Tween.interpolate_property($ResourceMenu, "modulate", Color.transparent, Color.white, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			$Tween.start()
			
			self.tween_running = true
			yield($Tween, "tween_all_completed")
			self.tween_running = false
		else:
			$ResourceMenu.visible = false
			$ResourceMenu.current_resource = null
		
	else:
		
		$ResourceMenu.set_resource(resource, true)
		
		$ResourceMenu.visible = true
		$Tween.interpolate_property($ResourceMenu, "modulate", Color.transparent, Color.white, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()
		
		self.tween_running = true
		yield($Tween, "tween_all_completed")
		self.tween_running = false
		
