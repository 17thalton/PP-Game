extends Control

var current_resource = null

func _ready():
	self.visible = false
	$Background.modulate = Global.Config["menu_colour"]
	$Camera2D.queue_free()

func set_resource(resource: String):
	current_resource = resource
	$Name.bbcode_text = "[right]" + resource.capitalize() + "[/right]"
	$Details.bbcode_text = "[right]" + Global.generation_data["resources"][resource]["details"] + "[/right]"
	$Description.text = Global.generation_data["resources"][resource]["description"]
