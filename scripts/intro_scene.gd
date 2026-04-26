extends Node2D

@onready var message: Label = $UI/MessagePanel/Message

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		message.text = "Spring, Camiel!"
		return

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):
		message.text = "Goed zo, Camiel wandelt!"
		return

	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		message.text = "Camiel zit rustig."
		return

	if Input.is_key_pressed(KEY_X):
		message.text = "Slaap lekker, Camiel."
		return

	message.text = "Hallo! Help Camiel op ontdekking."
