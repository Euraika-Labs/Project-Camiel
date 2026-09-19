# lesson_1.gd
# Lesson 1's orchestrator (D-35: every lesson owns its own script; no shared
# base this phase). The rule is all three tasks in any order -- touch the red
# target, touch the blue target, gather all three counting objects -- tracked
# in one array and checked against one total (D-36).
#
# The archived lesson_manager.gd tested only the red and blue tasks, so a child
# who finished the counting task first was locked into a lesson that could
# never end. Nothing below branches on which task arrived first: there is one
# array, one append, one label update and one comparison against the total.
extends Node3D

# ── Signals ──────────────────────────────────────────────────────

# Observability-only, emitted one line before the deferred engine call it
# shadows -- the same seam the title screen, the main menu and the intro level
# already carry, because a deferred scene change cannot be counted from
# outside.
signal transition_requested(target_path: String)

# The seam a probe counts a completion through. It never stands in for the
# file: D-42 is satisfied by reading user://progress.json back off the disk,
# because the archived tracker's record function was never called by anything
# and a signal assertion would have passed for years.
signal lesson_completed(lesson_id: String, time_seconds: float)

# ── Constants ────────────────────────────────────────────────────

const LESSON_ID := "lesson_1"
const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"
const TOTAL_TASKS := 3
const COUNT_TOTAL := 3
const COUNT_TASK_ID := "count"

# ── Node references ──────────────────────────────────────────────

@onready var _camiel: CharacterBody3D = $Camiel

# ── Private state ────────────────────────────────────────────────

var _completed_tasks: Array[String] = []
var _gathered_count_objects: Array[String] = []
var _count_task_ids: Array[String] = []
var _start_time_msec := 0
var _transitioning := false


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	VoiceManager.bind_scene(self, LESSON_ID)
	_start_time_msec = Time.get_ticks_msec()

	%RedTarget.task_completed.connect(_on_task_completed)
	%BlueTarget.task_completed.connect(_on_task_completed)
	for child: Node in %CountGroup.get_children():
		var count_target := child as Area3D
		if count_target == null:
			continue
		_count_task_ids.append(String(count_target.task_id))
		count_target.task_completed.connect(_on_task_completed)

	# Both of the shared display's return signals land on one handler, whose
	# guard makes the second arrival a no-op, and both go to lesson-select
	# rather than the main menu (D-34) so browsing context is not lost.
	%Hud.back_requested.connect(_on_hud_back_requested)
	%Hud.win_back_requested.connect(_on_hud_back_requested)
	%Hud.set_title("Les 1 - Rood, blauw en tellen")
	%Hud.set_step(0, TOTAL_TASKS)


# ── Signal handlers ──────────────────────────────────────────────

## One handler for all five targets. A single counting object is not a task of
## its own: all three must be gathered before the one "count" task is marked,
## which keeps the completion check at exactly three and the progress label at
## three steps (D-46) while still making the child count to three.
func _on_task_completed(task_id: String) -> void:
	if _count_task_ids.has(task_id):
		if not _gathered_count_objects.has(task_id):
			_gathered_count_objects.append(task_id)
			VoiceManager.play("correct")
		if _gathered_count_objects.size() < COUNT_TOTAL:
			return
		_mark_task(COUNT_TASK_ID)
		return
	_mark_task(task_id)


## The same one-shot guard and deferred scene change the two shipped screens
## use (D-15), reached from the in-play return control and the win panel's
## return control alike.
func _on_hud_back_requested() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(LESSON_SELECT_PATH)
	get_tree().change_scene_to_file.call_deferred(LESSON_SELECT_PATH)


# ── Internal helpers ─────────────────────────────────────────────

## The whole of LESSON-01: one array, one size, one comparison against the
## total. No arrival order is special-cased, and no subset of the tasks can
## satisfy the check.
func _mark_task(task_id: String) -> void:
	if not _completed_tasks.has(task_id):
		_completed_tasks.append(task_id)
		VoiceManager.play("correct")
	%Hud.set_step(_completed_tasks.size(), TOTAL_TASKS)
	if _completed_tasks.size() == TOTAL_TASKS:
		_apply_lesson_complete()


## Writes the child's result before anything celebratory happens and behind no
## timer at all. The archived failure was a save function that existed and was
## never reached; saving first means a probe reading the file has no race to
## lose, and a child who closes the window at the celebration has still kept
## their result.
func _apply_lesson_complete() -> void:
	var time_seconds := float(Time.get_ticks_msec() - _start_time_msec) / 1000.0
	ProgressTracker.record_lesson_complete(LESSON_ID, time_seconds)
	lesson_completed.emit(LESSON_ID, time_seconds)
	%Hud.show_win()
	_camiel.set_physics_process(false)
	AudioManager.play_sfx("finish")
	VoiceManager.play("complete")
