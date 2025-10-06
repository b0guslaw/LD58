extends Camera3D

## Orbiting camera for main menu
## Orbits around enemies in the scene

@export var orbit_radius: float = 8.0
@export var orbit_height: float = 5.0
@export var orbit_speed: float = 0.5
@export var time_per_enemy: float = 5.0
@export var transition_speed: float = 1.0
@export var fade_duration: float = 0.5

var angle: float = 0.0
var enemies: Array = []
var current_enemy_index: int = 0
var time_on_current: float = 0.0
var target_position: Vector3
var is_transitioning: bool = false

func _ready() -> void:
	ScreenFade.fade_out()
	await ScreenFade.fade_out_complete
	make_current()
	
	await get_tree().process_frame
	enemies = get_tree().get_nodes_in_group("enemies")
	
	var enemy = enemies[0]
	if is_instance_valid(enemy):
		var orbit_center = enemy.global_position
		var x = orbit_center.x + cos(angle) * orbit_radius
		var z = orbit_center.z + sin(angle) * orbit_radius
		var y = orbit_center.y + orbit_height
		global_position = Vector3(x, y, z)
		look_at(orbit_center, Vector3.UP)
	
	ScreenFade.fade_in()
	await ScreenFade.fade_in_complete

	await get_tree().process_frame
	enemies = get_tree().get_nodes_in_group("enemies")

func _process(delta: float) -> void:
	if enemies.size() == 0 or is_transitioning:
		return
	
	time_on_current += delta
	angle += orbit_speed * delta
	
	if time_on_current >= time_per_enemy:
		switch_to_next_enemy()

	if angle > TAU:
		angle -= TAU
	
	update_camera_position(delta)

func update_camera_position(delta: float) -> void:
	if current_enemy_index >= enemies.size():
		return
	
	var enemy = enemies[current_enemy_index]
	if not is_instance_valid(enemy):
		switch_to_next_enemy()
		return
	
	var orbit_center = enemy.global_position
	
	var x = orbit_center.x + cos(angle) * orbit_radius
	var z = orbit_center.z + sin(angle) * orbit_radius
	var y = orbit_center.y + orbit_height
	
	target_position = Vector3(x, y, z)
	global_position = global_position.lerp(target_position, transition_speed * delta)
	look_at(orbit_center, Vector3.UP)

func set_target_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	
	current_enemy_index = index
	time_on_current = 0.0
	angle = randf() * TAU

func switch_to_next_enemy() -> void:
	is_transitioning = true
	if ScreenFade:
		ScreenFade.fade_out()
		await ScreenFade.fade_out_complete
	else:
		await get_tree().create_timer(fade_duration).timeout

	current_enemy_index = (current_enemy_index + 1) % enemies.size()

	var attempts = 0
	while attempts < enemies.size() and not is_instance_valid(enemies[current_enemy_index]):
		current_enemy_index = (current_enemy_index + 1) % enemies.size()
		attempts += 1
	
	set_target_enemy(current_enemy_index)

	if current_enemy_index < enemies.size():
		var enemy = enemies[current_enemy_index]
		if is_instance_valid(enemy):
			var orbit_center = enemy.global_position
			var x = orbit_center.x + cos(angle) * orbit_radius
			var z = orbit_center.z + sin(angle) * orbit_radius
			var y = orbit_center.y + orbit_height
			global_position = Vector3(x, y, z)
			look_at(orbit_center, Vector3.UP)

	ScreenFade.fade_in()
	await ScreenFade.fade_in_complete
	
	is_transitioning = false
