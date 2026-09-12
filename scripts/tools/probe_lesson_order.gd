# probe_lesson_order.gd
# Headless proof that each of this phase's lessons finishes by its own stated
# rule (LESSON-01..LESSON-05) and that the finish reached the disk (PROGRESS-02,
# D-42). Lesson 1's rule is all three tasks in any order (D-36): the archived
# lesson checked only the red and blue tasks, so a child who finished the
# counting task first was locked into a lesson that could never end. That is
# exactly why the first case below does the counting task FIRST -- a probe that
# only ever drove colours-first would prove nothing about the defect being
# fixed.
#
# This probe drives real completions through the real ProgressTracker autoload,
# which writes to the same user://progress.json a real child's history lives
# at, so it moves any existing file aside before its cases and restores it on
# both the success and the failure path -- the same hygiene
# probe_progress_persistence.gd established in plan 03-01.
# Run by scripts/tools/run_headless_check.sh.
extends SceneTree

# ── Constants ────────────────────────────────────────────────────

const PROGRESS_PATH := "user://progress.json"
const PROGRESS_TMP_PATH := "user://progress.json.tmp"
const BACKUP_PATH := "user://progress.json.probe_backup"

const LESSON_1_PATH := "res://scenes/lesson_1.tscn"
const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"

# ── Internal state ───────────────────────────────────────────────

var _failed := false
var _cases_run := 0
var _took_backup := false

var _target_completed_count := 0
var _target_completed_ids: Array[String] = []
var _lesson_completed_count := 0
var _lesson_completed_ids: Array[String] = []
var _lesson_completed_times: Array[float] = []
var _transition_count := 0
var _transition_target := ""


# ── Lifecycle ────────────────────────────────────────────────────

func _initialize() -> void:
	_take_progress_backup()

	await _case_lesson_1_count_first()
	if _failed:
		return

	if _cases_run == 0:
		_fail("non_vacuity", "no case ran; the probe would verify nothing")
		return

	_restore_progress_backup()
	print("Lesson order probe passed.")
	quit(0)


func _fail(case_name: String, detail: String) -> void:
	_failed = true
	_restore_progress_backup()
	push_error("%s: %s" % [case_name, detail])
	quit(1)


# ── Save-file hygiene ────────────────────────────────────────────

## Moves any real user://progress.json aside before this probe's cases run, so
## a real child's saved history is never touched by this check.
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


## Removes whatever this probe left behind and puts the real file back. Called
## immediately before the success exit and as the first statement of _fail(),
## so the failure path restores the save just as reliably as the success path.
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


# ── Signal counters ──────────────────────────────────────────────

func _on_target_completed_counted(task_id: String) -> void:
	_target_completed_count += 1
	_target_completed_ids.append(task_id)


func _on_lesson_completed_counted(lesson_id: String, time_seconds: float) -> void:
	_lesson_completed_count += 1
	_lesson_completed_ids.append(lesson_id)
	_lesson_completed_times.append(time_seconds)


func _on_transition_requested_counted(target_path: String) -> void:
	_transition_count += 1
	_transition_target = target_path


# ── Helpers ──────────────────────────────────────────────────────

# Mirrors probe_screen_flow.gd's synthesised accept-action helper.
func _press_focused() -> void:
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = "ui_accept"
	release.pressed = false
	Input.parse_input_event(release)


# A guarded handler really does request a scene change, so after the first
# activation the engine loads the target scene into the tree and its own ready
# callback grabs focus on its own control. Without draining, the second
# activation in a guard test would land on a different screen and the case
# would be measuring the wrong thing. Mirrors probe_screen_flow.gd.
func _drain_scene_change() -> void:
	await process_frame
	await process_frame
	if current_scene != null:
		var stale: Node = current_scene
		root.remove_child(stale)
		stale.free()
		set_current_scene(null)


## Instantiates a lesson scene under the root and returns the handful of nodes
## every case needs from it. Returns an empty dictionary after failing the case
## if anything the lesson contract promises is missing.
func _open_lesson(case_name: String, scene_path: String) -> Dictionary:
	if not ResourceLoader.exists(scene_path):
		_fail(case_name, "%s does not exist" % scene_path)
		return {}
	var packed: PackedScene = load(scene_path)
	if packed == null:
		_fail(case_name, "%s did not load as a PackedScene" % scene_path)
		return {}

	var lesson: Node = packed.instantiate()
	if not lesson is Node3D:
		_fail(case_name, "%s root is not a Node3D" % scene_path)
		lesson.free()
		return {}
	root.add_child(lesson)
	await process_frame
	await process_frame

	var camiel: CharacterBody3D = lesson.get_node_or_null("Camiel")
	if camiel == null:
		_fail(case_name, "%s has no Camiel child" % scene_path)
		return {}
	var hud: CanvasLayer = lesson.get_node_or_null("%Hud")
	if hud == null:
		_fail(case_name, "%s has no %%Hud child" % scene_path)
		return {}
	var step_label: Label = hud.get_node_or_null("%StepLabel")
	if step_label == null:
		_fail(case_name, "the shared display in %s has no %%StepLabel" % scene_path)
		return {}
	var win_back_button: Button = hud.get_node_or_null("%WinBackButton")
	if win_back_button == null:
		_fail(case_name, "the shared display in %s has no %%WinBackButton" % scene_path)
		return {}

	return {
		"lesson": lesson,
		"camiel": camiel,
		"hud": hud,
		"step_label": step_label,
		"win_back_button": win_back_button,
	}


## Collects lesson 1's five targets in a stable, named shape: the red target,
## the blue target, and the counting objects in the order the scene declares
## them. Iterating the counting group rather than naming three nodes keeps this
## helper correct if a lesson ever counts to a different number.
func _lesson_1_targets(case_name: String, lesson: Node) -> Dictionary:
	var red: Area3D = lesson.get_node_or_null("%RedTarget")
	if red == null:
		_fail(case_name, "lesson 1 has no %RedTarget")
		return {}
	var blue: Area3D = lesson.get_node_or_null("%BlueTarget")
	if blue == null:
		_fail(case_name, "lesson 1 has no %BlueTarget")
		return {}
	var group: Node3D = lesson.get_node_or_null("%CountGroup")
	if group == null:
		_fail(case_name, "lesson 1 has no %CountGroup")
		return {}

	var counts: Array[Area3D] = []
	for child: Node in group.get_children():
		var area := child as Area3D
		if area != null:
			counts.append(area)
	if counts.size() != 3:
		_fail(case_name, "%%CountGroup holds %d counting targets, expected 3 -- counting to three means three objects" % counts.size())
		return {}

	return {"red": red, "blue": blue, "counts": counts}


## Connects this probe's own counter to every target's completion signal, so a
## case can wait on a specific target's touch landing rather than on a label
## changing -- the counting objects deliberately do not move the label until
## the third one is gathered.
func _watch_targets(red: Area3D, blue: Area3D, counts: Array[Area3D]) -> void:
	red.task_completed.connect(_on_target_completed_counted)
	blue.task_completed.connect(_on_target_completed_counted)
	for count_target: Area3D in counts:
		count_target.task_completed.connect(_on_target_completed_counted)


## Teleports the character onto one target and waits, bounded, for that touch
## to register through the target's own completion signal. The 120-physics-frame
## ceiling is the same one the shipped screen-flow and lesson-kit probes use.
## Returns the number of frames waited, or -1 if the touch never registered.
func _touch_target(camiel: CharacterBody3D, target: Area3D) -> int:
	var before := _target_completed_count
	camiel.teleport_to(target.global_position)
	var frames_waited := 0
	while _target_completed_count == before and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _target_completed_count != before + 1:
		return -1
	return frames_waited


## Opens the real progress file, parses it with the instance parser (never the
## static JSON.parse_string(), whose engine ERROR: line would fail this
## repository's headless check even on a correct recovery path), and returns
## the parsed dictionary.
func _read_progress_file(case_name: String) -> Dictionary:
	if not FileAccess.file_exists(PROGRESS_PATH):
		_fail(case_name, "%s was not created by a real lesson completion" % PROGRESS_PATH)
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


## Returns the entries array the progress file on disk currently holds, or an
## empty array when no file exists yet. Used for the before/after counting the
## append-log schema (D-40) makes meaningful.
func _disk_entry_count() -> int:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return 0
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if f == null:
		return 0
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return 0
	var data: Variant = json.get_data()
	if not (data is Dictionary) or not (data.get("entries") is Array):
		return 0
	return (data["entries"] as Array).size()


## Asserts the last entry on disk is a well-formed completion of `lesson_id`
## with all four fields PROGRESS-02 requires. This is D-42's whole point: the
## archived tracker's record function was never called by anything, so an
## assertion on a saved signal would have passed for years while no child's
## progress was ever written.
func _assert_last_entry(case_name: String, lesson_id: String) -> bool:
	var data := _read_progress_file(case_name)
	if _failed:
		return false
	if not (data.get("entries") is Array):
		_fail(case_name, "progress file has no entries array")
		return false
	var entries: Array = data["entries"]
	if entries.is_empty():
		_fail(case_name, "progress file holds no entries after a real completion")
		return false

	var last: Dictionary = entries[entries.size() - 1]
	if last.get("lesson_id", "") != lesson_id:
		_fail(case_name, "last entry's lesson_id is %s, expected %s" % [last.get("lesson_id"), lesson_id])
		return false
	if int(last.get("stars", -1)) != 3:
		_fail(case_name, "last entry's stars is %s, expected 3" % [last.get("stars")])
		return false
	var time_value: Variant = last.get("time_seconds", null)
	if not (time_value is float or time_value is int):
		_fail(case_name, "last entry's time_seconds is %s, expected a number" % [time_value])
		return false
	if float(time_value) <= 0.0:
		_fail(case_name, "last entry's time_seconds is %s, expected greater than zero" % [time_value])
		return false
	if String(last.get("completed_at", "")).is_empty():
		_fail(case_name, "last entry's completed_at is empty")
		return false

	print("[probe_lesson_order] %s last progress entry: %s" % [case_name, JSON.stringify(last, "\t")])
	return true


## Presses the win panel's return control, asserts exactly one transition to
## lesson-select, drains the scene change the handler really requested, presses
## the same control again, and asserts the one-shot guard blocked the second
## activation (D-34, D-15).
func _assert_win_return_is_one_shot(case_name: String, lesson: Node, win_back_button: Button) -> bool:
	_transition_count = 0
	_transition_target = ""
	lesson.transition_requested.connect(_on_transition_requested_counted)

	if not win_back_button.has_focus():
		_fail(case_name, "the win panel's return control does not hold focus after the lesson finished")
		return false

	_press_focused()
	await process_frame
	await process_frame

	if _transition_count != 1:
		_fail(case_name, "transition_requested fired %d times, expected 1" % _transition_count)
		return false
	if _transition_target != LESSON_SELECT_PATH:
		_fail(case_name, "transition_requested carried %s, expected %s -- both of a lesson's return controls go to lesson-select, never the main menu (D-34)" % [_transition_target, LESSON_SELECT_PATH])
		return false

	await _drain_scene_change()

	win_back_button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _transition_count != 1:
		_fail(case_name, "the one-shot guard did not block a second activation; count is %d" % _transition_count)
		return false

	lesson.transition_requested.disconnect(_on_transition_requested_counted)
	return true


# ── Cases ────────────────────────────────────────────────────────

## The tracer: lesson 1 driven with the counting task FIRST -- the exact order
## that permanently soft-locked the archived lesson -- and the resulting
## completion read back off the filesystem.
func _case_lesson_1_count_first() -> void:
	var case_name := "lesson_1_count_first"
	var opened: Dictionary = await _open_lesson(case_name, LESSON_1_PATH)
	if _failed:
		return
	var lesson: Node = opened["lesson"]
	var camiel: CharacterBody3D = opened["camiel"]
	var hud: CanvasLayer = opened["hud"]
	var step_label: Label = opened["step_label"]
	var win_back_button: Button = opened["win_back_button"]

	var targets := _lesson_1_targets(case_name, lesson)
	if _failed:
		return
	var red: Area3D = targets["red"]
	var blue: Area3D = targets["blue"]
	var counts: Array[Area3D] = targets["counts"]

	if step_label.text != "Stap: 0 / 3":
		_fail(case_name, "the progress label reads %s at the start of the lesson, expected Stap: 0 / 3" % step_label.text)
		return
	if hud.is_win_visible():
		_fail(case_name, "the win panel is already visible before the lesson was played")
		return

	_target_completed_count = 0
	_target_completed_ids.clear()
	_lesson_completed_count = 0
	_lesson_completed_ids.clear()
	_lesson_completed_times.clear()
	_watch_targets(red, blue, counts)
	lesson.lesson_completed.connect(_on_lesson_completed_counted)

	var entries_before := _disk_entry_count()

	# The counting task first. Two of three gathered is not two thirds of a
	# task -- it is not a task at all, so the label must not move until the
	# third object is gathered.
	for i in counts.size():
		var frames := await _touch_target(camiel, counts[i])
		if frames < 0:
			_fail(case_name, "counting object %d never registered a touch within 120 physics frames" % (i + 1))
			return
		print("[probe_lesson_order] count object %d frames to touch: %d" % [i + 1, frames])
		var expected := "Stap: 0 / 3" if i < counts.size() - 1 else "Stap: 1 / 3"
		if step_label.text != expected:
			_fail(case_name, "after gathering %d of %d counting objects the label reads %s, expected %s" % [i + 1, counts.size(), step_label.text, expected])
			return
		if _lesson_completed_count != 0:
			_fail(case_name, "the lesson completed after only the counting task; it must need all three tasks (D-36)")
			return

	var blue_frames := await _touch_target(camiel, blue)
	if blue_frames < 0:
		_fail(case_name, "the blue target never registered a touch within 120 physics frames")
		return
	if step_label.text != "Stap: 2 / 3":
		_fail(case_name, "after the blue target the label reads %s, expected Stap: 2 / 3" % step_label.text)
		return
	if _lesson_completed_count != 0:
		_fail(case_name, "the lesson completed on two of three tasks -- this is the archived defect, in a new place")
		return

	var red_frames := await _touch_target(camiel, red)
	if red_frames < 0:
		_fail(case_name, "the red target never registered a touch within 120 physics frames")
		return
	if step_label.text != "Stap: 3 / 3":
		_fail(case_name, "after the red target the label reads %s, expected Stap: 3 / 3" % step_label.text)
		return

	await process_frame
	await process_frame

	if _lesson_completed_count != 1:
		_fail(case_name, "lesson_completed fired %d times, expected exactly 1" % _lesson_completed_count)
		return
	if _lesson_completed_ids[0] != "lesson_1":
		_fail(case_name, "lesson_completed carried %s, expected lesson_1" % _lesson_completed_ids[0])
		return
	if not hud.is_win_visible():
		_fail(case_name, "the win panel is not visible after the lesson finished")
		return
	if camiel.is_physics_processing():
		_fail(case_name, "the character's physics processing is still on after the lesson finished")
		return

	if not _assert_last_entry(case_name, "lesson_1"):
		return
	var entries_after := _disk_entry_count()
	if entries_after != entries_before + 1:
		_fail(case_name, "the progress file holds %d entries, expected %d -- one completion appends exactly one entry (D-40)" % [entries_after, entries_before + 1])
		return

	if not await _assert_win_return_is_one_shot(case_name, lesson, win_back_button):
		return

	lesson.lesson_completed.disconnect(_on_lesson_completed_counted)
	lesson.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)
