# camiel_controller.gd
# Camiel's 3D movement controller: InputMap-driven walking and jumping
# (D-07), camera-relative and turn-and-walk steering models (D-11 playtest
# switch), a lazily-following camera rig with no mouse-look (D-05), and a
# soft fall-and-return to the last safe spot (D-06).
extends CharacterBody3D

signal returned_to_safe_spot(position: Vector3)

enum SteeringMode { CAMERA_RELATIVE, TURN_AND_WALK }

# Camera-relative is the shipped steering mode: the stick direction is the
# direction Camiel goes, which is what a five-year-old expects from a pad.
# Turn-and-walk stays available behind --steering=turn_and_walk because it is
# easier for a child who steers with two hands on a keyboard, but it is not the
# default. probe_camiel_movement.gd's steering_default case pins this value, so
# it cannot drift back silently -- it already did once.
@export var steering_mode: SteeringMode = SteeringMode.CAMERA_RELATIVE
@export var walk_speed := 2.5
@export var acceleration := 12.0
@export var deceleration := 16.0
@export var jump_velocity := 4.5
@export var turn_to_face_speed := 10.0
@export var turn_speed := 2.2
@export var camera_follow_speed := 2.0
@export var max_fall_speed := 30.0
@export var safe_spot_margin := 0.75
@export var safe_spot_sample_interval := 0.2

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _return_sound: AudioStreamPlayer = $ReturnSound

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _spawn_position: Vector3
var _last_safe_position: Vector3
var _safe_spot_timer := 0.0
var _is_returning := false
var _touch_controls: Control


func _ready() -> void:
	add_to_group("player")
	_spring_arm.add_excluded_object(get_rid())
	_spawn_position = global_position
	_last_safe_position = global_position
	apply_steering_arguments(OS.get_cmdline_user_args())
	_return_sound.stream = _build_return_tone()
	_snap_camera_behind()
	var touch_layer := CanvasLayer.new()
	touch_layer.name = "TouchLayer"
	touch_layer.layer = 5
	add_child(touch_layer)
	_touch_controls = preload("res://scripts/ui/touch_controller.gd").new()
	_touch_controls.name = "TouchControls"
	touch_layer.add_child(_touch_controls)


func _process(_delta: float) -> void:
	# Win panels disable player physics without pausing the scene tree.
	_touch_controls.visible = _touch_controls.available and is_physics_processing()


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_dir = (input_dir + _touch_controls.movement).limit_length(1.0)
	# Consume every tick, including in the air, so a tap never queues a stale jump.
	var touch_jump: bool = _touch_controls.consume_jump()

	if steering_mode == SteeringMode.TURN_AND_WALK:
		_process_turn_and_walk(input_dir, delta)
	else:
		_process_camera_relative(input_dir, delta)

	if not is_on_floor():
		velocity.y = max(velocity.y - _gravity * delta, -max_fall_speed)
	elif Input.is_action_just_pressed("jump") or touch_jump:
		velocity.y = jump_velocity

	move_and_slide()
	_sample_safe_spot(delta)

	if steering_mode == SteeringMode.TURN_AND_WALK:
		_camera_pivot.global_position = global_position + Vector3(0, 1.0, 0)
		_camera_pivot.rotation.y = rotation.y
	else:
		_update_camera(delta)


func _process_camera_relative(input_dir: Vector2, delta: float) -> void:
	var forward: Vector3 = -_camera_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = _camera_pivot.global_basis.x
	right.y = 0.0
	right = right.normalized()
	var direction: Vector3 = right * input_dir.x - forward * input_dir.y

	_apply_horizontal_velocity(direction * walk_speed, direction.length() > 0.01, delta)

	# Only turn to face the travel direction on a genuine forward/back push.
	# Turning to face pure lateral (strafe-only) input would make the camera
	# (which lazily follows Camiel's own facing) chase a target derived from
	# its own orientation every frame — a closed loop with no fixed point,
	# which spins Camiel in an endless circle instead of a straight sideways
	# step. Bad for a 3-year-old holding one arrow key, and it stops Camiel
	# from ever reaching an edge by strafing toward it (D-06).
	if absf(input_dir.y) > 0.01 and direction.length() > 0.01:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_to_face_speed * delta)


func _process_turn_and_walk(input_dir: Vector2, delta: float) -> void:
	rotation.y -= input_dir.x * turn_speed * delta

	var forward: Vector3 = -global_basis.z
	var target_velocity := forward * (-input_dir.y) * walk_speed
	_apply_horizontal_velocity(target_velocity, absf(input_dir.y) > 0.01, delta)


func _apply_horizontal_velocity(target_velocity: Vector3, has_input: bool, delta: float) -> void:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if has_input:
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, deceleration * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


func _update_camera(delta: float) -> void:
	_camera_pivot.global_position = global_position + Vector3(0, 1.0, 0)
	_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, rotation.y, clampf(camera_follow_speed * delta, 0.0, 1.0))


func _sample_safe_spot(_delta: float) -> void:
	_safe_spot_timer += _delta
	if _safe_spot_timer < safe_spot_sample_interval or not is_on_floor():
		return
	_safe_spot_timer = 0.0

	var offsets := [
		Vector3(safe_spot_margin, 0.5, safe_spot_margin),
		Vector3(safe_spot_margin, 0.5, -safe_spot_margin),
		Vector3(-safe_spot_margin, 0.5, safe_spot_margin),
		Vector3(-safe_spot_margin, 0.5, -safe_spot_margin),
	]
	var space_state := get_world_3d().direct_space_state
	for offset: Vector3 in offsets:
		var from := global_position + offset
		var to := from + Vector3(0, -1.5, 0)
		var params := PhysicsRayQueryParameters3D.create(from, to)
		params.exclude = [get_rid()]
		var result := space_state.intersect_ray(params)
		if result.is_empty():
			return

	_last_safe_position = global_position


func _on_fall_boundary_body_entered(body: Node3D) -> void:
	if body != self or _is_returning:
		return
	_is_returning = true
	return_to_safe_spot.call_deferred()


func return_to_safe_spot() -> void:
	teleport_to(_last_safe_position)
	_return_sound.play()
	returned_to_safe_spot.emit(global_position)
	_is_returning = false


func apply_steering_arguments(args: PackedStringArray) -> void:
	for arg: String in args:
		if arg == "--steering=turn_and_walk":
			steering_mode = SteeringMode.TURN_AND_WALK
		elif arg == "--steering=camera_relative":
			steering_mode = SteeringMode.CAMERA_RELATIVE
		elif arg.begins_with("--steering="):
			push_warning("[CamielController] Unknown steering mode: ", arg)


func teleport_to(target: Vector3) -> void:
	global_position = target
	velocity = Vector3.ZERO
	_snap_camera_behind()


func _snap_camera_behind() -> void:
	_camera_pivot.global_position = global_position + Vector3(0, 1.0, 0)
	_camera_pivot.rotation.y = rotation.y


func _build_return_tone() -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const DURATION := 0.35
	const ATTACK_TIME := 0.015
	const START_FREQ := 660.0
	const END_FREQ := 440.0
	const AMPLITUDE := 0.25

	var sample_count := int(SAMPLE_RATE * DURATION)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var phase := 0.0
	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var progress := float(i) / float(sample_count - 1)
		var freq := lerpf(START_FREQ, END_FREQ, progress)
		phase += freq / SAMPLE_RATE
		var envelope: float
		if t < ATTACK_TIME:
			envelope = t / ATTACK_TIME
		else:
			var decay_progress := (t - ATTACK_TIME) / (DURATION - ATTACK_TIME)
			envelope = exp(-4.0 * decay_progress)
		var sample_value := sin(phase * TAU) * AMPLITUDE * envelope
		var sample_int := int(clampf(sample_value, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
