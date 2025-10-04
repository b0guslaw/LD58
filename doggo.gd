@tool
extends CharacterBody3D

@export var detection_range = 10.0:
	set(value):
		detection_range = value
		update_debug_cone()
@export var detection_angle = 45.0:
	set(value):
		detection_angle = value
		update_debug_cone()
@export var move_speed = 3.0

var raycast: RayCast3D
var debug_cone: CSGCylinder3D
var player: Node3D
var can_see_player = false

func _ready():
	raycast = $RayCast3D
	debug_cone = $debug_vision_cone/CSGCylinder3D
	player = get_tree().get_first_node_in_group("player")
	update_debug_cone()

func update_debug_cone():
	if not debug_cone:
		return
		
	debug_cone.height = detection_range
	var radius = tan(deg_to_rad(detection_angle)) * detection_range
	debug_cone.radius = radius
	debug_cone.position.z = detection_range / 2.0

func _physics_process(delta):
	can_see_player = check_player_seen()
	
	if can_see_player:
		print("SPOTTED")
		# TODO chase
	else:
		# TODO patrol
		pass
		
	move_and_slide()

func check_player_seen() -> bool:
	if not player:
		return false
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	if distance > detection_range:
		return false
		
	var forward = global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_player.normalized()))
	if angle > detection_angle:
		return false
	
	# check for obstacles with raycast
	raycast.target_position = to_player
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		return hit.is_in_group("player")
	
	return false
