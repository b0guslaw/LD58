extends CanvasLayer

signal all_garbage_collected

@onready var trash_counter: Label = $TrashCounter

var trash_total: int = 0 # this is dynamically updated to count all garbage

func _ready():
	set_up_trash_ui()

func update_trash_ui(trash_number: int):
	trash_counter.text = "Trash %d / %d" % [trash_number, trash_total]
	if trash_number == trash_total:
		all_garbage_collected.emit()

func set_up_trash_ui():
	trash_total = get_tree().get_nodes_in_group("interactables").size()
	update_trash_ui(0)
