extends Control

@export_file("*.tscn") var level_scene_path: String = "res://neighborhood.tscn"

func _ready() -> void:
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	$PlayButton.pressed.connect(_on_play_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)
	
	if ScreenFade:
		await get_tree().process_frame
		ScreenFade.fade_in()

func _on_play_pressed() -> void:

	if ScreenFade:
		ScreenFade.fade_out()
		# Add a timeout in case the signal doesn't fire
		var fade_timer = get_tree().create_timer(1.5)
		await fade_timer.timeout

	print("Changing to level scene...")
	var result = get_tree().change_scene_to_file(level_scene_path)
	
	if result != OK:
		# Try to fade back in if it failed
		if ScreenFade:
			ScreenFade.fade_in()

func _on_quit_pressed() -> void:
	print("Quitting game...")

	if ScreenFade:
		ScreenFade.fade_out()
		await ScreenFade.fade_out_complete
	get_tree().quit()
