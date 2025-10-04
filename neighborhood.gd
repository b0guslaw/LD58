extends Node3D

@export var reset_wait_time = 2.0

@onready var player = $Player

func _ready():
	ScreenFade.instant_fill()
	await get_tree().process_frame
	ScreenFade.fade_in()
	
	if player:
		player.player_died.connect(_on_player_died)

func _on_player_died():
	var tree = get_tree()
	await tree.create_timer(reset_wait_time).timeout
	ScreenFade.fade_out()
	await ScreenFade.fade_out_complete
	tree.reload_current_scene()
