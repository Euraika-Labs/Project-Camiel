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
