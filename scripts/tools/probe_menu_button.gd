# probe_menu_button.gd
# Headless behaviour probe proving the D-14 single-activation-path contract
# for MENU-01, MENU-02, and INTRO-05: scenes/ui/menu_button.tscn is one
# focusable icon-plus-label button, activated by exactly one signal through
# exactly one path. Run by scripts/tools/run_headless_check.sh.
extends SceneTree

const BUTTON_SCENE_PATH := "res://scenes/ui/menu_button.tscn"

# GDScript lambdas capture outer locals by value, not by reference, so a
# `func(): fire_count += 1` closure never mutates a local `fire_count` —
# these must be script-level fields, updated by a real bound method, to
# observe the signal (see probe_camiel_movement.gd's identical note).
var _press_count := 0
var _failed := false


func _initialize() -> void:
	await _case_focus_and_single_emission()
	if _failed:
		return
	await _case_label_and_icon_binding()
	if _failed:
		return
	await _case_play_icon_geometry()
	if _failed:
		return
	await _case_defaults()
	if _failed:
		return
	await _case_all_icon_kinds()
	if _failed:
		return
	await _case_live_redraw()
	if _failed:
		return
	await _case_tap_through()
	if _failed:
		return
	await _case_theme_states()
	if _failed:
		return

	print("Menu button probe passed.")
	quit(0)


func _fail(case_name: String, detail: String) -> void:
	_failed = true
	push_error("%s: %s" % [case_name, detail])
	quit(1)


func _on_pressed_for_count() -> void:
	_press_count += 1


func _press_focused() -> void:
	var pressed_event := InputEventAction.new()
	pressed_event.action = "ui_accept"
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)

	var released_event := InputEventAction.new()
	released_event.action = "ui_accept"
	released_event.pressed = false
	Input.parse_input_event(released_event)


func _load_button() -> Button:
	var packed: PackedScene = load(BUTTON_SCENE_PATH)
	if packed == null:
		push_error("Could not load %s" % BUTTON_SCENE_PATH)
		return null
	return packed.instantiate() as Button


func _case_focus_and_single_emission() -> void:
	var button := _load_button()
	if button == null:
		_fail("focus_and_single_emission", "menu button scene failed to load")
		return

	root.add_child(button)
	await process_frame
	await process_frame

	button.label_text = "Spelen"
	button.icon_kind = "play"

	_press_count = 0
	button.pressed.connect(_on_pressed_for_count)

	var connections := button.get_signal_connection_list("pressed")
	if connections.size() != 1:
		_fail("focus_and_single_emission", "pressed connection list has %d entries, expected exactly 1" % connections.size())
		button.queue_free()
		return

	button.grab_focus()
	if not button.has_focus():
		_fail("focus_and_single_emission", "has_focus() is false after grab_focus()")
		button.queue_free()
		return

	_press_focused()
	await process_frame
	await process_frame

	if _press_count != 1:
		_fail("focus_and_single_emission", "pressed fired %d times after one activation, expected exactly 1" % _press_count)
		button.queue_free()
		return

	# The component holds no one-shot guard of its own — pressing again must
	# fire pressed again; the one-shot behaviour the menus need is the call
	# site's job, not this component's.
	_press_focused()
	await process_frame
	await process_frame

	if _press_count != 2:
		_fail("focus_and_single_emission", "pressed fired %d times after two activations, expected exactly 2" % _press_count)
		button.queue_free()
		return

	button.queue_free()
	print("PASS focus_and_single_emission")


func _case_label_and_icon_binding() -> void:
	# Assigned before entering the tree.
	var before_button := _load_button()
	if before_button == null:
		_fail("label_and_icon_binding", "menu button scene failed to load")
		return
	before_button.label_text = "Start"
	before_button.icon_kind = "walk"
	root.add_child(before_button)
	await process_frame
	await process_frame

	var before_label: Label = before_button.get_node("%Label")
	var before_icon: Control = before_button.get_node("%Icon")
	if before_label.text != "Start":
		_fail("label_and_icon_binding", "label_text set before entering the tree did not reach %%Label (%s)" % before_label.text)
		before_button.queue_free()
		return
	if before_icon.icon_kind != "walk":
		_fail("label_and_icon_binding", "icon_kind set before entering the tree did not reach %%Icon (%s)" % before_icon.icon_kind)
		before_button.queue_free()
		return
	before_button.queue_free()

	# Assigned after entering the tree.
	var after_button := _load_button()
	if after_button == null:
		_fail("label_and_icon_binding", "menu button scene failed to load")
		return
	root.add_child(after_button)
	await process_frame
	await process_frame

	after_button.label_text = "Nog een keer"
	after_button.icon_kind = "replay"

	var after_label: Label = after_button.get_node("%Label")
	var after_icon: Control = after_button.get_node("%Icon")
	if after_label.text != "Nog een keer":
		_fail("label_and_icon_binding", "label_text set after entering the tree did not reach %%Label (%s)" % after_label.text)
		after_button.queue_free()
		return
	if after_icon.icon_kind != "replay":
		_fail("label_and_icon_binding", "icon_kind set after entering the tree did not reach %%Icon (%s)" % after_icon.icon_kind)
		after_button.queue_free()
		return

	after_button.queue_free()
	print("PASS label_and_icon_binding")


func _shape_extreme_points(shape: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	match shape.get("type", ""):
		"polygon":
			for point: Vector2 in shape["points"]:
				points.append(point)
		"circle", "arc":
			var center: Vector2 = shape["center"]
			var radius: float = shape["radius"]
			points.append(center - Vector2(radius, radius))
			points.append(center + Vector2(radius, radius))
		"rect":
			var rect: Rect2 = shape["rect"]
			points.append(rect.position)
			points.append(rect.position + rect.size)
	return points


func _case_play_icon_geometry() -> void:
	var icon_script: GDScript = load("res://scripts/ui/vector_icon.gd")
	var icon: Control = icon_script.new()
	var shapes: Array[Dictionary] = icon.get_icon_shapes("play", Vector2(64, 64))
	icon.free()

	if shapes.is_empty():
		_fail("play_icon_geometry", "get_icon_shapes(\"play\", Vector2(64, 64)) returned no shapes")
		return

	var tolerance := 1.0
	for shape: Dictionary in shapes:
		for point: Vector2 in _shape_extreme_points(shape):
			if point.x < -tolerance or point.x > 64.0 + tolerance or point.y < -tolerance or point.y > 64.0 + tolerance:
				_fail("play_icon_geometry", "shape coordinate %s lies outside the 64x64 rectangle" % point)
				return

	print("PASS play_icon_geometry")


func _case_defaults() -> void:
	var button := _load_button()
	if button == null:
		_fail("defaults", "menu button scene failed to load")
		return

	root.add_child(button)
	await process_frame
	await process_frame

	button.grab_focus()
	if not button.has_focus():
		_fail("defaults", "has_focus() is false after grab_focus() on a default-configured button")
		button.queue_free()
		return

	button.queue_free()
	print("PASS defaults")


const ALL_ICON_KINDS := [
	"play",
	"walk",
	"replay",
	"home",
	"speaker",
	"music_note",
	"lesson_colors",
	"lesson_shapes",
	"lesson_sequence",
]


func _case_all_icon_kinds() -> void:
	var icon_script: GDScript = load("res://scripts/ui/vector_icon.gd")
	var icon: Control = icon_script.new()
	var tolerance := 1.0

	for kind: String in ALL_ICON_KINDS:
		var shapes: Array[Dictionary] = icon.get_icon_shapes(kind, Vector2(64, 64))
		if shapes.is_empty():
			icon.free()
			_fail("all_icon_kinds", "get_icon_shapes(\"%s\", ...) returned no shapes" % kind)
			return
		for shape: Dictionary in shapes:
			for point: Vector2 in _shape_extreme_points(shape):
				if point.x < -tolerance or point.x > 64.0 + tolerance or point.y < -tolerance or point.y > 64.0 + tolerance:
					icon.free()
					_fail("all_icon_kinds", "%s shape coordinate %s lies outside the 64x64 rectangle" % [kind, point])
					return

	var unknown_shapes: Array[Dictionary] = icon.get_icon_shapes("this_kind_does_not_exist", Vector2(64, 64))
	icon.free()
	if not unknown_shapes.is_empty():
		_fail("all_icon_kinds", "an unrecognised icon kind returned %d shapes, expected 0" % unknown_shapes.size())
		return

	print("PASS all_icon_kinds")


func _case_live_redraw() -> void:
	var button := _load_button()
	if button == null:
		_fail("live_redraw", "menu button scene failed to load")
		return

	root.add_child(button)
	await process_frame
	await process_frame

	var icon: Control = button.get_node("%Icon")
	for kind: String in ALL_ICON_KINDS:
		icon.icon_kind = kind
		icon.queue_redraw()
		await process_frame

	button.queue_free()
	print("PASS live_redraw")


func _case_tap_through() -> void:
	var button := _load_button()
	if button == null:
		_fail("tap_through", "menu button scene failed to load")
		return

	root.add_child(button)
	await process_frame
	await process_frame

	var content: Control = button.get_node("Content")
	var icon: Control = button.get_node("%Icon")
	var label: Control = button.get_node("%Label")

	if content.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("tap_through", "Content.mouse_filter is not MOUSE_FILTER_IGNORE")
		button.queue_free()
		return
	if icon.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("tap_through", "%%Icon.mouse_filter is not MOUSE_FILTER_IGNORE")
		button.queue_free()
		return
	if label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("tap_through", "%%Label.mouse_filter is not MOUSE_FILTER_IGNORE")
		button.queue_free()
		return

	if button.custom_minimum_size.x < 280.0 or button.custom_minimum_size.y < 112.0:
		_fail("tap_through", "custom_minimum_size %s is smaller than 280x112" % button.custom_minimum_size)
		button.queue_free()
		return

	button.queue_free()
	print("PASS tap_through")


func _case_theme_states() -> void:
	var theme: Theme = load("res://assets/theme/ui_theme.tres")
	if theme == null:
		_fail("theme_states", "could not load res://assets/theme/ui_theme.tres")
		return

	for state_name: String in ["normal", "hover", "pressed", "focus"]:
		if not theme.has_stylebox(state_name, "Button"):
			_fail("theme_states", "Button theme has no '%s' stylebox" % state_name)
			return

	var focus_box: StyleBox = theme.get_stylebox("focus", "Button")
	if not (focus_box is StyleBoxFlat):
		_fail("theme_states", "Button 'focus' stylebox is not a StyleBoxFlat")
		return

	var focus_flat := focus_box as StyleBoxFlat
	var accent := Color("ed9e4d")
	if not focus_flat.border_color.is_equal_approx(accent):
		_fail("theme_states", "focus stylebox border color %s does not match accent %s" % [focus_flat.border_color, accent])
		return
	if focus_flat.border_width_left != 4 or focus_flat.border_width_top != 4 or focus_flat.border_width_right != 4 or focus_flat.border_width_bottom != 4:
		_fail("theme_states", "focus stylebox border width is not 4 on all sides")
		return

	print("PASS theme_states")
