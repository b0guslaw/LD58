extends StaticBody3D

@export var interaction_time: float = 2.0  # How long the interaction takes

var interaction_timer: Timer
var interacting_player: Node3D = null

func _ready() -> void:
	# Create and setup timer
	interaction_timer = Timer.new()
	interaction_timer.one_shot = true
	interaction_timer.timeout.connect(_on_interaction_timer_timeout)
	add_child(interaction_timer)

func start_interaction(player: Node3D) -> void:
	interacting_player = player
	interaction_timer.start(interaction_time)
	print("Interaction started, will complete in ", interaction_time, " seconds")
	# Optional: Add visual feedback here (progress bar, animation, etc.)

func cancel_interaction() -> void:
	interaction_timer.stop()
	interacting_player = null
	print("Interaction cancelled")
	# Optional: Reset visual feedback here

func _on_interaction_timer_timeout() -> void:
	if interacting_player != null and interacting_player.has_method("on_interaction_complete"):
		interacting_player.on_interaction_complete(self)
		print("Interaction completed!")
		interacting_player = null
		# Optional: Add completion effects here
