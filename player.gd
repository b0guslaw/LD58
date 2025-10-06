extends CharacterBody3D

@onready var animation_player = $trash_panda/AnimationPlayer

@export_range(0.0, 2.0) var anim_blend_time = 0.5
@export_category("Movement Settings")
@export var speed: float = 10.0
@export var acceleration: float = 30.0
@export var friction: float = 30.0
@export var jump_force: float = 6.0
@export var gravity: float = 14.0

@export_category("Camera Settings")
@export var mouse_sensitivity: float = 0.8
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

@export_category("FOV & Shake Settings")
@export var normal_fov = 75.0
@export var chase_fov = 82.0
@export var fov_lerp_speed = 2.0
@export var shake_amt_range: Vector2i = Vector2i(4,10)
@export var shake_strength = 0.1

@onready var camera_pivot = $CameraPivot
@onready var spring_arm = $CameraPivot/SpringArm3D
@onready var camera = $CameraPivot/SpringArm3D/Camera3D

var pitch: float = 0.0
var yaw: float = 0.0
var interactables_in_range: Array[Node3D] = []
var current_interaction: Node3D = null

var is_alive = true
var is_being_chased = false
var trash_counter: int = 0;
var is_hidden: bool = false

signal player_died

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	yaw = camera_pivot.global_rotation.y
	pitch = camera_pivot.global_rotation.x
	animation_player.play("Idle")
	camera_pivot.top_level = true
	TrashUi.update_trash_ui(trash_counter)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity * 0.01
		pitch -= event.relative.y * mouse_sensitivity * 0.01
		pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	if event.is_action_pressed("interact") and interactables_in_range.size() > 0 and current_interaction == null:
		start_interaction(interactables_in_range[0])

func _physics_process(delta: float) -> void:
	camera_pivot.global_position = global_position
	camera_pivot.global_rotation.y = yaw
	camera_pivot.global_rotation.x = pitch
	
	if not is_alive:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return # skip input processing
	
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
	
	var accel = acceleration if is_on_floor() else acceleration * 0.6
	var fric = friction if is_on_floor() else friction * 0.3
	
	if move_dir.length() > 0:
		velocity.x = lerp(velocity.x, target_velocity.x, accel * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, accel * delta)

		if is_on_floor():
			var target_rotation = atan2(move_dir.x, move_dir.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)

		if is_on_floor() and animation_player.current_animation != "Walk":
			animation_player.play("Walk", anim_blend_time)
	else:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, fric * delta)
			velocity.z = lerp(velocity.z, 0.0, fric * delta)
			animation_player.play("Idle", anim_blend_time)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.01
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		animation_player.play("Jump", anim_blend_time)
		velocity.y = jump_force
	
	move_and_slide()
func set_being_chased(chased: bool):
	is_being_chased = chased
	if is_being_chased:
		apply_spot_shake()

func apply_spot_shake():
	print("shake")
	var original_pos = camera.position
	var shake_count = randf_range(shake_amt_range.x, shake_amt_range.y)

	for i in shake_count:
		var offset = Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength * 0.5, shake_strength * 0.5),
			0
		)
		var time = randf_range(shake_strength * 0.5, shake_strength)
		await create_tween().tween_property(camera, "position", original_pos + offset, time).finished

	# Return to center
	create_tween().tween_property(camera, "position", original_pos, 0.1)

func take_damage(attacker_pos: Vector3, knockback_power: float):
	if is_alive:
		print("player caught by doggo")
		player_died.emit()
		animation_player.play("Dead", anim_blend_time)
		
	is_alive = false
	var knockback_dir = (global_position - attacker_pos).normalized()
	velocity = knockback_dir * knockback_power

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
		TrashUi.update_trash_ui(trash_counter)
		interactables_in_range.erase(interactable)

func _on_interaction_body_entered(body: Node3D) -> void:
	if body.is_in_group("interactables"):
		if not interactables_in_range.has(body):
			interactables_in_range.append(body)

func _on_interaction_body_exited(body: Node3D) -> void:
	if body.is_in_group("interactables"):
		interactables_in_range.erase(body)
		
		if body == current_interaction:
			interrupt_interaction()
			
func set_hidden(hidden: bool) -> void:
	is_hidden = hidden

func is_hiding() -> bool:
	return is_hidden
