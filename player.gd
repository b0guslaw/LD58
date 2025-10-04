extends CharacterBody3D

# --- Movement Settings ---
@export var speed: float = 10.0
@export var acceleration: float = 30.0
@export var friction: float = 15.0
@export var jump_force: float = 6.0
@export var gravity: float = 14.0

# --- Camera Settings ---
@export var mouse_sensitivity: float = 0.8
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

@onready var camera_pivot = $CameraPivot
@onready var spring_arm = $CameraPivot/SpringArm3D

var pitch: float = 0.0
var yaw: float = 0.0
var interactable_in_range: Node3D = null
var current_interaction: Node3D = null

var trash_counter: int = 0;

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	yaw = camera_pivot.global_rotation.y
	pitch = camera_pivot.global_rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity * 0.01
		pitch -= event.relative.y * mouse_sensitivity * 0.01
		pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	
	if event.is_action_pressed("interact") and interactable_in_range != null and current_interaction == null:
		start_interaction(interactable_in_range)

func _physics_process(delta: float) -> void:
	camera_pivot.global_rotation.y = yaw
	camera_pivot.global_rotation.x = pitch
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var move_dir = Vector3.ZERO
	
	if input_dir.length() > 0:
		var cam_forward = Vector3(sin(yaw), 0, cos(yaw))
		var cam_right = Vector3(cos(yaw), 0, -sin(yaw))
		move_dir = (cam_right * input_dir.x - cam_forward * input_dir.y).normalized()
		
		# Interrupt interaction if player moves
		if current_interaction != null:
			interrupt_interaction()
	
	var target_velocity = move_dir * speed
	
	if move_dir.length() > 0:
		velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
		
		var target_rotation = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.01
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	
	move_and_slide()

func start_interaction(interactable: Node3D) -> void:
	current_interaction = interactable
	print("Start interaction")
	if interactable.has_method("start_interaction"):
		interactable.start_interaction(self)

func interrupt_interaction() -> void:
	if current_interaction != null:
		if current_interaction.has_method("cancel_interaction"):
			current_interaction.cancel_interaction()
		print("Interrupted interaction with: ", current_interaction.name)
		current_interaction = null

func on_interaction_complete(interactable: Node3D) -> void:
	# Called by the interactable when interaction finishes
	if current_interaction == interactable:
		current_interaction = null
		trash_counter += 1
		print("Trash counter: ", trash_counter)

func _on_interaction_body_entered(body: Node3D) -> void:	
	if body.is_in_group("interactables"):
		interactable_in_range = body

func _on_interaction_body_exited(body: Node3D) -> void:	
	if body == interactable_in_range:
		interactable_in_range = null		
		if body == current_interaction:
			interrupt_interaction()
