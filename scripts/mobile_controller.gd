# mobile_controller.gd
# Virtual joystick and action button overlay for touch/mobile devices.
# Shows on touch devices, hidden on keyboard/mouse devices.
extends CanvasLayer

signal move_vector(v: Vector2)  # x: -1/0/1, y: 0 (no vertical movement for side-scroller)
signal jump()

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var jump_button: Button = $JumpButton

var _touch_id: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _deadzone := 0.2

func _ready():
	add_to_group("mobile_controller")
	# Only show on touch devices
	var is_mobile = DisplayServer.is_touchscreen_available()
	visible = is_mobile
	if not is_mobile:
		return
	# Initialise joystick position (bottom-left for movement, bottom-right for jump)
	var vp := get_viewport().get_visible_rect()
	joystick_base.position = Vector2(80, vp.size.y - 200)
	jump_button.position = Vector2(vp.size.x - 200, vp.size.y - 200)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			var pos = event.position
			if joystick_base.get_global_rect().has_point(pos):
				_joystick_center = joystick_base.global_position + joystick_base.size * 0.5
				_update_joystick(pos)
			elif jump_button.get_global_rect().has_point(pos):
				Input.action_press("jump")
				jump.emit()
				Input.action_release("jump")
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			joystick_knob.position = joystick_base.size * 0.5
			move_vector.emit(Vector2.ZERO)
			Input.action_release("ui_left")
			Input.action_release("ui_right")
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_joystick(event.position)

func _update_joystick(pos: Vector2) -> void:
	var delta = pos - _joystick_center
	var dist = delta.length()
	var max_dist = joystick_base.size.x * 0.5
	var clamped = delta.normalized() * min(dist, max_dist)
	joystick_knob.position = joystick_base.size * 0.5 + clamped
	if dist < _deadzone * max_dist:
		move_vector.emit(Vector2.ZERO)
		Input.action_release("ui_left")
		Input.action_release("ui_right")
	else:
		var vector := Vector2(delta.x / max_dist, 0.0).normalized()
		move_vector.emit(vector)
		if vector.x < 0.0:
			Input.action_press("ui_left")
			Input.action_release("ui_right")
		else:
			Input.action_press("ui_right")
			Input.action_release("ui_left")
