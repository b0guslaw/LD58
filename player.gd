extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_force: float = 4.5
@export var gravity: float = 9.8
@export var interact_key := "interact"
@onready var camera_pivot = $CameraPivot
@onready var spring_arm = $CameraPivot/SpringArm3D

var interactable_in_range: Area3D = null
var mouse_sensitivity: float = 0.3
var vertical_angle: float = 0.0
var horizontal_angle: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		horizontal_angle -= event.relative.x * mouse_sensitivity
		vertical_angle -= event.relative.y * mouse_sensitivity
		vertical_angle = clamp(vertical_angle, -80.0, 80.0)
		camera_pivot.rotation_degrees = Vector3(vertical_angle, horizontal_angle, 0)

func _physics_process(delta: float) -> void:
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_back"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if Input.is_action_just_pressed(interact_key) and interactable_in_range:
		interactable_in_range.interact()

	input_dir = input_dir.normalized()

	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_basis = cam.global_transform.basis
		var forward = -cam_basis.z
		var right = cam_basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		input_dir = (forward * input_dir.z + right * input_dir.x).normalized()

	var velocity = self.velocity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force

	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed

	self.velocity = velocity
	move_and_slide()
