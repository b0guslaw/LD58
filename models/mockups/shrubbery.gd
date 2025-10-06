extends Node3D

@export var wobble_strength: float = 0.12
@export var wobble_speed: float = 25.0
@export var wobble_duration: float = 0.4 

var original_rotation: Vector3
var wobble_time: float = 0.0
var wobble_direction: Vector3 = Vector3.ZERO
var is_wobbling: bool = false

func _ready() -> void:
	original_rotation = rotation

func _process(delta: float) -> void:
	if is_wobbling:
		wobble_time += delta
		
		var progress = wobble_time / wobble_duration
		var damping = 1.0 - progress
		
		# Sin wave for back-and-forth
		var shake = sin(wobble_time * wobble_speed) * wobble_strength * damping

		rotation.x = original_rotation.x + wobble_direction.z * shake
		rotation.z = original_rotation.z + wobble_direction.x * shake
		rotation.y = original_rotation.y + wobble_direction.y * shake

		if wobble_time >= wobble_duration:
			rotation = original_rotation
			is_wobbling = false
			wobble_time = 0.0

func trigger_wobble(player: Node3D) -> void:
	if is_wobbling:
		return

	var direction_from_player = (global_position - player.global_position).normalized()

	direction_from_player.x += randf_range(-0.3, 0.3)
	direction_from_player.z += randf_range(-0.3, 0.3)
	direction_from_player = direction_from_player.normalized()
	
	wobble_direction = direction_from_player
	wobble_time = 0.0
	is_wobbling = true

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		trigger_wobble(body)
