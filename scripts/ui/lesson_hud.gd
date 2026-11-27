# lesson_hud.gd
# The shared lesson heads-up display (D-34, D-46) reused by every one of the
# five lessons: a title, the single progress-label form, a Dutch return
# control, and a win panel with its own return control. Announces both
# returns through signals and never changes a scene itself -- each lesson's
# own script decides where back goes.
#
# D-46 resolution: one label form, set_step(current, total), with the total
# as a parameter. Lessons 1-4 pass 3, lesson 5 passes 4 -- the same call
# shape stays correct for the four-step lesson instead of hardcoding a 3
# that would misreport lesson 5's actual rule to the child.
extends CanvasLayer

signal back_requested
signal win_back_requested
signal open_lesson_requested(path: String)

const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")
const WALK_HINT_DISTANCE := 0.5

@onready var _camiel := get_parent().get_node_or_null("Camiel") as CharacterBody3D
@onready var _title_label: Label = %TitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _step_label: Label = %StepLabel
@onready var _back_button: Button = %BackButton
@onready var _win_root: Control = %WinRoot
@onready var _scrim: Control = %Scrim
@onready var _win_back_button: Button = %WinBackButton
var _lesson_index := -1
var _next_lesson_index := -1
var _play_seconds := 0.0
var _ordered := false
var _next_goal: Area3D
var _goal_cue := ""
var _stone_ids := PackedStringArray()
var _color_prompt_cues := PackedStringArray()
var _movement_hint_origin := Vector3.ZERO
var _movement_cue := ""


func _ready() -> void:
	_back_button.pressed.connect(_on_back_button_pressed)
	_win_back_button.pressed.connect(_on_win_back_button_pressed)
	%ListenButton.pressed.connect(_repeat_instructions)
	%ReplayButton.pressed.connect(_play_again)
	%NextButton.pressed.connect(_play_next)
	%CelebrationButton.pressed.connect(_celebrate_garden)
	# Load-bearing, not a style choice: %BackButton's own script
	# (menu_button.gd) assigns Control.FOCUS_ALL inside its own _ready(), so
	# a scene-file override here would be silently undone. A child node's
	# ready callback runs before its parent's, so this display's ready
	# callback is the one place that reliably wins. `jump` and the engine's
	# `ui_accept` are both bound to the space key in this project's input
	# map, so a focusable in-play control would fire on every jump attempt.
	_back_button.focus_mode = Control.FOCUS_NONE
	%ListenButton.focus_mode = Control.FOCUS_NONE
	ScreenLayout.layout_changed.connect(_layout_hud)
	_layout_hud(ScreenLayout.portrait)


func _process(delta: float) -> void:
	if _lesson_index >= 0 and not get_tree().paused and not is_win_visible():
		_play_seconds += delta
		if %MovementHint.visible:
			_update_movement_hint()


func elapsed_play_time() -> float:
	return _play_seconds


func _layout_hud(portrait: bool) -> void:
	var progress: Container = %Task if portrait else %Progress
	if _step_label.get_parent() != progress:
		_step_label.reparent(progress, false)
		%LessonCues.reparent(progress, false)
	%ProgressCard.visible = not portrait
	var shallow := ScreenLayout.short_landscape
	var listen_height := 90.0 if portrait else 86.0
	%ListenButton.custom_minimum_size.y = 102.0 if shallow else listen_height
	var back_height := ScreenLayout.SHORT_LANDSCAPE_BUTTON_HEIGHT if shallow else 90.0
	_back_button.custom_minimum_size.y = back_height
	_back_button.offset_top = -22.0 - back_height
	var result_height := ScreenLayout.SHORT_LANDSCAPE_BUTTON_HEIGHT if shallow else 92.0
	for button: Button in [%NextButton, %CelebrationButton, %ReplayButton, _win_back_button]:
		button.custom_minimum_size.y = result_height


func set_lesson(lesson_id: String) -> void:
	_lesson_index = LESSON_CATALOG.index_for_id(lesson_id)
	if _lesson_index < 0:
		return
	var lesson: Dictionary = LESSON_CATALOG.LESSONS[_lesson_index]
	_play_seconds = 0.0
	_hint_label.text = String(lesson["prompt"])
	%ListenButton.show()
	%PauseButton.show()
	if _camiel != null and not ProgressTracker.has_completed_intro() and ProgressTracker.completed_lesson_ids().is_empty():
		_show_movement_hint()


func _show_movement_hint() -> void:
	var touch: bool = _camiel.has_touch_controls()
	_movement_hint_origin = _camiel.global_position
	_movement_cue = "move_touch" if touch else "move_keyboard"
	%MovementKeys.visible = not touch
	%MovementLabel.text = "Sleep het gele rondje." if touch else "Loop met de pijltjes."
	%MovementHint.show()
	_camiel.show_touch_hints(true, false)


func _update_movement_hint() -> void:
	var offset := _camiel.global_position - _movement_hint_origin
	if Vector2(offset.x, offset.z).length_squared() >= WALK_HINT_DISTANCE * WALK_HINT_DISTANCE:
		_hide_movement_hint()
	elif not _movement_cue.is_empty() and _play_seconds >= 1.0 and not VoiceManager.is_playing():
		VoiceManager.play(_movement_cue)
		_movement_cue = ""


func _hide_movement_hint() -> void:
	if %MovementHint.visible:
		%MovementHint.hide()
		_movement_cue = ""
		_camiel.show_touch_hints(false, false)


## Sets the title shown across the top of every lesson.
func set_title(text: String) -> void:
	_title_label.text = text


func set_targets(targets: Array[Area3D], ordered: bool, stone_ids := PackedStringArray()) -> void:
	_ordered = ordered
	_stone_ids = stone_ids
	_step_label.visible = ordered
	%LessonCues.set_targets(targets, ordered, _stone_ids.size())
	%GoalDirection.configure(_camiel, %TopBar, _back_button)
	_update_guidance(%LessonCues.active_markers())


func complete_target(task_id: String) -> void:
	%LessonCues.complete_target(task_id)
	var remaining: Array[Dictionary] = %LessonCues.active_markers()
	_update_guidance(remaining)
	if remaining.is_empty():
		return
	AudioManager.play_sfx("collect")
	if _ordered:
		VoiceManager.play("correct")
		if not _goal_cue.is_empty():
			VoiceManager.enqueue(_goal_cue)


func _update_guidance(remaining: Array[Dictionary]) -> void:
	%GoalDirection.set_active(remaining)
	_next_goal = null
	_goal_cue = ""
	_color_prompt_cues.clear()
	if not _stone_ids.is_empty():
		_update_color_prompt(remaining)
		return
	if not _ordered or remaining.is_empty():
		return
	var next: Dictionary = remaining[0]
	_next_goal = next["target"]
	if LESSON_CATALOG.ORDERED_PROMPTS.has(next["id"]):
		_hint_label.text = LESSON_CATALOG.ORDERED_PROMPTS[next["id"]]
		_goal_cue = "goal_" + String(next["id"])
	elif _lesson_index >= 0:
		_hint_label.text = String(LESSON_CATALOG.LESSONS[_lesson_index]["prompt"])


func _update_color_prompt(remaining: Array[Dictionary]) -> void:
	var colors := PackedStringArray()
	var stones_left := 0
	for goal: Dictionary in remaining:
		var id := String(goal["id"])
		if _stone_ids.has(id):
			stones_left += 1
		elif LESSON_CATALOG.COLOR_NAMES.has(id):
			colors.append(LESSON_CATALOG.COLOR_NAMES[id])
			_color_prompt_cues.append("color_" + id)
	var instructions := PackedStringArray()
	if not colors.is_empty():
		instructions.append("Raak %s aan." % " en ".join(colors))
	if stones_left > 0:
		_color_prompt_cues.append("goal_stones")
		if stones_left == 1:
			instructions.append("Pak nog één telsteen.")
		else:
			instructions.append("Pak nog %d telstenen." % stones_left)
	_hint_label.text = " ".join(instructions)


## Uses the same active goal for visual and spoken help.
func guide_current_target() -> void:
	if _next_goal != null:
		_next_goal.emphasize_active()
	var cue := "retry" if _goal_cue.is_empty() else _goal_cue
	if VoiceManager.current_cue != cue:
		VoiceManager.play(cue)


## Sets the progress label to "Stap: <current> / <total>". This is the only
## place in the repository this format string exists (D-46) -- lessons 1-4
## pass a total of 3, lesson 5 passes 4, from the same call shape with no
## branch on the total.
func set_step(current: int, total: int) -> void:
	_step_label.text = "Stap: %d / %d" % [current, total]


## Shows the available routes and returns the narration for the primary action.
func show_win(saved := true, garden_completed := false, pending_save: ProgressTracker.BrowserSave = null) -> String:
	%SaveNote.visible = not saved
	if pending_save != null:
		%SaveNote.text = "Opslaan duurt even…"
		pending_save.finished.connect(_on_lesson_save_finished, CONNECT_ONE_SHOT)
	%ReplayButton.visible = _lesson_index >= 0
	_next_lesson_index = -1
	var cue := "complete"
	var primary := _win_back_button
	if garden_completed:
		primary = %CelebrationButton
		cue = "garden_ready"
	elif _lesson_index >= 0:
		var completed := ProgressTracker.completed_lesson_ids()
		_next_lesson_index = LESSON_CATALOG.next_unfinished_index(completed, _lesson_index)
		if completed.size() == LESSON_CATALOG.LESSONS.size() and _lesson_index + 1 < completed.size():
			_next_lesson_index = _lesson_index + 1
		if _next_lesson_index >= 0:
			primary = %NextButton
			primary.label_text = "Naar les %d" % (_next_lesson_index + 1)
			primary.accessibility_name = primary.label_text
			cue = "lesson_continue"
	%NextButton.visible = _next_lesson_index >= 0
	%CelebrationButton.visible = garden_completed
	%WinTitle.text = "Alle zes lessen klaar!" if garden_completed else "Goed zo!"
	_hint_label.hide()
	_hide_movement_hint()
	_back_button.hide()
	%ListenButton.hide()
	%PauseButton.hide()
	%GoalDirection.hide()
	_win_root.visible = true
	_scrim.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_scrim, "modulate:a", 1.0, 0.3)
	primary.grab_focus()
	return cue


func _on_lesson_save_finished(request: ProgressTracker.BrowserSave) -> void:
	%SaveNote.text = "Les opgeslagen." if request.receipt is String else "Les voltooid. Opslaan mislukt."


func _repeat_instructions() -> void:
	if _lesson_index < 0 or is_win_visible():
		return
	if not _goal_cue.is_empty():
		guide_current_target()
	elif not _color_prompt_cues.is_empty():
		VoiceManager.play(_color_prompt_cues[0])
		for index in range(1, _color_prompt_cues.size()):
			VoiceManager.enqueue(_color_prompt_cues[index])
	else:
		VoiceManager.play(String(LESSON_CATALOG.LESSONS[_lesson_index]["id"]))


func _play_again() -> void:
	open_lesson_requested.emit(String(LESSON_CATALOG.LESSONS[_lesson_index]["path"]))


func _play_next() -> void:
	if _next_lesson_index >= 0:
		open_lesson_requested.emit(String(LESSON_CATALOG.LESSONS[_next_lesson_index]["path"]))


func _celebrate_garden() -> void:
	open_lesson_requested.emit(LESSON_CATALOG.CELEBRATION_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if is_win_visible():
			_on_win_back_button_pressed()
		else:
			_on_back_button_pressed()
	elif event.is_action_pressed("listen_again"):
		get_viewport().set_input_as_handled()
		_repeat_instructions()


## Whether the win panel is currently showing. Public so an orchestrator or
## a probe never reads a private node path across scripts.
func is_win_visible() -> bool:
	return _win_root.visible


func _on_back_button_pressed() -> void:
	back_requested.emit()


func _on_win_back_button_pressed() -> void:
	win_back_requested.emit()
