extends Node2D

@onready var start_button: Button = $ColorRect/VBox/StartButton
@onready var lesson_button: Button = $ColorRect/VBox/LessonButton

var version_label := "alpha-v0.0.3"


func _ready() -> void:
	start_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_lesson_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lesson_1.tscn")
