# lesson_4.gd
# Placeholder scene for Lesson 4.
extends Node2D


func _ready() -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")