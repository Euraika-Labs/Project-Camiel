# probe_lesson_select.gd
# Headless proof of LESSON-06: a Dutch control on the main menu opens the
# lesson-select screen, that screen's buttons are built from one table, the
# keyboard walks around them in the order the screen declares, and every lesson
# the table advertises really loads as a playable 3D scene.
#
# Every assertion below iterates the screen's own table. It never names a
# lesson. That is deliberate and load-bearing: the archived main menu linked
# only the first lesson and left four unreachable, so a probe that hardcoded
# the first lesson would reproduce that exact blind spot in the form of a
# passing test. Adding a row to the table is what makes a lesson verified here,
# and a row whose scene does not exist fails this probe loudly.
# Run by scripts/tools/run_headless_check.sh.
extends SceneTree

# ── Constants ────────────────────────────────────────────────────

const LESSON_SELECT_SCRIPT_PATH := "res://scripts/lesson_select.gd"
const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const INTRO_LEVEL_PATH := "res://scenes/intro_level.tscn"
const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")

## How many lessons this milestone promises a child (LESSON-06). Asserted as a
## number rather than inferred from the table, because every other assertion in
## this file iterates the table and would therefore pass just as happily on a
## table holding four -- which is what shipped in the archive, where the screen
## that should have offered five offered one.
const EXPECTED_LESSON_COUNT := 6

# ── Internal state ───────────────────────────────────────────────

var _failed := false
var _cases_run := 0
var _transition_count := 0
var _transition_target := ""


# ── Lifecycle ────────────────────────────────────────────────────

func _initialize() -> void:
	await _case_main_menu_opens_lesson_select()
	if _failed:
		return
	await _case_lesson_table_drives_buttons()
	if _failed:
		return
	await _case_lesson_button_transitions()
	if _failed:
		return

	if _cases_run == 0:
		_fail("non_vacuity", "no case ran; the probe would verify nothing")
		return

	print("Lesson select probe passed.")
	quit(0)


func _fail(case_name: String, detail: String) -> void:
	_failed = true
	push_error("%s: %s" % [case_name, detail])
	quit(1)


# ── Helpers ──────────────────────────────────────────────────────

func _on_transition_requested_counted(target_path: String) -> void:
	_transition_count += 1
	_transition_target = target_path


# Mirrors probe_screen_flow.gd's synthesised accept-action helper.
func _press_focused() -> void:
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = "ui_accept"
	release.pressed = false
	Input.parse_input_event(release)


# Each guarded handler really does request a scene change, so after the first
# activation the engine loads the target scene into the tree and its own ready
# callback grabs focus on its own control. Without draining, a second
# activation would land on a different screen and the guard test would be
# measuring the wrong thing. Mirrors probe_screen_flow.gd.
func _drain_scene_change() -> void:
	await process_frame
	await process_frame
	if current_scene != null:
		var stale: Node = current_scene
		root.remove_child(stale)
		stale.free()
		set_current_scene(null)


## Adds a screen to the root, settles it, and returns it. Fails the case and
## returns null when the scene will not load.
func _open_screen(case_name: String, scene_path: String) -> Control:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		_fail(case_name, "could not load %s" % scene_path)
		return null
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	return screen


## Reads the lesson table off the screen's own script, through the instance the
## case is already holding. The screen, its transitions and this probe all read
## this one array, which is what keeps them from drifting apart (D-33).
func _read_table(case_name: String, screen: Node) -> Array:
	var script := screen.get_script() as GDScript
	if script == null:
		_fail(case_name, "the lesson-select instance carries no script")
		return []
	var constants := script.get_script_constant_map()
	if not constants.has("LESSONS"):
		_fail(case_name, "the lesson-select script declares no LESSONS table")
		return []
	var table: Array = constants["LESSONS"]
	if table.is_empty():
		_fail(case_name, "the LESSONS table is empty; the screen would offer nothing")
		return []
	return table


## Resolves one declared focus neighbour and returns the node it points at, or
## null when the property was never set. Reading the neighbour as a NodePath and
## resolving it is the same assertion shape the shipped win-screen probe uses.
func _resolve_neighbor(control: Control, path: NodePath) -> Node:
	if path.is_empty():
		return null
	return control.get_node_or_null(path)


# ── Cases ────────────────────────────────────────────────────────

## The main menu's new control opens the lesson screen exactly once, and the
## Start control still does exactly what it always did -- the regression guard
## for what this plan changed on a screen that already shipped.
func _case_main_menu_opens_lesson_select() -> void:
	var case_name := "main_menu_opens_lesson_select"
	var menu: Control = await _open_screen(case_name, MAIN_MENU_PATH)
	if _failed:
		return

	var lessons_button: Button = menu.get_node_or_null("%LessonsButton")
	if lessons_button == null:
		_fail(case_name, "the main menu has no %LessonsButton")
		return
	if lessons_button.label_text != "Lessen":
		_fail(case_name, "%%LessonsButton's label reads %s, expected Lessen" % lessons_button.label_text)
		return

	var connections := lessons_button.get_signal_connection_list("pressed")
	if connections.size() != 1:
		_fail(case_name, "%%LessonsButton.pressed has %d connections, expected 1 (the menu's own handler)" % connections.size())
		return

	var start_button: Button = menu.get_node_or_null("%StartButton")
	var sfx_slider: Control = menu.get_node_or_null("%SfxSlider")
	if start_button == null or sfx_slider == null:
		_fail(case_name, "the main menu is missing %StartButton or %SfxSlider")
		return
	if _resolve_neighbor(lessons_button, lessons_button.focus_neighbor_top) != start_button:
		_fail(case_name, "%LessonsButton's upward focus neighbour does not resolve to %StartButton")
		return
	if _resolve_neighbor(lessons_button, lessons_button.focus_neighbor_bottom) != sfx_slider:
		_fail(case_name, "%LessonsButton's downward focus neighbour does not resolve to %SfxSlider -- a keyboard user would leave the chain at the new control")
		return

	_transition_count = 0
	_transition_target = ""
	menu.transition_requested.connect(_on_transition_requested_counted)

	lessons_button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _transition_count != 1:
		_fail(case_name, "transition_requested fired %d times, expected 1" % _transition_count)
		return
	if _transition_target != LESSON_SELECT_PATH:
		_fail(case_name, "transition_requested carried %s, expected %s" % [_transition_target, LESSON_SELECT_PATH])
		return

	await _drain_scene_change()

	lessons_button.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _transition_count != 1:
		_fail(case_name, "the one-shot guard did not block a second activation; count is %d" % _transition_count)
		return

	menu.transition_requested.disconnect(_on_transition_requested_counted)
	menu.queue_free()
	await process_frame

	# A fresh menu checks that visiting the lesson picker preserves the route
	# offered by the primary button for the player's saved progress.
	var tracker := root.get_node("ProgressTracker")
	var completed: Dictionary = tracker.completed_lesson_ids()
	var expected_target := INTRO_LEVEL_PATH
	if tracker.has_completed_intro() or not completed.is_empty():
		var next := LESSON_CATALOG.next_unfinished_index(completed)
		expected_target = LESSON_CATALOG.LESSONS[next]["path"] if next >= 0 else LESSON_CATALOG.CELEBRATION_PATH
	var fresh_menu: Control = await _open_screen(case_name, MAIN_MENU_PATH)
	if _failed:
		return
	var fresh_start: Button = fresh_menu.get_node_or_null("%StartButton")
	if fresh_start == null:
		_fail(case_name, "the fresh main menu has no %StartButton")
		return

	_transition_count = 0
	_transition_target = ""
	fresh_menu.transition_requested.connect(_on_transition_requested_counted)

	fresh_start.grab_focus()
	_press_focused()
	await process_frame
	await process_frame

	if _transition_count != 1:
		_fail(case_name, "the Start control fired transition_requested %d times, expected 1" % _transition_count)
		return
	if _transition_target != expected_target:
		_fail(case_name, "the primary control requested %s, expected %s" % [_transition_target, expected_target])
		return

	fresh_menu.transition_requested.disconnect(_on_transition_requested_counted)
	await _drain_scene_change()
	fresh_menu.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)


## The table is the screen: one button per entry, each button's label and icon
## from its entry, each entry's scene proved loadable and 3D, and the focus
## cycle running all the way around in both directions.
func _case_lesson_table_drives_buttons() -> void:
	var case_name := "lesson_table_drives_buttons"
	var initial_size := root.size
	root.size = Vector2i(800, 450)
	var screen: Control = await _open_screen(case_name, LESSON_SELECT_PATH)
	if _failed:
		return

	var table := _read_table(case_name, screen)
	if _failed:
		return
	if table.size() != EXPECTED_LESSON_COUNT:
		_fail(case_name, "the lesson table holds %d entries, %d wanted -- the screen offers exactly the lessons this milestone promises" % [table.size(), EXPECTED_LESSON_COUNT])
		return

	# Every entry's identifier, path and label must be its own. A copied row
	# pointing a second button at an existing lesson passes every other
	# assertion in this file -- the button is built, its label and icon match
	# its entry, its path loads and instantiates as a 3D node -- while a child
	# taps two different buttons and arrives at the same lesson twice.
	var seen_ids := {}
	var seen_paths := {}
	var seen_labels := {}
	for entry: Dictionary in table:
		var seen_id := String(entry.get("id", ""))
		var seen_path := String(entry.get("path", ""))
		var seen_label := String(entry.get("label", ""))
		if seen_id.is_empty() or seen_path.is_empty() or seen_label.is_empty():
			_fail(case_name, "a table entry is missing its identifier, path or label: %s" % [entry])
			return
		if seen_ids.has(seen_id):
			_fail(case_name, "two table entries carry the identifier %s; a lesson's identifier is what its saved progress is filed under, so a duplicate loses one lesson's history into another's" % seen_id)
			return
		if seen_paths.has(seen_path):
			_fail(case_name, "two table entries point at %s; one of the buttons opens the wrong lesson" % seen_path)
			return
		if seen_labels.has(seen_label):
			_fail(case_name, "two table entries are labelled %s; a child cannot tell the two buttons apart" % seen_label)
			return
		seen_ids[seen_id] = true
		seen_paths[seen_path] = true
		seen_labels[seen_label] = true

	var grid: GridContainer = screen.get_node_or_null("%LessonGrid")
	if grid == null:
		_fail(case_name, "the lesson screen has no %LessonGrid")
		return
	if grid.get_child_count() != table.size():
		_fail(case_name, "%%LessonGrid holds %d buttons for a table of %d entries" % [grid.get_child_count(), table.size()])
		return

	var buttons: Array[Button] = []
	for i in table.size():
		var entry: Dictionary = table[i]
		var entry_id := String(entry.get("id", ""))
		var child: Button = grid.get_node_or_null(NodePath(entry_id)) as Button
		if child == null:
			_fail(case_name, "no button named %s was built for table entry %d" % [entry_id, i])
			return
		if child.label_text != String(entry.get("label", "")):
			_fail(case_name, "%s's label reads %s, expected %s" % [entry_id, child.label_text, entry.get("label")])
			return
		if child.icon_kind != String(entry.get("icon", "")):
			_fail(case_name, "%s's icon kind is %s, expected %s" % [entry_id, child.icon_kind, entry.get("icon")])
			return
		var illustration := child.get_node_or_null("%Illustration") as TextureRect
		if illustration == null or illustration.texture == null or illustration.texture.resource_path.get_file() != entry_id + ".webp":
			_fail(case_name, "%s does not show its own lesson preview" % entry_id)
			return
		if child.accessibility_name != "%s, %s" % [entry["label"], entry["caption"]]:
			_fail(case_name, "%s is missing the accessible lesson name" % entry_id)
			return
		var connections := child.get_signal_connection_list("pressed")
		if connections.size() != 1:
			_fail(case_name, "%s.pressed has %d connections, expected 1 (the screen's own handler)" % [entry_id, connections.size()])
			return

		# The reachability assertion. A table row is a promise that a child can
		# play that lesson; this is where the promise is checked against the
		# filesystem rather than trusted.
		var entry_path := String(entry.get("path", ""))
		if not ResourceLoader.exists(entry_path):
			_fail(case_name, "%s's scene path %s does not exist" % [entry_id, entry_path])
			return
		var packed: PackedScene = load(entry_path)
		if packed == null:
			_fail(case_name, "%s's scene %s did not load as a PackedScene" % [entry_id, entry_path])
			return
		var instance := packed.instantiate()
		if instance == null:
			_fail(case_name, "%s's scene %s failed to instantiate" % [entry_id, entry_path])
			return
		if not instance is Node3D:
			_fail(case_name, "%s's scene %s does not instantiate as a 3D node" % [entry_id, entry_path])
			instance.free()
			return
		instance.free()

		buttons.append(child)

	if not buttons[0].has_focus():
		_fail(case_name, "the first lesson button does not hold focus after the screen is ready")
		return

	var back_button: Button = screen.get_node_or_null("%BackButton")
	if back_button == null:
		_fail(case_name, "the lesson screen has no %BackButton")
		return
	if back_button.label_text != "Naar menu":
		_fail(case_name, "%%BackButton's label reads %s, expected Naar menu" % back_button.label_text)
		return
	var first := buttons[0]
	var second := buttons[1]
	var lower := buttons[3]
	var last: Button = buttons.back()
	if _resolve_neighbor(first, first.focus_neighbor_right) != second or _resolve_neighbor(second, second.focus_neighbor_left) != first:
		_fail(case_name, "horizontal arrows did not connect adjacent cards")
		return
	if _resolve_neighbor(first, first.focus_neighbor_bottom) != lower or _resolve_neighbor(lower, lower.focus_neighbor_top) != first:
		_fail(case_name, "vertical arrows did not connect matching columns")
		return
	if _resolve_neighbor(lower, lower.focus_neighbor_bottom) != back_button:
		_fail(case_name, "the menu button was unreachable from the bottom row")
		return
	var celebration: Button = screen.get_node("%CelebrationButton")
	var after_back := celebration if celebration.visible else first
	if _resolve_neighbor(last, last.focus_next) != back_button or _resolve_neighbor(back_button, back_button.focus_next) != after_back:
		_fail(case_name, "the Tab cycle did not include both the lessons and the menu button")
		return
	if celebration.visible and _resolve_neighbor(celebration, celebration.focus_next) != first:
		_fail(case_name, "the Tab cycle did not continue from the celebration to the first card")
		return

	root.size = Vector2i(320, 568)
	for frame in 6:
		await process_frame
	var view := root.get_visible_rect()
	if grid.columns != 2 or not view.encloses(grid.get_global_rect()) or not view.encloses(back_button.get_global_rect()):
		_fail(case_name, "illustrated cards or the return button overflow the small portrait screen")
		return
	if _resolve_neighbor(first, first.focus_neighbor_bottom) != buttons[2]:
		_fail(case_name, "portrait keyboard focus does not follow the two visible columns")
		return
	root.size = Vector2i(540, 540)
	for frame in 6:
		await process_frame
	if grid.columns != 2 or not root.get_visible_rect().encloses(grid.get_global_rect()):
		_fail(case_name, "the nearly square window should keep the two-column layout")
		return
	root.size = Vector2i(568, 260)
	for frame in 6:
		await process_frame
	view = root.get_visible_rect()
	if grid.columns != 3 or not view.encloses(grid.get_global_rect()) or not view.encloses(back_button.get_global_rect()):
		_fail(case_name, "illustrated cards or the return button overflow the short landscape screen")
		return
	if _resolve_neighbor(first, first.focus_neighbor_bottom) != buttons[3]:
		_fail(case_name, "landscape keyboard focus does not follow the three visible columns")
		return
	root.size = initial_size
	await process_frame
	screen.queue_free()
	await process_frame

	_cases_run += 1
	print("PASS %s" % case_name)


## Every button, on its own fresh screen, requests exactly one transition
## carrying its own entry's path -- and a second activation requests none. A
## fresh instance per entry because the one-shot guard is supposed to block
## everything after the first transition, which would otherwise mask a button
## wired to the wrong path.
func _case_lesson_button_transitions() -> void:
	var case_name := "lesson_button_transitions"
	var table_source: GDScript = load(LESSON_SELECT_SCRIPT_PATH)
	if table_source == null:
		_fail(case_name, "could not load %s" % LESSON_SELECT_SCRIPT_PATH)
		return
	var table: Array = table_source.get_script_constant_map().get("LESSONS", [])
	if table.is_empty():
		_fail(case_name, "the LESSONS table is empty; the screen would offer nothing")
		return

	for entry: Dictionary in table:
		var entry_id := String(entry.get("id", ""))
		var entry_path := String(entry.get("path", ""))

		var screen: Control = await _open_screen(case_name, LESSON_SELECT_PATH)
		if _failed:
			return
		var grid: GridContainer = screen.get_node_or_null("%LessonGrid")
		if grid == null:
			_fail(case_name, "the lesson screen has no %LessonGrid")
			return
		var button: Button = grid.get_node_or_null(NodePath(entry_id)) as Button
		if button == null:
			_fail(case_name, "no button named %s exists on a fresh screen" % entry_id)
			return

		_transition_count = 0
		_transition_target = ""
		screen.transition_requested.connect(_on_transition_requested_counted)

		button.grab_focus()
		_press_focused()
		await process_frame
		await process_frame

		if _transition_count != 1:
			_fail(case_name, "%s fired transition_requested %d times, expected 1" % [entry_id, _transition_count])
			return
		if _transition_target != entry_path:
			_fail(case_name, "%s carried %s, expected its own entry's path %s" % [entry_id, _transition_target, entry_path])
			return

		button.grab_focus()
		_press_focused()
		await process_frame
		await process_frame

		if _transition_count != 1:
			_fail(case_name, "%s's one-shot guard did not block a second activation; count is %d" % [entry_id, _transition_count])
			return

		screen.transition_requested.disconnect(_on_transition_requested_counted)
		screen.queue_free()
		await _drain_scene_change()

	_cases_run += 1
	print("PASS %s" % case_name)
