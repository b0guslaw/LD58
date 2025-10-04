extends CanvasLayer

@onready var trash_counter: Label = $TrashCounter

var trash_total: int = 10 # TODO, make this dynamic based on trash in scene

func _ready():
	update_trash_ui(0)

func update_trash_ui(trash_number: int):
	trash_counter.text = "Trash %d / %d" % [trash_number, trash_total]
