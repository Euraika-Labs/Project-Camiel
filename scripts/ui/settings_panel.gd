# Accessible settings overlay, created only from the main menu.
extends CanvasLayer


func _ready() -> void:
	layer = 20
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme = load("res://assets/theme/ui_theme.tres")
	center.add_child(panel)
	var rows := VBoxContainer.new()
	rows.custom_minimum_size = Vector2(500, 0)
	rows.add_theme_constant_override("separation", 24)
	panel.add_child(rows)
	var title := Label.new()
	title.text = "Instellingen"
	title.theme_type_variation = "HeadingLabel"
	rows.add_child(title)
	var contrast := CheckButton.new()
	contrast.text = "Hoog contrast"
	contrast.custom_minimum_size.y = 64
	contrast.button_pressed = Accessibility.high_contrast
	contrast.toggled.connect(Accessibility.set_high_contrast)
	rows.add_child(contrast)
	var focus_controls: Array[Control] = [contrast]
	var voice := get_tree().root.get_node_or_null("VoiceManager")
	if voice != null:
		var voice_label := Label.new()
		voice_label.text = "Stem"
		rows.add_child(voice_label)
		var voice_volume := HSlider.new()
		voice_volume.name = "VoiceVolume"
		voice_volume.custom_minimum_size = Vector2(420, 64)
		voice_volume.min_value = 0
		voice_volume.max_value = 100
		voice_volume.step = 5
		voice_volume.value = voice.get_volume() * 100.0
		voice_volume.value_changed.connect(func(value: float) -> void: voice.set_volume(value / 100.0))
		rows.add_child(voice_volume)
		focus_controls.append(voice_volume)
	var close := Button.new()
	close.text = "Terug"
	close.custom_minimum_size.y = 64
	close.pressed.connect(queue_free)
	rows.add_child(close)
	focus_controls.append(close)
	for index in focus_controls.size():
		var control := focus_controls[index]
		var next := focus_controls[(index + 1) % focus_controls.size()]
		var previous := focus_controls[(index - 1 + focus_controls.size()) % focus_controls.size()]
		control.focus_next = control.get_path_to(next)
		control.focus_previous = control.get_path_to(previous)
		control.focus_neighbor_bottom = control.focus_next
		control.focus_neighbor_top = control.focus_previous
	contrast.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
