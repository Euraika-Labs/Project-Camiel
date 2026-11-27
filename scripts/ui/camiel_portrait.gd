extends SubViewportContainer
## A live portrait of the playable character in the same 3D garden.

const CAMIEL := preload("res://assets/characters/camiel/camiel.glb")
const GARDEN := preload("res://scripts/world/garden_scenery.gd")
const GOLDEN_BALL := preload("res://assets/materials/golden_ball.tres")

@export var celebrate := false
@export var show_golden_ball := false

var _camiel: Node3D
var _animation: AnimationPlayer


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var view := SubViewport.new()
	view.size = Vector2i(640, 720)
	view.own_world_3d = true
	view.gui_disable_input = true
	view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	view.msaa_3d = Viewport.MSAA_2X
	add_child(view)

	var garden := GARDEN.new()
	garden.show_fence = false
	garden.half_extent = 4.5
	garden.show_pennants = celebrate
	garden.rotation.y = PI
	view.add_child(garden)

	if show_golden_ball:
		# Drawing the pickup here prepares the material shared by the glowing goals.
		var ball := MeshInstance3D.new()
		ball.mesh = GOLDEN_BALL
		var portrait_material := GOLDEN_BALL.material.duplicate() as StandardMaterial3D
		portrait_material.emission_energy_multiplier = 0.35
		ball.material_override = portrait_material
		ball.position = Vector3(-0.56, 0.16, -0.27)
		ball.scale = Vector3.ONE * 0.52
		view.add_child(ball)

	_camiel = CAMIEL.instantiate() as Node3D
	view.add_child(_camiel)
	_animation = _camiel.get_node("AnimationPlayer") as AnimationPlayer
	_animation.get_animation(&"idle").loop_mode = Animation.LOOP_LINEAR
	_animation.play(&"idle")

	var camera := Camera3D.new()
	camera.fov = 52.0 if celebrate else 43.0
	camera.position = Vector3(1.02, 1.16, -2.46) if celebrate else Vector3(1.13, 1.09, -2.37)
	view.add_child(camera)
	camera.look_at(Vector3(0.0, 0.62 if celebrate else 0.60, -0.06))
	camera.current = true


func play_cheer() -> void:
	if _camiel == null:
		return
	var hops := _camiel.create_tween().set_trans(Tween.TRANS_SINE)
	for height: float in [0.27, 0.18]:
		hops.tween_callback(_start_cheer_hop)
		hops.tween_property(_camiel, "position:y", height, 0.25).set_ease(Tween.EASE_OUT)
		hops.tween_property(_camiel, "position:y", 0.0, 0.29).set_ease(Tween.EASE_IN)
		hops.tween_callback(_animation.play.bind(&"idle", 0.14))
		hops.tween_interval(0.14)


func _start_cheer_hop() -> void:
	_animation.play(&"jump", 0.10)
