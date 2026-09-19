# Focused lesson 6 regression; shared harness uses real physics and disk reads.
extends "res://scripts/tools/probe_lesson_order.gd"

var _menu_roundtrip_passed := false

func _initialize() -> void:
	_take_progress_backup()
	await _case_lesson_6_order_enforced()
	if _failed:
		return
	await _case_menu_roundtrip()
	if _failed:
		return
	if _cases_run != 1 or not _menu_roundtrip_passed:
		_fail("non_vacuity", "both lesson-6 cases must reach their final assertion")
		return
	_restore_progress_backup()
	print("Lesson 6 probe passed.")
	quit(0)


func _expect_scene(path: String) -> bool:
	for frame in 120:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == path:
			await process_frame
			return true
	_fail("lesson_6_menu_roundtrip", "scene did not become " + path)
	return false


func _case_menu_roundtrip() -> void:
	var case_name := "lesson_6_menu_roundtrip"
	var entries_before := _disk_entry_count()
	change_scene_to_file("res://scenes/title_screen.tscn")
	if not await _expect_scene("res://scenes/title_screen.tscn"):
		return
	current_scene.get_node("%PlayButton").pressed.emit()
	if not await _expect_scene("res://scenes/main_menu.tscn"):
		return
	current_scene.get_node("%LessonsButton").pressed.emit()
	if not await _expect_scene(LESSON_SELECT_PATH):
		return
	current_scene.get_node("%LessonGrid").get_node("lesson_6").pressed.emit()
	if not await _expect_scene(LESSON_6_PATH):
		return
	var lesson := current_scene
	var camiel := lesson.get_node("Camiel") as CharacterBody3D
	for step in range(1, 6):
		var target := lesson.get_node("%%Step%dTarget" % step) as Area3D
		target.task_completed.connect(_on_target_completed_counted)
		await _park(camiel)
		if await _touch_target(camiel, target) < 0:
			_fail(case_name, "target not collected in full menu flow")
			return
	var hud := lesson.get_node("%Hud")
	if not hud.is_win_visible() or _disk_entry_count() != entries_before + 1:
		_fail(case_name, "menu-launched lesson did not finish and save exactly once")
		return
	if not _assert_last_entry(case_name, "lesson_6"):
		return
	hud.get_node("%WinBackButton").pressed.emit()
	if not await _expect_scene(LESSON_SELECT_PATH):
		return
	current_scene.get_node("%BackButton").pressed.emit()
	if not await _expect_scene("res://scenes/main_menu.tscn"):
		return
	await _drain_scene_change()
	_menu_roundtrip_passed = true
	print("PASS lesson_6_menu_roundtrip")
