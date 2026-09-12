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
const LESSONS: Array[Dictionary] = [
	{"id": "lesson_1", "path": "res://scenes/lesson_1.tscn", "label": "Les 1", "icon": "lesson_colors"},
	{"id": "lesson_2", "path": "res://scenes/lesson_2.tscn", "label": "Les 2", "icon": "lesson_shapes"},
	{"id": "lesson_3", "path": "res://scenes/lesson_3.tscn", "label": "Les 3", "icon": "lesson_sequence"},
	{"id": "lesson_4", "path": "res://scenes/lesson_4.tscn", "label": "Les 4", "icon": "lesson_colors"},
]

const MENU_BUTTON_PATH := "res://scenes/ui/menu_button.tscn"
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

# ── Private state ────────────────────────────────────────────────

var _transitioning := false
var _buttons: Array[Button] = []


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	_build_buttons()
	_wire_focus_order()
	%BackButton.pressed.connect(_on_back_button_pressed)
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


# ── Internal helpers ─────────────────────────────────────────────

## Builds one button per table entry. Each button's node name is its lesson's
## identifier, so a probe can find a lesson's button without knowing the grid's
## child order, and each entry's path is carried into the handler through bound
## context rather than a wrapper lambda (this project's convention).
func _build_buttons() -> void:
	var packed: PackedScene = load(MENU_BUTTON_PATH)
	if packed == null:
		push_warning("[LessonSelect] Could not load ", MENU_BUTTON_PATH)
		return

	var grid: GridContainer = %LessonGrid
	for lesson: Dictionary in LESSONS:
		var button: Button = packed.instantiate()
		button.name = String(lesson["id"])
		# Safe before the node enters the tree: menu_button.gd stores both
		# exported values and applies them in its own ready callback.
		button.label_text = String(lesson["label"])
		button.icon_kind = String(lesson["icon"])
		grid.add_child(button)
		button.pressed.connect(_on_lesson_button_pressed.bind(String(lesson["path"])))
		_buttons.append(button)


## Declares the focus cycle explicitly rather than leaving it to the engine's
## tree-order inference (D-32), because the probe is written against the
## declared order -- the same focus-neighbour property the shipped win-screen
## probe already reads and resolves.
func _wire_focus_order() -> void:
	var total := _buttons.size()
	if total == 0:
		return
	for i in total:
		var button := _buttons[i]
		var next := _buttons[(i + 1) % total]
		var previous := _buttons[(i - 1 + total) % total]
		button.focus_neighbor_right = button.get_path_to(next)
		button.focus_neighbor_bottom = button.get_path_to(next)
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_neighbor_top = button.get_path_to(previous)


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
