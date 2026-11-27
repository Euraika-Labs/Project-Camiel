extends Control
## A brief paper shower around the edges of Camiel's portrait.

const DURATION := 2.45
const PALETTE: Array[Color] = [
	Color("#e38369"), Color("#f9c957"), Color("#348987"), Color("#5178a8"), Color("#bf6791"),
]

var _elapsed := 0.0


func _ready() -> void:
	set_process(false)


func scatter() -> void:
	_elapsed = 0.0
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if not is_processing():
		return
	var paper_size := clampf(minf(size.x, size.y) * 0.031, 9.0, 17.0)
	for index in 26:
		var lane := index >> 1
		var delay := lane * 0.028
		var time := (_elapsed - delay) / (DURATION - 0.34)
		if time <= 0.0 or time >= 1.0:
			continue
		var pattern := lane + (index % 2) * 5
		var start_x := lerpf(0.15, 0.31, float((pattern * 5) % 13) / 12.0)
		var drift := lerpf(0.05, 0.17, float(pattern % 6) / 5.0)
		var rise := lerpf(0.38, 0.64, float((pattern * 7) % 13) / 12.0)
		var x := clampf(start_x - drift * time + sin(time * TAU + pattern) * 0.023, 0.036, 0.34)
		if index % 2 == 1:
			x = 1.0 - x
		var start_y := lerpf(0.64, 0.74, float((pattern * 3) % 11) / 10.0)
		var y := start_y - 4.0 * rise * time * (1.0 - time) + time * 0.29
		var center := Vector2(x, y) * size
		var axis := Vector2.from_angle(lane * 1.7 + time * 6.5)
		var long_edge := axis * paper_size * (0.53 + 0.06 * (lane % 3))
		var short_edge := axis.orthogonal() * paper_size * (0.22 + 0.19 * absf(cos(time * TAU * 2.0 + lane)))
		var color := PALETTE[(index + lane) % PALETTE.size()]
		color.a = smoothstep(0.0, 0.10, time) * (1.0 - smoothstep(0.72, 1.0, time))
		draw_colored_polygon(PackedVector2Array([
			center - long_edge - short_edge, center + long_edge - short_edge,
			center + long_edge + short_edge, center - long_edge + short_edge,
		]), color)
