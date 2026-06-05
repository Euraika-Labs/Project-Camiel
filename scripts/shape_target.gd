# shape_target.gd
# Educational micro-task: touch the correct shape in order.
# Shapes: circle, square, triangle. Turns green on successful touch.
extends Area2D

signal task_completed(task_name: String)

enum ShapeType { CIRCLE, SQUARE, TRIANGLE }

@export var shape_type: ShapeType = ShapeType.CIRCLE
@export var success_color := Color(0.15, 0.85, 0.15)
@export var normal_bg_color := Color(0.85, 0.85, 0.85)

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label

var _touched := false
var _shape_names := ["circle", "square", "triangle"]


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_shape_appearance()


func _apply_shape_appearance() -> void:
	match shape_type:
		ShapeType.CIRCLE:
			# Circle is shown as an oval ColorRect
			color_rect.color = normal_bg_color
			label.text = "Rond"
		ShapeType.SQUARE:
			color_rect.color = normal_bg_color
			label.text = "Vierkant"
		ShapeType.TRIANGLE:
			color_rect.color = normal_bg_color
			label.text = "Driehoek"


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
	AudioManager.play_sfx("finish")
	task_completed.emit(_shape_names[shape_type])
	print("Shape '%s' touched! Task complete." % _shape_names[shape_type])