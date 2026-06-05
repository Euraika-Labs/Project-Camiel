# dialog_popup.gd
# Reusable modal dialog for messages and confirmations.
extends CanvasLayer

signal dismissed

@onready var bg: ColorRect = $ColorRect
@onready var panel: Panel = $Panel
@onready var message_label: Label = $Panel/VBox/Label
@onready var ok_button: Button = $Panel/VBox/OkButton


func _ready() -> void:
	hide()


func show_message(msg: String, button_text: String = "OK") -> void:
	message_label.text = msg
	ok_button.text = button_text
	show()


func _on_ok_button_pressed() -> void:
	hide()
	dismissed.emit()