# Live theme/contrast and reachable settings checks; preserves existing preferences.
extends SceneTree

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var prefs_path := "user://settings.cfg"
	var had_prefs := FileAccess.file_exists(prefs_path)
	var saved := FileAccess.get_file_as_bytes(prefs_path) if had_prefs else PackedByteArray()
	var accessibility := root.get_node("Accessibility")
	var original: bool = accessibility.high_contrast
	accessibility.set_high_contrast(false)
	var theme := load("res://assets/theme/ui_theme.tres") as Theme
	var ink := theme.get_color("font_color", "SmallLabel")
	var backgrounds := [Color(0.62, 0.82, 0.95), Color(1, 0.9647059, 0.9098039), Color(0.92, 0.88752943, 0.8370196)]
	for background: Color in backgrounds:
		var ratio := _contrast(ink, background)
		print("UI contrast: %.2f:1" % ratio)
		_check(ratio >= 4.5, "normal text contrast below AA")
	for type_name: StringName in theme.get_type_list():
		for color_name: StringName in theme.get_color_list(type_name):
			if not String(color_name).begins_with("font") or "disabled" in String(color_name):
				continue
			for background: Color in backgrounds:
				_check(_contrast(theme.get_color(color_name, type_name), background) >= 4.5,
					"text contrast: %s/%s" % [type_name, color_name])
	var menu := load("res://scenes/main_menu.tscn").instantiate() as Control
	root.add_child(menu)
	await process_frame
	var settings_button: Button
	for child: Node in menu.get_children():
		if child is Button and child.text == "Instellingen":
			settings_button = child
	_check(settings_button != null, "settings not reachable from menu")
	if settings_button != null:
		settings_button.pressed.emit()
		await process_frame
		var overlay := menu.get_node_or_null("Settings")
		_check(overlay != null, "settings button did not open overlay")
		if overlay != null:
			var toggles := overlay.find_children("*", "CheckButton", true, false)
			_check(not toggles.is_empty(), "contrast toggle missing")
			if not toggles.is_empty():
				toggles[0].button_pressed = true
				await process_frame
				_check(accessibility.high_contrast, "UI toggle did not change setting")
				_check(theme.get_color("font_color", "SmallLabel") == Color.BLACK, "live cached theme unchanged")
				_check(theme.get_stylebox("normal", "Button").bg_color == Color.WHITE, "contrast background unchanged")
				_check(theme.get_stylebox("grabber_area", "HSlider").bg_color == Color.BLACK, "volume fill invisible on white panel")
				var persisted := ConfigFile.new()
				_check(persisted.load(prefs_path) == OK and persisted.get_value("accessibility", "high_contrast", false), "contrast not persisted")
			var cancel := InputEventAction.new()
			cancel.action = "ui_cancel"
			cancel.pressed = true
			root.push_input(cancel)
			await process_frame
			await process_frame
			_check(menu.get_node_or_null("Settings") == null, "Escape did not close settings")
			_check(root.gui_get_focus_owner() == menu.get_node("%StartButton"), "menu focus not restored")
	menu.queue_free()
	await process_frame
	accessibility.set_high_contrast(original)
	if had_prefs:
		var file := FileAccess.open(prefs_path, FileAccess.WRITE)
		file.store_buffer(saved)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(prefs_path))
	if not _failed:
		print("Accessibility probe passed.")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)


func _linear(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)


func _luminance(color: Color) -> float:
	return 0.2126 * _linear(color.r) + 0.7152 * _linear(color.g) + 0.0722 * _linear(color.b)


func _contrast(a: Color, b: Color) -> float:
	var first := _luminance(a)
	var second := _luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)
