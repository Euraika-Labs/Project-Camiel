extends Control
## Shows one reachable goal at the edge when the play area contains none.

const LESSON_CUES := preload("res://scripts/ui/lesson_cues.gd")
const TOUCH_CONTROLS := preload("res://scripts/ui/touch_controller.gd")
const INK := Color("#234638")
const PAPER := Color("#fff0bc")
const INSET := 72.0
const BADGE_RADIUS := 30.0
const ARROW := [
	Vector2(62, 0), Vector2(41, 16), Vector2(41, 7), Vector2(20, 7),
	Vector2(20, -7), Vector2(41, -7), Vector2(41, -16),
]

var _active: Array[Dictionary] = []
var _player: Node3D
var _header: Control
var _back: Control
var _touch: TOUCH_CONTROLS
var _indicated: Dictionary = {}
var _position := Vector2.ZERO
var _direction := Vector2.ZERO


func configure(player: Node3D, header: Control, back: Control) -> void:
	_player = player
	_header = header
	_back = back
	if is_instance_valid(player):
		_touch = player.get_node_or_null("TouchLayer/TouchControls") as TOUCH_CONTROLS


func set_active(markers: Array[Dictionary]) -> void:
	_active = markers
	_refresh()


func indicated_target_id() -> String:
	return _indicated.get("id", "") if is_visible_in_tree() else ""


func pointing_direction() -> Vector2:
	return _direction if not indicated_target_id().is_empty() else Vector2.ZERO


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if not is_visible_in_tree() or not is_instance_valid(_player) or _active.is_empty():
		_clear()
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null or size.x < INSET * 2.0:
		_clear()
		return
	var header := _header.get_global_rect()
	var nearest: Dictionary = {}
	var nearest_distance := INF
	for marker: Dictionary in _active:
		var goal: Node3D = marker["target"]
		if not is_instance_valid(goal):
			continue
		var center := goal.global_position + Vector3.UP * float(marker.get("offset_y", 0.14))
		if _in_view(camera, center, header):
			_clear()
			return
		var distance := goal.global_position.distance_squared_to(_player.global_position)
		if distance < nearest_distance:
			nearest = marker
			nearest_distance = distance
	if nearest.is_empty():
		_clear()
		return

	# Navigation points in the same horizontal basis as the joystick.
	# This also gives a meaningful down arrow for goals behind the camera.
	var target: Node3D = nearest["target"]
	var offset := target.global_position - _player.global_position
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	var direction := Vector2(offset.dot(right.normalized()), -offset.dot(forward.normalized())).normalized()
	var top := header.end.y + INSET
	if direction.is_zero_approx() or size.y - top < INSET * 1.5:
		_clear()
		return
	var area := Rect2(INSET, top, size.x - INSET * 2.0, size.y - top - INSET)
	var half := area.size * 0.5
	var distance_to_edge := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	var position := area.get_center() + direction * distance_to_edge
	if _back.visible and _back.get_global_rect().grow(INSET).has_point(position):
		position.y = _back.get_global_rect().position.y - INSET
	if is_instance_valid(_touch) and _touch.is_visible_in_tree():
		position.y = _above_pad(position, _touch.stick_center(), TOUCH_CONTROLS.STICK_RADIUS)
		position.y = _above_pad(position, _touch.jump_center(), TOUCH_CONTROLS.JUMP_RADIUS)
	position.y = maxf(area.position.y, position.y)

	if _indicated.get("target") != target or position.distance_squared_to(_position) > 0.5 or direction.distance_squared_to(_direction) > 0.0004:
		_indicated = nearest
		_position = position
		_direction = direction
		queue_redraw()


func _in_view(camera: Camera3D, center: Vector3, header: Rect2) -> bool:
	if camera.is_position_behind(center):
		return false
	var point := camera.unproject_position(center)
	var field := Rect2(Vector2(20.0, 20.0), size - Vector2(40.0, 40.0))
	if not field.has_point(point) or header.grow(8).has_point(point):
		return false
	if _back.visible and _back.get_global_rect().grow(10).has_point(point):
		return false
	if is_instance_valid(_touch) and _touch.is_visible_in_tree():
		return point.distance_to(_touch.stick_center()) > TOUCH_CONTROLS.STICK_RADIUS + 8.0 and point.distance_to(_touch.jump_center()) > TOUCH_CONTROLS.JUMP_RADIUS + 8.0
	return true


func _above_pad(point: Vector2, center: Vector2, radius: float) -> float:
	var reserved := radius + INSET
	var horizontal := absf(point.x - center.x)
	if horizontal < reserved:
		return minf(point.y, center.y - sqrt(reserved * reserved - horizontal * horizontal))
	return point.y


func _clear() -> void:
	if not _indicated.is_empty():
		_indicated = {}
		queue_redraw()


func _draw() -> void:
	if _indicated.is_empty():
		return
	var side := _direction.orthogonal()
	var arrow := PackedVector2Array()
	for point: Vector2 in ARROW:
		arrow.append(_position + _direction * point.x + side * point.y)
	draw_colored_polygon(arrow, INK)
	arrow.append(arrow[0])
	draw_polyline(arrow, PAPER, 4.0, true)
	draw_circle(_position + Vector2(0, 3), BADGE_RADIUS, Color(0.13, 0.20, 0.16, 0.26))
	draw_circle(_position, BADGE_RADIUS, INK)
	draw_circle(_position, BADGE_RADIUS - 3.5, PAPER)
	LESSON_CUES.paint_symbol(self, _position, _indicated["shape"], _indicated["color"], _indicated.get("pips", PackedVector2Array()))
