extends Node3D

func _ready() -> void:
	var player = $Player
	var player_cam = player.get_node("SpringArm3D/Camera3D") as Camera3D
	player_cam.make_current()
