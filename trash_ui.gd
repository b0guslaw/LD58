extends CanvasLayer

signal all_garbage_collected

@onready var trash_counter: Label = $TrashCounter
@onready var trash_timer: Label = $TrashTimer
@onready var timer: Timer = $Timer

var trash_total: int = 0 # this is dynamically updated to count all garbage
var trash_time: float = 0.0
var timer_running: bool = false

func _ready():
	trash_timer.text = "00:00"
	timer.timeout.connect(_on_timer_tick)
	timer.wait_time = 1.0
	timer.one_shot = false

func update_trash_ui(trash_number: int):
	trash_counter.text = "Trash %d / %d" % [trash_number, trash_total]
	if trash_number == 1:
		all_garbage_collected.emit()

func set_up_trash_ui():
	trash_counter.visible = true
	trash_total = get_tree().get_nodes_in_group("interactables").size()
	update_trash_ui(0)
	
func reset_trash_timer():
	trash_time = 0.0
	_update_trash_timer_label()

func start_trash_timer():
	trash_time = 0.0
	timer.start()
	timer_running = true

func stop_trash_timer():
	timer.stop()
	timer_running = false

func _on_timer_tick():
	if timer_running:
		trash_time += 1
		_update_trash_timer_label()
		
func _update_trash_timer_label():
	var minutes = int(trash_time) / 60
	var seconds = int(trash_time) % 60
	trash_timer.text = "%02d:%02d" % [minutes, seconds]
