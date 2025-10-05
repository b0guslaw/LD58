@tool
extends CharacterBody3D

@export var rotation_speed_rads = 5.0
@export var detection_range = 10.0:
	set(value):
		detection_range = value
		update_debug_tools()
@export var detection_angle = 45.0:
	set(value):
		detection_angle = value
		update_debug_tools()
@export var chase_speed = 4.0
@export var chase_give_up_time = 7.0
@export var chase_give_up_variance = 2.0
@export var chase_rotate_time = 1.0
@export var knockback_power = 10.0
@export var wander_speed = 2.0
@export var wander_range = 10.0: #raidus of wander from start pos
	set(value):
		wander_range = value
		update_debug_tools()
@export var wander_target_threshold = 1.0 # how close to the target to be "there"
@export_tool_button(
	"Reset Wander Indicator", 
	"CSGCylinder3D"
	) var reset_wander_debug: Callable = Callable(self, "_reset_wander_debug")
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
var chase_timer: float = 0.0
var search_timer: float = 0.0
var search_direction: Vector3
var last_known_pos: Vector3
var was_seeing_player_last_frame = false

signal player_spotted
signal player_lost

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

func _reset_wander_debug():
	start_position = global_position
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
	
	# checking if currently chasing player for signals
	if can_see_player and not was_seeing_player_last_frame:
		player_spotted.emit()
	if not can_see_player and was_seeing_player_last_frame:
		player_lost.emit()
	
	was_seeing_player_last_frame = can_see_player
	
	if can_see_player:
		var variance = randf_range(-chase_give_up_variance, chase_give_up_variance)
		chase_timer = chase_give_up_time + variance
		search_timer = 0.0
		last_known_pos = player.global_position
	
	if chase_timer > 0:
		if not can_see_player:
			chase_timer -= delta
		if chase_timer > 0:
			chase(delta)
		else:
			velocity = Vector3.ZERO
	else:
		wander(delta)
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(global_position, knockback_power)
	
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

func chase(delta):
	var direction = (last_known_pos - global_position)
	direction.y = 0
	
	if direction.length() > wander_target_threshold:
		direction = direction.normalized()
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed
		smooth_look_at(direction, delta)
		if check_if_stuck(delta, chase_speed):
			last_known_pos = global_position
			search_timer = 0.0
	else:
		search_behavior(delta)

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
		search_behavior(delta)
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
	velocity.x = direction.x * wander_speed
	velocity.z = direction.z * wander_speed
	
	if check_if_stuck(delta, wander_speed):
		choose_new_wander_target()
	
	smooth_look_at(direction, delta)

func search_behavior(delta):
	velocity = Vector3.ZERO
	search_timer -= delta
	if search_timer <= 0:
		var random_angle = randf() * TAU
		search_direction = Vector3(cos(random_angle), 0, sin(random_angle))
		search_timer = chase_rotate_time
	smooth_look_at(search_direction, delta)

func check_if_stuck(delta, expected_speed: float) -> bool:
	var expected_movement = expected_speed * delta
	var distance_moved = global_position.distance_to(last_position)
	if distance_moved < expected_movement * stuck_threshold:
		stuck_timer += delta
		if stuck_timer > stuck_timeout:
			print("Dog got stuck.")
			stuck_timer = 0.0
			return true
	else:
		stuck_timer = 0.0
	last_position = global_position
	return false

func smooth_look_at(target_direction: Vector3, delta: float):
	if target_direction.length() < 0.01:
		return
	target_direction = target_direction.normalized()
	var current_forward = global_transform.basis.z
	var angle = current_forward.signed_angle_to(target_direction, Vector3.UP)
	var max_rotation = rotation_speed_rads * delta
	angle = clamp(angle, -max_rotation, max_rotation)
	rotate_y(angle)
