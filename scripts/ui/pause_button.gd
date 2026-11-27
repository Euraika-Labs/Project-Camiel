extends "res://scripts/ui/menu_button.gd"

const SETTINGS_PANEL := preload("res://scenes/ui/settings_panel.tscn")


func _ready() -> void:
	super._ready()
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_open_pause)
	ScreenLayout.layout_changed.connect(_layout_button)
	_layout_button(ScreenLayout.portrait)


func _layout_button(_portrait: bool) -> void:
	custom_minimum_size = Vector2(102, 102) if ScreenLayout.short_landscape else Vector2(92, 90)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and not get_tree().paused and event.is_action_pressed("pause_play"):
		get_viewport().set_input_as_handled()
		_open_pause()


func _open_pause() -> void:
	if get_tree().paused or not is_visible_in_tree():
		return
	var dialog := SETTINGS_PANEL.instantiate()
	dialog.pause_game = true
	add_child(dialog)
