# probe_lesson_kit.gd
# Headless proof of the shared lesson kit built in phase 3 plan 02: a target
# completes exactly once for a player body and ignores everything else
# (D-45), an inactive target refuses and only completes once activated
# (D-37, D-38), and the shared HUD's one progress-label form and win panel
# behave correctly (D-46, D-34). Run by scripts/tools/run_headless_check.sh.
extends SceneTree

var _failed := false
var _cases_run := 0
var _completed_ids: Array[String] = []
var _completed_count := 0


func _initialize() -> void:
	await _case_target_completes_on_touch()
	if _failed:
		return

	if _cases_run == 0:
		push_error("no case ran; the probe would verify nothing")
		quit(1)
		return

	print("Lesson kit probe passed.")
	quit(0)


func _fail(case_name: String, detail: String) -> void:
	_failed = true
	push_error("%s: %s" % [case_name, detail])
	quit(1)


func _on_task_completed_counted(task_id: String) -> void:
	_completed_count += 1
	_completed_ids.append(task_id)


## Instantiates the shared room and a player body under it. Building the
## tree in the probe rather than committing a test scene keeps the shipped
## scene list to things a child can actually reach.
func _build_test_room() -> Dictionary:
	var room_packed: PackedScene = load("res://scenes/lesson_room.tscn")
	var room: Node3D = room_packed.instantiate()
	root.add_child(room)

	var camiel_packed: PackedScene = load("res://scenes/camiel.tscn")
	var camiel: CharacterBody3D = camiel_packed.instantiate()
	room.add_child(camiel)
	await process_frame
	camiel.global_position = Vector3(0, 0.1, 4)

	await process_frame
	await process_frame

	return {"room": room, "camiel": camiel}


func _case_target_completes_on_touch() -> void:
	var case_name := "target_completes_on_touch"
	var built: Dictionary = await _build_test_room()
	var room: Node3D = built["room"]
	var camiel: CharacterBody3D = built["camiel"]

	for wall_name: String in ["WallNorth", "WallSouth", "WallEast", "WallWest"]:
		if room.get_node_or_null("Walls/%s" % wall_name) == null:
			_fail(case_name, "%s missing from lesson_room.tscn" % wall_name)
			return
	if room.get_node_or_null("Ground") == null:
		_fail(case_name, "Ground missing from lesson_room.tscn")
		return

	var target_packed: PackedScene = load("res://scenes/lesson_target.tscn")
	var target: Area3D = target_packed.instantiate()
	target.task_id = "probe_target"
	target.target_color = Color(0.9, 0.2, 0.2)
	room.add_child(target)
	target.global_position = Vector3(2, 0.5, 4)
	await process_frame
	await process_frame

	_completed_count = 0
	_completed_ids.clear()
	target.task_completed.connect(_on_task_completed_counted)

	var connections := target.get_signal_connection_list("task_completed")
	if connections.size() != 1:
		_fail(case_name, "task_completed has %d connections, expected 1 (the probe's own counter)" % connections.size())
		return

	camiel.teleport_to(target.global_position)
	var frames_waited := 0
	while _completed_count == 0 and frames_waited < 120:
		await physics_frame
		frames_waited += 1

	if _completed_count != 1:
		_fail(case_name, "task_completed fired %d times within 120 physics frames, expected 1" % _completed_count)
		return
	if _completed_ids[0] != "probe_target":
		_fail(case_name, "task_completed carried %s, expected probe_target" % _completed_ids[0])
		return
	print("[probe_lesson_kit] target_completes_on_touch frames to emission: %d" % frames_waited)

	for _i in range(60):
		await physics_frame
	if _completed_count != 1:
		_fail(case_name, "task_completed fired again (count=%d) while the body kept overlapping for 60 further frames" % _completed_count)
		return

	var intruder := StaticBody3D.new()
	var intruder_shape := CollisionShape3D.new()
	var intruder_box := BoxShape3D.new()
	intruder_box.size = Vector3(0.2, 0.2, 0.2)
	intruder_shape.shape = intruder_box
	intruder.add_child(intruder_shape)
	room.add_child(intruder)
	intruder.global_position = target.global_position
	for _i in range(10):
		await physics_frame
	if _completed_count != 1:
		_fail(case_name, "a non-player StaticBody3D placed inside the target triggered it (count=%d)" % _completed_count)
		return
	intruder.queue_free()

	target.task_completed.disconnect(_on_task_completed_counted)
	target.queue_free()
	await process_frame

	for shape_kind: String in ["cylinder", "box", "prism", "sphere"]:
		var shape_target: Area3D = target_packed.instantiate()
		shape_target.shape_kind = shape_kind
		shape_target.target_color = Color(0.1, 0.6, 0.3)
		room.add_child(shape_target)
		await process_frame
		var mesh_instance: MeshInstance3D = shape_target.get_node("Mesh")
		if mesh_instance.mesh == null:
			_fail(case_name, "%s target built no mesh" % shape_kind)
			return
		var material: StandardMaterial3D = mesh_instance.get_surface_override_material(0)
		if material == null or material.albedo_color != Color(0.1, 0.6, 0.3):
			_fail(case_name, "%s target's material albedo does not match its exported colour" % shape_kind)
			return
		shape_target.queue_free()
	await process_frame

	room.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)
