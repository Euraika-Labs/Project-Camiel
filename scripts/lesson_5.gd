# lesson_5.gd
# Review lesson: touch red, yellow, then blue in order.
extends Node2D

signal lesson_finished

@onready var red_target: Area2D = $RedTarget
@onready var yellow_target: Area2D = $YellowTarget
@onready var blue_target: Area2D = $BlueTarget
@onready var progress_label: Label = $ProgressLabel

const ORDER := ["red", "yellow", "blue"]
const DUTCH_NAMES := {
	"red": "rood",
	"yellow": "geel",
	"blue": "blauw"
}

var _current_index := 0
var _started_at := 0
var _targets := {}


func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	_targets = {
		"red": red_target,
		"yellow": yellow_target,
		"blue": blue_target
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
		_set_target(target_name, Color(0.9, 0.11, 0.13), "Nog eens")
		return

	_set_target(target_name, Color(0.15, 0.85, 0.15), "Goed zo!")
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("collect")
	_current_index += 1
	if _current_index >= ORDER.size():
		_complete_lesson()
	else:
		_update_progress_label()


func _set_target(target_name: String, color: Color, text: String) -> void:
	var area := _targets[target_name] as Area2D
	var rect := area.get_node("ColorRect") as ColorRect
	var label := area.get_node("Label") as Label
	rect.color = color
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))


func _update_progress_label() -> void:
	progress_label.text = "Raak %s  |  Stap: %d / 3" % [
		DUTCH_NAMES[ORDER[_current_index]],
			_current_index + 1
	]


func _complete_lesson() -> void:
	progress_label.text = "Goed zo! De rij is klaar!"
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("finish")
	var progress_tracker := get_node_or_null("/root/ProgressTracker")
	if progress_tracker:
		progress_tracker.record_lesson_complete("lesson_5", 3, _elapsed_seconds())
	await get_tree().create_timer(2.0).timeout
	lesson_finished.emit()
	get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lesson_select.tscn")


func _elapsed_seconds() -> int:
	return int((Time.get_ticks_msec() - _started_at) / 1000)
