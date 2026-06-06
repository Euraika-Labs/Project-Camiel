# progress_tracker.gd
# Offline progress store for parent/teacher review.
extends Node

signal progress_saved
signal progress_reset

const PROGRESS_PATH := "user://progress.json"

var _progress: Dictionary = {"lessons": {}}


func _ready() -> void:
	_progress = _load_progress()


func record_lesson_complete(lesson_id: String, stars: int = 3, time_seconds: int = 0) -> void:
	var lessons := _progress.get("lessons", {}) as Dictionary
	var previous := lessons.get(lesson_id, {}) as Dictionary
	var previous_stars := int(previous.get("stars", 0))
	var best_time := int(previous.get("best_time_seconds", 0))
	var clean_time: int = maxi(time_seconds, 0)

	if clean_time > 0 and (best_time == 0 or clean_time < best_time):
		best_time = clean_time

	lessons[lesson_id] = {
		"lesson_id": lesson_id,
		"stars": maxi(clampi(stars, 1, 3), previous_stars),
		"last_time_seconds": clean_time,
		"best_time_seconds": best_time,
		"completed_at": Time.get_datetime_string_from_system()
	}
	_progress["lessons"] = lessons
	_save_progress(_progress)
	progress_saved.emit()


func get_lesson_progress(lesson_id: String) -> Dictionary:
	var lessons := _progress.get("lessons", {}) as Dictionary
	return lessons.get(lesson_id, {}) as Dictionary


func get_completed_count() -> int:
	var lessons := _progress.get("lessons", {}) as Dictionary
	return lessons.size()


func get_total_stars() -> int:
	var lessons := _progress.get("lessons", {}) as Dictionary
	var total := 0
	for lesson in lessons.values():
		if lesson is Dictionary:
			total += int(lesson.get("stars", 0))
	return total


func get_progress_summary() -> String:
	var lines: Array[String] = [
		"Voltooide lessen: %d / 5" % get_completed_count(),
		"Sterren totaal: %d / 15" % get_total_stars()
	]
	var lessons := _progress.get("lessons", {}) as Dictionary
	for lesson_id in ["lesson_1", "lesson_2", "lesson_3", "lesson_4", "lesson_5"]:
		var entry := lessons.get(lesson_id, {}) as Dictionary
		if entry.is_empty():
			lines.append("%s: nog niet klaar" % lesson_id)
		else:
			lines.append("%s: %d sterren, %ds" % [
				lesson_id,
				int(entry.get("stars", 0)),
				int(entry.get("last_time_seconds", 0))
			])
	return "\n".join(lines)


func reset_progress() -> void:
	_progress = {"lessons": {}}
	_save_progress(_progress)
	progress_reset.emit()


func _load_progress() -> Dictionary:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return {"lessons": {}}

	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file == null:
		return {"lessons": {}}
	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		var data := parsed as Dictionary
		if not data.has("lessons") or not (data["lessons"] is Dictionary):
			data["lessons"] = {}
		return data
	return {"lessons": {}}


func _save_progress(data: Dictionary) -> void:
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[ProgressTracker] Could not write progress file.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
