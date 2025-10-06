extends AudioStreamPlayer

@export var fade_time = 1.0

var target_vol: float

func _ready():
	target_vol = volume_db
	fade_in()

func fade_in():
	volume_db = -80.0
	var tween = create_tween()
	tween.tween_property(self, "volume_db", target_vol, fade_time)

func fade_out():
	print("fade music...")
	volume_db = target_vol
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -80.0, fade_time)
