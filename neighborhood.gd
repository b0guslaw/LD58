extends Node3D

@export var reset_wait_time = 2.0

@onready var player = $Player

func _ready():
	ScreenFade.instant_fill()
	TrashUi.set_up_trash_ui()
	NotificationUi.reset()
	await get_tree().process_frame
	ScreenFade.fade_in()
	
	if player:
		player.player_died.connect(_on_player_died)
	TrashUi.all_garbage_collected.connect(_on_game_won)

func _on_player_died():
	print("oof") # set up "game won" or "game over" ui
	NotificationUi.lose()
	await get_tree().create_timer(reset_wait_time).timeout
	ScreenFade.fade_out()
	await ScreenFade.fade_out_complete
	get_tree().reload_current_scene()

func _on_game_won():
	print("yay") # set up "game won" or "game over" ui
	NotificationUi.win()
	await get_tree().create_timer(reset_wait_time).timeout
	ScreenFade.fade_out()
	await ScreenFade.fade_out_complete
	get_tree().reload_current_scene()
