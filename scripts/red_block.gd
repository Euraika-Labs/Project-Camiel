# red_block.gd
# Educational micro-task: touch the red block.
# On Camiel's first touch the block turns green and plays a chime.
extends Area2D

signal task_completed(task_name: String)

@export var original_color := Color(0.9, 0.11, 0.13)
@export var success_color  := Color(0.15, 0.85, 0.15)

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label

var _touched := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	_touched = true
	_apply_success()


func _apply_success() -> void:
	color_rect.color = success_color
	label.text = "Goed zo!"
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("finish")
	task_completed.emit("red_block")
	print("Red block touched! Task complete.")
