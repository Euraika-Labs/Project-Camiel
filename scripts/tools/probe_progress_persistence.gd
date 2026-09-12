# probe_progress_persistence.gd
# Headless proof that ProgressTracker satisfies PROGRESS-01 and PROGRESS-02.
# A missing progress file must start a fresh tracker silently with an empty
# history (PROGRESS-01); one recorded completion must round-trip through the
# real user://progress.json file on disk with all four required fields when
# re-read from disk, never proved only by a signal firing (D-42). This probe
# deletes and rewrites a path a real child's saved history could live at, so
# it moves any existing file aside before its cases and restores it
# afterward on both the success and the failure path. Run by
# scripts/tools/run_headless_check.sh.
extends SceneTree

const PROGRESS_PATH := "user://progress.json"
const PROGRESS_TMP_PATH := "user://progress.json.tmp"
const BACKUP_PATH := "user://progress.json.probe_backup"

var _failed := false
var _cases_run := 0
var _took_backup := false


func _initialize() -> void:
	_take_progress_backup()

	await _case_first_run_is_silent()
	if _failed:
		return
	await _case_write_then_reread()
	if _failed:
		return

	if _cases_run == 0:
		_fail("non_vacuity", "no case ran; the probe would verify nothing")
		return

	_restore_progress_backup()
	print("Progress persistence probe passed.")
	quit(0)


func _fail(case_name: String, detail: String) -> void:
	_failed = true
	_restore_progress_backup()
	push_error("%s: %s" % [case_name, detail])
	quit(1)


# ── Save-file hygiene ────────────────────────────────────────────

## Moves any real user://progress.json aside before this probe's cases run,
## so a real child's saved history is never touched by this check.
func _take_progress_backup() -> void:
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))
	_took_backup = false
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(PROGRESS_PATH),
			ProjectSettings.globalize_path(BACKUP_PATH)
		)
		_took_backup = true


## Removes whatever this probe left behind and puts the real file back, if
## one was backed up. Called immediately before the success exit and as the
## first statement of _fail(), so the failure path restores the save just as
## reliably as the success path does.
func _restore_progress_backup() -> void:
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROGRESS_PATH))
	if FileAccess.file_exists(PROGRESS_TMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROGRESS_TMP_PATH))
	if _took_backup:
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(BACKUP_PATH),
			ProjectSettings.globalize_path(PROGRESS_PATH)
		)
		_took_backup = false


# ── Helpers ──────────────────────────────────────────────────────

## Builds a fresh tracker from the script and settles it in the tree. A
## fresh instance rather than the registered autoload, because the autoload
## already loaded its history at process start, before this probe moved the
## real file aside — only a fresh instance can observe a genuine first run.
func _make_tracker() -> Node:
	var script: GDScript = load("res://scripts/progress_tracker.gd")
	var tracker: Node = script.new()
	tracker.name = "ProgressTrackerProbeInstance"
	root.add_child(tracker)
	await process_frame
	return tracker


func _free_tracker(tracker: Node) -> void:
	root.remove_child(tracker)
	tracker.free()


## Opens the real progress file, parses it with the instance parser, and
## returns the parsed dictionary. Fails the case with a clear message if the
## file is absent or does not parse.
func _read_progress_file(case_name: String) -> Dictionary:
	if not FileAccess.file_exists(PROGRESS_PATH):
		_fail(case_name, "%s was not created" % PROGRESS_PATH)
		return {}

	var f := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if f == null:
		_fail(case_name, "could not open %s for reading" % PROGRESS_PATH)
		return {}
	var text := f.get_as_text()
	f.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		_fail(case_name, "%s is not valid JSON: %s" % [PROGRESS_PATH, json.get_error_message()])
		return {}

	var data: Variant = json.get_data()
	if not (data is Dictionary):
		_fail(case_name, "%s did not parse to a Dictionary" % PROGRESS_PATH)
		return {}
	return data


# ── Cases ────────────────────────────────────────────────────────

func _case_first_run_is_silent() -> void:
	var case_name := "first_run_is_silent"
	if FileAccess.file_exists(PROGRESS_PATH):
		_fail(case_name, "%s exists right after the backup was taken" % PROGRESS_PATH)
		return

	var tracker := await _make_tracker()
	var entries: Array[Dictionary] = tracker.get_entries()
	if not entries.is_empty():
		_fail(case_name, "a fresh tracker with no file on disk reported %d entries, expected 0" % entries.size())
		return

	_free_tracker(tracker)
	_cases_run += 1
	print("PASS %s" % case_name)


func _case_write_then_reread() -> void:
	var case_name := "write_then_reread"
	var tracker := await _make_tracker()
	tracker.record_lesson_complete("lesson_1", 42.5)

	var data := _read_progress_file(case_name)
	if _failed:
		return

	if int(data.get("version", -1)) != 1:
		_fail(case_name, "version was %s, expected 1" % [data.get("version")])
		return
	if not (data.has("entries") and data["entries"] is Array):
		_fail(case_name, "entries missing or not an Array")
		return

	var entries: Array = data["entries"]
	if entries.size() != 1:
		_fail(case_name, "entries has %d elements, expected 1" % entries.size())
		return

	var entry: Dictionary = entries[0]
	var keys: Array = entry.keys()
	keys.sort()
	var expected_keys: Array = ["completed_at", "lesson_id", "stars", "time_seconds"]
	if keys != expected_keys:
		_fail(case_name, "entry keys were %s, expected %s" % [keys, expected_keys])
		return
	if entry["lesson_id"] != "lesson_1":
		_fail(case_name, "lesson_id was %s, expected lesson_1" % entry["lesson_id"])
		return
	if entry["stars"] != 3:
		_fail(case_name, "stars was %s, expected 3" % entry["stars"])
		return
	if not (entry["time_seconds"] is float or entry["time_seconds"] is int) or absf(float(entry["time_seconds"]) - 42.5) > 0.001:
		_fail(case_name, "time_seconds was %s, expected 42.5" % entry["time_seconds"])
		return
	if String(entry["completed_at"]).is_empty():
		_fail(case_name, "completed_at was empty")
		return
	if FileAccess.file_exists(PROGRESS_TMP_PATH):
		_fail(case_name, "%s still exists after a successful write" % PROGRESS_TMP_PATH)
		return

	print("[probe_progress_persistence] user data dir: %s" % OS.get_user_data_dir())
	print("[probe_progress_persistence] progress.json after write_then_reread: %s" % JSON.stringify(data, "\t"))

	_free_tracker(tracker)
	_cases_run += 1
	print("PASS %s" % case_name)
