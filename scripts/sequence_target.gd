# sequence_target.gd
# Educational micro-task: touch the correct object in sequence.
# Only activates when the previous target in the sequence was touched.
extends Area2D

signal task_completed(task_name: String)

@export var order_number: int = 1  # 1 = first, 2 = second, 3 = third
@export var success_color := Color(0.15, 0.85, 0.15)
@export var error_color := Color(0.9, 0.11, 0.13)
@export var inactive_color := Color(0.5, 0.5, 0.5, 0.5)

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label
@onready var order_indicator: Label = $OrderIndicator

var _touched := false
var _active := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_set_inactive()


func activate() -> void:
	_active = true
	color_rect.color = Color(0.8, 0.6, 0.1)  # warm amber when active
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	print("Sequence target %d is now ACTIVE." % order_number)


func _set_inactive() -> void:
	_active = false
	color_rect.color = inactive_color


func _on_body_entered(body: Node2D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	if not _active:
		_flash_error()
		return
	_touched = true
	_apply_success()


func _flash_error() -> void:
	# Gentle error feedback: flash red briefly, then return to inactive
	var original_color = color_rect.color
	color_rect.color = error_color
	label.text = "Nog eens proberen!"
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	await get_tree().create_timer(0.8).timeout
	color_rect.color = inactive_color
	label.text = str(order_number)
	label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1))


func _apply_success() -> void:
	color_rect.color = success_color
	label.text = "Goed zo!"
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	order_indicator.visible = false
	AudioManager.play_sfx("finish")
	task_completed.emit("sequence_%d" % order_number)
	print("Sequence target %d touched! Task complete." % order_number)