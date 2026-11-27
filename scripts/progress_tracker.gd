extends Node
## Appends lesson completions to the dashboard-compatible local history.

signal progress_saved
## Emitted when the visible progress changes, including in another browser tab.
signal progress_changed

const INTRO_COMPLETION_PATH := "user://intro-completed"
const PROGRESS_PATH := "user://progress.json"
const PROGRESS_TMP_PATH := "user://progress.json.tmp"
const SAVE_LOCK_PATH := "user://progress.lock"
const SAVE_LOCK_TIMEOUT_MS := 250
const BROWSER_SAVE_WAIT := 0.45
const SCHEMA_VERSION := 1
const STARS_PER_COMPLETION := 3
const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")

class BrowserSave:
	signal ready_to_continue
	signal finished(request: BrowserSave)
	var receipt: Variant
	var pending := true
	var entry: Dictionary
	var callback := JavaScriptBridge.create_callback(_receive)
	var _waiting := true

	func _receive(arguments: Array) -> void:
		receipt = null if arguments.is_empty() else arguments[0]
		pending = false
		continue_playing()
		finished.emit(self)

	func continue_playing() -> void:
		if _waiting:
			_waiting = false
			ready_to_continue.emit()

var _browser_store: JavaScriptObject
var _browser_progress_callback: JavaScriptObject
var _session_entries: Array[Dictionary] = []
var _session_intro_complete := false
var _pending_intro: BrowserSave
var _pending_lesson_writes: Array[BrowserSave] = []


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_browser_store = JavaScriptBridge.get_interface("camielProgress")
	if _browser_store == null:
		return
	_browser_progress_callback = JavaScriptBridge.create_callback(_on_browser_progress_changed)
	JavaScriptBridge.get_interface("window").addEventListener("camiel-progress-changed", _browser_progress_callback)
	var old_entries: Variant = _load_file_entries()
	var intro_complete := FileAccess.file_exists(INTRO_COMPLETION_PATH)
	if intro_complete or (old_entries is Array and not old_entries.is_empty()):
		_browser_store.import_legacy(JSON.stringify({
			"entries": old_entries if old_entries is Array else [],
			"intro_complete": intro_complete,
		}))


func _exit_tree() -> void:
	if _browser_progress_callback != null:
		JavaScriptBridge.get_interface("window").removeEventListener("camiel-progress-changed", _browser_progress_callback)


func _on_browser_progress_changed(_arguments: Array) -> void:
	call_deferred("emit_signal", "progress_changed")


func has_completed_intro() -> bool:
	if _browser_store != null:
		return _session_intro_complete or _pending_intro != null or _browser_progress().get("intro_complete", false)
	return FileAccess.file_exists(INTRO_COMPLETION_PATH)


func record_intro_complete() -> void:
	if has_completed_intro():
		return
	if _browser_store != null:
		var request := BrowserSave.new()
		_pending_intro = request
		request.finished.connect(_on_intro_write_finished, CONNECT_ONE_SHOT)
		_browser_store.save("intro", "", request.callback)
		await _wait_for_browser_save(request)
		return
	# The empty file records a single fact independently of the lesson history.
	var marker := FileAccess.open(INTRO_COMPLETION_PATH, FileAccess.WRITE)
	if marker == null:
		push_warning("[ProgressTracker] The intro completion could not be saved: %s" % error_string(FileAccess.get_open_error()))
		return
	marker.close()
	progress_changed.emit()


func record_lesson_complete(lesson_id: String, time_seconds: float) -> bool:
	var result: Dictionary = await record_lesson_result(lesson_id, time_seconds)
	var request: BrowserSave = result.get("pending")
	if request == null:
		return result["saved"]
	if request.pending:
		await request.finished
	return request.receipt is String


func record_lesson_result(lesson_id: String, time_seconds: float) -> Dictionary:
	var entry := {
		"lesson_id": lesson_id,
		"stars": STARS_PER_COMPLETION,
		"time_seconds": time_seconds,
		"completed_at": Time.get_datetime_string_from_system(),
	}
	if _browser_store != null:
		return await _record_browser_lesson_result(entry)
	var lock_directory := ProjectSettings.globalize_path(SAVE_LOCK_PATH)
	var owner := ""
	if not OS.has_feature("web"):
		owner = _acquire_lock(lock_directory)
		if owner.is_empty():
			push_warning("[ProgressTracker] The progress file is busy.")
			return {"saved": false, "garden_completed": false}
	var result := _append_entry(entry)
	if not owner.is_empty():
		_remove_lock(lock_directory, owner)
	if result["saved"]:
		progress_saved.emit()
		progress_changed.emit()
	return result


func get_entries() -> Array[Dictionary]:
	if _browser_store != null:
		var browser_entries := _entries_from_array(_browser_progress().get("entries"))
		browser_entries.append_array(_session_entries)
		return browser_entries
	var entries: Variant = _load_file_entries()
	return entries if entries is Array else []


func completed_lesson_ids() -> Dictionary:
	var completed := _completed_ids(get_entries())
	_add_pending_lesson_ids(completed)
	return completed


func _completed_ids(entries: Array[Dictionary]) -> Dictionary:
	var completed := {}
	for entry: Dictionary in entries:
		var lesson_id := str(entry.get("lesson_id", ""))
		if LESSON_CATALOG.index_for_id(lesson_id) >= 0 and entry.get("stars") in [1, 2, 3]:
			completed[lesson_id] = true
	return completed


func _append_entry(entry: Dictionary) -> Dictionary:
	var entries: Variant = _load_file_entries()
	if not (entries is Array):
		return {"saved": false, "garden_completed": false}
	var final_lesson := _unlocks_garden(_completed_ids(entries), entry["lesson_id"])
	entries.append(entry)
	var written := _write_entries(entries)
	return {"saved": written, "garden_completed": written and final_lesson}


func _unlocks_garden(completed: Dictionary, lesson_id: String) -> bool:
	return completed.size() == LESSON_CATALOG.LESSONS.size() - 1 \
		and LESSON_CATALOG.index_for_id(lesson_id) >= 0 and not completed.has(lesson_id)


func _browser_progress() -> Dictionary:
	var data: Variant = JSON.parse_string(str(_browser_store.read()))
	return data if data is Dictionary else {}


func _record_browser_lesson_result(entry: Dictionary) -> Dictionary:
	var local_prior := _completed_ids(_session_entries)
	_add_pending_lesson_ids(local_prior)
	var request := BrowserSave.new()
	request.entry = entry
	_pending_lesson_writes.append(request)
	request.finished.connect(_on_lesson_write_finished, CONNECT_ONE_SHOT)
	_browser_store.save("lesson", JSON.stringify(entry), request.callback)
	await _wait_for_browser_save(request)
	var saved := request.receipt is String
	var prior: Variant = JSON.parse_string(request.receipt) if saved else _browser_progress().get("entries")
	var completed := _completed_ids(_entries_from_array(prior))
	completed.merge(local_prior)
	return {
		"saved": saved,
		"pending": request if request.pending else null,
		"garden_completed": _unlocks_garden(completed, entry["lesson_id"]),
	}


func _add_pending_lesson_ids(completed: Dictionary) -> void:
	# A pending write counts towards the route even if its acknowledgement
	# arrives after the player changes scenes. It is not part of the history yet.
	for request: BrowserSave in _pending_lesson_writes:
		var lesson_id: String = request.entry["lesson_id"]
		if LESSON_CATALOG.index_for_id(lesson_id) >= 0:
			completed[lesson_id] = true


func _wait_for_browser_save(request: BrowserSave) -> void:
	if request.pending:
		get_tree().create_timer(BROWSER_SAVE_WAIT).timeout.connect(request.continue_playing)
		await request.ready_to_continue


func _on_intro_write_finished(request: BrowserSave) -> void:
	_pending_intro = null
	if request.receipt == null:
		_session_intro_complete = true
		progress_changed.emit()
		push_warning("[ProgressTracker] The browser could not store intro completion.")


func _on_lesson_write_finished(request: BrowserSave) -> void:
	_pending_lesson_writes.erase(request)
	if request.receipt is String:
		progress_saved.emit()
	else:
		_session_entries.append(request.entry)
		progress_changed.emit()


func _load_file_entries() -> Variant:
	var entries: Array[Dictionary] = []
	if not FileAccess.file_exists(PROGRESS_PATH):
		return entries
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file == null:
		push_warning("[ProgressTracker] Could not read existing progress: %s" % error_string(FileAccess.get_open_error()))
		return null
	var text := file.get_as_text()
	file.close()

	# The instance parser lets a truncated save recover with a warning.
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("[ProgressTracker] Corrupt progress file, starting fresh: %s (line %d)" % [
			json.get_error_message(), json.get_error_line(),
		])
		return entries
	var data: Variant = json.get_data()
	if not (data is Dictionary) or not (data.get("entries") is Array):
		push_warning("[ProgressTracker] Unexpected progress file shape, starting fresh.")
		return entries
	return _entries_from_array(data["entries"])


func _entries_from_array(data: Variant) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not (data is Array):
		return entries
	for item: Variant in data:
		if item is Dictionary:
			# Godot's JSON parser reads numbers as floats. Keep the integer
			# star field when a new session rewrites earlier completions.
			var stars: Variant = item.get("stars")
			if stars is float and stars in [1.0, 2.0, 3.0]:
				item["stars"] = int(stars)
			entries.append(item)
	return entries


func _write_entries(entries: Array[Dictionary]) -> bool:
	var data := {"version": SCHEMA_VERSION, "entries": entries}
	var tmp := FileAccess.open(PROGRESS_TMP_PATH, FileAccess.WRITE)
	if tmp == null:
		push_warning("[ProgressTracker] Could not open temporary progress file: %s" % error_string(FileAccess.get_open_error()))
		return false
	var stored := tmp.store_string(JSON.stringify(data, "\t"))
	tmp.flush()
	stored = stored and tmp.get_error() == OK
	tmp.close()
	if not stored:
		push_warning("[ProgressTracker] The progress file could not be written.")
		return false
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(PROGRESS_TMP_PATH),
		ProjectSettings.globalize_path(PROGRESS_PATH)
	)
	if error != OK:
		push_warning("[ProgressTracker] Atomic replacement failed: %s" % error_string(error))
	return error == OK


func _acquire_lock(directory: String) -> String:
	var nonce := Crypto.new().generate_random_bytes(12).hex_encode()
	var owner := "writer_%d_%s" % [OS.get_process_id(), nonce]
	var candidate := directory + "." + owner
	if DirAccess.make_dir_absolute(candidate) != OK:
		return ""
	var marker := FileAccess.open(candidate.path_join(owner), FileAccess.WRITE)
	if marker == null:
		DirAccess.remove_absolute(candidate)
		return ""
	marker.close()

	# Publish a populated directory in one rename. A rename cannot replace an
	# occupied, nonempty directory, and ownership is visible immediately.
	var deadline := Time.get_ticks_msec() + SAVE_LOCK_TIMEOUT_MS
	while true:
		if DirAccess.rename_absolute(candidate, directory) == OK:
			return owner
		_remove_abandoned_lock(directory)
		if Time.get_ticks_msec() >= deadline:
			break
		OS.delay_msec(8)
	_remove_lock(candidate, owner)
	return ""


func _remove_abandoned_lock(directory: String) -> void:
	var owners := DirAccess.get_files_at(directory)
	if owners.is_empty():
		DirAccess.remove_absolute(directory)
		return
	if owners.size() != 1:
		return
	var parts := owners[0].split("_")
	if parts.size() == 3 and parts[0] == "writer" and parts[1].is_valid_int():
		var pid := parts[1].to_int()
		if pid > 0 and not OS.is_process_running(pid):
			_remove_lock(directory, owners[0])


func _remove_lock(directory: String, owner: String) -> void:
	# A competitor may have acquired a freshly empty directory in the meantime.
	# Only remove this exact marker and attempt a non-recursive removal.
	DirAccess.remove_absolute(directory.path_join(owner))
	DirAccess.remove_absolute(directory)
