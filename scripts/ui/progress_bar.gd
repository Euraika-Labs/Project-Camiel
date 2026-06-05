# progress_bar.gd
# Reusable progress display showing current/total tasks.
extends HBoxContainer

@onready var label: Label = $Label
@onready var bar: ProgressBar = $ProgressBar

var _total: int = 3
var _current: int = 0


func _ready() -> void:
	bar.max_value = _total
	bar.value = _current


func set_progress(done: int, total_tasks: int) -> void:
	_current = done
	_total = total_tasks
	label.text = "Taken: %d / %d" % [_current, _total]
	bar.value = _current