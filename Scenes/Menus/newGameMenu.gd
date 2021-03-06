extends Control
# https://www.youtube.com/watch?v=LdHKs2Foon0&list=PLI95OAGEsXs8_5_OrBpZylMFp4xuEVleL&index=2


# Characters that cannot be contained in the world name
const invalid_worldname_chars = [
	"\n",
	"	",
	"/"
]

# Called when the node enters the scene tree for the first time. 
func _ready():
	for node in $choice_difficulty.get_children():
		if node is CheckBox:
			node.connect("toggled", self, "difficulty_selected", [node])

	$text_name/text.connect("text_changed", self, "text_changed", [$text_name])
	
	$text_seed/text.connect("text_changed", self, "text_changed", [$text_seed])
	$text_seed/random.connect("toggled", self, "random_seed_toggled")
	
	$button_create/button.connect("pressed", self, "create_world")


func difficulty_selected(button_pressed: bool, selected_difficulty: CheckBox):
	$choice_difficulty/error.text = ""
	if button_pressed:
		for difficulty in [$choice_difficulty/hard, $choice_difficulty/normal, $choice_difficulty/easy]:
			if difficulty != selected_difficulty:
				difficulty.pressed = false
	else:
		for difficulty in [$choice_difficulty/hard, $choice_difficulty/normal, $choice_difficulty/easy]:
			if difficulty.pressed:
				return
		$choice_difficulty/error.text = "Please select a difficulty"

func random_seed_toggled(button_pressed: bool):
	if button_pressed:
		$text_seed/text.readonly = true
		$text_seed/text.text = ""
		$text_seed/error.text = ""
	else:
		$text_seed/text.readonly = false
		
	

# Alert user when a text field contains invalid characters
func text_changed(node: Node2D):
	var text: TextEdit = node.get_node("text")
	var error_label: Label = node.get_node("error")
	
	if node == $text_name:
		if text.text.strip_edges() == "":
			error_label.text = "Name cannot be blank"
			return
			
		var used_invalid_chars = ""
		for character in invalid_worldname_chars:
			if character in $text_name/text.text:
				if character == "\n":
					character = "newline"
				elif character == "	":
					character = "tab"
				used_invalid_chars = used_invalid_chars + character + " "
	
		if used_invalid_chars != "":
			error_label.text = "Name cannot contain these characters:\n" + used_invalid_chars
		else:
			error_label.text = ""
	elif node == $text_seed:
		if text.text.strip_edges() == "":
			error_label.text = "Seed cannot be blank"
		elif str(int(text.text.strip_edges())) == text.text.strip_edges():
			error_label.text = ""
		else:
			error_label.text = "Seed must be an integer"

func create_world():
	
	# Check if all fields have beet set and are valid
	var error_occured = false
	
	# DIFFICULTY
	var difficulty = ""
	for node in $choice_difficulty.get_children():
		if node is CheckBox:
			if node.pressed:
				difficulty = node.name
	if difficulty == "":
		$choice_difficulty/error.text = "Please select a difficulty"
		error_occured = true
	
	# WORLD NAME / SEED
	text_changed($text_name)
	text_changed($text_seed)
	if $text_name/error.text != "" or $text_seed/error.text != "":
		error_occured = true
	var world_name = $text_name/text.text.strip_edges()
	var world_seed = int($text_seed/text.text.strip_edges())
	var random_seed = $text_seed/random.pressed
		
	if error_occured:
		return
	else:
		var world = $WorldGenerator.generateWorld(world_name, world_seed, random_seed, difficulty)

		for planet in world["planets"]:
			print(planet.get_json())
			
		print(world["seed"])
