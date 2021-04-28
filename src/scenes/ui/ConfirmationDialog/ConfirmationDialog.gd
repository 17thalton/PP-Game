extends Node2D

signal button_pressed
var right_button_last_pressed = null

onready var original_nodes = {
	"Background": $Background.duplicate(),
	"Title": $Title.duplicate(),
	"Content": $Content.duplicate(),
	"ButtonRight": $ButtonRight.duplicate(),
	"ButtonLeft": $ButtonLeft.duplicate()
}
onready var original_self = self.duplicate()

var instance_id = null

func reset_popup(single_node: String = ""):
	
	var nodes = original_nodes
	if single_node != "_":
		if single_node != "":
			nodes = {single_node: original_nodes[single_node]}
		if single_node == "" or single_node == "self":
			self.position = original_self.position
			if single_node == "self":
				return
	
	for node in nodes.keys():
		for property in ["rect_position", "rect_size", "visible"]:
			self.get_node(node).set(property, nodes[node].get(property))

func _ready():
	$ButtonLeft.connect("pressed", self, "button_pressed", [false])
	$ButtonRight.connect("pressed", self, "button_pressed", [true])
#	self.visible = false

func show_popup(title: String, content, button_left, button_right, title_height_modifier: float = 1.0, skip_position_reset: bool = false):
	
	if self.visible:
		yield(hide_popup(2), "completed")
	if $AnimationPlayer.current_animation != "":
		return
	
	if skip_position_reset:
		reset_popup("_")
	else:
		reset_popup()
		
	
	if title_height_modifier != 1.0:
		$Title.rect_size.y *= title_height_modifier
		$Background.rect_size.y += $Title.rect_size.y - original_nodes["Title"].rect_size.y
		for node in [$Content, $ButtonLeft, $ButtonRight]:
			node.rect_position.y += $Title.rect_size.y - original_nodes["Title"].rect_size.y
	
	$Title.bbcode_text = title
	
	if content == null:
		$Content.visible = false
		$Background.rect_size.y -= $Content.rect_size.y
		$ButtonRight.rect_position.y -= $Content.rect_size.y
		$ButtonLeft.rect_position.y -= $Content.rect_size.y
		$Title.rect_position.y += 10
		self.position.y += $Content.rect_size.y/2
	else:
		$Content.bbcode_text = content
	
	if button_left == null and button_right == null:
		$ButtonLeft.visible = false
		$ButtonRight.visible = false
	else:
		if button_left == null:
			$ButtonLeft.visible = false
			$ButtonRight.rect_position.x = $Background.rect_size.x/2 - $ButtonRight.rect_size.x/2
			$ButtonRight.text = button_right
		elif button_right == null:
			$ButtonRight.visible = false
			$ButtonLeft.rect_position.x = $Background.rect_size.x/2 - $ButtonRight.rect_size.x/2
			$ButtonLeft.text = button_left
		else:
			$ButtonRight.text = button_right
			$ButtonLeft.text = button_left
	
	$AnimationPlayer.play("FadeIn", -1, Global.Config["animation_speed"])
	yield($AnimationPlayer, "animation_finished")
	
func hide_popup(speed_modifier: float = 1.0):
	
	if not self.visible or $AnimationPlayer.current_animation != "":
		yield(Global, "next_frame")
		return
		
#	self.instance_id = null
	
	$AnimationPlayer.play("FadeOut", -1, Global.Config["animation_speed"] * speed_modifier)
	yield($AnimationPlayer, "animation_finished")
	
	
func button_pressed(right: bool):
	right_button_last_pressed = right
	self.emit_signal("button_pressed")
	hide_popup()
