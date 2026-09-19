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
var _rejected_count := 0


func _initialize() -> void:
	await _case_target_completes_on_touch()
	if _failed:
		return
	await _case_hud_form_and_win_panel()
	if _failed:
		return
	await _case_activation_gate_refuses_then_allows()
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


func _on_rejected_counted() -> void:
	_rejected_count += 1


func _emission_energy(target: Area3D) -> float:
	var mesh_instance: MeshInstance3D = target.get_node("Mesh")
	var material: StandardMaterial3D = mesh_instance.get_surface_override_material(0)
	return material.emission_energy_multiplier


var _back_requested_count := 0
var _win_back_requested_count := 0


func _on_back_requested_counted() -> void:
	_back_requested_count += 1


func _on_win_back_requested_counted() -> void:
	_win_back_requested_count += 1


# Mirrors probe_screen_flow.gd's synthesised accept-action helper.
func _press_focused() -> void:
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = "ui_accept"
	release.pressed = false
	Input.parse_input_event(release)


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


func _case_hud_form_and_win_panel() -> void:
	var case_name := "hud_form_and_win_panel"
	var hud_packed: PackedScene = load("res://scenes/ui/lesson_hud.tscn")
	var hud: CanvasLayer = hud_packed.instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame

	var title_label: Label = hud.get_node("%TitleLabel")
	var back_button: Button = hud.get_node("%BackButton")
	var win_back_button: Button = hud.get_node("%WinBackButton")

	hud.set_title("Les 1")
	if title_label.text != "Les 1":
		_fail(case_name, "title label reads %s, expected Les 1" % title_label.text)
		return

	hud.set_step(2, 3)
	var step_label: Label = hud.get_node("%StepLabel")
	if step_label.text != "Stap: 2 / 3":
		_fail(case_name, "step label reads %s, expected Stap: 2 / 3" % step_label.text)
		return
	hud.set_step(4, 4)
	if step_label.text != "Stap: 4 / 4":
		_fail(case_name, "step label reads %s, expected Stap: 4 / 4 -- the same call shape must stay correct for the four-step lesson" % step_label.text)
		return

	if hud.is_win_visible():
		_fail(case_name, "hud.is_win_visible() is true before show_win() was ever called")
		return
	if back_button.focus_mode != Control.FOCUS_NONE:
		_fail(case_name, "%%BackButton.focus_mode is %d, expected FOCUS_NONE" % back_button.focus_mode)
		return

	_back_requested_count = 0
	_win_back_requested_count = 0
	hud.back_requested.connect(_on_back_requested_counted)
	hud.win_back_requested.connect(_on_win_back_requested_counted)

	var back_connections := back_button.get_signal_connection_list("pressed")
	if back_connections.size() != 1:
		_fail(case_name, "%%BackButton.pressed has %d connections, expected 1 (the display's own handler)" % back_connections.size())
		return
	var win_back_connections := win_back_button.get_signal_connection_list("pressed")
	if win_back_connections.size() != 1:
		_fail(case_name, "%%WinBackButton.pressed has %d connections, expected 1 (the display's own handler)" % win_back_connections.size())
		return

	hud.show_win()
	await process_frame
	await process_frame

	if not hud.is_win_visible():
		_fail(case_name, "hud.is_win_visible() is false after show_win()")
		return
	if not win_back_button.has_focus():
		_fail(case_name, "%WinBackButton does not hold focus after show_win()")
		return

	_press_focused()
	await process_frame
	await process_frame

	if _win_back_requested_count != 1:
		_fail(case_name, "win_back_requested fired %d times, expected 1" % _win_back_requested_count)
		return
	if _back_requested_count != 0:
		_fail(case_name, "back_requested fired %d times, expected 0 -- the space key must not reach the in-play control" % _back_requested_count)
		return

	# Proves the in-play control still works while proving the keyboard
	# cannot reach it: its own signal, not a synthesised keyboard press.
	back_button.pressed.emit()
	await process_frame
	await process_frame
	if _back_requested_count != 1:
		_fail(case_name, "back_requested fired %d times after the button's own pressed signal, expected 1" % _back_requested_count)
		return

	hud.back_requested.disconnect(_on_back_requested_counted)
	hud.win_back_requested.disconnect(_on_win_back_requested_counted)
	hud.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)


func _case_activation_gate_refuses_then_allows() -> void:
	var case_name := "activation_gate_refuses_then_allows"
	var built: Dictionary = await _build_test_room()
	var room: Node3D = built["room"]
	var camiel: CharacterBody3D = built["camiel"]
	var target_packed: PackedScene = load("res://scenes/lesson_target.tscn")
	var far_away := Vector3(0, 0.1, -5.5)
	camiel.teleport_to(far_away)

	_completed_count = 0
	_completed_ids.clear()
	_rejected_count = 0

	# --- Target 1: inactive touch rejects, does not consume the one shot,
	# then activation makes the same target completable. ---
	var target1: Area3D = target_packed.instantiate()
	target1.task_id = "t1"
	target1.requires_activation = true
	target1.display_text = "1"
	room.add_child(target1)
	target1.global_position = Vector3(2, 0.5, 4)
	await process_frame
	await process_frame

	if target1.is_active():
		_fail(case_name, "target1 reports itself active immediately after _ready(), expected inactive")
		return
	var emission_inactive := _emission_energy(target1)

	target1.rejected.connect(_on_rejected_counted)
	target1.task_completed.connect(_on_task_completed_counted)
	var rejected_connections := target1.get_signal_connection_list("rejected")
	if rejected_connections.size() != 1:
		_fail(case_name, "target1.rejected has %d connections, expected 1" % rejected_connections.size())
		return
	var completed_connections := target1.get_signal_connection_list("task_completed")
	if completed_connections.size() != 1:
		_fail(case_name, "target1.task_completed has %d connections, expected 1" % completed_connections.size())
		return

	camiel.teleport_to(target1.global_position)
	var frames_waited := 0
	while _rejected_count == 0 and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _rejected_count != 1:
		_fail(case_name, "rejected fired %d times within 120 physics frames, expected 1" % _rejected_count)
		return
	if _completed_count != 0:
		_fail(case_name, "task_completed fired %d times for an inactive target, expected 0" % _completed_count)
		return
	var label1: Label3D = target1.get_node("Label")
	if label1.text != "1":
		_fail(case_name, "target1's label reads %s after rejection, expected 1 -- rejection must never touch the label" % label1.text)
		return
	print("[probe_lesson_kit] activation_gate rejection frames: %d" % frames_waited)

	camiel.teleport_to(far_away)
	for _i in range(10):
		await physics_frame

	target1.activate()
	if not target1.is_active():
		_fail(case_name, "target1 does not report active after activate()")
		return
	var emission_active := _emission_energy(target1)
	if emission_active <= emission_inactive:
		_fail(case_name, "target1's emission energy did not increase after activate() (inactive=%.2f, active=%.2f)" % [emission_inactive, emission_active])
		return

	camiel.teleport_to(target1.global_position)
	frames_waited = 0
	while _completed_count == 0 and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _completed_count != 1:
		_fail(case_name, "task_completed fired %d times after activation, expected 1" % _completed_count)
		return
	if _rejected_count != 1:
		_fail(case_name, "rejected count changed to %d after the later completion; the earlier refusal must not have consumed the one shot, nor should completion add a new rejection" % _rejected_count)
		return
	print("[probe_lesson_kit] activation_gate post-activation completion frames: %d" % frames_waited)

	# --- Target 2: activating a target the body is already standing inside
	# completes it without the body leaving and returning, because an area
	# never re-fires body_entered for a body that never left. ---
	var target2: Area3D = target_packed.instantiate()
	target2.task_id = "t2"
	target2.requires_activation = true
	room.add_child(target2)
	target2.global_position = Vector3(-2, 0.5, 4)
	await process_frame
	await process_frame
	target2.rejected.connect(_on_rejected_counted)
	target2.task_completed.connect(_on_task_completed_counted)

	var rejected_before_t2 := _rejected_count
	var completed_before_t2 := _completed_count
	camiel.teleport_to(target2.global_position)
	frames_waited = 0
	while _rejected_count == rejected_before_t2 and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _rejected_count != rejected_before_t2 + 1:
		_fail(case_name, "target2 did not reject the initial touch while inactive")
		return
	if _completed_count != completed_before_t2:
		_fail(case_name, "target2 completed while inactive, before activation")
		return

	# The body has not moved. Activating now must complete it without a
	# fresh body_entered signal, since the body never left the area.
	target2.activate()
	frames_waited = 0
	while _completed_count == completed_before_t2 and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _completed_count != completed_before_t2 + 1:
		_fail(case_name, "target2 did not complete after activate() while the body stood inside it, without moving")
		return
	if _rejected_count != rejected_before_t2 + 1:
		_fail(case_name, "target2's rejected count changed again during the already-standing completion")
		return

	# --- Target 3: deactivating a completable target makes a touch reject
	# again. ---
	var target3: Area3D = target_packed.instantiate()
	target3.task_id = "t3"
	target3.requires_activation = true
	room.add_child(target3)
	target3.global_position = Vector3(4, 0.5, -4)
	await process_frame
	await process_frame
	target3.rejected.connect(_on_rejected_counted)
	target3.task_completed.connect(_on_task_completed_counted)
	target3.activate()
	target3.deactivate()

	var rejected_before_t3 := _rejected_count
	var completed_before_t3 := _completed_count
	camiel.teleport_to(far_away)
	for _i in range(10):
		await physics_frame
	camiel.teleport_to(target3.global_position)
	frames_waited = 0
	while _rejected_count == rejected_before_t3 and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _rejected_count != rejected_before_t3 + 1:
		_fail(case_name, "target3 did not reject after deactivate() was called on an activated target")
		return
	if _completed_count != completed_before_t3:
		_fail(case_name, "target3 completed after deactivate(), expected a rejection")
		return

	# --- Reset: target2 returns to inactive and its one-shot latch clears. ---
	target2.reset()
	if target2.is_active():
		_fail(case_name, "target2 still reports active after reset(), expected inactive")
		return

	var rejected_before_reset := _rejected_count
	var completed_before_reset := _completed_count
	camiel.teleport_to(far_away)
	for _i in range(10):
		await physics_frame
	camiel.teleport_to(target2.global_position)
	frames_waited = 0
	while _rejected_count == rejected_before_reset and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _rejected_count != rejected_before_reset + 1:
		_fail(case_name, "target2 did not reject after reset(), expected it to reject rather than complete")
		return
	if _completed_count != completed_before_reset:
		_fail(case_name, "target2 completed after reset(), expected a rejection")
		return

	target1.queue_free()
	target2.queue_free()
	target3.queue_free()
	room.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)
