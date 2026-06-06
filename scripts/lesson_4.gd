# lesson_4.gd
# Size comparison: touch large, small, then middle.
extends Node2D

signal lesson_finished

@onready var big_target: Area2D = $BigTarget
@onready var small_target: Area2D = $SmallTarget
@onready var middle_target: Area2D = $MiddleTarget
@onready var progress_label: Label = $ProgressLabel

const ORDER := ["big", "small", "middle"]
const PROMPTS := {
	"big": "Raak GROOT",
	"small": "Raak KLEIN",
	"middle": "Raak MIDDEN"
}

var _current_index := 0
var _started_at := 0
var _targets := {}


func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	_targets = {
		"big": big_target,
		"small": small_target,
		"middle": middle_target
	}
	for target_name in _targets.keys():
		var area := _targets[target_name] as Area2D
		area.body_entered.connect(_on_target_body_entered.bind(target_name))
	_update_progress_label()


func _on_target_body_entered(body: Node2D, target_name: String) -> void:
	if not body.is_in_group("player"):
		return
	var expected: String = ORDER[_current_index]
	if target_name != expected:
		_flash_target(target_name, Color(0.9, 0.11, 0.13), "Nog eens")
		return

	_mark_success(target_name)
	_current_index += 1
	if _current_index >= ORDER.size():
		_complete_lesson()
	else:
		_update_progress_label()


func _mark_success(target_name: String) -> void:
	_flash_target(target_name, Color(0.15, 0.85, 0.15), "Goed zo!")
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("collect")


func _flash_target(target_name: String, color: Color, text: String) -> void:
	var area := _targets[target_name] as Area2D
	var rect := area.get_node("ColorRect") as ColorRect
	var label := area.get_node("Label") as Label
	rect.color = color
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))


func _update_progress_label() -> void:
	progress_label.text = "%s  |  Stap: %d / 3" % [
		PROMPTS[ORDER[_current_index]],
			_current_index + 1
	]


func _complete_lesson() -> void:
	progress_label.text = "Goed zo! Groot en klein klaar!"
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("finish")
	var progress_tracker := get_node_or_null("/root/ProgressTracker")
	if progress_tracker:
		progress_tracker.record_lesson_complete("lesson_4", 3, _elapsed_seconds())
	await get_tree().create_timer(2.0).timeout
	lesson_finished.emit()
	get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _elapsed_seconds() -> int:
	return int((Time.get_ticks_msec() - _started_at) / 1000)
