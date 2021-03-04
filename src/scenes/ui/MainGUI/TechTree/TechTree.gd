extends Control

onready var techtree_data = Global.load_json("res://src/data/tech_tree.json")
onready var column_object = preload("res://src/scenes/ui/MainGUI/TechTree/Column/Column.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$Background.modulate = Global.Config["menu_colour"]
	$Background.modulate.a = 1
	
	#DEBUG
	for column in $ColumnContainer.get_children():
		$ColumnContainer.remove_child(column)
		column.queue_free()

	var new_column: Control
	for column in techtree_data["columns"].keys():
		new_column = column_object.instance()
		new_column.populate(techtree_data["columns"][column], column)
		$ColumnContainer.add_child(new_column)
		
	$ColumnContainer.rect_size.x = len($ColumnContainer.get_children()) * (new_column.get_node("ScrollContainer").rect_size.x + $ColumnContainer.get("custom_constants/separation"))



func technology_pressed(category: String, technology: Dictionary):
	
	if $ConfirmationDialog.instance_id == technology["id"]:
		$ConfirmationDialog.hide_popup()
		return

	if technology["id"] in Global.current_world.developed_technology:
		$ConfirmationDialog.show_popup(
			"[center]That technology has already been developed[/center]", 
			null, 
			null, "Ok", 2.0)
		return
	
	var cost_text = ""
	for resource in technology["develop_cost"].keys():
		cost_text = cost_text + " •  " + str(technology["develop_cost"][resource]) + "  " + resource.capitalize() + "\n"
	
	$ConfirmationDialog.instance_id = technology["id"]
	$ConfirmationDialog.show_popup(
		"[center]Develop this technology?[/center]", 
		"[center][b]" + technology["name"] + "[/b]\n- - - - - - - - -\nRequired resources:\n\n" + cost_text + "[/center]", 
		"Cancel", "Develop")
	yield($ConfirmationDialog, "button_pressed")
	yield($ConfirmationDialog/AnimationPlayer, "animation_finished")
	
	if $ConfirmationDialog.right_button_last_pressed:
		Global.current_world.developed_technology.append(technology["id"])
		
		var content = null
		match technology["type"]:
			"planet_deploy": content = "Go to a planet to construct and deploy"
		
		$ConfirmationDialog.show_popup(
			"[center]The technology has been developed[/center]", 
			"[center]" + content + "[/center]",
			null, "Yes")


