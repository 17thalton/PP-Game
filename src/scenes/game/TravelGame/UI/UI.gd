extends CanvasLayer

var complete_width: float = 832

# Called when the node enters the scene tree for the first time.
func _ready():
	set_progress(0)

func set_progress(percentage: float):
	$Control/ProgressBar.rect_size.x = max(complete_width * 0.005, complete_width * percentage)
