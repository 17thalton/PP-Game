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



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
