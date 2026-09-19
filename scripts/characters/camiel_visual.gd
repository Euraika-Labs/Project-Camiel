# Visual-only adapter: movement, InputMap, collisions and camera stay controller-owned.
extends Node3D

@onready var _body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var _player: AnimationPlayer = $CamielModel/AnimationPlayer

var animation_state: StringName = &"idle"


func _ready() -> void:
	for clip: StringName in [&"idle", &"walk", &"jump"]:
		assert(_player.has_animation(clip), "Camiel model is missing animation: " + clip)
		_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if clip != &"jump" else Animation.LOOP_NONE
	_player.play(&"idle")


func _physics_process(_delta: float) -> void:
	# Real displacement prevents walking in place against a wall; no raw input polling.
	var movement := _body.get_real_velocity()
	var speed := Vector2(movement.x, movement.z).length()
	var next: StringName = &"idle"
	if _body.is_physics_processing():
		if not _body.is_on_floor():
			next = &"jump"
		elif speed > 0.08:
			next = &"walk"
	if next != animation_state:
		animation_state = next
		_player.play(next, 0.12)
	_player.speed_scale = clampf(speed / maxf(_body.walk_speed, 0.01), 0.25, 1.5) if next == &"walk" else 1.0
