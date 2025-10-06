extends Node3D

@export var fade_time = 1.0

@onready var ambience_player = $NightSounds

func _ready():
	fade_in()

func fade_in():
	ambience_player.volume_db = -80.0
	var tween = create_tween()
	tween.tween_property(ambience_player, "volume_db", 0.0, fade_time)

func fade_out():
	ambience_player.volume_db = 0.0
	var tween = create_tween()
	tween.tween_property(ambience_player, "volume_db", -80.0, fade_time)
