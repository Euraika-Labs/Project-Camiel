# menu_button.gd
# The single activation component for every screen in this phase (D-16): a
# focusable icon-plus-label button used by the title screen, main menu, and
# win screen. Rooted on Button so a tap, a click, and Enter on the focused
# control all resolve to the inherited BaseButton.pressed signal (D-14) —
# this file declares no signal of its own and never overrides _input or
# _gui_input, which is exactly the archived title screen's double-transition
# defect this component must not reproduce.
extends Button

@export var label_text: String = "":
	set(value):
		label_text = value
		if is_node_ready():
			%Label.text = label_text

@export var icon_kind: String = "play":
	set(value):
		icon_kind = value
		if is_node_ready():
			%Icon.icon_kind = icon_kind

@export var caption := "":
	set(value):
		caption = value
		if is_node_ready():
			%Caption.text = caption
			%Caption.visible = not caption.is_empty()
@export var compact := false
var icon_colors := PackedColorArray()
var completed := false:
	set(value):
		completed = value
		if is_node_ready():
			%Completed.visible = completed


func _ready() -> void:
	%Label.text = label_text
	%Icon.icon_kind = icon_kind
	%Icon.shape_colors = icon_colors
	%Caption.text = caption
	%Caption.visible = not caption.is_empty()
	%Completed.visible = completed
	if compact:
		%Icon.custom_minimum_size = Vector2(36, 34)
		%Label.add_theme_font_size_override("font_size", 22)
	if not caption.is_empty():
		%Icon.custom_minimum_size = Vector2(51, 47)
	# Restates the engine default (VF18) rather than changing it; kept
	# because the UI contract names it and a future theme/scene edit could
	# plausibly clear it.
	focus_mode = Control.FOCUS_ALL
