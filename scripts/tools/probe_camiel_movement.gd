# probe_camiel_movement.gd
# Headless behaviour probe for FOUND-05: drives Camiel through the real
# physical InputMap keys and asserts movement, jump, and camera-follow
# behaviour. Run by scripts/tools/run_headless_check.sh.
extends SceneTree

const MAX_TOTAL_FRAMES := 3000
const SPAWN_POSITION := Vector3(0, 0, 2)
const ALL_KEYS := [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE]

# Mirrors camiel_controller.gd's SteeringMode enum order (CAMERA_RELATIVE = 0,
# TURN_AND_WALK = 1); the probe has no class_name to import the enum type by.
const STEERING_CAMERA_RELATIVE := 0
const STEERING_TURN_AND_WALK := 1

var _camiel: CharacterBody3D
var _spring_arm: SpringArm3D
var _camera: Camera3D
var _total_frames := 0
var _failed := false

# State for _case_fall_at_edge(). GDScript lambdas capture outer locals by
# value, not by reference, so a `func(x): fire_count += 1` closure never
# mutates a local `fire_count` — these must be script-level fields, updated
# by a real bound method (_on_return_for_fall_edge), to observe the signal.
var _fall_fire_count := 0
var _fall_returned_position := Vector3.ZERO


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/test_space.tscn")
	if packed == null:
		push_error("Could not load res://scenes/test_space.tscn")
		quit(1)
		return

	var test_space: Node = packed.instantiate()
	root.add_child(test_space)

	# Wait for Camiel's _ready() (which assigns its @onready camera nodes) to
	# run before touching it — add_child() enters the tree synchronously, but
	# _ready() notifications are deferred to the end of the frame.
	await process_frame

	_camiel = test_space.get_node_or_null("Camiel") as CharacterBody3D
	if _camiel == null:
		push_error("Camiel node not found in test_space.tscn")
		quit(1)
		return

	_spring_arm = _camiel.get_node_or_null("CameraPivot/SpringArm3D") as SpringArm3D
	_camera = _camiel.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	if _spring_arm == null or _camera == null:
		push_error("Camiel is missing CameraPivot/SpringArm3D/Camera3D")
		quit(1)
		return

	_run_cases()


func _run_cases() -> void:
	await _case_early_fall()
	if _failed:
		return
	await _case_idle()
	if _failed:
		return
	await _case_forward()
	if _failed:
		return
	await _case_same_direction_keys()
	if _failed:
		return
	await _case_opposite_keys()
	if _failed:
		return
	await _case_jump()
	if _failed:
		return
	await _case_camera_behind()
	if _failed:
		return
	await _case_fall_at_edge()
	if _failed:
		return
	await _case_soft_return()
	if _failed:
		return
	await _case_wall()
	if _failed:
		return
	await _case_turn_and_walk()
	if _failed:
		return
	await _case_arguments()
	if _failed:
		return

	print("Camiel movement probe passed.")
	quit(0)


func _fail(case_name: String, detail: String) -> void:
	_failed = true
	push_error("%s: %s" % [case_name, detail])
	quit(1)


func _send_key(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _release_all_keys() -> void:
	for keycode: int in ALL_KEYS:
		_send_key(keycode, false)


func _reset(position: Vector3 = SPAWN_POSITION, steering_mode: int = STEERING_CAMERA_RELATIVE) -> void:
	_release_all_keys()
	_camiel.steering_mode = steering_mode
	_camiel.teleport_to(position)


func _wait_frames(count: int) -> void:
	for _i in range(count):
		if _failed:
			return
		_total_frames += 1
		if _total_frames > MAX_TOTAL_FRAMES:
			_fail("frame_budget", "probe exceeded frame budget")
			return
		await physics_frame


func _horizontal(a: Vector3, b: Vector3) -> Vector2:
	return Vector2(b.x - a.x, b.z - a.z)


func _case_idle() -> void:
	_reset()
	var start := _camiel.global_position
	await _wait_frames(60)
	if _failed:
		return
	var horizontal := _horizontal(start, _camiel.global_position)
	if horizontal.length() >= 0.01:
		_fail("idle", "horizontal movement %.4f m >= 0.01 m with no input" % horizontal.length())
		return
	if not _camiel.is_on_floor():
		_fail("idle", "is_on_floor() is false with no input")
		return
	print("PASS idle")


func _case_forward() -> void:
	_reset()
	await _wait_frames(2)
	if _failed:
		return
	var camera_forward: Vector3 = -_camera.global_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var start := _camiel.global_position
	_send_key(KEY_W, true)
	await _wait_frames(60)
	_send_key(KEY_W, false)
	if _failed:
		return
	var forward_delta := (_camiel.global_position - start).dot(camera_forward)
	if forward_delta <= 0.5:
		_fail("forward", "forward displacement %.4f m <= 0.5 m" % forward_delta)
		return
	print("PASS forward")


func _case_same_direction_keys() -> void:
	_reset()
	_send_key(KEY_W, true)
	_send_key(KEY_UP, true)
	await _wait_frames(60)
	_send_key(KEY_W, false)
	_send_key(KEY_UP, false)
	if _failed:
		return
	var horizontal_speed := Vector2(_camiel.velocity.x, _camiel.velocity.z).length()
	var walk_speed: float = _camiel.walk_speed
	if horizontal_speed > walk_speed + 0.05:
		_fail("same_direction_keys", "horizontal speed %.4f m/s > walk_speed + 0.05 (%.4f)" % [horizontal_speed, walk_speed + 0.05])
		return
	print("PASS same_direction_keys")


func _case_opposite_keys() -> void:
	_reset()
	var start := _camiel.global_position
	_send_key(KEY_A, true)
	_send_key(KEY_D, true)
	await _wait_frames(30)
	_send_key(KEY_A, false)
	_send_key(KEY_D, false)
	if _failed:
		return
	var horizontal := _horizontal(start, _camiel.global_position)
	if horizontal.length() >= 0.05:
		_fail("opposite_keys", "horizontal movement %.4f m >= 0.05 m" % horizontal.length())
		return
	print("PASS opposite_keys")


func _case_jump() -> void:
	_reset()
	await _wait_frames(2)
	if _failed:
		return
	var start_y := _camiel.global_position.y
	var max_height := start_y
	var reached_height := false
	_send_key(KEY_SPACE, true)
	for i in range(30):
		await _wait_frames(1)
		if _failed:
			return
		if i == 0:
			_send_key(KEY_SPACE, false)
		max_height = max(max_height, _camiel.global_position.y)
		if max_height - start_y > 0.3:
			reached_height = true
	if not reached_height:
		_fail("jump", "did not rise over 0.3 m within 30 frames (max %.4f m)" % (max_height - start_y))
		return
	var landed := false
	for _i in range(120):
		await _wait_frames(1)
		if _failed:
			return
		if _camiel.is_on_floor():
			landed = true
			break
	if not landed:
		_fail("jump", "did not return to floor within 120 frames")
		return
	print("PASS jump")


func _case_camera_behind() -> void:
	_reset()
	_send_key(KEY_W, true)
	await _wait_frames(180)
	_send_key(KEY_W, false)
	if _failed:
		return
	var to_camiel: Vector3 = _camiel.global_position - _camera.global_position
	var flat_to_camiel := Vector3(to_camiel.x, 0.0, to_camiel.z)
	var facing: Vector3 = -_camiel.global_basis.z
	facing.y = 0.0
	var dot := flat_to_camiel.normalized().dot(facing.normalized())
	if dot <= 0.0:
		_fail("camera_behind", "camera is not behind Camiel (dot %.4f)" % dot)
		return
	var distance := to_camiel.length()
	var spring_length: float = _spring_arm.spring_length
	if distance < 1.0 or distance > spring_length + 1.5:
		_fail("camera_behind", "camera distance %.4f m not within [1.0, %.4f]" % [distance, spring_length + 1.5])
		return
	print("PASS camera_behind")


func _case_early_fall() -> void:
	# No _reset() here on purpose: this proves the behaviour on the very
	# first probe frame, before any case has ever teleported Camiel or given
	# _sample_safe_spot a chance to record a spot away from spawn.
	_camiel.steering_mode = STEERING_CAMERA_RELATIVE
	_camiel.return_to_safe_spot()
	var horizontal := _horizontal(SPAWN_POSITION, _camiel.global_position)
	if horizontal.length() >= 0.01 or absf(_camiel.global_position.y - SPAWN_POSITION.y) >= 0.5:
		_fail("early_fall", "return_to_safe_spot() before any spot was sampled did not return to spawn (%s)" % _camiel.global_position)
		return
	print("PASS early_fall")


func _on_return_for_fall_edge(position: Vector3) -> void:
	_fall_fire_count += 1
	_fall_returned_position = position


func _case_fall_at_edge() -> void:
	_reset(Vector3(4, 0, 0))
	await _wait_frames(2)
	if _failed:
		return

	_fall_fire_count = 0
	_fall_returned_position = Vector3.ZERO
	_camiel.returned_to_safe_spot.connect(_on_return_for_fall_edge)

	_send_key(KEY_D, true)
	var fired := false
	for _i in range(300):
		await _wait_frames(1)
		if _failed:
			_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
			return
		if _fall_fire_count >= 1:
			fired = true
			break
	_send_key(KEY_D, false)

	if not fired:
		_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
		_fail("fall_at_edge", "returned_to_safe_spot did not fire within 300 frames")
		return

	if _fall_returned_position.x > 5.30:
		_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
		_fail("fall_at_edge", "returned x %.4f m > 5.30 m" % _fall_returned_position.x)
		return

	var velocity_magnitude: float = _camiel.velocity.length()
	if velocity_magnitude > 0.5:
		_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
		_fail("fall_at_edge", "velocity not settled after return: %.4f m/s" % velocity_magnitude)
		return

	var drift_start := _camiel.global_position
	for _i in range(120):
		await _wait_frames(1)
		if _failed:
			_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
			return
	var drift := _horizontal(drift_start, _camiel.global_position)
	if drift.length() >= 0.05:
		_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
		_fail("fall_at_edge", "horizontal drift %.4f m >= 0.05 m after return" % drift.length())
		return

	if _fall_fire_count != 1:
		_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
		_fail("fall_at_edge", "returned_to_safe_spot fired %d times, expected exactly 1" % _fall_fire_count)
		return

	_camiel.returned_to_safe_spot.disconnect(_on_return_for_fall_edge)
	print("PASS fall_at_edge")


func _case_soft_return() -> void:
	_reset()
	# Let a safe spot register at the spawn location before triggering a
	# controlled return, so this case focuses on the sound/camera assertions
	# rather than repeating fall_at_edge's edge-walk.
	await _wait_frames(20)
	if _failed:
		return

	var pivot: Node3D = _camiel.get_node("CameraPivot")
	_camiel.return_to_safe_spot()

	var return_sound: AudioStreamPlayer = _camiel.get_node("ReturnSound")
	if not return_sound.playing:
		_fail("soft_return", "ReturnSound.playing is false right after the return")
		return

	var stream := return_sound.stream
	if not (stream is AudioStreamWAV):
		_fail("soft_return", "ReturnSound.stream is not an AudioStreamWAV")
		return
	if (stream as AudioStreamWAV).get_length() > 0.5:
		_fail("soft_return", "ReturnSound.stream is longer than 0.5 s (%.4f s)" % (stream as AudioStreamWAV).get_length())
		return

	var expected_pivot_position := _camiel.global_position + Vector3(0, 1.0, 0)
	if pivot.global_position.distance_to(expected_pivot_position) > 0.01:
		_fail("soft_return", "CameraPivot is not within 0.01 m of its resting offset after the return")
		return

	print("PASS soft_return")


func _case_wall() -> void:
	_release_all_keys()
	_camiel.steering_mode = STEERING_CAMERA_RELATIVE
	_camiel.rotation.y = PI
	_camiel.teleport_to(Vector3(0, 0, -4.8))
	await _wait_frames(30)
	if _failed:
		return
	var hit_length: float = _spring_arm.get_hit_length()
	var threshold: float = _spring_arm.spring_length - 0.5
	if hit_length >= threshold:
		_fail("wall", "spring arm hit length %.4f m not below spring_length - 0.5 (%.4f m)" % [hit_length, threshold])
		return
	print("PASS wall")


func _case_turn_and_walk() -> void:
	_reset(SPAWN_POSITION, STEERING_TURN_AND_WALK)
	await _wait_frames(2)
	if _failed:
		return

	var start_yaw := _camiel.rotation.y
	var start_pos := _camiel.global_position
	_send_key(KEY_D, true)
	await _wait_frames(30)
	_send_key(KEY_D, false)
	if _failed:
		return

	var yaw_delta := absf(wrapf(_camiel.rotation.y - start_yaw, -PI, PI))
	if yaw_delta <= 0.3:
		_fail("turn_and_walk", "rotation.y changed by %.4f rad <= 0.3 rad while turning" % yaw_delta)
		return
	var turn_horizontal := _horizontal(start_pos, _camiel.global_position)
	if turn_horizontal.length() >= 0.05:
		_fail("turn_and_walk", "horizontal movement %.4f m >= 0.05 m while turning in place" % turn_horizontal.length())
		return

	var pivot: Node3D = _camiel.get_node("CameraPivot")
	var pivot_yaw_diff := absf(wrapf(pivot.rotation.y - _camiel.rotation.y, -PI, PI))
	if pivot_yaw_diff > 0.05:
		_fail("turn_and_walk", "camera pivot yaw diverges from rotation.y by %.4f rad while turning" % pivot_yaw_diff)
		return

	var walk_start := _camiel.global_position
	_send_key(KEY_W, true)
	await _wait_frames(60)
	_send_key(KEY_W, false)
	if _failed:
		return

	var forward_vec: Vector3 = -_camiel.global_basis.z
	var forward_delta := (_camiel.global_position - walk_start).dot(forward_vec)
	if forward_delta <= 0.5:
		_fail("turn_and_walk", "forward displacement %.4f m <= 0.5 m while walking" % forward_delta)
		return

	pivot_yaw_diff = absf(wrapf(pivot.rotation.y - _camiel.rotation.y, -PI, PI))
	if pivot_yaw_diff > 0.05:
		_fail("turn_and_walk", "camera pivot yaw diverges from rotation.y by %.4f rad after walking" % pivot_yaw_diff)
		return

	print("PASS turn_and_walk")


func _case_arguments() -> void:
	_reset()
	_camiel.apply_steering_arguments(PackedStringArray(["--steering=turn_and_walk"]))
	if _camiel.steering_mode != STEERING_TURN_AND_WALK:
		_fail("arguments", "apply_steering_arguments did not select turn_and_walk")
		return
	_camiel.apply_steering_arguments(PackedStringArray(["--steering=sideways"]))
	if _camiel.steering_mode != STEERING_TURN_AND_WALK:
		_fail("arguments", "an unknown --steering value changed the mode")
		return
	_camiel.steering_mode = STEERING_CAMERA_RELATIVE
	print("PASS arguments")
