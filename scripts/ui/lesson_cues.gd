extends Control
## Pictograms use the lesson's own target shape, colour and counting dots.

const SLOT_WIDTH := 48.0
const HEIGHT := 44.0
const GROUP_GAP := 18.0
const INK := Color("#234638")
const PAPER := Color("#fff9eb")

var _cues: Array[Dictionary] = []
var _completed: Dictionary = {}
var _ordered := false
var _stone_slots := 0


# Counting stones in free-order lessons follow the two color goals.
func set_targets(targets: Array[Area3D], ordered: bool, stone_slots := 0) -> void:
	_ordered = ordered
	_stone_slots = stone_slots
	_cues.clear()
	_completed.clear()
	for target: Area3D in targets:
		_cues.append({
			"id": String(target.task_id),
			"target": target,
			"color": target.target_color,
			"shape": String(target.shape_kind),
			"pips": target.get_count_pips(),
		})
	var gap := GROUP_GAP if _stone_slots > 0 else 0.0
	custom_minimum_size = Vector2(_cues.size() * SLOT_WIDTH + gap, HEIGHT)
	queue_redraw()


func complete_target(task_id: String) -> void:
	_completed[task_id] = true
	queue_redraw()


func is_complete(task_id: String) -> bool:
	return _completed.has(task_id)


func active_target_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for cue: Dictionary in active_markers():
		ids.append(cue["id"])
	return ids


func active_markers() -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	for cue: Dictionary in _cues:
		if not is_complete(cue["id"]):
			active.append(cue)
			if _ordered:
				break
	return active


func _draw() -> void:
	var active := active_target_ids()
	var start := (size.x - custom_minimum_size.x + SLOT_WIDTH) * 0.5
	var stone_start := _cues.size() - _stone_slots
	var stones_found := 0
	for index in range(stone_start, _cues.size()):
		if is_complete(_cues[index]["id"]):
			stones_found += 1
	if _stone_slots > 0:
		var divider := start + (stone_start - 0.5) * SLOT_WIDTH + GROUP_GAP * 0.5
		draw_line(Vector2(divider, 8), Vector2(divider, size.y - 8), Color("#cbb997"), 2.0, true)
	for index in _cues.size():
		var cue := _cues[index]
		var point := Vector2(start + index * SLOT_WIDTH, size.y * 0.5)
		if index >= stone_start:
			point.x += GROUP_GAP
			_draw_stone_slot(point, cue["color"], index - stone_start < stones_found)
			continue
		var task_id := String(cue["id"])
		var next := task_id in active
		var finished := is_complete(task_id)
		draw_circle(point, 21.0, INK if next else Color("#d9cdb6"))
		draw_circle(point, 17.5 if next else 19.0, Color("#ffe4aa") if next else PAPER)
		var tint: Color = cue["color"]
		if finished:
			tint = tint.lerp(PAPER, 0.4)
		paint_symbol(self, point, String(cue["shape"]), tint, cue["pips"])
		if finished:
			_draw_check(point + Vector2(12, 12))


func _draw_stone_slot(point: Vector2, tint: Color, filled: bool) -> void:
	draw_circle(point, 21.0, INK if filled else Color("#cbb997"))
	draw_circle(point, 18.0, Color("#ffe4aa") if filled else PAPER)
	if filled:
		paint_symbol(self, point, "sphere", tint, PackedVector2Array())
		_draw_check(point + Vector2(12, 12))
	else:
		draw_arc(point, 10.0, 0.0, TAU, 30, Color("#baa37c"), 2.0, true)


static func paint_symbol(canvas: CanvasItem, point: Vector2, shape: String, tint: Color, pips: PackedVector2Array) -> void:
	match shape:
		"box":
			canvas.draw_rect(Rect2(point - Vector2(12, 12), Vector2(24, 24)), tint)
		"prism":
			canvas.draw_colored_polygon(PackedVector2Array([
				point + Vector2(0, -14), point + Vector2(14, 11), point + Vector2(-14, 11),
			]), tint)
		"sphere":
			canvas.draw_circle(point, 12.5, tint)
			canvas.draw_circle(point + Vector2(-3, -4), 4, tint.lightened(0.35))
		"ring":
			canvas.draw_arc(point, 11.0, 0.0, TAU, 48, tint, 5.0, true)
		_:
			canvas.draw_circle(point, 13.0, tint)
			for pip: Vector2 in pips:
				canvas.draw_circle(point + pip * 5.4, 2.45, PAPER)


func _draw_check(point: Vector2) -> void:
	draw_circle(point, 9.0, INK)
	draw_colored_polygon(PackedVector2Array([
		point + Vector2(-5, 0), point + Vector2(-3, -2), point + Vector2(-1, 0),
		point + Vector2(4, -5), point + Vector2(6, -3), point + Vector2(-1, 4),
	]), Color.WHITE)
