extends Control

@onready var music_slider = $MusicSlider
@onready var sfx_slider = $SFXSlider

var music_bus: int
var sfx_bus: int

func _ready():
	music_bus = AudioServer.get_bus_index("Master")
	sfx_bus = AudioServer.get_bus_index("Sfx")
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))

func _on_music_slider_value_changed(value):
	if value == 0:
		AudioServer.set_bus_mute(music_bus, true)
	else:
		AudioServer.set_bus_mute(music_bus, false)
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))

func _on_sfx_slider_value_changed(value):
	if value == 0:
		AudioServer.set_bus_mute(sfx_bus, true)
	else:
		AudioServer.set_bus_mute(sfx_bus, false)
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
