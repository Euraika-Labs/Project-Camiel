# lesson_manager.gd
# Orchestrates the three educational micro-tasks in Lesson 1.
# Emits lesson_finished when all three tasks are complete, then
# returns the player to the main menu after a short celebration delay.
extends Node2D

signal lesson_finished

@onready var red_block = $RedBlock
@onready var blue_target = $BlueTarget
@onready var count_challenge = $CountChallenge
@onready var progress_label = $ProgressLabel

var _completed_tasks: Array[String] = []
var _started_at := 0


func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	# Connect each micro-task's completion signal.
	red_block.task_completed.connect(_on_task_completed.bind("red_block"))
	blue_target.task_completed.connect(_on_task_completed.bind("blue_target"))
	count_challenge.task_completed.connect(_on_lesson_complete)
	_update_progress_label()


func _on_task_completed(task_name: String) -> void:
	if not _completed_tasks.has(task_name):
		_completed_tasks.append(task_name)
	_update_progress_label()


func _update_progress_label() -> void:
	progress_label.text = "Taken: %d / 3" % _completed_tasks.size()


func _on_lesson_complete() -> void:
	# Both positional tasks must be done before the lesson can finish.
	if _completed_tasks.has("red_block") and _completed_tasks.has("blue_target"):
		progress_label.text = "Goed zo! Alle taken klaar!"
		var progress_tracker := get_node_or_null("/root/ProgressTracker")
		if progress_tracker:
			progress_tracker.record_lesson_complete("lesson_1", 3, _elapsed_seconds())
		await get_tree().create_timer(2.0).timeout
		lesson_finished.emit()
		get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _elapsed_seconds() -> int:
	return int((Time.get_ticks_msec() - _started_at) / 1000)
