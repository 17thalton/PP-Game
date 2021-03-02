extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func btnLoadGame():
	print("load")
	
func btnOptions():
	print("options")
	
func btnExit():
	print("Quitting...")
	get_tree().quit()
