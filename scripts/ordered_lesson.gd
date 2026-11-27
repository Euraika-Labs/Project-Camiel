# Reusable ordered lesson: subclasses provide identity, title and target paths.
# Target activation enforces order; persistence precedes celebration.
extends Node3D

signal transition_requested(target_path: String)
signal lesson_completed(lesson_id: String, time_seconds: float)

const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"

var _sequence: Array[Area3D] = []
var _step := 0
var _completed_tasks: Array[String] = []
var _transitioning := false
var _finished := false
var _lesson_id := ""

func _configure_lesson(lesson_id: String, title: String, target_paths: Array[NodePath]) -> void:
	VoiceManager.bind_scene(self, lesson_id)
	_lesson_id = lesson_id
	for path: NodePath in target_paths:
		var target := get_node(path) as Area3D
		_sequence.append(target)
		target.task_completed.connect(_on_task_completed)
		target.rejected.connect(_on_wrong_target)
	%Hud.back_requested.connect(_on_hud_back_requested)
	%Hud.win_back_requested.connect(_on_hud_back_requested)
	%Hud.open_lesson_requested.connect(_open_scene)
	%Hud.set_lesson(lesson_id)
	%Hud.set_title(title)
	%Hud.set_targets(_sequence, true)
	%Hud.set_step(0, _sequence.size())
	_sequence[0].activate()

func _on_wrong_target() -> void:
	if not _finished and not _transitioning and _step < _sequence.size():
		%Hud.guide_current_target()

func _on_task_completed(task_id: String) -> void:
	# Ignore stale or duplicate notifications, including any after completion.
	if _finished or _transitioning or _step >= _sequence.size():
		return
	if task_id != String(_sequence[_step].task_id):
		return
	_completed_tasks.append(task_id)
	_step += 1
	%Hud.complete_target(task_id)
	%Hud.set_step(_step, _sequence.size())
	if _step == _sequence.size():
		_apply_lesson_complete()
	else:
		_sequence[_step].activate()

func _on_hud_back_requested() -> void:
	_open_scene(LESSON_SELECT_PATH)

func _open_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(path)
	get_tree().change_scene_to_file.call_deferred(path)

func _apply_lesson_complete() -> void:
	if _finished:
		return
	_finished = true
	var time_seconds: float = %Hud.elapsed_play_time()
	$Camiel.set_physics_process(false)
	var result: Dictionary = await ProgressTracker.record_lesson_result(_lesson_id, time_seconds)
	if _transitioning:
		return
	lesson_completed.emit(_lesson_id, time_seconds)
	var cue: String = %Hud.show_win(result["saved"], result["garden_completed"], result.get("pending"))
	AudioManager.play_sfx("finish")
	VoiceManager.play(cue)
