# Real physics + animation integration probe. Optional rendered captures:
# Godot --path . --script scripts/tools/probe_camiel_model.gd -- --capture-dir=/tmp/camiel-model
extends SceneTree

var _failed := false
var _camiel: CharacterBody3D
var _visual: Node3D
var _player: AnimationPlayer
var _capture_dir := ""


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func() -> void:
		push_error("Camiel model probe exceeded frame/time budget")
		quit(1)
	)
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)


func _frames(count: int) -> void:
	for _i in count:
		await physics_frame
	await process_frame


func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _capture(label: String) -> void:
	if _capture_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(_capture_dir.path_join(label + ".png"))
	_check(error == OK, "Could not save rendered capture " + label)


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			_capture_dir = arg.trim_prefix("--capture-dir=")
	if not _capture_dir.is_empty():
		_check(DisplayServer.get_name() != "headless", "Capture mode requires a real renderer")
		DirAccess.make_dir_recursive_absolute(_capture_dir)

	# All player-bearing game scenes must resolve the shared imported model.
	var directory := DirAccess.open("res://scenes")
	var instance_count := 0
	for file: String in directory.get_files():
		if not file.ends_with(".tscn") or file == "camiel.tscn":
			continue
		var text := FileAccess.get_file_as_string("res://scenes/" + file)
		if not text.contains('path="res://scenes/camiel.tscn"'):
			continue
		var packed: PackedScene = load("res://scenes/" + file)
		var level := packed.instantiate()
		var actor := level.get_node_or_null("Camiel")
		_check(actor != null and actor.has_node("Visual/CamielModel/AnimationPlayer"), file + " missing model")
		_check(not actor.has_node("Body") and not actor.has_node("Nose"), file + " still has placeholder")
		instance_count += 1
		level.free()
	_check(instance_count >= 7, "Missing player-bearing scenes")
	print("PASS model instances: ", instance_count)

	var world: Node3D = load("res://scenes/test_space.tscn").instantiate()
	root.add_child(world)
	await _frames(4)
	_camiel = world.get_node("Camiel")
	_visual = _camiel.get_node("Visual")
	_player = _visual.get_node("CamielModel/AnimationPlayer")
	var leg: Node3D = _visual.find_child("FrontLeft", true, false)
	_check(leg != null, "Model is missing the animated FrontLeft pivot")
	if _failed:
		quit(1)
		return
	for clip: StringName in [&"idle", &"walk", &"jump"]:
		_check(_player.has_animation(clip), "Missing " + clip)
		_check(_player.get_animation(clip).get_track_count() >= 7, "Incomplete transform rig " + clip)
	await _frames(20)
	_check(_visual.animation_state == &"idle", "Grounded actor must idle")
	await _capture("01-idle-follow")
	var start := _camiel.position
	_key(KEY_W, true)
	await _frames(14)
	_check(_visual.animation_state == &"walk", "Forward key must select walk")
	var pose_a := leg.rotation.x
	await _frames(10)
	_check(absf(leg.rotation.x - pose_a) > 0.1, "Walk clip must actually move the leg")
	_check(_camiel.position.distance_to(start) > 0.3, "Walk must move actor")
	await _capture("02-walk")
	_key(KEY_SPACE, true)
	await _frames(5)
	_key(KEY_SPACE, false)
	_check(_visual.animation_state == &"jump", "Airborne actor must select jump")
	_check(_camiel.position.y > start.y + 0.1, "Jump must clear ground")
	await _capture("03-jump")
	_key(KEY_W, false)
	await _frames(90)
	_check(_camiel.is_on_floor(), "Jump must land")
	_check(_visual.animation_state == &"idle", "Landing must return to idle")
	_check(absf(leg.rotation.x) < 0.01, "Idle must restore neutral legs after jump")
	_check(_camiel.get_node("CameraPivot/SpringArm3D/Camera3D").current, "Follow camera must remain current")
	print("PASS idle -> moving walk -> jump -> landing idle; animated pose restored")

	_camiel.rotation.y = 0
	_camiel.teleport_to(Vector3(0, 0, -4.8))
	_key(KEY_W, true)
	await _frames(70)
	_key(KEY_W, false)
	_check(_visual.animation_state == &"idle", "A blocked dog must stop its walk cycle")
	var nose: MeshInstance3D = _visual.find_child("Nose", true, false)
	var nose_bounds: AABB = nose.global_transform * nose.get_aabb()
	_check(nose_bounds.position.z > -6.03, "Muzzle penetrates the wall")
	_check(_camiel.position.z > -5.5, "Head collider must stop the actor before the muzzle reaches the wall")
	print("PASS head clearance at wall and blocked-motion idle")
	_camiel.teleport_to(Vector3(0,0,2))
	await _frames(5)

	# Front three-quarter inspection supplements the actual gameplay-camera captures.
	if not _capture_dir.is_empty():
		_camiel.set_physics_process(false)
		_camiel.rotation.y = 0
		var camera := Camera3D.new()
		camera.fov = 38.0
		world.add_child(camera)
		camera.global_position = _camiel.global_position + Vector3(1.65,1.15,-2.0)
		camera.look_at(_camiel.global_position + Vector3(0,.60,0))
		camera.current = true
		await _frames(20)
		await _capture("04-front-inspection")

	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	world.queue_free()
	await process_frame
	if _failed:
		quit(1)
	else:
		print("Camiel model probe passed.")
		quit(0)
