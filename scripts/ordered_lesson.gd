# Reusable ordered lesson: subclasses provide identity, title and target paths.
# Target activation enforces order; persistence precedes celebration.
extends Node3D

signal transition_requested(target_path: String)
signal lesson_completed(lesson_id: String, time_seconds: float)

const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"

var _sequence: Array[Area3D] = []
var _step := 0
var _completed_tasks: Array[String] = []
var _start_time_msec := 0
var _transitioning := false
var _finished := false
var _lesson_id := ""

func _configure_lesson(lesson_id: String, title: String, target_paths: Array[NodePath]) -> void:
	VoiceManager.bind_scene(self, lesson_id)
	_lesson_id = lesson_id
	_start_time_msec = Time.get_ticks_msec()
	for path: NodePath in target_paths:
		var target := get_node(path) as Area3D
		_sequence.append(target)
		target.task_completed.connect(_on_task_completed)
	%Hud.back_requested.connect(_on_hud_back_requested)
	%Hud.win_back_requested.connect(_on_hud_back_requested)
	%Hud.set_title(title)
	%Hud.set_step(0, _sequence.size())
	_sequence[0].activate()

func _on_task_completed(task_id: String) -> void:
	# Ignore stale or duplicate notifications, including any after completion.
	if _finished or _transitioning or _step >= _sequence.size():
		return
	if task_id != String(_sequence[_step].task_id):
		return
	_completed_tasks.append(task_id)
	_step += 1
	%Hud.set_step(_step, _sequence.size())
	if _step == _sequence.size():
		_apply_lesson_complete()
	else:
		VoiceManager.play("correct")
		_sequence[_step].activate()

func _on_hud_back_requested() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(LESSON_SELECT_PATH)
	get_tree().change_scene_to_file.call_deferred(LESSON_SELECT_PATH)

func _apply_lesson_complete() -> void:
	if _finished:
		return
	_finished = true
	var time_seconds := float(Time.get_ticks_msec() - _start_time_msec) / 1000.0
	ProgressTracker.record_lesson_complete(_lesson_id, time_seconds)
	lesson_completed.emit(_lesson_id, time_seconds)
	%Hud.show_win()
	$Camiel.set_physics_process(false)
	AudioManager.play_sfx("finish")
	VoiceManager.play("complete")
