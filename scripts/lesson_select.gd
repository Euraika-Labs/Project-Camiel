# lesson_select.gd
# The lesson-select screen the archived game never had (D-31). Its reason to
# exist is a recorded defect: lessons 2 through 5 existed as scenes and were
# unreachable, because the main menu only ever linked lesson 1. The fix is
# structural rather than a second hardcoded link -- one typed table below is
# the single source of truth for every lesson's identifier, scene path, label
# and icon (D-33), and the buttons, the transitions and the headless probe all
# read that same table. A lesson that is in the table is reachable; a lesson
# that is not in the table does not pretend to exist.
extends Control

# ── Signals ──────────────────────────────────────────────────────

# Observability-only, emitted one line before the deferred engine call it
# shadows -- the same seam the title screen, the main menu and the intro level
# already carry, because a deferred scene change cannot be counted from
# outside.
signal transition_requested(target_path: String)

# ── Constants ────────────────────────────────────────────────────

## Every lesson this screen offers. Plans 03-04 and 03-05 append their own
## entries as each lesson's scene lands; an entry whose scene does not exist
## yet fails the lesson-select probe loudly, which is the whole point -- the
## probe iterates this table and loads every path, so the table can never
## advertise a lesson that is not there.
const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")
const LESSONS := LESSON_CATALOG.LESSONS

const LESSON_CARD := preload("res://scenes/ui/lesson_card.tscn")
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

# ── Private state ────────────────────────────────────────────────

var _transitioning := false
var _buttons: Array[Button] = []


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	VoiceManager.bind_scene(self, "lesson_select")
	_build_buttons()
	_refresh_progress()
	ProgressTracker.progress_changed.connect(_refresh_progress)
	ScreenLayout.layout_changed.connect(_layout_screen)
	_layout_screen(ScreenLayout.portrait)
	%BackButton.pressed.connect(_on_back_button_pressed)
	%CelebrationButton.pressed.connect(_on_lesson_button_pressed.bind(LESSON_CATALOG.CELEBRATION_PATH))
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


# ── Internal helpers ─────────────────────────────────────────────

## Builds one button per table entry. Each button's node name is its lesson's
## identifier, so a probe can find a lesson's button without knowing the grid's
## child order, and each entry's path is carried into the handler through bound
## context rather than a wrapper lambda (this project's convention).
func _build_buttons() -> void:
	var grid: GridContainer = %LessonGrid
	for lesson: Dictionary in LESSONS:
		var button := LESSON_CARD.instantiate() as Button
		button.name = String(lesson["id"])
		# Safe before the node enters the tree: menu_button.gd stores both
		# exported values and applies them in its own ready callback.
		button.label_text = String(lesson["label"])
		button.icon_kind = String(lesson["icon"])
		button.icon_colors = PackedColorArray(lesson.get("icon_colors", []))
		button.caption = String(lesson["caption"])
		button.accessibility_name = "%s, %s" % [button.label_text, button.caption]
		var illustration: TextureRect = button.get_node("%Illustration")
		illustration.texture = load(String(lesson["preview"])) as Texture2D
		grid.add_child(button)
		button.pressed.connect(_on_lesson_button_pressed.bind(String(lesson["path"])))
		_buttons.append(button)


func _refresh_progress() -> void:
	var completed := ProgressTracker.completed_lesson_ids()
	for button: Button in _buttons:
		button.completed = completed.has(String(button.name))
		button.accessibility_description = "Afgerond" if button.completed else ""
	%ProgressSummary.text = "%d van %d afgerond" % [completed.size(), LESSONS.size()]
	%ProgressSummary.visible = not completed.is_empty()
	var celebration: Button = %CelebrationButton
	var can_celebrate := completed.size() == LESSONS.size()
	if celebration.visible != can_celebrate:
		celebration.visible = can_celebrate
		_wire_focus_order()


func _layout_screen(portrait: bool) -> void:
	%LessonGrid.columns = 2 if portrait else 3
	var card_size := Vector2(348, 226)
	var photo_height := 142.0
	if portrait:
		card_size = Vector2(276, 194)
		photo_height = 110.0
	elif ScreenLayout.short_landscape:
		card_size.y = 172.0
		photo_height = 86.0
	for button: Button in _buttons:
		button.custom_minimum_size = card_size
		button.get_node("%Photo").custom_minimum_size.y = photo_height
	var footer_height := 104.0 if ScreenLayout.short_landscape else 90.0
	%BackButton.custom_minimum_size.y = footer_height
	%CelebrationButton.custom_minimum_size.y = footer_height
	_wire_focus_order()


## Arrows follow the visible rows. Tab visits every card and the exit.
func _wire_focus_order() -> void:
	var total := _buttons.size()
	var columns: int = %LessonGrid.columns
	var back: Button = %BackButton
	var celebration: Button = %CelebrationButton
	if total == 0:
		return
	var final_button := celebration if celebration.visible else back
	for i in total:
		var button := _buttons[i]
		var is_left_edge := i % columns == 0
		var is_right_edge := i % columns == columns - 1 or i == total - 1
		button.focus_neighbor_left = button.get_path_to(button if is_left_edge else _buttons[i - 1])
		button.focus_neighbor_right = button.get_path_to(button if is_right_edge else _buttons[i + 1])
		button.focus_neighbor_top = button.get_path_to(_buttons[i - columns] if i >= columns else button)
		var bottom := celebration if celebration.visible and i % columns > 0 else back
		button.focus_neighbor_bottom = button.get_path_to(_buttons[i + columns] if i + columns < total else bottom)
		button.focus_previous = button.get_path_to(final_button if i == 0 else _buttons[i - 1])
		button.focus_next = button.get_path_to(back if i == total - 1 else _buttons[i + 1])
	back.focus_neighbor_top = back.get_path_to(_buttons[maxi(0, total - columns)])
	back.focus_neighbor_bottom = back.get_path_to(_buttons[0])
	back.focus_previous = back.get_path_to(_buttons.back())
	back.focus_next = back.get_path_to(celebration if celebration.visible else _buttons[0])
	back.focus_neighbor_right = back.get_path_to(final_button)
	celebration.focus_previous = celebration.get_path_to(back)
	celebration.focus_next = celebration.get_path_to(_buttons[0])
	celebration.focus_neighbor_left = celebration.focus_previous
	celebration.focus_neighbor_top = celebration.get_path_to(_buttons.back())
	celebration.focus_neighbor_bottom = celebration.focus_next


# ── Signal handlers ──────────────────────────────────────────────

## The same one-shot guard and deferred scene change the two shipped screens
## use (D-15). target_path comes from the table entry this button was built
## from, bound at connection time.
func _on_lesson_button_pressed(target_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(target_path)
	get_tree().change_scene_to_file.call_deferred(target_path)


func _on_back_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(MAIN_MENU_PATH)
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
