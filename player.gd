extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_force: float = 4.5
@export var gravity: float = 9.8

func _physics_process(delta: float) -> void:
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	# Rotate input relative to camera
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
