extends Control

# https://www.youtube.com/watch?v=LdHKs2Foon0&list=PLI95OAGEsXs8_5_OrBpZylMFp4xuEVleL&index=2
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Connect functions to menu buttons
	$btn_new.connect("pressed", self, "btnNewGame")
	$btn_load.connect("pressed", self, "btnLoadGame")
	$btn_options.connect("pressed", self, "btnOptions")
	$btn_exit.connect("pressed", self, "btnExit")

func btnNewGame():
	get_tree().change_scene("res://Scenes/Menus/newGameMenu.tscn")

func btnLoadGame():
	get_tree().change_scene("res://Scenes/Menus/loadGameMenu.tscn")
	
func btnOptions():
	get_tree().change_scene("res://Scenes/Menus/optionsMenu.tscn")
	
func btnExit():
	print("Quitting...")
	get_tree().quit()
