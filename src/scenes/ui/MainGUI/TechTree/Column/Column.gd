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
		new_item.get_node("Text").rect_size = new_item.rect_size
		new_item.get_node("Text").rect_size.y -= 15
		new_item.get_node("Text").rect_position.y += 7
#		new_item.get_node("Text").rect_size.x -= 10
#		new_item.get_node("Text").rect_position.x += 5
		new_item.get_node("Text").bbcode_text = item["text"].replace('"', '"')
		new_item.get_node("Text").bbcode_text = "[center]" + new_item.get_node("Text").bbcode_text + "[/center]"
		$ScrollContainer/Container.add_child(new_item)
		
		new_item.connect("pressed", self, "technology_pressed", [item, title])

	$ScrollContainer/Container/ItemTemplate.queue_free()

func technology_pressed(item: Dictionary, title):
	get_parent().get_parent().technology_pressed(title, item)
