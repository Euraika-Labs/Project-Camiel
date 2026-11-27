extends Control

signal transition_requested(target_path: String)

const INTRO_LEVEL_PATH := "res://scenes/intro_level.tscn"
const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")
const SETTINGS_PANEL := preload("res://scenes/ui/settings_panel.tscn")

var _transitioning := false
var _start_path := INTRO_LEVEL_PATH


func _ready() -> void:
	VoiceManager.bind_scene(self, _configure_primary_action())
	_add_settings_button()
	ScreenLayout.layout_changed.connect(_layout_screen)
	_layout_screen(ScreenLayout.portrait)
	ProgressTracker.progress_changed.connect(_configure_primary_action)
	%StartButton.pressed.connect(_on_start_pressed)
	%LessonsButton.pressed.connect(_open_scene.bind(LESSON_CATALOG.SELECT_PATH))
	%IntroButton.pressed.connect(_open_scene.bind(INTRO_LEVEL_PATH))
	%StartButton.grab_focus()

	%SfxSlider.value_changed.connect(_on_sfx_slider_value_changed)
	%BgmSlider.value_changed.connect(_on_bgm_slider_value_changed)
	_sync_volume_sliders()


func _configure_primary_action() -> String:
	var completed := ProgressTracker.completed_lesson_ids()
	var can_continue := ProgressTracker.has_completed_intro() or not completed.is_empty()
	%IntroButton.visible = can_continue
	if not can_continue:
		return "main_menu"
	%LessonsButton.focus_next = %LessonsButton.get_path_to(%IntroButton)
	%LessonsButton.focus_neighbor_right = %LessonsButton.focus_next
	%SfxSlider.focus_previous = %SfxSlider.get_path_to(%IntroButton)
	var button: Button = %StartButton
	var cue := "menu_continue"
	var next := LESSON_CATALOG.next_unfinished_index(completed)
	if next >= 0:
		var lesson: Dictionary = LESSON_CATALOG.LESSONS[next]
		_start_path = lesson["path"]
		button.label_text = "Verder spelen"
		button.caption = "%s · %s" % [lesson["label"], lesson["caption"]]
		button.icon_kind = "play"
	else:
		_start_path = LESSON_CATALOG.CELEBRATION_PATH
		button.label_text = "Tuinfeest"
		button.caption = "Vier het samen met Camiel"
		button.icon_kind = "paw"
		cue = "menu_garden"
	button.accessibility_name = button.label_text
	button.accessibility_description = button.caption
	return cue


func _sync_volume_sliders() -> void:
	%SfxSlider.set_value_no_signal(AudioManager.get_sfx_volume() * 100.0)
	%BgmSlider.set_value_no_signal(AudioManager.get_bgm_volume() * 100.0)


func _layout_screen(portrait: bool) -> void:
	var picture := Vector4(0, 0, 1, 0.31) if portrait else Vector4(0.55, 0, 1, 1)
	var options := Vector4(0, 0.31, 1, 1) if portrait else Vector4(0, 0, 0.55, 1)
	ScreenLayout.place($CamielPortrait, picture)
	ScreenLayout.place($CenterContainer, options)
	var settings: Button = $SettingsButton
	var settings_height := 82.0 if portrait else 64.0
	settings.custom_minimum_size.y = 102.0 if ScreenLayout.short_landscape else settings_height
	settings.offset_bottom = settings.offset_top + settings.custom_minimum_size.y


func _open_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(path)
	get_tree().change_scene_to_file.call_deferred(path)


func _on_start_pressed() -> void:
	_open_scene(_start_path)


func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0, true)


func _on_bgm_slider_value_changed(value: float) -> void:
	AudioManager.set_bgm_volume(value / 100.0, true)


func _add_settings_button() -> void:
	var button := Button.new()
	button.text = "Instellingen"
	button.custom_minimum_size = Vector2(220, 64)
	button.name = "SettingsButton"
	add_child(button)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.offset_left = -244.0
	button.offset_top = 24.0
	button.offset_right = -24.0
	button.offset_bottom = 88.0
	%BgmSlider.focus_next = %BgmSlider.get_path_to(button)
	%BgmSlider.focus_neighbor_bottom = %BgmSlider.focus_next
	button.focus_previous = button.get_path_to(%BgmSlider)
	button.focus_neighbor_top = button.focus_previous
	button.focus_next = button.get_path_to(%StartButton)
	button.focus_neighbor_bottom = button.focus_next
	%StartButton.focus_previous = %StartButton.get_path_to(button)
	%StartButton.focus_neighbor_top = %StartButton.focus_previous
	button.pressed.connect(_open_settings)


func _open_settings() -> void:
	if _transitioning or has_node("Settings"):
		return
	var panel := SETTINGS_PANEL.instantiate()
	add_child(panel)
	panel.tree_exited.connect(_restore_menu_focus)


func _restore_menu_focus() -> void:
	var start := get_node_or_null("%StartButton") as Control
	if is_inside_tree() and start != null and start.is_inside_tree():
		_sync_volume_sliders()
		start.grab_focus()
