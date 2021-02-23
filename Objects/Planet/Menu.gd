extends Control

onready var textboxes = [$PlanetInfo/PlanetName, $PlanetInfo/PlanetType, $PlanetInfo/Resources/Label]
onready var planet = get_parent().get_parent()

func _ready():
	
	$PlanetInfo/Background.modulate = Global.Config["menu_colour"]
	$PlanetInfo/PlanetName.bbcode_text = "[center]" + tr("PLANET_NAME_" + planet.name.to_upper()) + "[/center]"
	$PlanetInfo/PlanetType.bbcode_text = "[center]" + tr("PLANET_TYPE_" + planet.type.to_upper().replace(" ", "_")) + "[/center]"
	$PlanetInfo/Resources/Label.bbcode_text = "[center]" + tr("TEXT_RESOURCES") + ":[/center]"
	
	var ClickableResource = load("res://Objects/UI/ClickableResource.tscn")
	for resource in planet.resources:
		var new_resource: Button = ClickableResource.instance()
		new_resource.text = tr("RESOURCE_" + resource.to_upper())
		new_resource.name = resource
		$PlanetInfo/Resources/ResourceList/Container.add_child(new_resource)
		new_resource.connect("pressed", get_parent().get_node("ResourceMenu"), "resource_clicked", [resource, planet])

func process_display():
	
	planet.z_index = 100
	
	var animator: AnimationPlayer = planet.focus_self()
	await_stop_rotation()
	if not Global.Config["snappy_animations"]:
		yield(animator, "animation_finished")
		
	planet.get_node("Visual/InteractButton").disabled = true
	$InteractButton.disabled = false
	planet.get_node("AnimationPlayer").play("MenuFadeIn", -1, Global.Config["animation_speed"])
	
	# Don't animate text at all if text_speed is lower than 1
	if Global.Config["text_speed"] < 1:
		return
	
	for resource in $PlanetInfo/Resources/ResourceList/Container.get_children():
		resource.text = ""
	
	for textbox in textboxes:
		textbox.visible_characters = 0
	
	for textbox in textboxes:
		yield(Global.text_fade_in(textbox), "completed")
		
	for resource in $PlanetInfo/Resources/ResourceList/Container.get_children():
		for _i in range(10 / Global.Config["text_speed"]):
			yield(Global, "next_frame")
		resource.text = tr("RESOURCE_" + resource.name.to_upper())

# Waits for the focus tween to complete, then stops all planet orbits
func await_stop_rotation():
	yield(planet.get_node("Tween"), "tween_completed")
	for planet in Global.current_world.planets:
		planet.orbit_stopped = true
	
func process_hide(main: Node2D):
	
	for planet in Global.current_world.planets:
		planet.orbit_stopped = false
	
	planet.z_index = 0
	
	planet.get_node("AnimationPlayer").play("MenuFadeOut", -1, Global.Config["animation_speed"])
	if not Global.Config["snappy_animations"]:
		yield(planet.get_node("AnimationPlayer"), "animation_finished")
		
	main.reset_camera()
	
	$InteractButton.disabled = true
	planet.get_node("Visual/InteractButton").disabled = false

