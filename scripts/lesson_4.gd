# lesson_4.gd
# Lesson 4's orchestrator (D-35: every lesson owns its own script; no shared
# base this phase). The rule is all three tasks in any order -- touch the
# yellow target, touch the green target, gather all three counting objects --
# tracked in one array and checked against one total.
#
# This file is deliberately the same shape as scripts/lesson_1.gd over a second
# colour pair, which is exactly what D-43 asks for: lesson 4 is a second
# colour-recognition-and-counting task, so building it on lesson 1's rule
# exercises the D-36 fix a second time rather than inventing a second rule to
# get wrong. The archived lesson_manager.gd tested only two of its three tasks,
# so a child who finished the counting task first was locked into a lesson that
# could never end. Nothing below branches on which task arrived first: there is
# one array, one append, one label update and one comparison against the total.
#
# The duplication with lesson 1 is recorded rather than removed. D-35 keeps the
# five orchestrators independent for this phase and the shared-lesson pattern is
# explicitly a later phase's scope (MORE-02). No shared base, no global class
# name and no helper autoload was extracted from it.
#
# What the archive shipped under this name was ten lines -- `_ready(): pass` --
# inside a scene whose own label told a child the lesson was available. That is
# the one defect a forbidden-phrase scan cannot catch, so the guard against it
# is a probe that drives this lesson to a real completion from two different
# task orders and then reads the result back off the disk.
extends Node3D

# ── Signals ──────────────────────────────────────────────────────

# Observability-only, emitted one line before the deferred engine call it
# shadows -- the same seam the title screen, the main menu, the intro level and
# the first three lessons already carry, because a deferred scene change cannot
# be counted from outside.
signal transition_requested(target_path: String)

# The seam a probe counts a completion through. It never stands in for the
# file: D-42 is satisfied by reading user://progress.json back off the disk,
# because the archived tracker's record function was never called by anything
# and a signal assertion would have passed for years.
signal lesson_completed(lesson_id: String, time_seconds: float)

# ── Constants ────────────────────────────────────────────────────

const LESSON_ID := "lesson_4"
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

	%YellowTarget.task_completed.connect(_on_task_completed)
	%GreenTarget.task_completed.connect(_on_task_completed)
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
	%Hud.set_title("Les 4 - Geel, groen en tellen")
	%Hud.set_step(0, TOTAL_TASKS)


# ── Signal handlers ──────────────────────────────────────────────

## One handler for all five targets. A single counting object is not a task of
## its own: all three must be gathered before the one "count" task is marked,
## which keeps the completion check at exactly three while still making the
## child count to three. The counting objects may also arrive interleaved with
## the two colour targets, which is why the gathered set is state rather than a
## streak -- a colour target landing between two counting objects must not cost
## the child the ones they already gathered.
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


## The same one-shot guard and deferred scene change the shipped screens use
## (D-15), reached from the in-play return control and the win panel's return
## control alike.
func _on_hud_back_requested() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(LESSON_SELECT_PATH)
	get_tree().change_scene_to_file.call_deferred(LESSON_SELECT_PATH)


# ── Internal helpers ─────────────────────────────────────────────

## The whole of this lesson's rule: one array, one size, one comparison against
## the total. No arrival order is special-cased, and no subset of the tasks can
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
## their result. How many the result is worth is the tracker's own constant
## (D-41), so this lesson has no scoring rule of its own to disagree with.
func _apply_lesson_complete() -> void:
	var time_seconds := float(Time.get_ticks_msec() - _start_time_msec) / 1000.0
	ProgressTracker.record_lesson_complete(LESSON_ID, time_seconds)
	lesson_completed.emit(LESSON_ID, time_seconds)
	%Hud.show_win()
	_camiel.set_physics_process(false)
	AudioManager.play_sfx("finish")
	VoiceManager.play("complete")
