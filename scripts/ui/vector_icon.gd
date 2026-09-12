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
## "speaker", "music_note". An unrecognised kind warns and returns no shapes.
func get_icon_shapes(kind: String, target_size: Vector2) -> Array[Dictionary]:
	match kind:
		"play":
			return _play_shapes(target_size)
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
