extends Control
## Shared per-player touch state. Never synthesizes InputMap actions: releasing
## a finger cannot cancel a held keyboard key, nor survive a scene change.

const STICK_RADIUS := 84.0
const JUMP_RADIUS := 64.0
const DEADZONE := 0.12
const HINT_CYCLE := 2.8
const JUMP_HINT_START := 1.48

var movement := Vector2.ZERO
var available := false
var stick_finger := -1
var jump_finger := -1
var _jump_pending := false
var _stick_offset := Vector2.ZERO
var _extra_fingers: Dictionary = {}
var _hint_time := 0.0
var _show_movement_hint := false
var _show_jump_hint := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	available = DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch-controls")
	visible = available
	resized.connect(reset)
	visibility_changed.connect(_on_visibility_changed)
	set_process(false)


func stick_center() -> Vector2:
	# Leave the bottom 144 px free for the shared lesson return button.
	return Vector2(112.0, size.y - 240.0)


func jump_center() -> Vector2:
	return Vector2(size.x - 96.0, size.y - 112.0)


func set_hints(walk: bool, jump: bool) -> void:
	_show_movement_hint = walk
	_show_jump_hint = jump
	_hint_time = JUMP_HINT_START if jump and not walk else 0.0
	set_process(walk or jump)
	queue_redraw()


func _process(delta: float) -> void:
	_hint_time = fposmod(_hint_time + delta, HINT_CYCLE)
	if is_visible_in_tree() and ((_show_movement_hint and stick_finger == -1) or (_show_jump_hint and jump_finger == -1)):
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if _extra_fingers.erase(event.index):
				get_viewport().set_input_as_handled()
			if event.index == stick_finger:
				stick_finger = -1
				movement = Vector2.ZERO
				_stick_offset = Vector2.ZERO
				get_viewport().set_input_as_handled()
			if event.index == jump_finger:
				jump_finger = -1
				get_viewport().set_input_as_handled()
				if event.canceled:
					_jump_pending = false
		elif stick_finger == -1 and event.position.distance_to(stick_center()) <= STICK_RADIUS:
			stick_finger = event.index
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
		elif jump_finger == -1 and event.position.distance_to(jump_center()) <= JUMP_RADIUS:
			jump_finger = event.index
			_jump_pending = true
			get_viewport().set_input_as_handled()
		elif event.position.distance_to(stick_center()) <= STICK_RADIUS or event.position.distance_to(jump_center()) <= JUMP_RADIUS:
			_extra_fingers[event.index] = true
			get_viewport().set_input_as_handled()
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == stick_finger:
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
		elif event.index == jump_finger or _extra_fingers.has(event.index):
			get_viewport().set_input_as_handled()


func _update_stick(position: Vector2) -> void:
	_stick_offset = (position - stick_center()).limit_length(STICK_RADIUS)
	var raw := _stick_offset / STICK_RADIUS
	var strength := maxf(0.0, (raw.length() - DEADZONE) / (1.0 - DEADZONE))
	movement = raw.normalized() * strength
	queue_redraw()


func consume_jump() -> bool:
	var pressed := _jump_pending
	_jump_pending = false
	return pressed


func reset() -> void:
	movement = Vector2.ZERO
	stick_finger = -1
	jump_finger = -1
	_jump_pending = false
	_stick_offset = Vector2.ZERO
	_extra_fingers.clear()
	queue_redraw()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		reset()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT,
			NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_PAUSED]:
		reset()


func _draw() -> void:
	var ink := Color("203c33")
	var border := Color("ffffff")
	var stick := stick_center()
	draw_circle(stick, STICK_RADIUS, ink)
	draw_arc(stick, STICK_RADIUS, 0, TAU, 64, border, 3.0, true)
	draw_circle(stick + _stick_offset * 0.62, 30.0, Color("f6cc7c"))
	if _show_movement_hint and stick_finger == -1:
		_draw_movement_hint(stick)
	draw_circle(jump_center(), JUMP_RADIUS, Color("347a53") if jump_finger == -1 else ink)
	draw_arc(jump_center(), JUMP_RADIUS, 0, TAU, 64, border, 3.0, true)
	var center := jump_center()
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -23), center + Vector2(22, -1), center + Vector2(15, 6),
		center + Vector2(5, -4), center + Vector2(5, 20), center + Vector2(-5, 20),
		center + Vector2(-5, -4), center + Vector2(-15, 6), center + Vector2(-22, -1),
	]), border)
	if _show_jump_hint and jump_finger == -1:
		_draw_jump_hint(center)


func _draw_movement_hint(stick: Vector2) -> void:
	# This preview draws a drag on the pad and leaves its actual input at rest.
	var direction := Vector2(-1, -2).normalized()
	var tip := stick + direction * 68.0
	var wing := direction.orthogonal() * 9.0
	var base := tip - direction * 14.0
	draw_polyline(PackedVector2Array([base + wing, tip, base - wing]), Color("f6cc7c"), 4.0, true)
	var distance := smoothstep(0.16, 0.96, _hint_time) * 47.0
	var opacity := 1.0 - smoothstep(1.0, 1.55, _hint_time)
	var ring := stick + direction * distance
	draw_arc(ring, 19.0, 0.0, TAU, 32, Color(0.10, 0.19, 0.16, opacity * 0.55), 7.0, true)
	draw_arc(ring, 19.0, 0.0, TAU, 32, Color(1.0, 0.98, 0.91, opacity), 3.5, true)


func _draw_jump_hint(center: Vector2) -> void:
	var press := smoothstep(JUMP_HINT_START, 1.91, _hint_time)
	var opacity := press * (1.0 - smoothstep(2.12, 2.52, _hint_time))
	if opacity > 0.0:
		var radius := lerpf(48.0, 36.0, press)
		draw_arc(center, radius, 0.0, TAU, 40, Color(1.0, 0.88, 0.62, opacity), 5.0, true)
