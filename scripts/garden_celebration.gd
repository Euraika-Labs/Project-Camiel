extends Control

signal transition_requested(target_path: String)

const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")
const VECTOR_ICON := preload("res://scripts/ui/vector_icon.gd")
const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

var _transitioning := false


func _ready() -> void:
	if ProgressTracker.completed_lesson_ids().size() != LESSON_CATALOG.LESSONS.size():
		_open_scene(LESSON_SELECT_PATH)
		return
	for lesson: Dictionary in LESSON_CATALOG.LESSONS:
		_add_badge(lesson)
	ScreenLayout.layout_changed.connect(_layout_screen)
	_layout_screen(ScreenLayout.portrait)
	%LessonsButton.pressed.connect(_open_scene.bind(LESSON_SELECT_PATH))
	%MenuButton.pressed.connect(_open_scene.bind(MAIN_MENU_PATH))
	%CheerButton.pressed.connect(_cheer)
	%LessonsButton.grab_focus()
	VoiceManager.bind_scene(self, "garden_complete")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	_cheer()


func _layout_screen(portrait: bool) -> void:
	var garden := Vector4(0, 0, 1, 0.43) if portrait else Vector4(0, 0, 0.5, 1)
	var content := Vector4(0, 0.43, 1, 1) if portrait else Vector4(0.5, 0, 1, 1)
	ScreenLayout.place($PictureArea, garden)
	ScreenLayout.place($ContentArea, content)
	var button_height := ScreenLayout.SHORT_LANDSCAPE_BUTTON_HEIGHT if ScreenLayout.short_landscape else 90.0
	for button: Button in [%CheerButton, %LessonsButton, %MenuButton]:
		button.custom_minimum_size.y = button_height
	%CheerButton.offset_top = %CheerButton.offset_bottom - button_height


func _cheer() -> void:
	if _transitioning or %PartyConfetti.is_processing():
		return
	%PartyConfetti.scatter()
	%CamielPortrait.play_cheer()
	AudioManager.play_sfx("finish")


func _add_badge(lesson: Dictionary) -> void:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"HudPanel"
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var icon := VECTOR_ICON.new()
	icon.custom_minimum_size = Vector2(36, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.icon_kind = String(lesson["icon"])
	icon.shape_colors = PackedColorArray(lesson.get("icon_colors", []))
	row.add_child(icon)
	var label := Label.new()
	label.text = String(lesson["label"])
	label.theme_type_variation = &"SmallLabel"
	label.add_theme_font_size_override("font_size", 19)
	row.add_child(label)
	badge.add_child(row)
	%LessonBadges.add_child(badge)


func _open_scene(target_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(target_path)
	get_tree().change_scene_to_file.call_deferred(target_path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_open_scene(LESSON_SELECT_PATH)
