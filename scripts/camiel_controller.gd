extends CharacterBody2D

@export var walk_speed := 260.0
@export var run_speed := 410.0
@export var jump_velocity := -560.0
@export var gravity := 1500.0
@export var acceleration := 1800.0
@export var friction := 2200.0
@export var min_x := 70.0
@export var max_x := 1210.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing := "right"

func _ready() -> void:
	add_to_group("player")
	_play("idle")

func _physics_process(delta: float) -> void:
	var direction := _read_direction()
	if direction != 0:
		_facing = "right" if direction > 0 else "left"

	var speed := run_speed if _run_pressed() else walk_speed
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not is_on_floor():
		velocity.y += gravity * delta
	elif _jump_pressed():
		velocity.y = jump_velocity
		_play("jump", true)

	move_and_slide()
	position.x = clampf(position.x, min_x, max_x)
	_update_animation(direction)

func _read_direction() -> int:
	var direction := 0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1
	return direction

func _run_pressed() -> bool:
	return Input.is_key_pressed(KEY_SHIFT)

func _jump_pressed() -> bool:
	return Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)

func _sit_pressed() -> bool:
	return Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)

func _sleep_pressed() -> bool:
	return Input.is_key_pressed(KEY_X)

func _update_animation(direction: int) -> void:
	if not is_on_floor():
		_play("jump")
		return

	if direction == 0 and _sleep_pressed():
		_play("sleep")
		return

	if direction == 0 and _sit_pressed():
		_play("sit")
		return

	if absf(velocity.x) > 15.0:
		_play("run" if _run_pressed() else "walk")
		return

	_play("idle")

func _play(base_name: String, restart := false) -> void:
	var animation_name := "%s_%s" % [base_name, _facing]
	if sprite.animation == animation_name and not restart:
		return

	sprite.play(animation_name)
