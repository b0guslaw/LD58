extends CanvasLayer

@export var win_color: Color
@export var lose_color: Color
@export var warning_color: Color
@export var warning_time = 1.0

@onready var label_huge : Label = $NotificationLabelHuge

var is_warning = false

func _ready():
	reset()

func reset():
	label_huge.text = ""

func win():
	label_huge.modulate = win_color
	label_huge.text = "yay"

func lose():
	label_huge.modulate = lose_color
	label_huge.text = "oof"

func warning():
	if not is_warning:
		is_warning = true
		label_huge.modulate = warning_color
		label_huge.text = "run"
		await get_tree().create_timer(1.0).timeout
		is_warning = false
		reset()
	else: return
