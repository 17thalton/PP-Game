extends Control

export var quickstart: Dictionary = {
	"is_quickstart": false,
	"difficulty": "normal",
	"seed": 0,
	"world_name": "QUICKSTART WORLD",
	"random_seed": false,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if quickstart["is_quickstart"]:
		Global.quickstart = quickstart
		btnNewGame()
		
	Global.active_camera = $Camera2D
	Global.correct_camera()
	
	# Connect functions to menu buttons
	$btn_new.connect("pressed", self, "btnNewGame")
	$btn_exit.connect("pressed", self, "btnExit")

func btnNewGame():
	get_tree().change_scene("res://src/scenes/ui/MainMenu/NewGameMenu/main.tscn")
	
func btnExit():
	print("Quitting...")
	get_tree().quit()
