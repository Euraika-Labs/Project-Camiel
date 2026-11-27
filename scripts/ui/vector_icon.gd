# vector_icon.gd
# Draws this phase's menu-button icons procedurally, in code, because the
# archived 2D artwork is deliberately unported (D-13). get_icon_shapes() is a
# pure function of its arguments, touching no node state, so a headless probe
# can assert icon geometry without ever needing a display; _draw() only
# renders what that function returns.
extends Control

const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")

@export var icon_kind: String = "play":
	set(value):
		icon_kind = value
		queue_redraw()

@export var icon_color: Color = Color("234638"):
	set(value):
		icon_color = value
		queue_redraw()

var shape_colors := PackedColorArray():
	set(value):
		shape_colors = value
		queue_redraw()


func _draw() -> void:
	var shapes := get_icon_shapes(icon_kind, size)
	for index in shapes.size():
		var shape := shapes[index]
		var tint: Color = shape_colors[index] if index < shape_colors.size() else shape.get("color", icon_color)
		match shape.get("type", ""):
			"polygon":
				draw_colored_polygon(shape["points"], tint)
			"circle":
				var center: Vector2 = shape["center"]
				var radius: float = shape["radius"]
				if icon_kind == "lesson_colors":
					var outline := minf(size.x, size.y) * 0.045
					draw_circle(center, radius + outline, icon_color, true, -1.0, true)
				draw_circle(center, radius, tint, true, -1.0, true)
			"arc":
				draw_arc(shape["center"], shape["radius"], shape["angle_from"], shape["angle_to"], shape["point_count"], tint, shape.get("width", 2.0), true)
			"rect":
				draw_rect(shape["rect"], tint)


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
		"pause":
			return _pause_shapes(target_size)
		"walk":
			return _walk_shapes(target_size)
		"arrow_keys":
			return _arrow_key_shapes(target_size)
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
		"count_3", "count_4", "count_5":
			return _count_shapes(target_size, kind.get_slice("_", 1).to_int())
		"paw":
			return _paw_shapes(target_size)
		"check":
			return _check_shapes(target_size)
		"medal":
			return _medal_shapes(target_size)
		"stars":
			return _star_shapes(target_size)
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


func _pause_shapes(target_size: Vector2) -> Array[Dictionary]:
	var bar := target_size * Vector2(0.16, 0.57)
	return [
		{"type": "rect", "rect": Rect2(target_size * Vector2(0.26, 0.22), bar)},
		{"type": "rect", "rect": Rect2(target_size * Vector2(0.58, 0.22), bar)},
	]


func _walk_shapes(target_size: Vector2) -> Array[Dictionary]:
	# Two overlapping footprints, offset diagonally.
	var w := target_size.x
	var h := target_size.y
	var radius: float = minf(w, h) * 0.08
	return [
		{"type": "circle", "center": Vector2(w * 0.32, h * 0.35), "radius": radius},
		{"type": "circle", "center": Vector2(w * 0.62, h * 0.6), "radius": radius},
	]


func _arrow_key_shapes(target_size: Vector2) -> Array[Dictionary]:
	var cell := minf(target_size.x / 3.0, target_size.y / 2.0)
	var origin := (target_size - Vector2(3.0, 2.0) * cell) * 0.5
	var positions := [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)]
	var directions := [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]
	var ink := Color("234638")
	var shapes: Array[Dictionary] = []
	for index in positions.size():
		var center: Vector2 = origin + (positions[index] + Vector2(0.5, 0.5)) * cell
		var direction: Vector2 = directions[index]
		var key := Rect2(center - Vector2.ONE * cell * 0.44, Vector2.ONE * cell * 0.88)
		shapes.append({"type": "rect", "rect": key, "color": ink})
		var face := Color("ffcf84") if direction == Vector2.UP else Color("fff9eb")
		shapes.append({"type": "rect", "rect": key.grow(-cell * 0.065), "color": face})
		var wing := direction.orthogonal() * cell * 0.23
		var base := center - direction * cell * 0.16
		var points := PackedVector2Array([center + direction * cell * 0.25, base + wing, base - wing])
		shapes.append({"type": "polygon", "points": points, "color": ink})
	return shapes


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
	var wave_width: float = minf(w, h) * 0.075
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
	var stem_rect := Rect2(Vector2(w * 0.45, h * 0.15), Vector2(w * 0.09, h * 0.6))
	return [
		{"type": "circle", "center": notehead_center, "radius": notehead_radius},
		{"type": "rect", "rect": stem_rect},
	]


func _lesson_colors_shapes(target_size: Vector2) -> Array[Dictionary]:
	var w := target_size.x
	var h := target_size.y
	var radius: float = minf(w, h) * 0.21
	return [
		{"type": "circle", "center": Vector2(w * 0.26, h * 0.5), "radius": radius},
		{"type": "circle", "center": Vector2(w * 0.74, h * 0.5), "radius": radius},
	]


func _count_shapes(target_size: Vector2, number: int) -> Array[Dictionary]:
	var shapes: Array[Dictionary] = []
	var unit := minf(target_size.x, target_size.y)
	for pip: Vector2 in LESSON_CATALOG.count_pips(number):
		shapes.append({
			"type": "circle",
			"center": target_size * 0.5 + pip * unit * 0.20,
			"radius": unit * 0.093,
		})
	return shapes


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


func _paw_shapes(target_size: Vector2) -> Array[Dictionary]:
	var unit := minf(target_size.x, target_size.y)
	var shapes: Array[Dictionary] = [
		{"type": "circle", "center": target_size * Vector2(0.5, 0.66), "radius": unit * 0.23},
	]
	for toe: Vector2 in [Vector2(0.20, 0.38), Vector2(0.39, 0.23), Vector2(0.61, 0.23), Vector2(0.80, 0.38)]:
		shapes.append({"type": "circle", "center": target_size * toe, "radius": unit * 0.105})
	return shapes


func _check_shapes(target_size: Vector2) -> Array[Dictionary]:
	var points := PackedVector2Array()
	for point: Vector2 in [
		Vector2(0.11, 0.54), Vector2(0.26, 0.39), Vector2(0.43, 0.56),
		Vector2(0.76, 0.22), Vector2(0.92, 0.36), Vector2(0.43, 0.85),
	]:
		points.append(point * target_size)
	return [{"type": "polygon", "points": points}]


func _medal_shapes(target_size: Vector2) -> Array[Dictionary]:
	var unit := minf(target_size.x, target_size.y)
	var center := target_size * Vector2(0.50, 0.40)
	var shapes: Array[Dictionary] = [
		{"type": "polygon", "color": Color("#b6614d"), "points": PackedVector2Array([
			target_size * Vector2(0.29, 0.49), target_size * Vector2(0.70, 0.49),
			target_size * Vector2(0.79, 0.96), target_size * Vector2(0.50, 0.82),
			target_size * Vector2(0.21, 0.96),
		])},
		{"type": "circle", "center": center, "radius": unit * 0.348, "color": Color("#a0642d")},
		{"type": "circle", "center": center, "radius": unit * 0.314, "color": Color("#ffcd68")},
		{"type": "arc", "center": center, "radius": unit * 0.262, "angle_from": 0.0, "angle_to": TAU,
			"point_count": 40, "width": 2.6, "color": Color("#edac4a")},
	]
	var paw_size := Vector2.ONE * unit * 0.43
	for part: Dictionary in _paw_shapes(paw_size):
		part["center"] = part["center"] + center - paw_size * Vector2(0.5, 0.54)
		part["color"] = Color("#905625")
		shapes.append(part)
	return shapes


func _star_shapes(target_size: Vector2) -> Array[Dictionary]:
	var shapes: Array[Dictionary] = []
	for index in 3:
		var center := target_size * Vector2((index + 0.5) / 3.0, 0.52)
		var radius := minf(target_size.x / 3.0, target_size.y) * (0.46 if index == 1 else 0.39)
		var points := PackedVector2Array()
		for tip in 10:
			var direction := Vector2.UP.rotated(TAU * tip / 10.0)
			points.append(center + direction * radius * (1.0 if tip % 2 == 0 else 0.46))
		shapes.append({"type": "polygon", "points": points})
	return shapes
