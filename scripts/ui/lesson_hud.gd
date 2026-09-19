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

@onready var _title_label: Label = %TitleLabel
@onready var _step_label: Label = %StepLabel
@onready var _back_button: Button = %BackButton
@onready var _win_root: Control = %WinRoot
@onready var _scrim: Control = %Scrim
@onready var _win_back_button: Button = %WinBackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_button_pressed)
	_win_back_button.pressed.connect(_on_win_back_button_pressed)
	# Load-bearing, not a style choice: %BackButton's own script
	# (menu_button.gd) assigns Control.FOCUS_ALL inside its own _ready(), so
	# a scene-file override here would be silently undone. A child node's
	# ready callback runs before its parent's, so this display's ready
	# callback is the one place that reliably wins. `jump` and the engine's
	# `ui_accept` are both bound to the space key in this project's input
	# map, so a focusable in-play control would fire on every jump attempt.
	_back_button.focus_mode = Control.FOCUS_NONE


## Sets the title shown across the top of every lesson.
func set_title(text: String) -> void:
	_title_label.text = text


## Sets the progress label to "Stap: <current> / <total>". This is the only
## place in the repository this format string exists (D-46) -- lessons 1-4
## pass a total of 3, lesson 5 passes 4, from the same call shape with no
## branch on the total.
func set_step(current: int, total: int) -> void:
	_step_label.text = "Stap: %d / %d" % [current, total]


## Makes the win panel visible, fades its scrim in rather than cutting, and
## moves keyboard focus onto its return control.
func show_win() -> void:
	_win_root.visible = true
	_scrim.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_scrim, "modulate:a", 1.0, 0.3)
	_win_back_button.grab_focus()


## Whether the win panel is currently showing. Public so an orchestrator or
## a probe never reads a private node path across scripts.
func is_win_visible() -> bool:
	return _win_root.visible


func _on_back_button_pressed() -> void:
	back_requested.emit()


func _on_win_back_button_pressed() -> void:
	win_back_requested.emit()
