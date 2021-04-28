extends Control

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
	for column in Global.techtree_data["columns"].keys():
		new_column = column_object.instance()
		new_column.populate(Global.techtree_data["columns"][column], column)
		$ColumnContainer.add_child(new_column)
		
	$ColumnContainer.rect_size.x = len($ColumnContainer.get_children()) * (new_column.get_node("ScrollContainer").rect_size.x + $ColumnContainer.get("custom_constants/separation"))
	
	
func technology_pressed(category: String, technology: Dictionary):
	
	if $ConfirmationDialog.instance_id == technology["id"]:
		$ConfirmationDialog.hide_popup()
		return

	if technology["id"] in Global.current_world_data["developed_technology"]:
		$ConfirmationDialog.show_popup(
			"[center]That technology has already been developed[/center]", 
			null, 
			null, "Ok", 2.0)
		return
	elif technology["id"] in Global.current_world_data["developing_technology"].keys():
		$ConfirmationDialog.show_popup(
			"[center]That technology is already in development[/center]", 
			null, 
			null, "Ok", 2.0)
		return
	elif technology["requires_previous_technology"]:
		var index = Global.techtree_data["columns"][category].find(technology)
		if index > 0:
			if not Global.techtree_data["columns"][category][index - 1]["id"] in Global.current_world_data["developed_technology"]:
				$ConfirmationDialog.show_popup(
					"[center]That technology cannot be developed[/center]", 
					"[center]The previous level technology must be developed in order to progress to this level[/center]", 
					null, "Ok", 2.0)
				return
	
	var cost_text = ""
	var not_enough_resources = false
	if technology["develop_cost"] == {}:
		cost_text = "\nNo development cost"
	else:
		cost_text = "Required resources:\n\n"
		for resource in technology["develop_cost"].keys():

			if technology["develop_cost"][resource] > Global.current_world.resources[resource]:
				not_enough_resources = true
			
			cost_text = cost_text + " •  " + str(technology["develop_cost"][resource]) + "  " + resource.capitalize() + "\n"
	
		if not_enough_resources:
			cost_text = cost_text + "\nYou do not have enough resources"
	
	if "develop_time" in technology.keys():
		cost_text = cost_text + "\nTime to develop: " + str(round(technology["develop_time"]/6)/10) + " minutes"
	
	$ConfirmationDialog.instance_id = technology["id"]
	if not_enough_resources:
		$ConfirmationDialog.show_popup(
			"[center]Cannot develop this technology[/center]", 
			"[center][b]" + technology["name"] + "[/b]\n- - - - - - - - -\n" + cost_text + "[/center]", 
			null, "OK")
	else:
		$ConfirmationDialog.show_popup(
			"[center]Develop this technology?[/center]", 
			"[center][b]" + technology["name"] + "[/b]\n- - - - - - - - -\n" + cost_text + "[/center]", 
			"Cancel", "Develop")
	
	yield($ConfirmationDialog, "button_pressed")
	yield($ConfirmationDialog/AnimationPlayer, "animation_finished")
	
	if $ConfirmationDialog.instance_id != technology["id"]:
		return
	
	if $ConfirmationDialog.right_button_last_pressed and not not_enough_resources:
		
		for resource in technology["develop_cost"].keys():
			Global.set_resource(resource, -technology["develop_cost"][resource], true)
		
		var content = ""
		if "develop_time" in technology.keys():
			Global.start_technology_development(technology)
			content = "Development of the technology has started. It will take " + str(round(technology["develop_time"]/6)/10) + " minutes to complete."
		else:
			Global.current_world_data["developed_technology"].append(technology["id"])
			content = "The technology has been constructed"
			Global.apply_technology(technology["id"])
		
		$ConfirmationDialog.show_popup(
			"", 
			"[center]" + content + "[/center]",
			null, "Yes")

	$ConfirmationDialog.instance_id = null
	$ConfirmationDialog.right_button_last_pressed = null
