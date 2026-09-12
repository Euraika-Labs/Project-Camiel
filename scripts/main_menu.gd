# main_menu.gd
# The main menu (D-28): one focusable Start button that transitions to the
# intro level. Mirrors title_screen.gd's guarded, deferred transition shape
# exactly (D-14, D-15). Plan 02-05 extends this same file with the audio
# panel and its sliders; the _ready() wiring stays in one place so that
# plan only needs to add to it, not restructure it.
extends Control

signal transition_requested(target_path: String)

const INTRO_LEVEL_PATH := "res://scenes/intro_level.tscn"
const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"

var _transitioning := false


func _ready() -> void:
	%StartButton.pressed.connect(_on_start_button_pressed)
	%StartButton.grab_focus()

	%LessonsButton.pressed.connect(_on_lessons_button_pressed)

	%SfxSlider.value_changed.connect(_on_sfx_slider_value_changed)
	%SfxSlider.set_value_no_signal(AudioManager.get_sfx_volume() * 100.0)

	%BgmSlider.value_changed.connect(_on_bgm_slider_value_changed)
	%BgmSlider.set_value_no_signal(AudioManager.get_bgm_volume() * 100.0)


func _on_start_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(INTRO_LEVEL_PATH)
	get_tree().change_scene_to_file.call_deferred(INTRO_LEVEL_PATH)


## Opens the lesson-select screen (D-31, LESSON-06) through the same one-shot
## guard and deferred change the Start control uses. This is the control the
## archived game never had: its main menu only ever linked lesson 1, so four
## lessons existed and could not be reached.
func _on_lessons_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(LESSON_SELECT_PATH)
	get_tree().change_scene_to_file.call_deferred(LESSON_SELECT_PATH)


func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)


func _on_bgm_slider_value_changed(value: float) -> void:
	AudioManager.set_bgm_volume(value / 100.0)
