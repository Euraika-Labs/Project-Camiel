extends CanvasLayer
## Shared settings dialog for the main menu and the paused playground.

var pause_game := false
var _owns_pause := false


func _ready() -> void:
	if pause_game:
		_owns_pause = not get_tree().paused
		get_tree().paused = true
		%Title.text = "Pauze"
		%CloseButton.label_text = "Verder spelen"

	_bind_volume(%MusicVolume, %MusicValue, AudioManager.get_bgm_volume(), AudioManager.set_bgm_volume.bind(true))
	_bind_volume(%EffectsVolume, %EffectsValue, AudioManager.get_sfx_volume(), AudioManager.set_sfx_volume.bind(true))
	_bind_volume(%VoiceVolume, %VoiceValue, VoiceManager.get_volume(), VoiceManager.set_volume)
	%Contrast.toggled.connect(Accessibility.set_high_contrast)
	Accessibility.contrast_changed.connect(_refresh_contrast)
	_refresh_contrast(Accessibility.high_contrast)
	%CloseButton.pressed.connect(queue_free)

	var controls: Array[Control] = [%MusicVolume, %EffectsVolume, %VoiceVolume, %Contrast, %CloseButton]
	for index in controls.size():
		var control := controls[index]
		control.focus_next = control.get_path_to(controls[(index + 1) % controls.size()])
		control.focus_previous = control.get_path_to(controls[posmod(index - 1, controls.size())])
		control.focus_neighbor_bottom = control.focus_next
		control.focus_neighbor_top = control.focus_previous
		control.focus_neighbor_left = NodePath(".")
		control.focus_neighbor_right = NodePath(".")
	if pause_game:
		%CloseButton.grab_focus()
	else:
		%Contrast.grab_focus()


func _refresh_contrast(enabled: bool) -> void:
	%Contrast.set_pressed_no_signal(enabled)
	%Contrast.text = "Hoog contrast (aan)" if enabled else "Hoog contrast (uit)"


func _bind_volume(slider: HSlider, caption: Label, level: float, setter: Callable) -> void:
	slider.set_value_no_signal(level * 100.0)
	caption.text = "%d%%" % roundi(slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		caption.text = "%d%%" % roundi(value)
		setter.call(value / 100.0)
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (pause_game and event.is_action_pressed("pause_play")):
		get_viewport().set_input_as_handled()
		queue_free()


func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = false
