extends Control

@export_file("*.tscn") var main_menu_path: String = "res://main_menu.tscn"

var is_paused: bool = false

func _ready() -> void:
	visible = false

	process_mode = Node.PROCESS_MODE_ALWAYS

	set_anchors_preset(Control.PRESET_FULL_RECT)

	$Panel/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)
	$Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	
	if is_paused:
		visible = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		visible = false
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	visible = false

	if ScreenFade:
		ScreenFade.fade_out()
		await ScreenFade.fade_out_complete
	
	get_tree().change_scene_to_file(main_menu_path)

func _on_quit_pressed() -> void:
	print("Quitting game...")
	if AmbientAudio:
		AmbientAudio.fade_out()
	if ScreenFade:
		ScreenFade.fade_out()
		await ScreenFade.fade_out_complete
	get_tree().quit()
