extends StaticBody3D

@export var interaction_time: float = 2.0
@export var empty_message_duration: float = 2.0  # How long "Empty" shows

var interaction_timer: Timer
var empty_message_timer: Timer
var interacting_player: Node3D = null
var can_loot: bool = true

@onready var timer_label: Label3D = $Label3D
@onready var trash_audio: AudioStreamPlayer3D = $TrashAudio

func _ready() -> void:
	interaction_timer = Timer.new()
	interaction_timer.one_shot = true
	interaction_timer.timeout.connect(_on_interaction_timer_timeout)
	add_child(interaction_timer)

	empty_message_timer = Timer.new()
	empty_message_timer.one_shot = true
	empty_message_timer.timeout.connect(_on_empty_message_timeout)
	add_child(empty_message_timer)
	
	# Hide label initially
	if timer_label:
		timer_label.visible = false

func _process(delta: float) -> void:
	if interacting_player != null and interaction_timer.time_left > 0:
		var time_remaining = interaction_timer.time_left
		timer_label.text = "%.1f" % time_remaining
		
		var progress = 1.0 - (time_remaining / interaction_time)
		
		# Color interpolation Red to Green
		var color = Color.RED.lerp(Color.GREEN, progress)
		timer_label.modulate = color

func start_interaction(player: Node3D) -> void:
	if can_loot == false: # Show empty message
		timer_label.visible = true
		timer_label.text = "Empty"
		timer_label.modulate = Color.GRAY
		empty_message_timer.start(empty_message_duration)
		return
	
	interacting_player = player
	interaction_timer.start(interaction_time)
	trash_audio.play()
	
	if timer_label:
		timer_label.visible = true
		timer_label.text = str(ceil(interaction_time))
		timer_label.modulate = Color.RED

func cancel_interaction() -> void:
	interaction_timer.stop()
	trash_audio.stop()
	interacting_player = null
	
	if timer_label:
		timer_label.visible = false

func _on_interaction_timer_timeout() -> void:
	if interacting_player != null and interacting_player.has_method("on_interaction_complete"):
		interacting_player.on_interaction_complete(self)
		
		can_loot = false # cant be looted again
		
		if timer_label:
			timer_label.visible = false
		
		interacting_player = null

func _on_empty_message_timeout() -> void:
	if timer_label:
		timer_label.visible = false
