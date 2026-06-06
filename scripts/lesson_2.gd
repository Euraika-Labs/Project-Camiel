# lesson_2.gd
# Orchestrates the Shape Matcher educational micro-task in Lesson 2.
# Child must touch the circle, then the square, then the triangle in order.
extends Node2D

signal lesson_finished

@onready var circle_target = $CircleTarget
@onready var square_target = $SquareTarget
@onready var triangle_target = $TriangleTarget
@onready var progress_label = $ProgressLabel

var _completed_shapes: Array[String] = []
var _expected_order := ["circle", "square", "triangle"]
var _started_at := 0


func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	circle_target.task_completed.connect(_on_shape_touched.bind("circle"))
	square_target.task_completed.connect(_on_shape_touched.bind("square"))
	triangle_target.task_completed.connect(_on_shape_touched.bind("triangle"))
	_update_progress_label()


func _on_shape_touched(shape_name: String) -> void:
	if not _completed_shapes.has(shape_name):
		_completed_shapes.append(shape_name)
	_update_progress_label()
	_check_lesson_complete()


func _update_progress_label() -> void:
	progress_label.text = "Vormen: %d / 3" % _completed_shapes.size()


func _check_lesson_complete() -> void:
	if _completed_shapes.size() >= 3:
		progress_label.text = "Goed zo! Alle vormen gevonden!"
		var audio_manager := get_node_or_null("/root/AudioManager")
		if audio_manager:
			audio_manager.play_sfx("finish")
		var progress_tracker := get_node_or_null("/root/ProgressTracker")
		if progress_tracker:
			progress_tracker.record_lesson_complete("lesson_2", 3, _elapsed_seconds())
		await get_tree().create_timer(2.0).timeout
		lesson_finished.emit()
		get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _elapsed_seconds() -> int:
	return int((Time.get_ticks_msec() - _started_at) / 1000)
