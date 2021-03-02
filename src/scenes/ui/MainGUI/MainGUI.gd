extends Control

onready var main: Node2D = get_tree().get_root().get_child(1)  # Top ancestor node

var ResourceInfo = preload("res://src/scenes/ui/MainGUI/ResourceInfo.tscn")

var resource_nodes = {}
enum MenuState {TRANSITIONING, NONE, OPEN}
var menu_status = MenuState.NONE
var open_menu = null

func update_resource(resource_name: String, value: int):
	
	resource_name = resource_name.to_lower()
	if resource_name == "max":
		$Visual/ResourceList/Max.bbcode_text = "[center]Storage cap: " + str(value) + "[/center]"
	else:
		resource_nodes[resource_name].get_child(1).bbcode_text = "[right]" + str(value) + "[/right]"
	

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Debug
	$Camera2D.queue_free()
	
	Global.overlay_gui = self
	$Visual/Background.modulate = Global.Config["menu_colour"]
	
	for button in $Visual/Buttons.get_children():
		button.connect("pressed", self, "menu_button_pressed", [button])
	
	for resource in Global.current_world.resources.keys():
		
		var new_resource = ResourceInfo.instance()
		
		new_resource.get_node("Container/Name").text = str(resource).capitalize()
		new_resource.get_node("Container").rect_size.x = $Visual/ResourceList/Container.rect_size.x
		
		new_resource.get_node("Button").connect("pressed", self, "menu_button_pressed", [new_resource.get_node("Button")])
		new_resource.get_node("Button").rect_size.x = $Visual/ResourceList/Container.rect_size.x
		new_resource.get_node("Button").name = resource
		
		$Visual/ResourceList/Container.add_child(new_resource)
		
		resource_nodes[resource] = new_resource.get_node("Container")
		
		update_resource(resource, Global.current_world.resources[resource])
		update_resource("max", Global.current_world.resource_cap)

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
	
	if Input.is_action_just_pressed("toggle_solarsystem_view"):
		menu_button_pressed($Visual/Buttons/ChangeView)
	
	if main.focused_planet != null:
		return
	var mouse_in_area = Global.is_point_in_area(get_global_mouse_position(), $TriggerArea.global_position, $TriggerArea.shape.extents)
	if mouse_in_area == menu_open:
		return
	
	if mouse_in_area:
		menu_open = true
		$AnimationPlayer.play("SlideIn")
	else:
		menu_open = false
		$AnimationPlayer.play("SlideOut")

func menu_button_pressed(button):

	# Do nothing if there is already a menu animation in progress
	if menu_status == MenuState.TRANSITIONING:
		return
	
	var menu: Control
	var resource = null
	
	# If the button is a resource button, get the resource name and set menu object
	if button.get_parent().get_parent() == $Visual/ResourceList/Container:
		menu = $Visual/Menus/ResourceMenu
		resource = button.name
		
	# Get the menu associated with the button
	else:
		match button.name:
			"TechTree":
				menu = $Visual/Menus/TechTree
			_:
				push_error("Button case not added")
				return
	
	# Check if the button refers to a menu that isn't open
	var show_menu = menu != open_menu or (resource != null and resource != $Visual/Menus/ResourceMenu.current_resource)
	
	# Close the currently open menu
	if menu_status == MenuState.OPEN:
		menu_status = MenuState.TRANSITIONING
		
		if not show_menu:
			main.fade_planets(true, [], true, true)
		
		yield(hide_menu(open_menu), "completed")
		open_menu = null

	if show_menu:
		
		if resource != null:
			menu.set_resource(resource)
		
		menu_status = MenuState.TRANSITIONING
		yield(show_menu(menu), "completed")
		open_menu = menu
		menu_status = MenuState.OPEN
	else:
		menu_status = MenuState.NONE


func show_menu(menu):
	menu.visible = true
	
	var duration = 0.2
	var final_modulate = menu.modulate
	final_modulate.a = 1
	
	$Tween.interpolate_property(menu, "modulate", Color.transparent, final_modulate, duration)
	$Tween.start()
	
	main.fade_planets(false, [], true, true)
	
	if $Tween.is_active():
		yield($Tween, "tween_all_completed")
	
func hide_menu(menu):
	
	var duration = 0.2
	var final_modulate = menu.modulate
	final_modulate.a = 0
	
	$Tween.interpolate_property(menu, "modulate", menu.modulate, final_modulate, duration)
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	
	menu.visible = false
