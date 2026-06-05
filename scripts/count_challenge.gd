# count_challenge.gd
# Educational micro-task: count three collectible stars and react.
# Places 3 collectibles in the scene. When all 3 are collected,
# a Label shows "3! Goed zo!".
extends Node2D

signal task_completed

@export var num_to_collect := 3

@onready var count_label: Label = $CountLabel
@onready var message_label: Label = $MessageLabel

var _collected := 0


func _ready() -> void:
	_connect_collectibles()
	_update_label()


func _connect_collectibles() -> void:
	for node in get_tree().get_nodes_in_group("count_collectibles"):
		if node.has_signal("collected") and not node.collected.is_connected(_on_one_collected):
			node.collected.connect(_on_one_collected)


func _on_one_collected() -> void:
	_collected += 1
	_update_label()
	if _collected >= num_to_collect:
		_apply_complete()


func _update_label() -> void:
	count_label.text = "Count: %d" % _collected


func _apply_complete() -> void:
	message_label.text = "%d! Goed zo!" % num_to_collect
	message_label.visible = true
	AudioManager.play_sfx("finish")
	task_completed.emit()
