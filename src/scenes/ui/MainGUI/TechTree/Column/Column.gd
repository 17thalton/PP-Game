extends Control

var rounded_rect = preload("res://assets/Sprites/UI/rounded_rect.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
#	$ScrollContainer/Container/ItemTemplate.queue_free()
	pass

func populate(items: Array, title: String):
	
	$Title.bbcode_text = "[center]" + title.capitalize() + "[/center]"
	
	for item in items:
		var new_item = $ScrollContainer/Container/ItemTemplate.duplicate()
		new_item.text = str(item)
		$ScrollContainer/Container.add_child(new_item)

	$ScrollContainer/Container/ItemTemplate.queue_free()
