# version_label.gd
# Reusable version label that auto-sets its text from project.godot.
# Attach to any Label node in a scene.
extends Label


func _ready() -> void:
	text = "Camiel beta-1-candidate"
