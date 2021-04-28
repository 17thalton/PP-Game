extends Control

var current_resource = null

onready var planet = get_parent().get_parent().get_parent()

#onready var resource_icons = {
#	"hydrogen": preload(),
#	"water": preload(),
#	"helium": preload(),
#	"carbon": preload(),
#	"methane": preload(),
#	"nitrogen": preload(),
#	"ammonia": preload(),
#	"oxygen": preload(),
#	"sulfur": preload()
#}

func _ready():
	self.visible = false
	$Background.modulate = Global.Config["menu_colour"]
	$Camera2D.queue_free()

	$ConstructButtons.visible = false
	for button in $ConstructButtons.get_children():
		button.connect("pressed", self, "construct_facility", [int(button.name)])

func set_resource(resource: String, show_buttons: bool):
	current_resource = resource
	$ConstructButtons.visible = show_buttons
	$Name.bbcode_text = "[right]" + resource.capitalize() + "[/right]"
	$Details.bbcode_text = "[right]" + Global.generation_data["resources"][resource]["details"] + "[/right]"
	$Description.text = Global.generation_data["resources"][resource]["description"]

func construct_facility(level: int):
	
	if not $ConstructButtons.visible:
		return
	
	var technology = Global.techtree_data["columns"][current_resource][level - 1]
	if technology in Global.current_world_data["planets"][Global.current_world.planets.find(planet)]["constructed_technology"]:
		yield(Global.display_confirmation_dialog("[center]Cannot construct facility[center]", "[center]That facility has already been constructed on this planet[/center]", null, "Ok"), "completed")
		Global.last_dialog_confirmed = null
		return
	elif technology["id"] in Global.current_world_data["developed_technology"]:
		if Global.current_world.current_planet == planet:
			var cost_text = ""
			var not_enough_resources = false
			if technology["construct_cost"] == {}:
				cost_text = "\nNo construction cost"
			else:
				cost_text = "Required resources:\n\n"
				for resource in technology["construct_cost"].keys():
		
					if technology["construct_cost"][resource] > Global.current_world.resources[resource]:
						not_enough_resources = true
					
					cost_text = cost_text + " •  " + str(technology["construct_cost"][resource]) + "  " + resource.capitalize() + "\n"
			
				if not_enough_resources:
					cost_text = cost_text + "\nYou do not have enough resources"
					
			if not_enough_resources:
				yield(Global.display_confirmation_dialog(
					"[center]Cannot construct this facility[/center]", 
					"[center][b]" + technology["name"] + "[/b]\n- - - - - - - - -\n" + cost_text + "[/center]", 
					null, "OK"), "completed")
				Global.last_dialog_confirmed = null
			else:
				yield(Global.display_confirmation_dialog(
					"[center]Construct this facility?[/center]", 
					"[center][b]" + technology["name"] + "[/b]\n- - - - - - - - -\n" + cost_text + "[/center]", 
					"Cancel", "Develop"), "completed")
				
				if Global.last_dialog_confirmed:
					for resource in technology["construct_cost"].keys():
						Global.set_resource(resource, -technology["construct_cost"][resource], true)
					Global.current_world_data["planets"][Global.current_world.planets.find(planet)]["constructed_technology"].append(technology)
				
				Global.last_dialog_confirmed = null
					
			
		else:
			yield(Global.display_confirmation_dialog("[center]You are not on this planet[center]", "[center]In order to construct a facility on this planet, you must first travel to it[/center]", null, "Ok"), "completed")
			Global.last_dialog_confirmed = null
			return
	else:
		yield(Global.display_confirmation_dialog("[center]This facility has not been developed[center]", "[center]This level of facility must be developed from the technology menu before it can be constructed[/center]", null, "Ok"), "completed")
		Global.last_dialog_confirmed = null
		return
