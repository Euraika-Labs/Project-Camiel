extends SceneTree

const ANIMATIONS := {
	"idle_right": {"frames": 4, "fps": 5.0, "loop": true},
	"idle_left": {"frames": 4, "fps": 5.0, "loop": true},
	"walk_right": {"frames": 6, "fps": 8.0, "loop": true},
	"walk_left": {"frames": 6, "fps": 8.0, "loop": true},
	"run_right": {"frames": 6, "fps": 10.0, "loop": true},
	"run_left": {"frames": 6, "fps": 10.0, "loop": true},
	"jump_right": {"frames": 4, "fps": 8.0, "loop": false},
	"jump_left": {"frames": 4, "fps": 8.0, "loop": false},
	"sit_right": {"frames": 4, "fps": 6.0, "loop": false},
	"sit_left": {"frames": 4, "fps": 6.0, "loop": false},
	"sleep_right": {"frames": 3, "fps": 3.0, "loop": true},
	"sleep_left": {"frames": 3, "fps": 3.0, "loop": true},
}

const ANIMATION_DIR := "res://assets/camiel/animations"
const SPRITE_FRAMES_PATH := "res://assets/camiel/camiel_sprite_frames.tres"
const CAMIEL_SCENE_PATH := "res://scenes/camiel.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"

func _initialize() -> void:
	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	for animation_name: String in ANIMATIONS.keys():
		var config: Dictionary = ANIMATIONS[animation_name]
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, float(config["fps"]))
		sprite_frames.set_animation_loop(animation_name, bool(config["loop"]))

		for frame_index in range(1, int(config["frames"]) + 1):
			var frame_path := "%s/%s/camiel_%s_%02d.png" % [
				ANIMATION_DIR,
				animation_name,
				animation_name,
				frame_index,
			]
			if not FileAccess.file_exists(frame_path):
				push_error("Missing animation frame: %s" % frame_path)
				quit(1)
				return

			var texture := load(frame_path)
			if texture == null:
				push_error("Could not load animation frame: %s" % frame_path)
				quit(1)
				return

			sprite_frames.add_frame(animation_name, texture, 1.0)

	var err := ResourceSaver.save(sprite_frames, SPRITE_FRAMES_PATH)
	if err != OK:
		push_error("Could not save SpriteFrames resource: %s" % error_string(err))
		quit(1)
		return

	err = _save_camiel_scene()
	if err != OK:
		push_error("Could not save Camiel scene: %s" % error_string(err))
		quit(1)
		return

	err = _save_main_scene()
	if err != OK:
		push_error("Could not save main scene: %s" % error_string(err))
		quit(1)
		return

	print("Saved Camiel SpriteFrames and scenes.")
	quit(0)

func _save_camiel_scene() -> Error:
	var root := Node2D.new()
	root.name = "Camiel"

	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = load(SPRITE_FRAMES_PATH)
	sprite.animation = "idle_right"
	sprite.play()
	root.add_child(sprite)
	sprite.owner = root

	var scene := PackedScene.new()
	var err := scene.pack(root)
	if err != OK:
		return err

	return ResourceSaver.save(scene, CAMIEL_SCENE_PATH)

func _save_main_scene() -> Error:
	var root := Node2D.new()
	root.name = "Main"

	var camiel_scene: PackedScene = load(CAMIEL_SCENE_PATH)
	if camiel_scene == null:
		return ERR_CANT_OPEN

	var camiel: Node2D = camiel_scene.instantiate()
	camiel.name = "Camiel"
	camiel.position = Vector2(640, 520)
	camiel.scale = Vector2(0.25, 0.25)
	root.add_child(camiel)
	camiel.owner = root

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(640, 360)
	camera.enabled = true
	root.add_child(camera)
	camera.owner = root

	var scene := PackedScene.new()
	var err := scene.pack(root)
	if err != OK:
		return err

	return ResourceSaver.save(scene, MAIN_SCENE_PATH)
