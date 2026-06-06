extends CanvasLayer

@onready var stars_label: Label = $StarsLabel

var _stars := 0


func _ready() -> void:
	_update_label()
	# Use get_tree().node_removed to detect scene-cleanup; for newly added
	# collectibles we connect to the "collectibles" group dynamically.
	_connect_to_collectibles()


func get_star_count() -> int:
	return _stars


func _update_label() -> void:
	stars_label.text = "Stars: %d" % _stars


func _on_collectible_collected() -> void:
	_stars += 1
	_update_label()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("collect")


func _connect_to_collectibles() -> void:
	# Connect to every collectible currently in the group.
	for node in get_tree().get_nodes_in_group("collectibles"):
		_connect_collectible(node)
	# Auto-connect future collectibles when they join the group.
	get_tree().group_added.connect(_on_group_added_collectible)


func _on_group_added_collectible(group: String) -> void:
	if group == "collectibles":
		for node in get_tree().get_nodes_in_group("collectibles"):
			_connect_collectible(node)


func _connect_collectible(node: Node) -> void:
	if not node.has_signal("collected"):
		return
	if not node.collected.is_connected(_on_collectible_collected):
		node.collected.connect(_on_collectible_collected)
