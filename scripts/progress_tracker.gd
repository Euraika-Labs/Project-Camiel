# progress_tracker.gd
# Autoload singleton — tracks lesson progress and saves to user://progress.json
extends Node

signal progress_saved

func _ready():
	pass  # loads existing progress on start

func record_lesson_complete(lesson_id: String, stars: int, time_seconds: int) -> void:
	var progress = _load_progress()
	var entry = {
		"lesson_id": lesson_id,
		"stars": stars,
		"time_seconds": time_seconds,
		"completed_at": Time.get_datetime_string_from_system()
	}
	if progress.has("lessons"):
		progress["lessons"].append(entry)
	else:
		progress["lessons"] = [entry]
	_save_progress(progress)
	progress_saved.emit()

func _load_progress() -> Dictionary:
	var path = "user://progress.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var json_str = f.get_as_text()
		f.close()
		return JSON.parse_string(json_str) if json_str else {}
	return {}

func _save_progress(data: Dictionary) -> void:
	var path = "user://progress.json"
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, JSON.SINDY_USE_HELPER))
		f.close()