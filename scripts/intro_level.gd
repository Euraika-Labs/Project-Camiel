# intro_level.gd
# The 3D intro level (D-20, D-28): the single listener for the collectible's
# and the finish marker's area signals, and the owner of the win-screen
# overlay. Every cross-object reaction the requirements describe as
# "signal-driven" is wired here, in code, in _ready() — no script in this
# level reaches into another script's private method or a group lookup,
# which is exactly the archived finish marker's defect (CONCERNS.md)
# INTRO-04's wording exists to prevent.
extends Node3D

# ── Signals ──────────────────────────────────────────────────────

# Observability-only, emitted one line before the real, deferred engine call
# it shadows — the same seam title_screen.gd and main_menu.gd already use so
# a headless probe can count an activation without racing
# change_scene_to_file's own timing. replay_requested has no deferred call to
# shadow (D-28: replay never changes scenes) but exists for the same reason:
# a probe cannot otherwise count "the replay handler ran" from outside.
signal transition_requested(target_path: String)
signal replay_requested

# ── Constants ────────────────────────────────────────────────────

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")
const BALL_COLOR := Color("#a65e20")
const RING_COLOR := Color("#2d7767")

# ── Node references ──────────────────────────────────────────────

@onready var _camiel: CharacterBody3D = $Camiel
@onready var _player_spawn: Marker3D = $PlayerSpawn
@onready var _trail_marker: MeshInstance3D = %TrailMarker

# ── Private state ────────────────────────────────────────────────

var _transitioning := false
var _collected_ball := false
var _walk_hint := false
var _jump_hint := false
var _continue_path := LESSON_CATALOG.SELECT_PATH
var _trail_motion: Tween
var _trail_fill: StandardMaterial3D


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	VoiceManager.bind_scene(self, _opening_cue())
	_camiel.jumped.connect(_on_player_jumped)
	%FinishMarker.finished.connect(_on_finish_marker_finished)
	%Collectible.collected.connect(_on_collectible_collected)
	%ContinueButton.pressed.connect(_on_continue_button_pressed)
	%ReplayButton.pressed.connect(_on_replay_button_pressed)
	%GoToMenuButton.pressed.connect(_on_go_to_menu_button_pressed)
	%ExploreBackButton.pressed.connect(_on_go_to_menu_button_pressed)
	%IntroListenButton.pressed.connect(_repeat_instructions)
	%ExploreBackButton.focus_mode = Control.FOCUS_NONE
	%IntroListenButton.focus_mode = Control.FOCUS_NONE
	ScreenLayout.layout_changed.connect(_layout_hud)
	_layout_hud(ScreenLayout.portrait)
	%GoalDirection.configure(_camiel, %Guide, %ExploreBackButton)
	_build_trail_marker()
	_set_control_hints(true, true)
	_show_goal()


func _layout_hud(portrait: bool) -> void:
	var shallow := ScreenLayout.short_landscape
	if portrait:
		ScreenLayout.place(%Guide, Vector4(0, 0, 1, 0), Vector4(18, 18, -18, 18))
	else:
		var left_edge := -688.0 if shallow else -608.0
		ScreenLayout.place(%Guide, Vector4(1, 0, 1, 0), Vector4(left_edge, 18, -24, 18))
	var listen_height := 90.0 if portrait else 82.0
	%IntroListenButton.custom_minimum_size.y = 102.0 if shallow else listen_height
	%IntroListenButton.size_flags_vertical = Control.SIZE_SHRINK_CENTER if shallow else Control.SIZE_FILL
	%Controls.add_theme_font_size_override("font_size", 23 if shallow else 17)
	var back_height := ScreenLayout.SHORT_LANDSCAPE_BUTTON_HEIGHT if shallow else 90.0
	%ExploreBackButton.custom_minimum_size.y = back_height
	%ExploreBackButton.offset_top = -22.0 - back_height
	var result_height := ScreenLayout.SHORT_LANDSCAPE_BUTTON_HEIGHT if shallow else 92.0
	%ReplayButton.custom_minimum_size.y = result_height
	%GoToMenuButton.custom_minimum_size.y = result_height


func _set_control_hints(walk: bool, jump: bool) -> void:
	_walk_hint = walk
	_jump_hint = jump
	var touch: bool = _camiel.has_touch_controls()
	var instructions := PackedStringArray()
	if walk:
		instructions.append("Sleep het gele rondje." if touch else "Pijltjes om te lopen")
	if jump:
		instructions.append("Tik op de pijl om te springen." if touch else "Spatie om te springen")
	%Controls.text = "\n".join(instructions)
	%ArrowKeys.visible = walk and not touch
	%ControlHints.visible = walk or jump
	_camiel.show_touch_hints(walk, jump)
	set_process(walk)


func _on_player_jumped() -> void:
	if _jump_hint:
		_set_control_hints(_walk_hint, false)


func _opening_cue() -> String:
	return "intro_touch" if _camiel.has_touch_controls() else "intro"


func _process(_delta: float) -> void:
	var offset := _camiel.global_position - _player_spawn.global_position
	if Vector2(offset.x, offset.z).length_squared() >= 0.25:
		_set_control_hints(false, _jump_hint)


func _build_trail_marker() -> void:
	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	outline.cull_mode = BaseMaterial3D.CULL_DISABLED
	outline.albedo_color = Color("#214638")
	_trail_fill = outline.duplicate() as StandardMaterial3D
	var arrow := ImmediateMesh.new()
	arrow.surface_begin(Mesh.PRIMITIVE_TRIANGLES, outline)
	arrow.surface_add_vertex(Vector3(-0.27, 0.15, 0.0))
	arrow.surface_add_vertex(Vector3(0.27, 0.15, 0.0))
	arrow.surface_add_vertex(Vector3(0.0, -0.26, 0.0))
	arrow.surface_end()
	arrow.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _trail_fill)
	arrow.surface_add_vertex(Vector3(-0.20, 0.11, 0.012))
	arrow.surface_add_vertex(Vector3(0.20, 0.11, 0.012))
	arrow.surface_add_vertex(Vector3(0.0, -0.19, 0.012))
	arrow.surface_end()
	_trail_marker.mesh = arrow


func _show_goal() -> void:
	var target: Area3D = %FinishMarker if _collected_ball else %Collectible
	%Task.text = "Volg de stenen naar de ring." if _collected_ball else "Loop naar de gouden bol."
	%FinishMarker.set_guided(_collected_ball)
	var markers: Array[Dictionary] = [{
		"id": "finish" if _collected_ball else "ball",
		"target": target,
		"shape": "ring" if _collected_ball else "sphere",
		"color": RING_COLOR if _collected_ball else BALL_COLOR,
		"offset_y": 0.1 if _collected_ball else 0.14,
	}]
	%GoalDirection.set_active(markers)
	var base := target.position + Vector3.UP * 0.89
	_trail_marker.position = base
	_trail_fill.albedo_color = Color("#99f3d9") if _collected_ball else Color("#ffde8e")
	_trail_marker.show()
	if _trail_motion != null:
		_trail_motion.kill()
	_trail_motion = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_trail_motion.tween_property(_trail_marker, "position", base + Vector3.UP * 0.16, 0.58)
	_trail_motion.tween_property(_trail_marker, "position", base, 0.58)


# ── Signal handlers ──────────────────────────────────────────────

## The single place in the runtime tree that plays the pickup effect
## (INTRO-03) — %Collectible only emits, it never plays a sound itself, so
## the archived two-listener defect (CONCERNS.md) cannot recur here.
func _on_collectible_collected() -> void:
	AudioManager.play_sfx("collect")
	if %WinLayer.visible:
		return
	_collected_ball = true
	_set_control_hints(false, false)
	_show_goal()
	VoiceManager.play("collected")
	VoiceManager.enqueue("intro_finish")


## Reached whether or not %Collectible was ever picked up (D-21: the finish
## is not gated on the collectible). Fades the win overlay in and freezes
## Camiel's own physics processing rather than pausing the scene tree, so
## the world visually holds still without needing PROCESS_MODE_ALWAYS
## overrides anywhere but the CanvasLayer itself.
func _on_finish_marker_finished() -> void:
	_trail_marker.hide()
	_trail_motion.kill()
	var no_markers: Array[Dictionary] = []
	%GoalDirection.set_active(no_markers)
	_set_control_hints(false, false)
	%PauseButton.hide()
	%ExploreHud.hide()
	_camiel.set_physics_process(false)
	await ProgressTracker.record_intro_complete()
	if _transitioning:
		return
	%WinLayer.visible = true
	_configure_continue_button()
	%Scrim.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(%Scrim, "modulate:a", 1.0, 0.3)
	%ContinueButton.grab_focus()
	AudioManager.play_sfx("finish")
	VoiceManager.play("intro_complete")


func _configure_continue_button() -> void:
	var next := LESSON_CATALOG.next_unfinished_index(ProgressTracker.completed_lesson_ids())
	var button: Button = %ContinueButton
	if next >= 0:
		button.label_text = "Naar les %d" % (next + 1)
		_continue_path = LESSON_CATALOG.LESSONS[next]["path"]
	else:
		button.label_text = "Naar de lessen"
		_continue_path = LESSON_CATALOG.SELECT_PATH
	button.accessibility_name = button.label_text


func _on_continue_button_pressed() -> void:
	if %WinLayer.visible:
		_open_scene(_continue_path)


## Same one-shot guard and deferred scene change title_screen.gd and
## main_menu.gd use (D-15).
func _on_go_to_menu_button_pressed() -> void:
	_open_scene(MAIN_MENU_PATH)


func _open_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(path)
	get_tree().change_scene_to_file.call_deferred(path)


## Resets the level in place (D-28): no scene change, no scene reload — the
## same level instance keeps running. Repeatable by design, so this handler
## carries no one-shot guard; that guard belongs only on handlers that
## change scene.
func _on_replay_button_pressed() -> void:
	VoiceManager.play(_opening_cue())
	replay_requested.emit()
	%WinLayer.visible = false
	%ExploreHud.show()
	%PauseButton.show()
	_camiel.set_physics_process(true)
	_camiel.global_rotation = _player_spawn.global_rotation
	_camiel.teleport_to(_player_spawn.global_position)
	%Collectible.reset()
	%FinishMarker.reset()
	_collected_ball = false
	_set_control_hints(true, true)
	_show_goal()


func _repeat_instructions() -> void:
	if %WinLayer.visible:
		return
	if _collected_ball:
		VoiceManager.play("intro_finish")
	elif _walk_hint:
		VoiceManager.play(_opening_cue())
	else:
		VoiceManager.play("intro_ball")


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_go_to_menu_button_pressed()
	elif event.is_action_pressed("listen_again"):
		get_viewport().set_input_as_handled()
		_repeat_instructions()
