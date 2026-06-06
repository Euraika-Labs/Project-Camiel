# menu_button.gd
# Reusable menu button with consistent styling across the game.
extends Button
const VERSION := "beta-1-candidate"

func _ready() -> void:
	custom_minimum_size = Vector2(200, 80)
	add_theme_stylebox_override("normal", _make_stylebox("normal"))
	add_theme_stylebox_override("hover", _make_stylebox("hover"))
	add_theme_stylebox_override("pressed", _make_stylebox("pressed"))
	add_theme_stylebox_override("disabled", _make_stylebox("disabled"))


func _make_stylebox(state: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	match state:
		"normal":
			s.bg_color = Color(0.2, 0.7, 0.2, 1.0)
		"hover":
			s.bg_color = Color(0.25, 0.8, 0.25, 1.0)
		"pressed":
			s.bg_color = Color(0.15, 0.55, 0.15, 1.0)
		"disabled":
			s.bg_color = Color(0.4, 0.4, 0.4, 1.0)
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s
