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
# Lessons 2 and 3 are the mirror image: their rules are written as negatives
# (LESSON-02, LESSON-03), so their cases lead with an out-of-turn touch and
# assert it refused and completed NOTHING before they ever drive the correct
# order. The archived lesson_2.gd declared an order array and never read it, so
# every order completed the lesson -- a case that only drove the correct order
# would have passed on that code too, which is why the negative half comes
# first here.
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
const LESSON_2_PATH := "res://scenes/lesson_2.tscn"
const LESSON_3_PATH := "res://scenes/lesson_3.tscn"
const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"

## A corner of the shared room that is at least 4 m from every target in every
## lesson this probe drives, used to take the character off a target so a later
## teleport onto it is a genuine fresh entry rather than a body that never left.
const PARKING_SPOT := Vector3(5, 0.1, 5)

## Every ordered lesson shares the shared display's three-step label form
## (D-46), so the label a child must see after step N is derivable rather than
## restated per lesson.
const ORDERED_TOTAL := 3

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

## One refusal counter per target node name. Separate counters rather than one
## total, because "the square refused" and "something refused" are different
## claims and only the first one proves the gate refused the right target.
var _rejection_counts: Dictionary = {}


# ── Lifecycle ────────────────────────────────────────────────────

func _initialize() -> void:
	_take_progress_backup()

	await _case_lesson_1_count_first()
	if _failed:
		return
	await _case_lesson_1_other_orders()
	if _failed:
		return
	await _case_lesson_1_guards()
	if _failed:
		return
	await _case_lesson_2_order_enforced()
	if _failed:
		return
	await _case_lesson_3_order_enforced()
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


## The refusal counter, bound to the refusing target's node name at connection
## time (this project's convention for passing context from a signal). The
## `rejected` signal carries no arguments precisely so the target stays silent
## about its own identity; the binding is what lets a case name it.
func _on_target_rejected_counted(target_name: String) -> void:
	_rejection_counts[target_name] = int(_rejection_counts.get(target_name, 0)) + 1


func _rejections(target: Area3D) -> int:
	return int(_rejection_counts.get(String(target.name), 0))


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


## Drives one lesson-1 instance through an explicit sequence of touches, each
## paired with the exact progress label a child must see after it, and asserts
## the lesson finishes exactly once and only on the final touch. Pairing every
## touch with its own expected label is what turns "the lesson eventually
## finished" into "the lesson counted correctly at every step" -- an early
## completion, or a counting object that wrongly counts on its own, fails on the
## step it happened rather than being absorbed by a passing end state.
func _drive_touch_sequence(case_name: String, opened: Dictionary, targets: Dictionary, sequence: Array) -> bool:
	var lesson: Node = opened["lesson"]
	var camiel: CharacterBody3D = opened["camiel"]
	var hud: CanvasLayer = opened["hud"]
	var step_label: Label = opened["step_label"]

	if step_label.text != "Stap: 0 / 3":
		_fail(case_name, "the progress label reads %s at the start of the lesson, expected Stap: 0 / 3" % step_label.text)
		return false
	if hud.is_win_visible():
		_fail(case_name, "the win panel is already visible before the lesson was played")
		return false

	_target_completed_count = 0
	_target_completed_ids.clear()
	_lesson_completed_count = 0
	_lesson_completed_ids.clear()
	_lesson_completed_times.clear()
	_watch_targets(targets["red"], targets["blue"], targets["counts"])
	lesson.lesson_completed.connect(_on_lesson_completed_counted)

	for i in sequence.size():
		var target: Area3D = sequence[i][0]
		var expected_label: String = sequence[i][1]
		if await _touch_target(camiel, target) < 0:
			_fail(case_name, "step %d (%s) never registered a touch within 120 physics frames" % [i + 1, target.name])
			return false
		if step_label.text != expected_label:
			_fail(case_name, "after step %d (%s) the label reads %s, expected %s" % [i + 1, target.name, step_label.text, expected_label])
			return false
		if i < sequence.size() - 1 and _lesson_completed_count != 0:
			_fail(case_name, "the lesson finished at step %d of %d, before all three tasks were done" % [i + 1, sequence.size()])
			return false

	await process_frame
	await process_frame

	if _lesson_completed_count != 1:
		_fail(case_name, "lesson_completed fired %d times, expected exactly 1" % _lesson_completed_count)
		return false
	if _lesson_completed_ids[0] != "lesson_1":
		_fail(case_name, "lesson_completed carried %s, expected lesson_1" % _lesson_completed_ids[0])
		return false
	if _lesson_completed_times[0] <= 0.0:
		_fail(case_name, "lesson_completed carried an elapsed time of %s, expected greater than zero" % _lesson_completed_times[0])
		return false
	if not hud.is_win_visible():
		_fail(case_name, "the win panel is not visible after the lesson finished")
		return false
	if camiel.is_physics_processing():
		_fail(case_name, "the character's physics processing is still on after the lesson finished")
		return false
	if not _assert_last_entry(case_name, "lesson_1"):
		return false

	lesson.lesson_completed.disconnect(_on_lesson_completed_counted)
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


# ── Ordered-lesson helpers (LESSON-02, LESSON-03) ────────────────

## Collects an ordered lesson's targets by the unique names its own scene
## declares, in the order that lesson's rule requires them. The array this
## returns is the order the case drives; the lesson's own script holds the same
## order as an array of the same nodes, and that is the only place either states
## it.
## The exact label a child must see after step `current` of an ordered lesson,
## built from its parts. Deliberately NOT the shared display's own format
## string: that string exists in exactly one .gd file in this repository
## (scripts/ui/lesson_hud.gd), and a probe that copied it would silently agree
## with the display about any change to it instead of catching one.
func _step_label_text(current: int) -> String:
	return "Stap: " + str(current) + " / " + str(ORDERED_TOTAL)


func _ordered_targets(case_name: String, lesson: Node, target_names: Array) -> Array[Area3D]:
	var targets: Array[Area3D] = []
	for raw_name: String in target_names:
		var target: Area3D = lesson.get_node_or_null("%%%s" % raw_name)
		if target == null:
			_fail(case_name, "%s has no %%%s" % [lesson.name, raw_name])
			return []
		targets.append(target)
	return targets


## Connects this probe's own counters: one shared completion counter across
## every target, and one refusal counter per target. The orchestrator
## deliberately does not listen for a refusal, so after this every completion
## signal carries exactly two connections and every refusal signal exactly one
## -- the numbers the connection-count assertions below are written against.
func _watch_ordered_targets(targets: Array[Area3D]) -> void:
	for target: Area3D in targets:
		target.task_completed.connect(_on_target_completed_counted)
		target.rejected.connect(_on_target_rejected_counted.bind(String(target.name)))


## Takes the character right off every target and waits for the area exits to
## register, so the next teleport is a genuine fresh entry.
func _park(camiel: CharacterBody3D) -> void:
	camiel.teleport_to(PARKING_SPOT)
	for _i in range(10):
		await physics_frame


## Teleports the character onto a target whose turn has NOT come and waits,
## bounded, for that target's own refusal signal. Returns the frames waited, or
## -1 when no refusal arrived -- which is the failure the archived lesson had.
func _touch_for_refusal(camiel: CharacterBody3D, target: Area3D) -> int:
	var before := _rejections(target)
	camiel.teleport_to(target.global_position)
	var frames_waited := 0
	while _rejections(target) == before and frames_waited < 120:
		await physics_frame
		frames_waited += 1
	if _rejections(target) != before + 1:
		return -1
	return frames_waited


## Asserts exactly one of an ordered lesson's targets reports itself active, and
## that it is the one whose turn it is -- or that none is, once the lesson is
## over. This is what D-37 means in practice: a target whose turn has not come
## is not merely refused after the fact, it is not live at all.
func _assert_only_active(case_name: String, targets: Array[Area3D], live_index: int) -> bool:
	var live_name := "nothing"
	if live_index >= 0:
		live_name = String(targets[live_index].name)
	for i in targets.size():
		var is_live: bool = targets[i].is_active()
		if i == live_index and not is_live:
			_fail(case_name, "%s is the target whose turn it is, but it reports itself inactive" % targets[i].name)
			return false
		if i != live_index and is_live:
			_fail(case_name, "%s reports itself active while the only live target should be %s -- exactly one target is live at a time (D-37)" % [targets[i].name, live_name])
			return false
	return true


## The cue in an ordered lesson is never colour. Lesson 2 asks a child to tell a
## circle from a square and lesson 3 asks them to read 1, 2, 3; either would
## collapse into "touch the orange one" if the three targets were three colours.
## So this asserts one shared colour across the whole lesson, and that the
## targets are nonetheless distinguishable by something -- their shape or the
## numeral they display.
func _assert_colour_is_not_the_cue(case_name: String, targets: Array[Area3D], labels: Array[Label3D]) -> bool:
	var shapes: Array[String] = []
	var texts: Array[String] = []
	var shared_colour: Color = targets[0].target_color
	for i in targets.size():
		var own_colour: Color = targets[i].target_color
		if own_colour != shared_colour:
			_fail(case_name, "%s is coloured %s while %s is %s -- every target in an ordered lesson shares one colour so hue cannot be the cue" % [targets[i].name, own_colour, targets[0].name, shared_colour])
			return false
		shapes.append(String(targets[i].shape_kind))
		texts.append(labels[i].text)

	var distinct_shapes := {}
	var distinct_texts := {}
	for shape: String in shapes:
		distinct_shapes[shape] = true
	for text: String in texts:
		distinct_texts[text] = true
	if distinct_shapes.size() < targets.size() and distinct_texts.size() < targets.size():
		_fail(case_name, "the lesson's targets are %s in shape and %s in displayed text -- sharing one colour, a child would have nothing left to tell them apart by" % [shapes, texts])
		return false

	print("[probe_lesson_order] %s shapes %s, texts %s, one shared colour %s" % [case_name, shapes, texts, shared_colour])
	return true


## `jump` and the engine's `ui_accept` are both bound to the space key in this
## project's input map, and menu_button.gd forces FOCUS_ALL in its own ready
## callback, so a scene-file override is silently undone. This asserts the
## consequence rather than the setting: no control holds focus during play and
## several accept presses change nothing at all.
func _assert_space_key_reaches_nothing(case_name: String, lesson: Node, hud: CanvasLayer, step_label: Label) -> bool:
	var in_play_back_button: Button = hud.get_node_or_null("%BackButton")
	if in_play_back_button == null:
		_fail(case_name, "the shared display has no %BackButton")
		return false
	if in_play_back_button.focus_mode != Control.FOCUS_NONE:
		_fail(case_name, "the in-play return control's focus mode is %d, FOCUS_NONE wanted" % in_play_back_button.focus_mode)
		return false
	var focus_owner := lesson.get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		_fail(case_name, "%s already holds keyboard focus during play; the space key would reach it on every jump" % focus_owner.name)
		return false

	var label_before := step_label.text
	_transition_count = 0
	_transition_target = ""
	lesson.transition_requested.connect(_on_transition_requested_counted)
	for _i in 3:
		_press_focused()
		await process_frame
	await process_frame
	if _transition_count != 0:
		_fail(case_name, "pressing the accept action during play requested %d transitions, 0 wanted -- jump and ui_accept share the space key" % _transition_count)
		return false
	if step_label.text != label_before:
		_fail(case_name, "the progress label moved from %s to %s when the accept action was pressed during play" % [label_before, step_label.text])
		return false
	if hud.is_win_visible():
		_fail(case_name, "the win panel appeared when the accept action was pressed during play")
		return false
	lesson.transition_requested.disconnect(_on_transition_requested_counted)
	return true


## Drives one ordered lesson end to end: the negative half first, then the
## correct order, then the disk. Shared by the lesson 2 and lesson 3 cases
## because the two lessons enforce their order through the same structure, so a
## regression in that structure should fail both cases rather than one. The
## lessons' own orchestrators stay independent scripts (D-35); only this probe
## shares code.
##
## `out_of_turn_indices` names the targets touched before their turn, and
## `label_texts` the text each target displays -- asserted before the refusals,
## after each refusal and again at the end, because the archived sequence target
## overwrote its own label with its order number on an error flash and lost the
## original text permanently.
func _drive_ordered_lesson(
	case_name: String,
	scene_path: String,
	lesson_id: String,
	target_names: Array,
	out_of_turn_indices: Array,
	label_texts: Array
) -> bool:
	var entries_before := _disk_entry_count()

	var opened: Dictionary = await _open_lesson(case_name, scene_path)
	if _failed:
		return false
	var lesson: Node = opened["lesson"]
	var camiel: CharacterBody3D = opened["camiel"]
	var hud: CanvasLayer = opened["hud"]
	var step_label: Label = opened["step_label"]
	var win_back_button: Button = opened["win_back_button"]

	var targets := _ordered_targets(case_name, lesson, target_names)
	if _failed:
		return false

	if step_label.text != _step_label_text(0):
		_fail(case_name, "the progress label reads %s at the start of the lesson, %s wanted" % [step_label.text, _step_label_text(0)])
		return false
	if hud.is_win_visible():
		_fail(case_name, "the win panel is already visible before the lesson was played")
		return false

	# Every target's own displayed text, before anything at all happens.
	var labels: Array[Label3D] = []
	for i in targets.size():
		var label_3d: Label3D = targets[i].get_node_or_null("Label")
		if label_3d == null:
			_fail(case_name, "%s has no Label child to read its displayed text from" % targets[i].name)
			return false
		if label_3d.text != String(label_texts[i]):
			_fail(case_name, "%s displays %s, %s wanted" % [targets[i].name, label_3d.text, label_texts[i]])
			return false
		labels.append(label_3d)

	if not _assert_colour_is_not_the_cue(case_name, targets, labels):
		return false
	if not await _assert_space_key_reaches_nothing(case_name, lesson, hud, step_label):
		return false

	_target_completed_count = 0
	_target_completed_ids.clear()
	_lesson_completed_count = 0
	_lesson_completed_ids.clear()
	_lesson_completed_times.clear()
	_rejection_counts.clear()
	_watch_ordered_targets(targets)
	lesson.lesson_completed.connect(_on_lesson_completed_counted)

	# Two listeners on every completion (the lesson's handler and this probe's
	# counter) and exactly one on every refusal (this probe's counter alone).
	# A future extra listener changes these numbers, and the numbers are in the
	# messages so the change is obvious rather than mysterious.
	for target: Area3D in targets:
		var completion_links := target.get_signal_connection_list("task_completed").size()
		if completion_links != 2:
			_fail(case_name, "%s.task_completed has %d connections, 2 wanted (the lesson's own handler and this probe's counter)" % [target.name, completion_links])
			return false
		var refusal_links := target.get_signal_connection_list("rejected").size()
		if refusal_links != 1:
			_fail(case_name, "%s.rejected has %d connections, 1 wanted (this probe's counter alone -- the orchestrator listens for completion only)" % [target.name, refusal_links])
			return false

	if not _assert_only_active(case_name, targets, 0):
		return false

	# --- The negative half, first. A touch out of turn refuses, completes
	# nothing, moves the label not at all, and leaves the target's own text
	# alone. This is the assertion that would have caught the archived defect. ---
	for raw_index in out_of_turn_indices:
		var index := int(raw_index)
		var out_of_turn: Area3D = targets[index]
		var text_before := labels[index].text
		await _park(camiel)
		var refusal_frames := await _touch_for_refusal(camiel, out_of_turn)
		if refusal_frames < 0:
			_fail(case_name, "touching %s before its turn refused %d times within 120 physics frames, exactly 1 wanted -- a wrong-order touch that is never refused is the archived defect" % [out_of_turn.name, _rejections(out_of_turn)])
			return false
		print("[probe_lesson_order] %s out-of-turn refusal on %s: %d frames" % [case_name, out_of_turn.name, refusal_frames])
		if _rejections(out_of_turn) != 1:
			_fail(case_name, "%s refused %d times for one touch, exactly 1 wanted" % [out_of_turn.name, _rejections(out_of_turn)])
			return false
		if _target_completed_count != 0:
			_fail(case_name, "touching %s before its turn completed %d tasks, 0 wanted" % [out_of_turn.name, _target_completed_count])
			return false
		if _lesson_completed_count != 0:
			_fail(case_name, "touching %s before its turn finished the whole lesson" % out_of_turn.name)
			return false
		if step_label.text != _step_label_text(0):
			_fail(case_name, "the progress label moved to %s after a refused touch on %s, %s wanted" % [step_label.text, out_of_turn.name, _step_label_text(0)])
			return false
		if labels[index].text != text_before:
			_fail(case_name, "refusing %s changed its own displayed text from %s to %s -- the archived sequence target destroyed its own label on an error flash" % [out_of_turn.name, text_before, labels[index].text])
			return false
		if not _assert_only_active(case_name, targets, 0):
			return false

	# --- Now the correct order, one target at a time, each paired with the
	# exact label a child must see after it and with the single target that must
	# be live next. ---
	for i in targets.size():
		await _park(camiel)
		var frames := await _touch_target(camiel, targets[i])
		if frames < 0:
			_fail(case_name, "step %d (%s) never registered a touch within 120 physics frames" % [i + 1, targets[i].name])
			return false
		var wanted_label := _step_label_text(i + 1)
		if step_label.text != wanted_label:
			_fail(case_name, "after step %d (%s) the label reads %s, %s wanted" % [i + 1, targets[i].name, step_label.text, wanted_label])
			return false
		if i < targets.size() - 1 and _lesson_completed_count != 0:
			_fail(case_name, "the lesson finished at step %d of %d, before its order was walked to the end" % [i + 1, targets.size()])
			return false
		var next_live := i + 1
		if next_live >= targets.size():
			next_live = -1
		if not _assert_only_active(case_name, targets, next_live):
			return false

	# A target that was refused once is still exactly one refusal later: the
	# wrong first guess cost the child nothing, and it did not repeat.
	for raw_index in out_of_turn_indices:
		var index := int(raw_index)
		if _rejections(targets[index]) != 1:
			_fail(case_name, "%s refused %d times across the whole run, exactly 1 wanted -- a wrong first guess must not cost a child the target" % [targets[index].name, _rejections(targets[index])])
			return false

	await process_frame
	await process_frame

	if _lesson_completed_count != 1:
		_fail(case_name, "lesson_completed fired %d times, exactly 1 wanted" % _lesson_completed_count)
		return false
	if _lesson_completed_ids[0] != lesson_id:
		_fail(case_name, "lesson_completed carried %s, %s wanted" % [_lesson_completed_ids[0], lesson_id])
		return false
	if _lesson_completed_times[0] <= 0.0:
		_fail(case_name, "lesson_completed carried an elapsed time of %s, greater than zero wanted" % _lesson_completed_times[0])
		return false
	if not hud.is_win_visible():
		_fail(case_name, "the win panel is not visible after the lesson finished")
		return false
	if camiel.is_physics_processing():
		_fail(case_name, "the character's physics processing is still on after the lesson finished")
		return false

	for i in targets.size():
		if labels[i].text != String(label_texts[i]):
			_fail(case_name, "%s displays %s after the whole run, %s wanted" % [targets[i].name, labels[i].text, label_texts[i]])
			return false

	if not _assert_last_entry(case_name, lesson_id):
		return false
	var entries_after := _disk_entry_count()
	if entries_after != entries_before + 1:
		_fail(case_name, "the progress file holds %d entries, %d wanted -- one completion appends exactly one entry (D-40)" % [entries_after, entries_before + 1])
		return false

	if not await _assert_win_return_is_one_shot(case_name, lesson, win_back_button):
		return false

	lesson.lesson_completed.disconnect(_on_lesson_completed_counted)
	lesson.queue_free()
	await _drain_scene_change()
	return true


## D-34's other half, on a fresh unfinished lesson: the control that is live
## during play also goes to lesson-select, through one guarded, deferred
## transition. Plan 03-03 found this half genuinely unwired while the win
## panel's half worked, so it is driven per lesson rather than assumed.
func _assert_in_play_return_is_one_shot(case_name: String, scene_path: String) -> bool:
	var opened: Dictionary = await _open_lesson(case_name, scene_path)
	if _failed:
		return false
	var lesson: Node = opened["lesson"]
	var hud: CanvasLayer = opened["hud"]

	# Deliberately unreachable by the space key, so drive its own signal rather
	# than synthesising a keyboard press -- the same way the lesson-kit probe
	# proves the control still works while proving the keyboard cannot reach it.
	var in_play_back_button: Button = hud.get_node_or_null("%BackButton")
	if in_play_back_button == null:
		_fail(case_name, "the shared display has no %BackButton")
		return false

	_transition_count = 0
	_transition_target = ""
	lesson.transition_requested.connect(_on_transition_requested_counted)

	in_play_back_button.pressed.emit()
	await process_frame
	await process_frame
	if _transition_count != 1:
		_fail(case_name, "the in-play return control requested %d transitions, 1 wanted" % _transition_count)
		return false
	if _transition_target != LESSON_SELECT_PATH:
		_fail(case_name, "the in-play return control carried %s, %s wanted -- neither of a lesson's return controls goes to the main menu (D-34)" % [_transition_target, LESSON_SELECT_PATH])
		return false

	await _drain_scene_change()

	in_play_back_button.pressed.emit()
	await process_frame
	await process_frame
	if _transition_count != 1:
		_fail(case_name, "the in-play return control's one-shot guard did not block a second activation; count is %d" % _transition_count)
		return false

	lesson.transition_requested.disconnect(_on_transition_requested_counted)
	lesson.queue_free()
	await _drain_scene_change()
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

	# `jump` and the engine's `ui_accept` are both bound to the space key in this
	# project's input map, so any focusable control alive during 3D play would
	# fire on every single jump attempt and end the lesson under the child's
	# feet. The in-play return control clears its own focus mode in the shared
	# display's ready callback, and the win panel's control is inside a hidden
	# subtree; this asserts the consequence rather than trusting either.
	var in_play_back_button: Button = hud.get_node_or_null("%BackButton")
	if in_play_back_button == null:
		_fail(case_name, "the shared display has no %BackButton")
		return
	if in_play_back_button.focus_mode != Control.FOCUS_NONE:
		_fail(case_name, "the in-play return control's focus mode is %d, expected FOCUS_NONE" % in_play_back_button.focus_mode)
		return
	var focus_owner := lesson.get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		_fail(case_name, "%s already holds keyboard focus during play; the space key would reach it on every jump" % focus_owner.name)
		return

	_transition_count = 0
	_transition_target = ""
	lesson.transition_requested.connect(_on_transition_requested_counted)
	for _i in 3:
		_press_focused()
		await process_frame
	await process_frame
	if _transition_count != 0:
		_fail(case_name, "pressing the accept action during play requested %d transitions, expected 0 -- jump and ui_accept share the space key" % _transition_count)
		return
	if step_label.text != "Stap: 0 / 3":
		_fail(case_name, "the progress label moved to %s when the accept action was pressed during play" % step_label.text)
		return
	if hud.is_win_visible():
		_fail(case_name, "the win panel appeared when the accept action was pressed during play")
		return
	lesson.transition_requested.disconnect(_on_transition_requested_counted)

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


## Lesson 1 finishes from two further task orders -- counting in the middle and
## counting last. Together with the tracer's counting-first run, that is three
## genuinely different orders, which is what "regardless of which of its three
## tasks is completed first" actually asks for (D-36).
func _case_lesson_1_other_orders() -> void:
	var case_name := "lesson_1_other_orders"
	var entries_before := _disk_entry_count()

	# --- Run 1: red, then the three counting objects, then blue. The counting
	# task sits in the middle here, and the two objects before the last one must
	# leave the label exactly where it was. ---
	var first: Dictionary = await _open_lesson(case_name, LESSON_1_PATH)
	if _failed:
		return
	var first_targets := _lesson_1_targets(case_name, first["lesson"])
	if _failed:
		return
	var first_counts: Array[Area3D] = first_targets["counts"]
	var first_sequence: Array = [
		[first_targets["red"], "Stap: 1 / 3"],
		[first_counts[0], "Stap: 1 / 3"],
		[first_counts[1], "Stap: 1 / 3"],
		[first_counts[2], "Stap: 2 / 3"],
		[first_targets["blue"], "Stap: 3 / 3"],
	]
	if not await _drive_touch_sequence(case_name, first, first_targets, first_sequence):
		return
	first["lesson"].queue_free()
	await _drain_scene_change()

	# --- Run 2: blue, then red, then the three counting objects. The counting
	# task is last here, so the lesson must not finish until the third object. ---
	var second: Dictionary = await _open_lesson(case_name, LESSON_1_PATH)
	if _failed:
		return
	var second_targets := _lesson_1_targets(case_name, second["lesson"])
	if _failed:
		return
	var second_counts: Array[Area3D] = second_targets["counts"]
	var second_sequence: Array = [
		[second_targets["blue"], "Stap: 1 / 3"],
		[second_targets["red"], "Stap: 2 / 3"],
		[second_counts[0], "Stap: 2 / 3"],
		[second_counts[1], "Stap: 2 / 3"],
		[second_counts[2], "Stap: 3 / 3"],
	]
	if not await _drive_touch_sequence(case_name, second, second_targets, second_sequence):
		return
	second["lesson"].queue_free()
	await _drain_scene_change()

	# One entry per completion is what D-40's append log means in practice: two
	# completions, two new lines in the file, neither overwriting the other.
	var entries_after := _disk_entry_count()
	if entries_after != entries_before + 2:
		_fail(case_name, "the progress file grew from %d to %d entries across two completions, expected %d" % [entries_before, entries_after, entries_before + 2])
		return
	var data := _read_progress_file(case_name)
	if _failed:
		return
	var entries: Array = data["entries"]
	for offset in 2:
		var entry: Dictionary = entries[entries.size() - 1 - offset]
		if entry.get("lesson_id", "") != "lesson_1":
			_fail(case_name, "one of the two new entries carries lesson_id %s, expected lesson_1" % [entry.get("lesson_id")])
			return
	print("[probe_lesson_order] progress entries before/after two completions: %d / %d" % [entries_before, entries_after])

	_cases_run += 1
	print("PASS %s" % case_name)


## Nothing short of all three tasks finishes lesson 1, and nothing other than
## the child finishes anything: two of three counting objects is not the
## counting task, a completed target contributes once and only once, and a plain
## body that is not the player completes nothing even though the room's own
## floor shares its collision layer with every target.
func _case_lesson_1_guards() -> void:
	var case_name := "lesson_1_guards"
	var entries_before := _disk_entry_count()

	var opened: Dictionary = await _open_lesson(case_name, LESSON_1_PATH)
	if _failed:
		return
	var lesson: Node = opened["lesson"]
	var camiel: CharacterBody3D = opened["camiel"]
	var hud: CanvasLayer = opened["hud"]
	var step_label: Label = opened["step_label"]

	var targets := _lesson_1_targets(case_name, lesson)
	if _failed:
		return
	var red: Area3D = targets["red"]
	var blue: Area3D = targets["blue"]
	var counts: Array[Area3D] = targets["counts"]

	_target_completed_count = 0
	_target_completed_ids.clear()
	_lesson_completed_count = 0
	_lesson_completed_ids.clear()
	_lesson_completed_times.clear()
	_watch_targets(red, blue, counts)
	lesson.lesson_completed.connect(_on_lesson_completed_counted)

	# Two of the three counting objects, plus the red target. An incomplete
	# counting task must not count as a task.
	for i in 2:
		if await _touch_target(camiel, counts[i]) < 0:
			_fail(case_name, "counting object %d never registered a touch within 120 physics frames" % (i + 1))
			return
	if await _touch_target(camiel, red) < 0:
		_fail(case_name, "the red target never registered a touch within 120 physics frames")
		return

	for _i in range(120):
		await physics_frame
	if _lesson_completed_count != 0:
		_fail(case_name, "the lesson completed on two of three counting objects plus one colour; an unfinished counting task must not count (D-36)")
		return
	if step_label.text != "Stap: 1 / 3":
		_fail(case_name, "after two counting objects and the red target the label reads %s, expected Stap: 1 / 3" % step_label.text)
		return

	# A completed target contributes once. Park the character away first so the
	# return is a genuine fresh entry into the area, not a body that never left.
	var label_before_repeat := step_label.text
	camiel.teleport_to(PARKING_SPOT)
	for _i in range(10):
		await physics_frame
	var completions_before_repeat := _target_completed_count
	camiel.teleport_to(red.global_position)
	for _i in range(60):
		await physics_frame
	if _target_completed_count != completions_before_repeat:
		_fail(case_name, "standing on an already-completed target for 60 further physics frames added %d completions, expected 0" % (_target_completed_count - completions_before_repeat))
		return
	if step_label.text != label_before_repeat:
		_fail(case_name, "the label moved to %s while standing on an already-completed target, expected it to stay at %s" % [step_label.text, label_before_repeat])
		return

	# A plain body that is not the player. The room's floor sits on the same
	# default collision layer as every target, so the player-group guard is what
	# keeps the room itself from finishing the lesson.
	camiel.teleport_to(PARKING_SPOT)
	for _i in range(10):
		await physics_frame
	var intruder := StaticBody3D.new()
	var intruder_shape := CollisionShape3D.new()
	var intruder_box := BoxShape3D.new()
	intruder_box.size = Vector3(0.2, 0.2, 0.2)
	intruder_shape.shape = intruder_box
	intruder.add_child(intruder_shape)
	lesson.add_child(intruder)
	intruder.global_position = counts[2].global_position
	for _i in range(10):
		await physics_frame
	if _lesson_completed_count != 0:
		_fail(case_name, "a non-player body placed on a lesson target completed the lesson")
		return
	if _target_completed_count != completions_before_repeat:
		_fail(case_name, "a non-player body placed on a lesson target completed a task (count rose to %d)" % _target_completed_count)
		return
	if step_label.text != label_before_repeat:
		_fail(case_name, "the label moved to %s when a non-player body was placed on a target" % step_label.text)
		return
	intruder.queue_free()

	if _disk_entry_count() != entries_before:
		_fail(case_name, "the progress file grew from %d to %d entries without any lesson finishing" % [entries_before, _disk_entry_count()])
		return

	# D-34's other half. The tracer proves the win panel's return control goes to
	# lesson-select; this proves the in-play one does too, on an unfinished
	# lesson, through the same one guarded transition. It is deliberately
	# unreachable by the space key, so drive its own signal rather than
	# synthesising a keyboard press -- the same way the lesson-kit probe proves
	# the control still works while proving the keyboard cannot reach it.
	var in_play_back_button: Button = hud.get_node_or_null("%BackButton")
	if in_play_back_button == null:
		_fail(case_name, "the shared display has no %BackButton")
		return

	_transition_count = 0
	_transition_target = ""
	lesson.transition_requested.connect(_on_transition_requested_counted)

	in_play_back_button.pressed.emit()
	await process_frame
	await process_frame
	if _transition_count != 1:
		_fail(case_name, "the in-play return control requested %d transitions, expected 1" % _transition_count)
		return
	if _transition_target != LESSON_SELECT_PATH:
		_fail(case_name, "the in-play return control carried %s, expected %s -- neither of a lesson's return controls goes to the main menu (D-34)" % [_transition_target, LESSON_SELECT_PATH])
		return

	await _drain_scene_change()

	in_play_back_button.pressed.emit()
	await process_frame
	await process_frame
	if _transition_count != 1:
		_fail(case_name, "the in-play return control's one-shot guard did not block a second activation; count is %d" % _transition_count)
		return

	lesson.transition_requested.disconnect(_on_transition_requested_counted)
	lesson.lesson_completed.disconnect(_on_lesson_completed_counted)
	lesson.queue_free()
	await _drain_scene_change()

	_cases_run += 1
	print("PASS %s" % case_name)


## LESSON-02 proved from the wrong end first. The square and then the triangle
## are each touched before their turn: each must refuse, complete nothing and
## leave the label where it was. Only then is circle, square, triangle driven --
## and the square it completes is the very target it refused a moment earlier, so
## a child's wrong first guess is shown to have cost them nothing.
##
## Three distinct orders are therefore really driven here, not one: square-first,
## triangle-first, and the correct one. The archived lesson_2.gd would have
## passed a correct-order-only case, which is exactly why it does not exist.
func _case_lesson_2_order_enforced() -> void:
	var case_name := "lesson_2_order_enforced"
	if not await _drive_ordered_lesson(
		case_name,
		LESSON_2_PATH,
		"lesson_2",
		["CircleTarget", "SquareTarget", "TriangleTarget"],
		[1, 2],
		["", "", ""]
	):
		return
	if not await _assert_in_play_return_is_one_shot(case_name, LESSON_2_PATH):
		return

	_cases_run += 1
	print("PASS %s" % case_name)


## LESSON-03, on lesson 2's shape over three numbered targets. The third target
## is touched first here rather than the second, so the two ordered lessons are
## not driven by the same wrong guess, and the assertion that its numeral still
## reads 3 afterwards is a direct regression test for a recorded defect: the
## archived sequence_target.gd's error flash overwrote a target's own label with
## str(order_number) and lost the original text permanently.
func _case_lesson_3_order_enforced() -> void:
	var case_name := "lesson_3_order_enforced"
	if not await _drive_ordered_lesson(
		case_name,
		LESSON_3_PATH,
		"lesson_3",
		["Step1Target", "Step2Target", "Step3Target"],
		[2, 1],
		["1", "2", "3"]
	):
		return
	if not await _assert_in_play_return_is_one_shot(case_name, LESSON_3_PATH):
		return

	_cases_run += 1
	print("PASS %s" % case_name)
