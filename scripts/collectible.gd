extends Area2D

signal collected

@export var bob_speed := 2.5
@export var bob_height := 6.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

var _base_y := 0.0
var _time := 0.0
var _collected := false


func _ready() -> void:
	_base_y = position.y
	add_to_group("collectibles")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _collected:
		return
	var accessibility := get_node_or_null("/root/Accessibility")
	if accessibility and accessibility.is_reduced_motion_enabled():
		position.y = _base_y
		return
	_time += delta
	position.y = _base_y + sin(_time * bob_speed) * bob_height


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return

	_collected = true
	hide()
	_play_sfx()
	collected.emit()


func _play_sfx() -> void:
	if sfx_player.stream != null:
		sfx_player.play()
