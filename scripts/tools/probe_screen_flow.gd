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
var _collected_signal_count := 0
var _drain_audio_manager: Node = null
var _replay_signal_count := 0


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
	await _case_collectible()
	if _failed:
		return
	await _case_collectible_reset_cancels_tween()
	if _failed:
		return
	await _case_win_buttons()
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


func _on_collected_counted() -> void:
	_collected_signal_count += 1


func _drain_sfx_idle() -> bool:
	return not _drain_audio_manager.is_sfx_playing()


# Polls `predicate` once per physics frame against a real wall-clock
# deadline (VF11, VF23 — the audio mix thread runs on real time, decoupled
# from --fixed-fps's simulated frames, so a fixed frame count is not a
# portable margin). Mirrors probe_audio_buses.gd's _wait_until helper.
func _wait_until(predicate: Callable, timeout_ms: int = 2000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await physics_frame
	return predicate.call()


func _count_collectible_instances(node: Node, count: Array) -> void:
	if node.scene_file_path == "res://scenes/collectible.tscn":
		count[0] += 1
	for child in node.get_children():
		_count_collectible_instances(child, count)


# Plan 02-04 Task 2: the collectible's exactly-once contract (INTRO-03), the
# single-instance count D-19 fixes, and the structural guarantee that
# intro_level.gd is the only thing that plays the pickup effect.
func _case_collectible() -> void:
	var case_name := "collectible"
	var packed: PackedScene = load("res://scenes/intro_level.tscn")
	if packed == null:
		_fail(case_name, "could not load res://scenes/intro_level.tscn")
		return

	var level: Node3D = packed.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	var collectible: Area3D = level.get_node("%Collectible")
	var camiel: CharacterBody3D = level.get_node("Camiel")
	var audio_manager: Node = root.get_node_or_null("AudioManager")
	if audio_manager == null:
		_fail(case_name, "AudioManager autoload not found at /root/AudioManager")
		return

	var instance_count := [0]
	_count_collectible_instances(level, instance_count)
	if instance_count[0] != 1:
		_fail(case_name, "intro_level.tscn contains %d collectible instances, expected exactly 1 (D-19)" % instance_count[0])
		return

	_collected_signal_count = 0
	collectible.collected.connect(_on_collected_counted)

	var connections := collectible.get_signal_connection_list("collected")
	if connections.size() != 2:
		_fail(case_name, "%%Collectible.collected has %d connections, expected 2 (the level's handler and the probe's counter)" % connections.size())
		return

	# The finish_marker case (run immediately before this one) also plays an
	# SFX event through this same singleton AudioManager, off its own short
	# placeholder stream. Drain it here rather than asserting a strict
	# same-instant baseline, so this case proves the collectible's own
	# effect rather than racing a prior case's cleanup.
	_drain_audio_manager = audio_manager
	await _wait_until(_drain_sfx_idle, 2000)
	if audio_manager.is_sfx_playing():
		_fail(case_name, "AudioManager still reports an SFX playing 2000ms after the finish_marker case; cannot prove a fresh pickup")
		return

	camiel.teleport_to(collectible.global_position)
	var frames_waited := 0
	while _collected_signal_count == 0 and frames_waited < 120:
		await physics_frame
		frames_waited += 1

	if _collected_signal_count != 1:
		_fail(case_name, "collected fired %d times within 120 physics frames, expected 1" % _collected_signal_count)
		return
	if collectible.monitoring:
		_fail(case_name, "%Collectible.monitoring is still true after pickup")
		return

	var became_playing := await _wait_until(audio_manager.is_sfx_playing, 2000)
	if not became_playing:
		_fail(case_name, "AudioManager did not report an SFX playing within 2000ms of pickup")
		return

	for _i in range(60):
		await physics_frame
	if _collected_signal_count != 1:
		_fail(case_name, "collected fired again (count=%d) while Camiel kept overlapping for 60 further frames" % _collected_signal_count)
		return

	var intruder := StaticBody3D.new()
	var intruder_shape := CollisionShape3D.new()
	var intruder_box := BoxShape3D.new()
	intruder_box.size = Vector3(0.2, 0.2, 0.2)
	intruder_shape.shape = intruder_box
	intruder.add_child(intruder_shape)
	level.add_child(intruder)
	intruder.global_position = collectible.global_position
	for _i in range(10):
		await physics_frame
	if _collected_signal_count != 1:
		_fail(case_name, "a non-player StaticBody3D placed inside the collectible triggered it (count=%d)" % _collected_signal_count)
		return
	intruder.queue_free()

	collectible.collected.disconnect(_on_collected_counted)
	level.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)


# WR-01 fix verification (02-REVIEW.md): Collectible.reset() must cancel any
# in-flight pickup tween, or the tween's own queued tween_callback(hide)
# fires after this reset's show() and leaves the collectible re-armed but
# permanently invisible. The shipped level geometry puts the collectible and
# finish marker ~5.6m apart -- far more than the 0.3s tween can be outrun --
# so replay can never race the tween through normal play. This case drives
# reset() directly, immediately after the pickup deferred-call fires, so the
# race is exercised regardless of level geometry.
func _case_collectible_reset_cancels_tween() -> void:
	var case_name := "collectible_reset_cancels_tween"
	var packed: PackedScene = load("res://scenes/intro_level.tscn")
	if packed == null:
		_fail(case_name, "could not load res://scenes/intro_level.tscn")
		return

	var level: Node3D = packed.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	var collectible: Area3D = level.get_node("%Collectible")
	var camiel: CharacterBody3D = level.get_node("Camiel")
	var player_spawn: Marker3D = level.get_node("PlayerSpawn")

	_collected_signal_count = 0
	collectible.collected.connect(_on_collected_counted)

	camiel.teleport_to(collectible.global_position)
	var frames_waited := 0
	while _collected_signal_count == 0 and frames_waited < 120:
		await physics_frame
		frames_waited += 1

	if _collected_signal_count != 1:
		_fail(case_name, "collected fired %d times within 120 physics frames, expected 1" % _collected_signal_count)
		return
	if not collectible.visible:
		_fail(case_name, "%Collectible is already hidden immediately after pickup, before the reset race can be tested")
		return

	# Move Camiel off the trigger volume before calling reset() -- reset()
	# flips monitoring back to true, and if the physics server had not yet
	# settled on Camiel's departure, that would fire a second, genuine
	# body_entered pickup of its own (a separate confound from the race this
	# case exists to prove). A couple of physics frames is enough for the
	# broadphase to catch up while staying far inside the tween's 18-frame
	# (0.3s) window.
	camiel.teleport_to(player_spawn.global_position)
	await physics_frame
	await physics_frame

	# reset() right now, while the 0.3s pickup-feedback tween created moments
	# ago is still running -- exactly the replay-during-pickup race WR-01
	# describes. A reset() that does not kill the tween leaves the tween's
	# own queued tween_callback(hide) to fire later and undo this show().
	collectible.reset()
	if not collectible.visible:
		_fail(case_name, "%Collectible.reset() did not restore visibility immediately")
		return

	# The pickup tween's own duration is 0.3s (18 physics frames at the
	# probe's fixed 60fps). Wait well past that so an unkilled tween's
	# queued hide() would have fired by now.
	for _i in range(40):
		await physics_frame

	if not collectible.visible:
		_fail(case_name, "%Collectible went invisible again after reset() -- the pickup tween's queued hide() fired late because reset() did not cancel it (WR-01)")
		return
	if not collectible.monitoring:
		_fail(case_name, "%Collectible.monitoring is false after reset(), expected true")
		return

	collectible.collected.disconnect(_on_collected_counted)
	level.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)


func _on_replay_requested_counted() -> void:
	_replay_signal_count += 1


# Plan 02-04 Task 3: the in-place replay reset (D-28), the explicit
# ReplayButton -> GoToMenuButton focus order (D-14), and each win button
# proved one-shot independently — including a second lap after a replay,
# so a child who replays is never left in a level with no ending.
func _case_win_buttons() -> void:
	var case_name := "win_buttons"
	var packed: PackedScene = load("res://scenes/intro_level.tscn")
	if packed == null:
		_fail(case_name, "could not load res://scenes/intro_level.tscn")
		return

	var level: Node3D = packed.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	var finish_marker: Area3D = level.get_node("%FinishMarker")
	var collectible: Area3D = level.get_node("%Collectible")
	var win_layer: CanvasLayer = level.get_node("%WinLayer")
	var replay_button: Button = level.get_node("%ReplayButton")
	var go_to_menu_button: Button = level.get_node("%GoToMenuButton")
	var camiel: CharacterBody3D = level.get_node("Camiel")
	var player_spawn: Marker3D = level.get_node("PlayerSpawn")

	camiel.teleport_to(finish_marker.global_position)
	var frames_waited := 0
	while not win_layer.visible and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if not win_layer.visible:
		_fail(case_name, "%WinLayer never became visible after teleporting Camiel onto the finish marker")
		return

	if not replay_button.has_focus():
		_fail(case_name, "%ReplayButton does not hold focus when the overlay appears")
		return

	var neighbor_path: NodePath = replay_button.focus_neighbor_right
	if neighbor_path.is_empty():
		_fail(case_name, "%ReplayButton.focus_neighbor_right is not set")
		return
	if replay_button.get_node(neighbor_path) != go_to_menu_button:
		_fail(case_name, "%ReplayButton's declared next-focus neighbour does not resolve to %GoToMenuButton")
		return

	_replay_signal_count = 0
	level.replay_requested.connect(_on_replay_requested_counted)
	var scene_before := current_scene

	_press_focused()
	await process_frame
	await process_frame

	if _replay_signal_count != 1:
		_fail(case_name, "replay_requested fired %d times, expected 1" % _replay_signal_count)
		return
	if win_layer.visible:
		_fail(case_name, "%WinLayer is still visible after replay")
		return
	if not collectible.monitoring:
		_fail(case_name, "%Collectible.monitoring is false after replay")
		return
	if not collectible.visible:
		_fail(case_name, "%Collectible is not visible after replay")
		return
	var distance_from_spawn := camiel.global_position.distance_to(player_spawn.global_position)
	if distance_from_spawn > 0.05:
		_fail(case_name, "Camiel is %.3f m from PlayerSpawn after replay, expected within 0.05m" % distance_from_spawn)
		return
	if camiel.velocity.length() > 0.01:
		_fail(case_name, "Camiel's velocity length is %.4f after replay, expected under 0.01" % camiel.velocity.length())
		return
	if not camiel.is_physics_processing():
		_fail(case_name, "Camiel's physics processing is still off after replay")
		return
	if current_scene != scene_before:
		_fail(case_name, "current_scene changed during replay; replay must not change scene")
		return
	if not level.is_inside_tree():
		_fail(case_name, "the level instance left the tree during replay")
		return

	# Prove the second lap: replay re-armed the finish marker too, so a
	# child who replays is not left in a level with no ending.
	camiel.teleport_to(finish_marker.global_position)
	frames_waited = 0
	while not win_layer.visible and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if not win_layer.visible:
		_fail(case_name, "%WinLayer did not become visible a second time after a replayed lap")
		return

	# Prove the replay button's own activation count independently of the
	# return-to-menu button.
	replay_button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame
	if _replay_signal_count != 2:
		_fail(case_name, "replay_requested fired %d times total, expected 2 after a second press" % _replay_signal_count)
		return

	# Re-trigger the win once more to test the return-to-menu button on its
	# own, independent of the replay button's own count.
	camiel.teleport_to(finish_marker.global_position)
	frames_waited = 0
	while not win_layer.visible and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if not win_layer.visible:
		_fail(case_name, "%WinLayer did not become visible a third time before testing the return-to-menu button")
		return

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

	await _drain_scene_change()

	go_to_menu_button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _level_transition_count != 1:
		_fail(case_name, "the _transitioning guard did not block a second press; count is %d" % _level_transition_count)
		return

	level.transition_requested.disconnect(_on_level_transition_requested)
	level.replay_requested.disconnect(_on_replay_requested_counted)
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
