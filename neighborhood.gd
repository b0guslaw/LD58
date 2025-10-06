extends Node3D

@export var reset_wait_time = 2.0
@export var is_menu_mode: bool = false

@onready var win_audio: AudioStreamPlayer3D = $Audio/Win

var dogs_chasing = 0
var player

func _ready():	
	if is_menu_mode:
		disable_gameplay_elements()
		return
		
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	ScreenFade.instant_fill()
	TrashUi.show()
	TrashUi.set_up_trash_ui()
	NotificationUi.reset()
	await get_tree().process_frame
	ScreenFade.fade_in()
	
	player = get_tree().get_first_node_in_group("player")
	
	var dogs = get_tree().get_nodes_in_group("enemies")
	for dog in dogs:
		dog.player_spotted.connect(_on_dog_spotted_player)
		dog.player_lost.connect(_on_dog_lost_player)
	if player:
		player.player_died.connect(_on_player_died)
	TrashUi.all_garbage_collected.connect(_on_game_won)

func _on_dog_spotted_player():
	if is_menu_mode:
		return
	if dogs_chasing == 0:
		NotificationUi.warning()
		player.set_being_chased(true)
	dogs_chasing += 1

func _on_dog_lost_player():
	if is_menu_mode:
		return
	dogs_chasing -= 1
	if dogs_chasing <= 0:
		dogs_chasing = 0
		if player:
			player.set_being_chased(false)

func _on_player_died():
	print("oof") # set up "game won" or "game over" ui
	NotificationUi.lose()
	await get_tree().create_timer(reset_wait_time).timeout
	ScreenFade.fade_out()
	await ScreenFade.fade_out_complete
	get_tree().reload_current_scene()

func _on_game_won():
	if is_menu_mode:
		return
	win_audio.play()
	NotificationUi.win()
	await get_tree().create_timer(reset_wait_time).timeout
	ScreenFade.fade_out()
	await ScreenFade.fade_out_complete
	get_tree().reload_current_scene()

func disable_gameplay_elements():
	player = get_tree().get_first_node_in_group("player")
	player.process_mode = Node.PROCESS_MODE_DISABLED

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED

	if TrashUi:
		TrashUi.hide()
