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

# ── Node references ──────────────────────────────────────────────

@onready var _camiel: CharacterBody3D = $Camiel

# ── Private state ────────────────────────────────────────────────

var _transitioning := false


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	%FinishMarker.finished.connect(_on_finish_marker_finished)
	%ReplayButton.pressed.connect(_on_replay_button_pressed)
	%GoToMenuButton.pressed.connect(_on_go_to_menu_button_pressed)


# ── Signal handlers ──────────────────────────────────────────────

## Reached whether or not %Collectible was ever picked up (D-21: the finish
## is not gated on the collectible). Fades the win overlay in and freezes
## Camiel's own physics processing rather than pausing the scene tree, so
## the world visually holds still without needing PROCESS_MODE_ALWAYS
## overrides anywhere but the CanvasLayer itself.
func _on_finish_marker_finished() -> void:
	%WinLayer.visible = true
	%Scrim.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(%Scrim, "modulate:a", 1.0, 0.3)
	%ReplayButton.grab_focus()
	_camiel.set_physics_process(false)


## Same one-shot guard and deferred scene change title_screen.gd and
## main_menu.gd use (D-15).
func _on_go_to_menu_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(MAIN_MENU_PATH)
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)


## Completed in plan 02-04 Task 3 (in-place replay reset). Declared and wired
## now so the connection is real from this commit rather than dangling.
func _on_replay_button_pressed() -> void:
	replay_requested.emit()
