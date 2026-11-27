extends Node3D
## Both color lessons accept the two colors and the counting stones in any order.

signal transition_requested(target_path: String)
signal lesson_completed(lesson_id: String, time_seconds: float)

const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"

var _lesson_id := ""
var _target_ids := PackedStringArray()
var _stone_ids := PackedStringArray()
var _task_total := 0
var _found: Dictionary = {}
var _stones_found := 0
var _transitioning := false
var _finished := false
var _playing_pickups := false


func _configure_color_lesson(lesson_id: String, title: String, colors: Array[Area3D]) -> void:
	_lesson_id = lesson_id
	_task_total = colors.size() + 1
	VoiceManager.bind_scene(self, lesson_id)
	VoiceManager.narration_stopped.connect(_reset_pickup_queue)

	var targets := colors.duplicate()
	for child: Node in %CountGroup.get_children():
		if child is Area3D:
			_stone_ids.append(String(child.task_id))
			targets.append(child)
	for target: Area3D in targets:
		_target_ids.append(String(target.task_id))
		target.task_completed.connect(_on_task_completed)

	%Hud.back_requested.connect(_on_hud_back_requested)
	%Hud.win_back_requested.connect(_on_hud_back_requested)
	%Hud.open_lesson_requested.connect(_open_scene)
	%Hud.set_lesson(lesson_id)
	%Hud.set_title(title)
	%Hud.set_targets(targets, false, _stone_ids)
	%Hud.set_step(0, _task_total)


func _on_task_completed(task_id: String) -> void:
	if _finished or _transitioning or not _target_ids.has(task_id) or _found.has(task_id):
		return
	_found[task_id] = true
	var cue := "color_" + task_id
	if _stone_ids.has(task_id):
		_stones_found += 1
		cue = "counted_%d" % _stones_found
	%Hud.complete_target(task_id)
	var tasks_completed := _found.size() - _stones_found
	if _stones_found == _stone_ids.size():
		tasks_completed += 1
	%Hud.set_step(tasks_completed, _task_total)
	_announce_pickup(cue)
	if tasks_completed == _task_total:
		_apply_lesson_complete()


func _announce_pickup(cue: String) -> void:
	# A pickup replaces instructions that describe an older state. Keep every
	# number in order when the player collects several stones in quick succession.
	if _playing_pickups:
		VoiceManager.enqueue(cue)
	else:
		VoiceManager.play(cue)
		_playing_pickups = true


func _reset_pickup_queue() -> void:
	_playing_pickups = false


func _on_hud_back_requested() -> void:
	_open_scene(LESSON_SELECT_PATH)


func _open_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(path)
	get_tree().change_scene_to_file.call_deferred(path)


func _apply_lesson_complete() -> void:
	_finished = true
	var time_seconds: float = %Hud.elapsed_play_time()
	$Camiel.set_physics_process(false)
	var result: Dictionary = await ProgressTracker.record_lesson_result(_lesson_id, time_seconds)
	if _transitioning:
		return
	lesson_completed.emit(_lesson_id, time_seconds)
	var cue: String = %Hud.show_win(result["saved"], result["garden_completed"], result.get("pending"))
	AudioManager.play_sfx("finish")
	VoiceManager.enqueue(cue)
