# main_menu.gd
# The main menu (D-28): one focusable Start button that transitions to the
# intro level. Mirrors title_screen.gd's guarded, deferred transition shape
# exactly (D-14, D-15). Plan 02-05 extends this same file with the audio
# panel and its sliders; the _ready() wiring stays in one place so that
# plan only needs to add to it, not restructure it.
extends Control

signal transition_requested(target_path: String)

const INTRO_LEVEL_PATH := "res://scenes/intro_level.tscn"

var _transitioning := false


func _ready() -> void:
	%StartButton.pressed.connect(_on_start_button_pressed)
	%StartButton.grab_focus()


func _on_start_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(INTRO_LEVEL_PATH)
	get_tree().change_scene_to_file.call_deferred(INTRO_LEVEL_PATH)
