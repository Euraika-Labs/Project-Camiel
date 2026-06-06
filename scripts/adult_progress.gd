extends Node2D

@onready var summary_label: Label = $ColorRect/VBox/SummaryLabel
@onready var settings_label: Label = $ColorRect/VBox/SettingsLabel
@onready var back_button: Button = $ColorRect/VBox/BackButton


func _ready() -> void:
	_update_summary_label()
	_update_settings_label()
	back_button.grab_focus()


func _on_reset_button_pressed() -> void:
	var progress_tracker := get_node_or_null("/root/ProgressTracker")
	if progress_tracker:
		progress_tracker.reset_progress()
	_update_summary_label()


func _on_mute_button_pressed() -> void:
	var accessibility := get_node_or_null("/root/Accessibility")
	if accessibility:
		accessibility.toggle_mute()
	_update_settings_label()


func _on_reduced_motion_button_pressed() -> void:
	var accessibility := get_node_or_null("/root/Accessibility")
	if accessibility:
		accessibility.toggle_reduced_motion()
	_update_settings_label()


func _on_high_contrast_button_pressed() -> void:
	var accessibility := get_node_or_null("/root/Accessibility")
	if accessibility:
		accessibility.toggle_high_contrast()
	_update_settings_label()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _update_settings_label() -> void:
	var accessibility := get_node_or_null("/root/Accessibility")
	if accessibility == null:
		settings_label.text = "Geluid: aan  |  Beweging: normaal  |  Contrast: normaal"
		return
	settings_label.text = "Geluid: %s  |  Beweging: %s  |  Contrast: %s" % [
		"uit" if accessibility.is_muted() else "aan",
		"rustig" if accessibility.is_reduced_motion_enabled() else "normaal",
		"hoog" if accessibility.is_high_contrast_enabled() else "normaal"
	]


func _update_summary_label() -> void:
	var progress_tracker := get_node_or_null("/root/ProgressTracker")
	if progress_tracker:
		summary_label.text = progress_tracker.get_progress_summary()
	else:
		summary_label.text = "Voltooide lessen: 0 / 5\nSterren totaal: 0 / 15"
