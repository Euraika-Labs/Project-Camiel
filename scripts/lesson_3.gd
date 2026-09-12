# lesson_3.gd
# Lesson 3's orchestrator (D-35: every lesson owns its own script; no shared
# base this phase). The rule is 1, then 2, then 3 -- and the lesson is
# structurally unable to finish any other way.
#
# This file is deliberately the same shape as scripts/lesson_2.gd over its own
# three targets. The duplication is recorded rather than removed: D-35 keeps
# the five orchestrators independent for this phase, and the shared-lesson
# pattern is explicitly a later phase's scope (MORE-02). No shared base, no
# global class name and no helper autoload was extracted from it.
#
# The order lives in the array of target nodes below, and that array is USED:
# every advance activates its next element, and every other target is inactive
# with no code path that reaches a completion (D-37). No comparison of an
# arriving identifier appears anywhere in this file -- a declared-and-never-read
# comparison is exactly the archived lesson_2.gd defect, and leaving one here
# would invite the next reader to believe the comparison is the mechanism.
#
# The refusal a wrong touch earns is not listened to here. A target's small
# scale dip is the whole of a child's feedback (D-38); nothing flashes red,
# nothing is taken away, and no numeral is ever rewritten -- the archived
# sequence_target.gd's error flash replaced a target's own label with its order
# number and lost the text permanently.
extends Node3D

# ── Signals ──────────────────────────────────────────────────────

# Observability-only, emitted one line before the deferred engine call it
# shadows -- the same seam the title screen, the main menu, the intro level and
# lessons 1 and 2 already carry, because a deferred scene change cannot be
# counted from outside.
signal transition_requested(target_path: String)

# The seam a probe counts a completion through. It never stands in for the
# file: D-42 is satisfied by reading user://progress.json back off the disk,
# because the archived tracker's record function was never called by anything
# and a signal assertion would have passed for years.
signal lesson_completed(lesson_id: String, time_seconds: float)

# ── Constants ────────────────────────────────────────────────────

const LESSON_ID := "lesson_3"
const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"
const TOTAL_TASKS := 3

# ── Node references ──────────────────────────────────────────────

## The order. Nothing else in this file states it, and nothing compares against
## it -- the array is read to decide which target becomes live next, which is
## the only thing that makes the order real.
@onready var _sequence: Array[Area3D] = [
	%Step1Target as Area3D,
	%Step2Target as Area3D,
	%Step3Target as Area3D,
]

@onready var _camiel: CharacterBody3D = $Camiel

# ── Private state ────────────────────────────────────────────────

var _step := 0
var _completed_tasks: Array[String] = []
var _start_time_msec := 0
var _transitioning := false


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	_start_time_msec = Time.get_ticks_msec()

	for target: Area3D in _sequence:
		target.task_completed.connect(_on_task_completed)

	# Both of the shared display's return signals land on one handler, whose
	# guard makes the second arrival a no-op, and both go to lesson-select
	# rather than the main menu (D-34) so browsing context is not lost.
	%Hud.back_requested.connect(_on_hud_back_requested)
	%Hud.win_back_requested.connect(_on_hud_back_requested)
	%Hud.set_title("Les 3 - Van 1 naar 3")
	%Hud.set_step(0, TOTAL_TASKS)

	# The first turn. Every target in the scene requires activation, including
	# this one, so all three are uniform and the advance below has exactly one
	# code path rather than a first-step special case.
	_sequence[_step].activate()


# ── Signal handlers ──────────────────────────────────────────────

## One handler for all three numbers. Only the live target can reach it, so the
## identifier that arrives is necessarily the one whose turn it was; checking it
## here would put the shape of the archived defect straight back into the file
## while changing no behaviour at all.
func _on_task_completed(task_id: String) -> void:
	_completed_tasks.append(task_id)
	_step += 1
	%Hud.set_step(_completed_tasks.size(), TOTAL_TASKS)
	if _step >= _sequence.size():
		_apply_lesson_complete()
		return
	_sequence[_step].activate()


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
