# finish_marker.gd
# The intro level's goal (D-20): an Area3D that emits `finished` once a
# player-group body enters it, and does nothing else. The archived finish
# marker declared this same signal, never emitted it, and instead reached
# into another script through a group lookup and a direct method call
# (CONCERNS.md) — that is exactly the defect INTRO-04's "single signal-driven
# path" wording exists to prevent. Every body in the level shares the default
# collision layer, so the ground and walls enter this area too; the group
# check below is a functional requirement, not a style preference.
extends Area3D

signal finished

var _touched := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	_touched = true
	finished.emit()


## Clears the one-shot latch so a replayed lap can reach the finish again.
func reset() -> void:
	_touched = false
