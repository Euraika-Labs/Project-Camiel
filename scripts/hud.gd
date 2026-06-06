extends CanvasLayer

@onready var star_label: Label = $StarCount

var star_count := 0


func _ready() -> void:
	_update_label()


func increment_stars() -> void:
	star_count += 1
	_update_label()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("collect")


func get_star_count() -> int:
	return star_count


func _update_label() -> void:
	star_label.text = "Stars: %d" % star_count
