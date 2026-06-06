extends Area2D

## Finish marker — Camiel's intro level goal.
## When the player reaches the flag:
##   1. Plays sfx_finish via AudioManager
##   2. Shows "Goed zo!" in the main message area
##   3. After 2 s shows "Press Enter to play again"
##   4. On Enter → reloads the current scene

signal finished

@onready var message_label: Label = $MessageLabel

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	_reach_finish(body)


func _reach_finish(_body: Node2D) -> void:
	# 1. Play the finish SFX via the shared audio autoload when present.
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("finish")

	# 2. Tell the main scene to show "Goed zo!" and trigger win screen.
	finished.emit()

	# 3. After 2 s, show the replay prompt on the flag label.
	await get_tree().create_timer(2.0).timeout
	_show_replay_prompt()


func _show_replay_prompt() -> void:
	message_label.text = "Druk op Enter om opnieuw te spelen!"
	message_label.visible = true


func _process(_delta: float) -> void:
	if _triggered and Input.is_key_pressed(KEY_ENTER):
		get_tree().reload_current_scene()
