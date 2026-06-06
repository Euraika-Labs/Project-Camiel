# blue_target.gd
# Educational micro-task: find and touch the blue target.
# The blue target is slightly camouflaged against the background.
extends Area2D

signal task_completed(task_name: String)

@export var found_color := Color(0.08, 0.35, 0.95)
@export var camo_factor := 0.82  # blend factor against background

@onready var sprite: ColorRect = $ColorRect
@onready var label: Label = $Label

var _found := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _found:
		return
	if not body.is_in_group("player"):
		return
	_found = true
	_apply_found()


func _apply_found() -> void:
	# Brighten the blue to make success obvious.
	sprite.color = found_color.lightened(0.4)
	label.text = "Gevonden!"
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("collect")
	task_completed.emit("blue_target")
	print("Blue target found! Task complete.")
