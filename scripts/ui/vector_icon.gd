# vector_icon.gd
# Draws this phase's menu-button icons procedurally, in code, because the
# archived 2D artwork is deliberately unported (D-13). get_icon_shapes() is a
# pure function of its arguments, touching no node state, so a headless probe
# can assert icon geometry without ever needing a display; _draw() only
# renders what that function returns.
extends Control

@export var icon_kind: String = "play":
	set(value):
		icon_kind = value
		queue_redraw()

@export var icon_color: Color = Color("ed9e4d"):
	set(value):
		icon_color = value
		queue_redraw()


func _draw() -> void:
	for shape: Dictionary in get_icon_shapes(icon_kind, size):
		match shape.get("type", ""):
			"polygon":
				draw_colored_polygon(shape["points"], icon_color)
			"circle":
				draw_circle(shape["center"], shape["radius"], icon_color)
			"arc":
				draw_arc(shape["center"], shape["radius"], shape["angle_from"], shape["angle_to"], shape["point_count"], icon_color, shape.get("width", 2.0))
			"rect":
				draw_rect(shape["rect"], icon_color)


## Returns the drawable shapes for one icon kind, as a pure function of kind
## and the target size: every coordinate is expressed as a fraction of
## target_size, so the same shape reads identically at a 32px slider-row icon
## and a 64px button icon. Valid kinds: "play", "walk", "replay", "home",
## "speaker", "music_note", "lesson_colors", "lesson_shapes",
## "lesson_sequence". An unrecognised kind warns and returns no shapes.
func get_icon_shapes(kind: String, target_size: Vector2) -> Array[Dictionary]:
	match kind:
		"play":
			return _play_shapes(target_size)
		"walk":
			return _walk_shapes(target_size)
		"replay":
			return _replay_shapes(target_size)
		"home":
			return _home_shapes(target_size)
		"speaker":
			return _speaker_shapes(target_size)
		"music_note":
			return _music_note_shapes(target_size)
		"lesson_colors":
			return _lesson_colors_shapes(target_size)
		"lesson_shapes":
			return _lesson_shapes_shapes(target_size)
		"lesson_sequence":
			return _lesson_sequence_shapes(target_size)
		_:
			push_warning("[VectorIcon] Unknown icon kind: ", kind)
			return []


func _play_shapes(target_size: Vector2) -> Array[Dictionary]:
	var w := target_size.x
	var h := target_size.y
	var points := PackedVector2Array([
		Vector2(w * 0.28, h * 0.2),
		Vector2(w * 0.28, h * 0.8),
		Vector2(w * 0.78, h * 0.5),
	])
	return [{"type": "polygon", "points": points}]


func _walk_shapes(target_size: Vector2) -> Array[Dictionary]:
	# Two overlapping footprints, offset diagonally.
	var w := target_size.x
	var h := target_size.y
	var radius: float = minf(w, h) * 0.08
	return [
		{"type": "circle", "center": Vector2(w * 0.32, h * 0.35), "radius": radius},
		{"type": "circle", "center": Vector2(w * 0.62, h * 0.6), "radius": radius},
	]


func _replay_shapes(target_size: Vector2) -> Array[Dictionary]:
	# A ~300 degree arc (loop) plus a small triangular arrowhead at one end.
	var w := target_size.x
	var h := target_size.y
	var center := Vector2(w * 0.5, h * 0.5)
	var radius: float = minf(w, h) * 0.28
	var angle_from := deg_to_rad(-240.0)
	var angle_to := deg_to_rad(60.0)

	var tip := center + Vector2(radius, 0.0).rotated(angle_to)
	var tangent := Vector2(radius, 0.0).rotated(angle_to + PI * 0.5).normalized()
	var arrow_size: float = minf(w, h) * 0.09
	var arrowhead := PackedVector2Array([
		tip + tangent * arrow_size,
		tip - tangent * arrow_size,
		tip + (tip - center).normalized() * arrow_size,
	])

	return [
		{
			"type": "arc",
			"center": center,
			"radius": radius,
			"angle_from": angle_from,
			"angle_to": angle_to,
			"point_count": 32,
			"width": minf(w, h) * 0.08,
		},
		{"type": "polygon", "points": arrowhead},
	]


func _home_shapes(target_size: Vector2) -> Array[Dictionary]:
	# A triangular roof over a square body.
	var w := target_size.x
	var h := target_size.y
	var roof := PackedVector2Array([
		Vector2(w * 0.12, h * 0.5),
		Vector2(w * 0.88, h * 0.5),
		Vector2(w * 0.5, h * 0.12),
	])
	var body := PackedVector2Array([
		Vector2(w * 0.22, h * 0.5),
		Vector2(w * 0.78, h * 0.5),
		Vector2(w * 0.78, h * 0.88),
		Vector2(w * 0.22, h * 0.88),
	])
	return [
		{"type": "polygon", "points": roof},
		{"type": "polygon", "points": body},
	]


func _speaker_shapes(target_size: Vector2) -> Array[Dictionary]:
	# A trapezoid speaker cone plus two sound-wave arcs.
	var w := target_size.x
	var h := target_size.y
	var cone := PackedVector2Array([
		Vector2(w * 0.15, h * 0.38),
		Vector2(w * 0.38, h * 0.38),
		Vector2(w * 0.55, h * 0.18),
		Vector2(w * 0.55, h * 0.82),
		Vector2(w * 0.38, h * 0.62),
		Vector2(w * 0.15, h * 0.62),
	])
	var wave_center := Vector2(w * 0.55, h * 0.5)
	var wave_width: float = minf(w, h) * 0.05
	return [
		{"type": "polygon", "points": cone},
		{
			"type": "arc",
			"center": wave_center,
			"radius": minf(w, h) * 0.14,
			"angle_from": deg_to_rad(-40.0),
			"angle_to": deg_to_rad(40.0),
			"point_count": 12,
			"width": wave_width,
		},
		{
			"type": "arc",
			"center": wave_center,
			"radius": minf(w, h) * 0.26,
			"angle_from": deg_to_rad(-40.0),
			"angle_to": deg_to_rad(40.0),
			"point_count": 12,
			"width": wave_width,
		},
	]


func _music_note_shapes(target_size: Vector2) -> Array[Dictionary]:
	# A filled notehead circle plus a thin vertical stem.
	var w := target_size.x
	var h := target_size.y
	var notehead_radius: float = minf(w, h) * 0.15
	var notehead_center := Vector2(w * 0.35, h * 0.75)
	var stem_rect := Rect2(Vector2(w * 0.47, h * 0.15), Vector2(w * 0.06, h * 0.6))
	return [
		{"type": "circle", "center": notehead_center, "radius": notehead_radius},
		{"type": "rect", "rect": stem_rect},
	]


func _lesson_colors_shapes(target_size: Vector2) -> Array[Dictionary]:
	# Two equal circles side by side with a clear gap: two colours to tell
	# apart. Horizontal and equal-sized on purpose, so it cannot be mistaken
	# for the walking icon's diagonally offset, much smaller pair. Both draw in
	# the component's one icon colour -- the kinds are distinguished by form and
	# count, never by hue.
	var w := target_size.x
	var h := target_size.y
	var radius: float = minf(w, h) * 0.16
	return [
		{"type": "circle", "center": Vector2(w * 0.30, h * 0.5), "radius": radius},
		{"type": "circle", "center": Vector2(w * 0.70, h * 0.5), "radius": radius},
	]


func _lesson_shapes_shapes(target_size: Vector2) -> Array[Dictionary]:
	# A circle, a square and a triangle in a row: shapes to put in order.
	var w := target_size.x
	var h := target_size.y
	var circle_radius: float = minf(w, h) * 0.13
	var triangle := PackedVector2Array([
		Vector2(w * 0.70, h * 0.63),
		Vector2(w * 0.92, h * 0.63),
		Vector2(w * 0.81, h * 0.35),
	])
	return [
		{"type": "circle", "center": Vector2(w * 0.20, h * 0.5), "radius": circle_radius},
		{"type": "rect", "rect": Rect2(Vector2(w * 0.40, h * 0.37), Vector2(w * 0.22, h * 0.26))},
		{"type": "polygon", "points": triangle},
	]


func _lesson_sequence_shapes(target_size: Vector2) -> Array[Dictionary]:
	# Three circles of increasing radius along a rising diagonal: a first, a
	# second and a third.
	var w := target_size.x
	var h := target_size.y
	var unit: float = minf(w, h)
	return [
		{"type": "circle", "center": Vector2(w * 0.22, h * 0.76), "radius": unit * 0.08},
		{"type": "circle", "center": Vector2(w * 0.50, h * 0.52), "radius": unit * 0.12},
		{"type": "circle", "center": Vector2(w * 0.78, h * 0.26), "radius": unit * 0.16},
	]
