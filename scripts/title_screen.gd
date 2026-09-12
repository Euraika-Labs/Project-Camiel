# title_screen.gd
# The game's boot screen (D-28): one focusable Play button that transitions
# to the main menu. Tap, click, and Enter on the focused control all resolve
# to the inherited BaseButton.pressed signal (D-14) — this script declares
# no _input/_gui_input override, which is exactly the archived title
# screen's double-transition defect (CONCERNS.md) this file must not repeat.
extends Control

signal transition_requested(target_path: String)

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

var _transitioning := false


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_button_pressed)
	%PlayButton.grab_focus()


func _on_play_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(MAIN_MENU_PATH)
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)
