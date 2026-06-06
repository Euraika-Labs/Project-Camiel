extends SceneTree

const PROGRESS_PATH := "user://progress.json"
const SCENES := [
	"res://scenes/title_screen.tscn",
	"res://scenes/main_menu.tscn",
	"res://scenes/lesson_select.tscn",
	"res://scenes/lesson_1.tscn",
	"res://scenes/lesson_2.tscn",
	"res://scenes/lesson_3.tscn",
	"res://scenes/lesson_4.tscn",
	"res://scenes/lesson_5.tscn",
	"res://scenes/adult_progress.tscn",
]


func _initialize() -> void:
	var saved := _read_progress_text()
	var had_saved := FileAccess.file_exists(PROGRESS_PATH)

	var tracker := _get_progress_tracker()
	if tracker == null:
		push_error("ProgressTracker is unavailable.")
		_restore_progress(had_saved, saved)
		quit(1)
		return

	tracker.reset_progress()
	tracker.record_lesson_complete("lesson_1", 3, 12)
	tracker.record_lesson_complete("lesson_2", 2, 9)

	if tracker.get_completed_count() != 2:
		push_error("Expected 2 completed lessons after progress smoke test.")
		_restore_progress(had_saved, saved)
		quit(1)
		return
	if tracker.get_total_stars() != 5:
		push_error("Expected 5 total stars after progress smoke test.")
		_restore_progress(had_saved, saved)
		quit(1)
		return

	for scene_path in SCENES:
		if not _instantiate_scene(scene_path):
			_restore_progress(had_saved, saved)
			quit(1)
			return

	_restore_progress(had_saved, saved)
	print("Camiel Beta 1 flow verified.")
	quit(0)


func _get_progress_tracker() -> Node:
	var tracker := root.get_node_or_null("ProgressTracker")
	if tracker:
		return tracker

	var script := load("res://scripts/progress_tracker.gd") as Script
	if script == null:
		return null
	tracker = script.new() as Node
	tracker.name = "ProgressTracker"
	root.add_child(tracker)
	return tracker


func _instantiate_scene(scene_path: String) -> bool:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load scene: %s" % scene_path)
		return false

	var instance := packed.instantiate()
	if instance == null:
		push_error("Could not instantiate scene: %s" % scene_path)
		return false

	root.add_child(instance)
	root.remove_child(instance)
	instance.queue_free()
	return true


func _read_progress_text() -> String:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return ""
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _restore_progress(had_saved: bool, saved: String) -> void:
	if had_saved:
		var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
		if file:
			file.store_string(saved)
			file.close()
		return

	var absolute_path := ProjectSettings.globalize_path(PROGRESS_PATH)
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.remove_absolute(absolute_path)
