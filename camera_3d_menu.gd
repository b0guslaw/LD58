extends Camera3D

## Orbiting camera for main menu

@export var orbit_center: Vector3 = Vector3(0, 5, 0)
@export var orbit_radius: float = 25.0
@export var orbit_height: float = 15.0
@export var orbit_speed: float = 0.3
@export var look_at_center: bool = true

var angle: float = 0.0

func _ready() -> void:
	make_current()
	update_camera_position()

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	# Keep angle in 0-2PI range
	if angle > TAU:
		angle -= TAU
	update_camera_position()

func update_camera_position() -> void:
	var x = orbit_center.x + cos(angle) * orbit_radius
	var z = orbit_center.z + sin(angle) * orbit_radius
	var y = orbit_center.y + orbit_height
	
	global_position = Vector3(x, y, z)

	if look_at_center:
		look_at(orbit_center, Vector3.UP)
