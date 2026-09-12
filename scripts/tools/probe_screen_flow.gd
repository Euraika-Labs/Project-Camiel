# probe_screen_flow.gd
# Headless behaviour probe proving MENU-01 and MENU-02's exactly-once
# contract (D-29): each screen's transition fires exactly once through the
# inherited BaseButton.pressed signal, a second activation of an
# already-transitioning control changes nothing, and the project's main
# scene is the title screen. Plan 02-04 extends this same file with the
# intro level's own win-screen cases; the case-runner/helper shape below
# matches scripts/tools/probe_camiel_movement.gd on purpose. Run by
# scripts/tools/run_headless_check.sh.
extends SceneTree

var _fire_count := 0
var _fired_target := ""
var _failed := false
var _cases_run := 0

var _finish_signal_count := 0
var _level_transition_count := 0
var _level_transition_target := ""


func _initialize() -> void:
	await _case_title_screen()
	if _failed:
		return
	await _case_main_menu()
	if _failed:
		return
	_case_main_scene_is_title()
	if _failed:
		return
	await _case_finish_marker()
	if _failed:
		return

	if _cases_run == 0:
		push_error("no case ran; the probe would verify nothing")
		quit(1)
		return

	print("Screen flow probe passed.")
	quit(0)


func _fail(case_name: String, detail: String) -> void:
	_failed = true
	push_error("%s: %s" % [case_name, detail])
	quit(1)


func _on_transition_requested(target_path: String) -> void:
	_fire_count += 1
	_fired_target = target_path


func _press_focused() -> void:
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = "ui_accept"
	release.pressed = false
	Input.parse_input_event(release)


# Each guarded handler really does request a scene change, so after the
# first activation the engine loads the target scene into the tree and its
# own ready callback grabs focus on its own button. Without draining, the
# second activation in the guard test would land on a different screen's
# control and the case would be measuring the wrong thing.
func _drain_scene_change() -> void:
	await process_frame
	await process_frame
	if current_scene != null:
		var stale: Node = current_scene
		root.remove_child(stale)
		stale.free()
		set_current_scene(null)


func _run_screen_case(case_name: String, scene_path: String, button_unique_name: String, expected_target: String) -> void:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		_fail(case_name, "could not load %s" % scene_path)
		return

	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	_fire_count = 0
	_fired_target = ""
	screen.transition_requested.connect(_on_transition_requested)

	var button: Button = screen.get_node(button_unique_name) as Button
	if button == null:
		_fail(case_name, "%s not found" % button_unique_name)
		return
	if not button.has_focus():
		_fail(case_name, "%s does not hold focus after _ready()" % button_unique_name)
		return

	var connections := button.get_signal_connection_list("pressed")
	if connections.size() != 1:
		_fail(case_name, "%s.pressed has %d connections, expected 1" % [button_unique_name, connections.size()])
		return

	_press_focused()
	await process_frame
	await process_frame

	if _fire_count != 1:
		_fail(case_name, "transition_requested fired %d times, expected 1" % _fire_count)
		return
	if _fired_target != expected_target:
		_fail(case_name, "transition_requested target was %s, expected %s" % [_fired_target, expected_target])
		return

	await _drain_scene_change()

	button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _fire_count != 1:
		_fail(case_name, "the _transitioning guard did not block a second press; count is %d" % _fire_count)
		return

	screen.transition_requested.disconnect(_on_transition_requested)
	screen.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)


func _case_title_screen() -> void:
	await _run_screen_case("title_screen", "res://scenes/title_screen.tscn", "%PlayButton", "res://scenes/main_menu.tscn")


func _case_main_menu() -> void:
	await _run_screen_case("main_menu", "res://scenes/main_menu.tscn", "%StartButton", "res://scenes/intro_level.tscn")


func _on_finish_marker_finished_counted() -> void:
	_finish_signal_count += 1


func _on_level_transition_requested(target_path: String) -> void:
	_level_transition_count += 1
	_level_transition_target = target_path


# Plan 02-04's cases: the finish marker's exactly-once contract (INTRO-04),
# the "not gated on a non-player body" edge (T-02-16), and the win screen's
# return-to-menu button carrying the same one-shot guard as the two flat
# screens.
func _case_finish_marker() -> void:
	var case_name := "finish_marker"
	var packed: PackedScene = load("res://scenes/intro_level.tscn")
	if packed == null:
		_fail(case_name, "could not load res://scenes/intro_level.tscn")
		return

	var level: Node3D = packed.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	var finish_marker: Area3D = level.get_node("%FinishMarker")
	var win_layer: CanvasLayer = level.get_node("%WinLayer")
	var replay_button: Button = level.get_node("%ReplayButton")
	var go_to_menu_button: Button = level.get_node("%GoToMenuButton")
	var camiel: CharacterBody3D = level.get_node("Camiel")

	_finish_signal_count = 0
	finish_marker.finished.connect(_on_finish_marker_finished_counted)

	if win_layer.visible:
		_fail(case_name, "%WinLayer is visible before the finish marker ever fired")
		return
	if win_layer.process_mode != Node.PROCESS_MODE_ALWAYS:
		_fail(case_name, "%%WinLayer.process_mode is %d, expected PROCESS_MODE_ALWAYS" % win_layer.process_mode)
		return

	var connections := finish_marker.get_signal_connection_list("finished")
	if connections.size() != 2:
		_fail(case_name, "%%FinishMarker.finished has %d connections, expected 2 (the level's handler and the probe's counter)" % connections.size())
		return

	camiel.teleport_to(finish_marker.global_position)
	var frames_waited := 0
	while _finish_signal_count == 0 and frames_waited < 120:
		await physics_frame
		frames_waited += 1

	if _finish_signal_count != 1:
		_fail(case_name, "finished fired %d times within 120 physics frames, expected 1" % _finish_signal_count)
		return
	if not win_layer.visible:
		_fail(case_name, "%WinLayer.visible is false after finished fired")
		return
	if not replay_button.has_focus():
		_fail(case_name, "%ReplayButton does not hold focus after the win overlay appeared")
		return

	for _i in range(60):
		await physics_frame
	if _finish_signal_count != 1:
		_fail(case_name, "finished fired again (count=%d) while Camiel kept overlapping for 60 further frames" % _finish_signal_count)
		return

	var intruder := StaticBody3D.new()
	var intruder_shape := CollisionShape3D.new()
	var intruder_box := BoxShape3D.new()
	intruder_box.size = Vector3(0.2, 0.2, 0.2)
	intruder_shape.shape = intruder_box
	intruder.add_child(intruder_shape)
	level.add_child(intruder)
	intruder.global_position = finish_marker.global_position
	for _i in range(10):
		await physics_frame
	if _finish_signal_count != 1:
		_fail(case_name, "a non-player StaticBody3D placed inside the marker triggered it (count=%d)" % _finish_signal_count)
		return
	intruder.queue_free()

	_level_transition_count = 0
	_level_transition_target = ""
	level.transition_requested.connect(_on_level_transition_requested)

	go_to_menu_button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _level_transition_count != 1:
		_fail(case_name, "transition_requested fired %d times, expected 1" % _level_transition_count)
		return
	if _level_transition_target != "res://scenes/main_menu.tscn":
		_fail(case_name, "transition_requested target was %s, expected res://scenes/main_menu.tscn" % _level_transition_target)
		return

	await _drain_scene_change()

	go_to_menu_button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _level_transition_count != 1:
		_fail(case_name, "the _transitioning guard did not block a second press; count is %d" % _level_transition_count)
		return

	level.transition_requested.disconnect(_on_level_transition_requested)
	finish_marker.finished.disconnect(_on_finish_marker_finished_counted)
	level.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)


func _case_main_scene_is_title() -> void:
	var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene_path != "res://scenes/title_screen.tscn":
		_fail("main_scene_is_title", "application/run/main_scene is %s, expected res://scenes/title_screen.tscn" % main_scene_path)
		return

	var packed: PackedScene = load(main_scene_path)
	if packed == null:
		_fail("main_scene_is_title", "main scene did not load as a PackedScene")
		return

	var instance := packed.instantiate()
	if instance == null:
		_fail("main_scene_is_title", "main scene failed to instantiate")
		return

	if not instance is Control:
		_fail("main_scene_is_title", "main scene root is not a Control")
		instance.free()
		return

	instance.free()
	_cases_run += 1
	print("PASS main_scene_is_title")
