# Shared, persistent high-contrast theme. Does not change lesson target colours.
extends Node

signal contrast_changed(enabled: bool)

const SETTINGS_PATH := "user://settings.cfg"
const THEME_PATH := "res://assets/theme/ui_theme.tres"
var high_contrast := false
var _theme: Theme
var _original: Theme


func _ready() -> void:
	_theme = load(THEME_PATH) as Theme
	_original = _theme.duplicate(true) as Theme
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		high_contrast = bool(config.get_value("accessibility", "high_contrast", false))
	_apply_theme()


func set_high_contrast(enabled: bool) -> void:
	high_contrast = enabled
	_apply_theme()
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("accessibility", "high_contrast", enabled)
	if config.save(SETTINGS_PATH) != OK:
		push_warning("Instellingen konden niet worden bewaard.")
	contrast_changed.emit(enabled)


func _apply_theme() -> void:
	for type_name: StringName in _original.get_type_list():
		for color_name: StringName in _original.get_color_list(type_name):
			var color := _original.get_color(color_name, type_name)
			if high_contrast and String(color_name).begins_with("font"):
				color = Color.BLACK
			_theme.set_color(color_name, type_name, color)
		for style_name: StringName in _original.get_stylebox_list(type_name):
			var style := _original.get_stylebox(style_name, type_name).duplicate(true) as StyleBox
			if high_contrast and style is StyleBoxFlat:
				style.bg_color = Color.WHITE
				style.border_color = Color.BLACK
				if type_name == &"HSlider" and String(style_name).begins_with("grabber_area"):
					style.bg_color = Color.BLACK
			_theme.set_stylebox(style_name, type_name, style)
