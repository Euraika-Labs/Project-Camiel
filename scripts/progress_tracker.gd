# progress_tracker.gd
# Autoload singleton and single owner of the child's saved lesson history at
# user://progress.json. Exists to not repeat three archived defects: passing
# a nonexistent JSON constant as the stringify indent argument, which failed
# this autoload to compile at every single startup; never once calling
# record_lesson_complete(), so progress was never written while the parent
# dashboard docs claimed it was; and a schema with no version field and no
# atomic write, so one corrupt write could lose the whole history.
extends Node

# ── Signals ──────────────────────────────────────────────────────

## Emitted after a completion has been written to disk. Declared for
## observability only — D-42 forbids treating this as evidence that a write
## actually happened; nothing in this phase asserts on it.
signal progress_saved

# ── Constants ────────────────────────────────────────────────────

const PROGRESS_PATH := "user://progress.json"
const PROGRESS_TMP_PATH := "user://progress.json.tmp"
const SCHEMA_VERSION := 1
const STARS_PER_COMPLETION := 3

# ── Internal state ───────────────────────────────────────────────

var _entries: Array[Dictionary] = []


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	_entries = _load_entries()


# ── Public API ───────────────────────────────────────────────────

## Record one lesson completion. lesson_id and time_seconds are the caller's
## real values; stars is always STARS_PER_COMPLETION (D-41) — no scoring
## rubric exists anywhere in this codebase, so no call site can invent one.
## Appends to the on-disk history (D-40's append-log schema), writes it
## atomically (D-39), then emits progress_saved.
func record_lesson_complete(lesson_id: String, time_seconds: float) -> void:
	var entry := {
		"lesson_id": lesson_id,
		"stars": STARS_PER_COMPLETION,
		"time_seconds": time_seconds,
		"completed_at": Time.get_datetime_string_from_system(),
	}
	_entries.append(entry)
	_write_entries()
	progress_saved.emit()


## Returns a duplicate of the loaded history, never the live array, so no
## caller can mutate saved state through this accessor.
func get_entries() -> Array[Dictionary]:
	return _entries.duplicate(true)


# ── Internal helpers ─────────────────────────────────────────────

func _load_entries() -> Array[Dictionary]:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return []  # Ordinary first run on a machine that has never played.

	var f := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if f == null:
		push_warning("[ProgressTracker] Could not open %s: %s" % [PROGRESS_PATH, error_string(FileAccess.get_open_error())])
		return []

	var text := f.get_as_text()
	f.close()

	# The static one-call JSON.parse_string() prints an engine ERROR: line on
	# invalid input even though it returns null cleanly to the caller, and
	# this repository's headless check fails the entire run on any such
	# line — so a corrupt or truncated file would turn the check red the
	# moment this path is exercised, even though the recovery itself is
	# correct. JSON.new().parse() returns an Error code silently, which is
	# the only call that keeps a fail-soft recovery path fail-soft under CI.
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("[ProgressTracker] Corrupt progress file, starting fresh: %s (line %d)" % [json.get_error_message(), json.get_error_line()])
		return []

	var data: Variant = json.get_data()
	if not (data is Dictionary) or not data.has("entries") or not (data["entries"] is Array):
		push_warning("[ProgressTracker] Unexpected progress file shape, starting fresh.")
		return []

	var typed: Array[Dictionary] = []
	for item: Variant in data["entries"]:
		if item is Dictionary:
			typed.append(item)
	return typed


func _write_entries() -> void:
	var data := {"version": SCHEMA_VERSION, "entries": _entries}
	var json_text := JSON.stringify(data, "\t")

	var tmp := FileAccess.open(PROGRESS_TMP_PATH, FileAccess.WRITE)
	if tmp == null:
		push_warning("[ProgressTracker] Could not open tmp file for write: %s" % error_string(FileAccess.get_open_error()))
		return
	tmp.store_string(json_text)
	tmp.close()

	# D-39: atomic rename over any existing target. Research verified this
	# rename returns OK both with no existing target and with one, and that
	# it fully replaces the target's content rather than merging it.
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(PROGRESS_TMP_PATH),
		ProjectSettings.globalize_path(PROGRESS_PATH)
	)
	if err != OK:
		push_warning("[ProgressTracker] Atomic rename failed: %s" % error_string(err))
