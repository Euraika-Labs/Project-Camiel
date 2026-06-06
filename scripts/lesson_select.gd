extends Node2D

@onready var lesson_1_button: Button = $ColorRect/VBox/Lesson1Button
@onready var summary_label: Label = $ColorRect/VBox/SummaryLabel

const LESSON_SCENES := {
	"lesson_1": "res://scenes/lesson_1.tscn",
	"lesson_2": "res://scenes/lesson_2.tscn",
	"lesson_3": "res://scenes/lesson_3.tscn",
	"lesson_4": "res://scenes/lesson_4.tscn",
	"lesson_5": "res://scenes/lesson_5.tscn"
}


func _ready() -> void:
	lesson_1_button.grab_focus()
	_update_summary()


func _update_summary() -> void:
	var progress_tracker := get_node_or_null("/root/ProgressTracker")
	var completed := 0
	if progress_tracker:
		completed = progress_tracker.get_completed_count()
	summary_label.text = "Klaar: %d / 5 lessen" % completed


func _open_lesson(lesson_id: String) -> void:
	var path := LESSON_SCENES.get(lesson_id, "") as String
	if path.is_empty():
		return
	get_tree().change_scene_to_file(path)


func _on_lesson_1_button_pressed() -> void:
	_open_lesson("lesson_1")


func _on_lesson_2_button_pressed() -> void:
	_open_lesson("lesson_2")


func _on_lesson_3_button_pressed() -> void:
	_open_lesson("lesson_3")


func _on_lesson_4_button_pressed() -> void:
	_open_lesson("lesson_4")


func _on_lesson_5_button_pressed() -> void:
	_open_lesson("lesson_5")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
