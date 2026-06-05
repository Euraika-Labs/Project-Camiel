# title_screen.gd
# Branded title screen — shows Camiel idle animation, game title,
# a Play button, and the current version label.
extends Node2D

@onready var play_button: Button = $UI/PlayButton
@onready var camiel_sprite: AnimatedSprite2D = $Camiel/AnimatedSprite2D

const VERSION := "alpha-v0.0.3"


func _ready() -> void:
	play_button.grab_focus()
	_play_idle()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_play_pressed()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _play_idle() -> void:
	if camiel_sprite.sprite_frames and camiel_sprite.sprite_frames.has_animation("idle_right"):
		camiel_sprite.play("idle_right")
	elif camiel_sprite.sprite_frames and camiel_sprite.sprite_frames.has_animation("idle"):
		camiel_sprite.play("idle")
