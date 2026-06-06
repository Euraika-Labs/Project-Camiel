# accessibility.gd
# Autoload singleton — manages high-contrast accessibility mode.
# Toggle with Accessibility.toggle_high_contrast().
extends Node

signal accessibility_changed

var _high_contrast := false
var _reduced_motion := false
var _muted := false


func _ready() -> void:
	# Persistence could be added here via ConfigFile if needed.
	pass


## Toggle high-contrast mode. When active, UI backgrounds darken
## and text uses WCAG AA compliant colours.
func toggle_high_contrast() -> void:
	_high_contrast = not _high_contrast
	_apply()


func toggle_reduced_motion() -> void:
	_reduced_motion = not _reduced_motion
	accessibility_changed.emit()


func toggle_mute() -> void:
	_muted = not _muted
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		accessibility_changed.emit()
		return
	if _muted:
		audio_manager.set_bgm_volume(0.0)
		audio_manager.set_sfx_volume(0.0)
	else:
		audio_manager.set_bgm_volume(0.8)
		audio_manager.set_sfx_volume(0.8)
	accessibility_changed.emit()


## Returns true if high-contrast mode is currently active.
func is_high_contrast_enabled() -> bool:
	return _high_contrast


func is_reduced_motion_enabled() -> bool:
	return _reduced_motion


func is_muted() -> bool:
	return _muted


func _apply() -> void:
	# Emit a signal so any UI that needs to update can respond.
	# Components should connect to this signal to refresh their colours.
	if _high_contrast:
		print("[Accessibility] High-contrast mode ON")
	else:
		print("[Accessibility] High-contrast mode OFF")
	# Update all CanvasLayer nodes that expose an _apply_contrast method.
	for layer in _get_contrast_layers():
		if layer.has_method("_apply_contrast"):
			layer._apply_contrast(_high_contrast)
	accessibility_changed.emit()


func _get_contrast_layers() -> Array[CanvasLayer]:
	var result: Array[CanvasLayer] = []
	var tree := get_tree()
	if tree == null:
		return result
	var root := tree.root
	if root == null:
		return result
	_collect_canvas_layers(root, result)
	return result


func _collect_canvas_layers(node: Node, result: Array[CanvasLayer]) -> void:
	if node is CanvasLayer:
		result.append(node)
	for child in node.get_children():
		_collect_canvas_layers(child, result)


# ── Convenience helpers for theme colours ──────────────────────────────────

## WCAG AA minimum contrast ratio for normal text (4.5:1) against white.
const HIGH_CONTRAST_TEXT_COLOR := Color(0.05, 0.05, 0.05, 1.0)
## WCAG AA minimum for large text / UI components (3:1).
const HIGH_CONTRAST_LARGE_COLOR := Color(0.10, 0.10, 0.10, 1.0)
