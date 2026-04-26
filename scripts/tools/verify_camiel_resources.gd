extends SceneTree

const EXPECTED := {
	"idle_right": 4,
	"idle_left": 4,
	"walk_right": 6,
	"walk_left": 6,
	"run_right": 6,
	"run_left": 6,
	"jump_right": 4,
	"jump_left": 4,
	"sit_right": 4,
	"sit_left": 4,
	"sleep_right": 3,
	"sleep_left": 3,
}

func _initialize() -> void:
	var frames: SpriteFrames = load("res://assets/camiel/camiel_sprite_frames.tres")
	if frames == null:
		push_error("Missing camiel_sprite_frames.tres")
		quit(1)
		return

	for animation_name: String in EXPECTED.keys():
		if not frames.has_animation(animation_name):
			push_error("Missing animation: %s" % animation_name)
			quit(1)
			return
		var actual := frames.get_frame_count(animation_name)
		var expected := int(EXPECTED[animation_name])
		if actual != expected:
			push_error("Animation %s has %d frames, expected %d" % [animation_name, actual, expected])
			quit(1)
			return

	for scene_path in ["res://scenes/camiel.tscn", "res://scenes/main.tscn"]:
		if load(scene_path) == null:
			push_error("Could not load scene: %s" % scene_path)
			quit(1)
			return

	var camiel_scene: PackedScene = load("res://scenes/camiel.tscn")
	var camiel := camiel_scene.instantiate()
	if not camiel is CharacterBody2D:
		push_error("Camiel scene root is not a CharacterBody2D.")
		quit(1)
		return
	if camiel.get_script() == null:
		push_error("Camiel scene has no controller script attached.")
		quit(1)
		return
	camiel.queue_free()

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main := main_scene.instantiate()
	if main.get_node_or_null("Camiel") == null:
		push_error("Main scene has no Camiel instance.")
		quit(1)
		return
	main.queue_free()

	print("Camiel Godot resources verified.")
	quit(0)
