# probe_camiel_movement.gd
# Headless behaviour probe for FOUND-05: drives Camiel through the real
# physical InputMap keys and asserts movement, jump, and camera-follow
# behaviour. Run by scripts/tools/run_headless_check.sh.
extends SceneTree

const MAX_TOTAL_FRAMES := 3000
const SPAWN_POSITION := Vector3(0, 0, 2)
const ALL_KEYS := [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE]

var _camiel: CharacterBody3D
var _spring_arm: SpringArm3D
var _camera: Camera3D
var _total_frames := 0
var _failed := false


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


func _reset() -> void:
	_release_all_keys()
	_camiel.teleport_to(SPAWN_POSITION)


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
