# lesson_3.gd
# Orchestrates the Sequence educational micro-task in Lesson 3.
# Child must touch the 3 objects in the correct order.
# Shows gentle error feedback if the wrong target is touched.
extends Node2D

signal lesson_finished

@onready var target_1 = $Target1
@onready var target_2 = $Target2
@onready var target_3 = $Target3
@onready var progress_label = $ProgressLabel

var _current_step := 1
var _total_steps := 3


func _ready() -> void:
	target_1.order_number = 1
	target_2.order_number = 2
	target_3.order_number = 3

	target_1.task_completed.connect(_on_target_completed.bind(1))
	target_2.task_completed.connect(_on_target_completed.bind(2))
	target_3.task_completed.connect(_on_target_completed.bind(3))

	# Activate the first target only
	target_1.activate()
	target_2._set_inactive()
	target_3._set_inactive()

	_update_progress_label()


func _on_target_completed(target_order: int) -> void:
	if target_order != _current_step:
		return

	_current_step += 1

	if _current_step > _total_steps:
		_apply_lesson_complete()
	else:
		_activate_next_target()


func _activate_next_target() -> void:
	match _current_step:
		2:
			target_2.activate()
		3:
			target_3.activate()
	_update_progress_label()


func _update_progress_label() -> void:
	progress_label.text = "Stap: %d / 3" % (_current_step - 1)


func _apply_lesson_complete() -> void:
	progress_label.text = "Goed zo! Alle stappen goed!"
	AudioManager.play_sfx("finish")
	await get_tree().create_timer(2.0).timeout
	lesson_finished.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")