extends Node2D

@onready var start_button: Button = $ColorRect/VBox/StartButton
@onready var lesson_button: Button = $ColorRect/VBox/LessonButton
@onready var adult_button: Button = $ColorRect/VBox/AdultButton

const VERSION := "beta-1-candidate"


func _ready() -> void:
	start_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_on_start_button_pressed()


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_lesson_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _on_adult_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_progress.tscn")
