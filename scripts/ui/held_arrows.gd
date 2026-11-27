extends Control
## Keeps held movement arrows from changing menu focus when the panel opens.

const ARROW_ACTIONS: Array[StringName] = [&"ui_left", &"ui_up", &"ui_right", &"ui_down"]

var _held_actions: Array[StringName] = []


func _ready() -> void:
	visibility_changed.connect(_capture_held_arrows)
	_capture_held_arrows()


func _capture_held_arrows() -> void:
	_held_actions.clear()
	if is_visible_in_tree():
		for action: StringName in ARROW_ACTIONS:
			if Input.is_action_pressed(action):
				_held_actions.append(action)
	set_process_input(not _held_actions.is_empty())


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	for action: StringName in _held_actions:
		if not event.is_action(action):
			continue
		if event.is_pressed() and event.is_echo():
			get_viewport().set_input_as_handled()
		else:
			_held_actions.erase(action)
			set_process_input(not _held_actions.is_empty())
		return
