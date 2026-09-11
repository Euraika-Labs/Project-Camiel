# camiel_controller.gd
# Camiel's 3D movement controller: InputMap-driven walking and jumping
# (D-07), with a camera-relative steering model and a lazily-following
# camera rig behind him (D-05).
extends CharacterBody3D

@export var walk_speed := 2.5
@export var acceleration := 12.0
@export var deceleration := 16.0
@export var jump_velocity := 4.5
@export var turn_to_face_speed := 10.0
@export var camera_follow_speed := 2.0
@export var max_fall_speed := 30.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("player")
	_spring_arm.add_excluded_object(get_rid())
	_snap_camera_behind()


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var forward: Vector3 = -_camera_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = _camera_pivot.global_basis.x
	right.y = 0.0
	right = right.normalized()
	var direction: Vector3 = right * input_dir.x - forward * input_dir.y

	var target_velocity := direction * walk_speed
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if direction.length() > 0.01:
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, deceleration * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if direction.length() > 0.01:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_to_face_speed * delta)

	if not is_on_floor():
		velocity.y = max(velocity.y - _gravity * delta, -max_fall_speed)
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	_camera_pivot.global_position = global_position + Vector3(0, 1.0, 0)
	_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, rotation.y, clampf(camera_follow_speed * delta, 0.0, 1.0))


func teleport_to(target: Vector3) -> void:
	global_position = target
	velocity = Vector3.ZERO
	_snap_camera_behind()


func _snap_camera_behind() -> void:
	_camera_pivot.global_position = global_position + Vector3(0, 1.0, 0)
	_camera_pivot.rotation.y = rotation.y
