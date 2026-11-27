extends Node
## Chooses a reference canvas based on the space available for the controls.

signal layout_changed(portrait: bool)

const LANDSCAPE_SIZE := Vector2i(1280, 720)
const SHORT_LANDSCAPE_SIZE := Vector2i(1140, 600)
const PORTRAIT_SIZE := Vector2i(640, 920)
const SHORT_LANDSCAPE_BUTTON_HEIGHT := 104.0

var portrait := false
var short_landscape := false


func _ready() -> void:
	var window := get_window()
	# Scene controls and decorations animate on render frames. Camiel opts in.
	window.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	window.size_changed.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var window := get_window()
	# Use aspect ratios so the layout is consistent at different pixel densities.
	var stacked := window.size.x < window.size.y * 1.2
	var shallow := window.size.x >= window.size.y * 2
	var changed := portrait != stacked or short_landscape != shallow
	portrait = stacked
	short_landscape = shallow
	var reference := LANDSCAPE_SIZE
	if portrait:
		reference = PORTRAIT_SIZE
	elif short_landscape:
		reference = SHORT_LANDSCAPE_SIZE
	if window.content_scale_size != reference:
		window.content_scale_size = reference
	if changed:
		layout_changed.emit(portrait)


func place(control: Control, anchors: Vector4, offsets := Vector4.ZERO) -> void:
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w
