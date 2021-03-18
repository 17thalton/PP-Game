extends Node2D

# The planet currently focused on
var focused_planet = null

var test: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	
	print(Global.current_world_data)
	
	$Star.queue_free()
	
	# Add sun and planets to scene
	add_child(Global.current_world.sun)
	Global.current_world.sun.position = Vector2(1920/2, 1080/2)
#	Global.current_world.sun.scale = Vector2(2, 2)
	
	for planet in Global.current_world.planets:
		$Planets.add_child(planet)
	
	Global.active_camera = $Camera2D
	Global.correct_camera()
	
func reset_camera(duration: float = 0.75):
	
	focused_planet = null
	
	duration /= Global.Config["animation_speed"]
	
	$Camera2D.global_position = Global.active_camera.global_position
	$Camera2D.zoom = Global.active_camera.zoom
	$Camera2D.offset = Global.camera_offset
	$Camera2D.current = true
	Global.active_camera = $Camera2D
	
	$Tween.interpolate_property($Camera2D, "global_position", $Camera2D.global_position, Vector2(0, 0), duration, $Tween.TRANS_SINE, $Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Camera2D, "zoom", $Camera2D.zoom, Vector2(1, 1) * Global.zoom_modifier, duration, $Tween.TRANS_SINE, $Tween.EASE_IN_OUT)
	$Tween.start()
	
	fade_planets(true, [], true, Global.Config["snappy_animations"])

func fade_planets(fade_in: bool, exclude: Array, stop_orbit: bool, yield_completion: bool):
	
	var animation = "FadeIn"
	var required_visibility = !fade_in
	if not fade_in:
		animation = "FadeOut"
	
	var ret = null
	var planets_to_stop = []
	for planet in Global.current_world.planets + [Global.current_world.sun]:
		
		if planet in exclude:
			continue
		
		if planet.visible == required_visibility and planet.get_node("AnimationPlayer").current_animation == "":
			if stop_orbit and planet != Global.current_world.sun:
				planets_to_stop.append(planet)
			planet.get_node("AnimationPlayer").play(animation, -1, Global.Config["animation_speed"])
			if ret == null:
				ret = planet.get_node("AnimationPlayer")
	
	for planet in planets_to_stop:
		await_orbit_stop(planet, !fade_in)
	
	if yield_completion and ret != null:
		yield(ret, "animation_finished")
	
		
	return ret

func await_orbit_stop(planet, value_to_set):
	
	if value_to_set == true:
		yield(planet.get_node("AnimationPlayer"), "animation_finished")
	
	planet.orbit_stopped = value_to_set

func travel_to_planet(destination_planet):
	
	if destination_planet == Global.current_world.current_planet:
		return
	
	var distance = destination_planet.distance_to_planet(Global.current_world.current_planet)
	
	var required_transportation = Global.techtree_data["columns"]["transportation"][min(3, distance) - 1]["name"]
	
	if Global.techtree_data["columns"]["transportation"][min(3, distance) - 1]["id"] in Global.current_world_data["developed_technology"]:
		yield(Global.display_confirmation_dialog(
			"[center]Travel to " + destination_planet.name + "?[/center]",
			"[center]Distance from current planet: " + str(distance) + "\n\nRequired transportation:\n" + required_transportation + "[/center]",
			 "Cancel", "OK"),
		"completed")
		
		if Global.last_dialog_confirmed:
			Global.minigame_destination = {"sprite": destination_planet.sprite_name}
			var i = 0
			for destination_planet in Global.current_world.planets:
				if destination_planet == destination_planet:
					Global.minigame_destination["index"] = i
					break
				i += 1
			
			Global.minigame_start = {"sprite": Global.current_world.current_planet.sprite_name}
			i = 0
			for planet in Global.current_world.planets:
				if planet == Global.current_world.current_planet:
					Global.minigame_start["index"] = i
					break
				i += 1
			
			get_tree().change_scene("res://src/scenes/game/TravelGame/TravelGame.tscn")
		else:
			Global.last_dialog_confirmed = null
		
	else:
		yield(Global.display_confirmation_dialog(
			"[center]Cannot travel to that planet[/center]",
			"[center]Distance from current planet: " + str(distance) + "\n\nRequired transportation:\n" + required_transportation + "\n\nThe required transportation method has not been developed[/center]",
			 null, "OK"),
		"completed")
	
