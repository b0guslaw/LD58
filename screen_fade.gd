extends CanvasLayer

@export var screen_color: Color
@export var f_out_duration = 1.0
@export var f_in_duration = 1.0

@onready var fade_rect: ColorRect = $FadeRect

signal fade_out_complete
signal fade_in_complete

func _ready():
	fade_rect.color = screen_color
	fade_rect.color.a = 0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func instant_fill():
	fade_rect.color.a = 100

func fade_out():
	var tween = create_tween()
	fade_rect.color.a = 0
	tween.tween_property(fade_rect, "color:a", 1.0, f_out_duration)
	await tween.finished
	fade_out_complete.emit()

func fade_in():
	var tween = create_tween()
	fade_rect.color.a = 1.0
	tween.tween_property(fade_rect, "color:a", 0.0, f_in_duration)
	await tween.finished
	fade_in_complete.emit()
