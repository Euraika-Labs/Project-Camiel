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
	VoiceManager.bind_scene(self, "title")
	var version: String = ProjectSettings.get_setting("application/config/version")
	var channel: String = ProjectSettings.get_setting("application/config/release_channel", "stable")
	%Version.text = ("alpha-v" if channel == "alpha" else "v") + version
	ScreenLayout.layout_changed.connect(_layout_screen)
	_layout_screen(ScreenLayout.portrait)
	%PlayButton.pressed.connect(_on_play_button_pressed)
	%PlayButton.grab_focus()

	if OS.has_feature("web"):
		# The Web loading screen covers the canvas until the portrait is drawn.
		await RenderingServer.frame_post_draw
		JavaScriptBridge.get_interface("window").dispatchEvent(
			JavaScriptBridge.create_object("Event", "camiel-first-frame")
		)


func _layout_screen(portrait: bool) -> void:
	var picture := Vector4(0, 0, 1, 0.44) if portrait else Vector4(0.47, 0, 1, 1)
	ScreenLayout.place($PortraitBackground, picture)
	ScreenLayout.place($CamielPortrait, picture)
	if portrait:
		ScreenLayout.place($Welcome, Vector4(0, 0.44, 1, 1), Vector4(34, 12, -34, -60))
	else:
		ScreenLayout.place($Welcome, Vector4(0, 0, 0.47, 1), Vector4(72, 54, -48, -68))
	$Welcome/TitleLabel.add_theme_font_size_override("font_size", 88 if portrait else 108)
	%Version.offset_left = 34.0 if portrait else 72.0
	%PlayButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL if portrait else Control.SIZE_SHRINK_BEGIN


func _on_play_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(MAIN_MENU_PATH)
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)
