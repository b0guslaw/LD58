@tool
extends CharacterBody3D

@export var detection_range = 10.0:
	set(value):
		detection_range = value
		update_debug_tools()
@export var detection_angle = 45.0:
	set(value):
		detection_angle = value
		update_debug_tools()
@export var wander_speed = 2.0
@export var wander_range = 10.0: #raidus of wander from start pos
	set(value):
		wander_range = value
		update_debug_tools()
@export var wander_target_threshold = 1.0 # how close to the target to be "there"
@export var wander_pause_time = 2.0
@export var wander_pause_variance = 2.0
@export var stuck_timeout = 1.0
@export var stuck_threshold = 0.1

var start_position: Vector3
var debug_range: CSGCylinder3D
var wander_target: Vector3
var debug_wander_target: CSGCylinder3D
var wander_timer: float = 0.0
var is_wandering = false
var last_position: Vector3
var stuck_timer: float = 0.0

var raycast: RayCast3D
var debug_cone: CSGCylinder3D
var player: Node3D
var can_see_player = false

func _ready():
	raycast = $RayCast3D
	debug_cone = $debug_vision_cone/CSGCylinder3D
	debug_range = $debug_wander_range/CSGCylinder3D
	debug_range.top_level = true
	debug_wander_target = $debug_wander_target/CSGCylinder3D
	debug_wander_target.top_level = true
	player = get_tree().get_first_node_in_group("player")
	start_position = global_position
	last_position = start_position
	choose_new_wander_target()
	update_debug_tools()

func update_debug_tools():
	if not debug_cone or not debug_range or not debug_wander_target:
		return
		
	debug_cone.height = detection_range
	var radius = tan(deg_to_rad(detection_angle)) * detection_range
	debug_cone.radius = radius
	debug_cone.position.z = detection_range / 2.0
	
	debug_range.global_position = start_position
	debug_range.radius = wander_range
	
	debug_wander_target.global_position = wander_target

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	
	can_see_player = check_player_seen()
	
	if can_see_player:
		print("SPOTTED")
		# TODO chase
	else:
		wander(delta)
		
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
	raycast.target_position = raycast.to_local(player.global_position)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		return hit.is_in_group("player")
	
	return false

func choose_new_wander_target():
	var rand_angle = randf() * TAU
	var rand_dist = randf() * wander_range
	
	var rand_offset = Vector3(
		cos(rand_angle) * rand_dist,
		0,
		sin(rand_angle) * rand_dist
	)
	
	var desired_target = start_position + rand_offset
	desired_target.y = global_position.y + raycast.position.y
	
	raycast.target_position = raycast.to_local(desired_target)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var direction = (hit_point - global_position).normalized()
		wander_target = hit_point - direction * 0.5
	else:
		#no hits, clear path
		wander_target = desired_target
	
	update_debug_tools()
	
func wander(delta):
	if wander_timer > 0: # waiting
		wander_timer -= delta
		velocity = Vector3.ZERO
		stuck_timer = 0
		last_position = global_position
		return
		
	#move toward target
	var direction = (wander_target - global_position)
	direction.y = 0 # stick to the ground for now...
	
	if direction.length() < wander_target_threshold:
		var variance = randf_range(-wander_pause_variance, wander_pause_time)
		wander_timer = wander_pause_time + variance
		choose_new_wander_target()
		return
	
	direction = direction.normalized()
	var expected_movement = wander_speed * delta
	velocity.x = direction.x * wander_speed
	velocity.z = direction.z * wander_speed
	
	var distance_moved = global_position.distance_to(last_position)
	
	if distance_moved < expected_movement * stuck_threshold: #moving slower than normal
		stuck_timer += delta
		if stuck_timer > stuck_timeout:
			print("doggo got stuck, picking new target")
			choose_new_wander_target()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
		
	last_position = global_position
	
	if direction.length() > 0:
		look_at(global_position - direction, Vector3.UP)
