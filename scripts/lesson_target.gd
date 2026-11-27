# lesson_target.gd
# The one parametrized lesson target every one of the five lessons instances
# (D-45): identity, colour, shape, display text and whether the target must
# be activated before it can be completed are all exported values, so no
# lesson needs a script per shape. The one-shot latch plus player-group
# guard follow the shipped collectible's pattern (scripts/collectible.gd).
# The activation gate is deliberately structural, not a counter an
# orchestrator promises to consult (D-37) -- an inactive target has no code
# path that reaches task_completed; it can only emit rejected (D-38).
extends Area3D

signal task_completed(task_id: String)
signal rejected

const LESSON_CATALOG := preload("res://scripts/lesson_catalog.gd")
const LESSON_PAINT := preload("res://assets/materials/lesson_paint.gdshader")
const GOAL_SIGN := preload("res://scripts/world/lesson_goal_sign.gd")
const TOKEN_HEIGHT := 0.30
const PEDESTAL_TOP := -0.37
const COMPLETED_SCALE := 0.55

static var _check_mesh: ImmediateMesh
static var _rounded_block: ArrayMesh

@export var task_id: String = ""
@export var target_color: Color = Color.WHITE
@export_enum("cylinder", "box", "prism", "sphere") var shape_kind: String = "cylinder"
@export var display_text: String = ""
@export var requires_activation: bool = false
@export var painted := false

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label
@onready var _ring: MeshInstance3D = $GuideRing
@onready var _check: MeshInstance3D = $Check
@onready var _label_offset := _label.offset
@onready var _label_tint := _label.modulate
@onready var _label_outline := _label.outline_size

var _touched := false
var _active := true
var _feedback_tween: Tween
var _guidance_tween: Tween
var _material: Material
var _goal_sign: MeshInstance3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_active = not requires_activation
	_build_mesh()
	_check.mesh = _build_check()
	_label.text = display_text
	if requires_activation:
		_goal_sign = MeshInstance3D.new()
		_goal_sign.name = "GoalSign"
		_goal_sign.mesh = GOAL_SIGN.face(shape_kind, get_count_pips())
		_goal_sign.position = _label.position
		_goal_sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_goal_sign)
	_apply_visual_state()


func _on_body_entered(body: Node3D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	if requires_activation and not _active:
		_play_rejection_feedback()
		rejected.emit()
		return
	# Area3D forbids toggling its own monitoring synchronously inside this
	# callback since the callback still holds the physics lock, so the whole
	# reaction is deferred as one step, exactly as the shipped collectible.
	_apply_touch.call_deferred()


## Whether this target currently accepts a completing touch. Public so an
## orchestrator or a probe never reads the private latch/active fields --
## the archived sequence lesson reached into a private member across
## scripts and that is a recorded defect.
func is_active() -> bool:
	return _active


## Draws attention to the goal that is still reachable after a wrong turn.
func emphasize_active() -> void:
	if not _ring.visible or (_guidance_tween != null and _guidance_tween.is_running()):
		return
	_guidance_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_guidance_tween.tween_property(_ring, "scale", Vector3.ONE * 1.4, 0.23)
	_guidance_tween.tween_property(_ring, "scale", Vector3.ONE, 0.38)
	_guidance_tween.tween_property(_ring, "scale", Vector3.ONE * 1.25, 0.23)
	_guidance_tween.tween_property(_ring, "scale", Vector3.ONE, 0.38)


func get_count_pips() -> PackedVector2Array:
	if shape_kind != "cylinder" or not display_text.is_valid_int():
		return PackedVector2Array()
	return LESSON_CATALOG.count_pips(display_text.to_int())


## Marks this target as the child's current turn. Also defers a check for a
## body already standing inside the area: an Area3D never re-fires
## body_entered for a body that never left, so without this check a child
## who touched the wrong target and stayed on it would be soft-locked the
## moment it became their turn. Deferred because activate() is itself
## reached from another target's deferred touch reaction, and asking an
## area about its overlapping bodies is only safe outside the physics
## callback.
func activate() -> void:
	_active = true
	_apply_visual_state()
	_check_already_overlapping.call_deferred()


## Marks this target as not the child's current turn. A touch while
## deactivated rejects rather than completes.
func deactivate() -> void:
	_active = false
	_apply_visual_state()


## Restores this target to its just-readied state: latch cleared, active
## flag returned to the negation of requires_activation, mesh scale and
## material reset. Kills any in-flight tween first -- a reset landing
## mid-feedback would otherwise let a queued tween step fire afterwards and
## leave the target re-armed but visually finished.
func reset() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_touched = false
	_active = not requires_activation
	_mesh.scale = Vector3.ONE
	_mesh.position.y = _mesh_center_y(1.0)
	_check.scale = Vector3.ONE
	_apply_visual_state()


func _check_already_overlapping() -> void:
	if _touched or not _active:
		return
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			_apply_touch()
			return


func _apply_touch() -> void:
	if _touched or (requires_activation and not _active):
		return
	_touched = true
	if requires_activation:
		_active = false
	_apply_visual_state()
	_play_completion_feedback()
	task_completed.emit(task_id)


func _build_mesh() -> void:
	var mesh: Mesh
	match shape_kind:
		"box":
			if painted:
				mesh = _build_rounded_block()
			else:
				var box := BoxMesh.new()
				box.size = Vector3.ONE * 0.69
				mesh = box
		"prism":
			var prism := PrismMesh.new()
			prism.size = Vector3(0.74, 0.73, 0.64)
			mesh = prism
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.29
			sphere.height = 0.58
			mesh = sphere
		_:
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.36
			cylinder.bottom_radius = 0.37
			cylinder.height = TOKEN_HEIGHT
			mesh = cylinder
	_mesh.mesh = mesh
	_mesh.position.y = _mesh_center_y(1.0)
	if painted:
		var paint := ShaderMaterial.new()
		paint.shader = LESSON_PAINT
		_material = paint
	else:
		var surface := StandardMaterial3D.new()
		surface.emission_enabled = true
		surface.roughness = 0.78
		_material = surface
	_mesh.set_surface_override_material(0, _material)
	_add_count_pips()


static func _build_rounded_block() -> ArrayMesh:
	if _rounded_block != null:
		return _rounded_block
	const HALF := 0.38
	const RADIUS := 0.09
	const INNER := HALF - RADIUS
	var box := BoxMesh.new()
	box.size = Vector3.ONE * (HALF * 2.0)
	box.subdivide_width = 5
	box.subdivide_height = 5
	box.subdivide_depth = 5
	var arrays := box.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var profile := PackedFloat32Array([-HALF, -HALF + RADIUS * 0.5, -INNER, 0.0, INNER, HALF - RADIUS * 0.5, HALF])
	var inner_corner := Vector3.ONE * INNER
	for i in vertices.size():
		# Put most of the subdivision rings around the rim instead of on the flat face.
		var index := ((vertices[i] + Vector3.ONE * HALF) * (3.0 / HALF)).round()
		var point := Vector3(profile[int(index.x)], profile[int(index.y)], profile[int(index.z)])
		var center := point.clamp(-inner_corner, inner_corner)
		normals[i] = (point - center).normalized()
		vertices[i] = center + normals[i] * RADIUS
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = null
	_rounded_block = ArrayMesh.new()
	_rounded_block.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _rounded_block


func _mesh_center_y(scale_factor: float) -> float:
	return PEDESTAL_TOP - _mesh.mesh.get_aabb().position.y * scale_factor


func _add_count_pips() -> void:
	var pips := get_count_pips()
	if pips.is_empty():
		return
	var rim := _pip_disk(0.086, Color("#244638"))
	var dot := _pip_disk(0.064, Color("#fff6e2"))
	for pip: Vector2 in pips:
		var at := Vector3(pip.x * 0.136, TOKEN_HEIGHT * 0.5 + 0.006, pip.y * 0.136)
		var inset := MeshInstance3D.new()
		inset.mesh = rim
		inset.position = at
		inset.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(inset)
		var top := MeshInstance3D.new()
		top.mesh = dot
		top.position = at + Vector3.UP * 0.008
		top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.add_child(top)


func _pip_disk(radius: float, color: Color) -> CylinderMesh:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true
	var disk := CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius
	disk.height = 0.012
	disk.radial_segments = 16
	disk.material = material
	return disk


static func _build_check() -> ImmediateMesh:
	if _check_mesh != null:
		return _check_mesh
	var base := StandardMaterial3D.new()
	base.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	base.billboard_keep_scale = true
	base.cull_mode = BaseMaterial3D.CULL_DISABLED
	base.albedo_color = Color("#254c3c")
	var fill := base.duplicate() as StandardMaterial3D
	fill.albedo_color = Color("#fff5d8")
	_check_mesh = ImmediateMesh.new()
	_check_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, base)
	for index in 28:
		_check_mesh.surface_add_vertex(Vector3.ZERO)
		for angle: float in [TAU * index / 28.0, TAU * (index + 1) / 28.0]:
			_check_mesh.surface_add_vertex(Vector3(0.253 * cos(angle), 0.253 * sin(angle), 0.0))
	_check_mesh.surface_end()
	var tick := PackedVector2Array([
		Vector2(-0.154, -0.004), Vector2(-0.105, 0.051), Vector2(-0.041, -0.012),
		Vector2(0.112, 0.126), Vector2(0.160, 0.074), Vector2(-0.040, -0.111),
	])
	_check_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, fill)
	for vertex in Geometry2D.triangulate_polygon(tick):
		var point := tick[vertex]
		_check_mesh.surface_add_vertex(Vector3(point.x, point.y, 0.012))
	_check_mesh.surface_end()
	return _check_mesh


## Updates the on-field markers and keeps feedback within the target's hue.
func _apply_visual_state() -> void:
	if _material == null:
		return
	_ring.visible = _active and not _touched
	_check.visible = _touched
	_label.visible = not _touched and not display_text.is_empty()
	if _goal_sign != null:
		_goal_sign.visible = _ring.visible
		_label.offset = Vector2(GOAL_SIGN.DIGIT_X / _label.pixel_size, _label_offset.y) if _goal_sign.visible else _label_offset
		_label.modulate = GOAL_SIGN.INK if _goal_sign.visible else _label_tint
		_label.outline_size = 0 if _goal_sign.visible else _label_outline
	if _guidance_tween != null and not _ring.visible:
		_guidance_tween.kill()
		_ring.scale = Vector3.ONE
	var color := target_color if _active else target_color.lerp(Color(0.5, 0.5, 0.5), 0.6)
	if _material is ShaderMaterial:
		_material.set_shader_parameter("pigment", color)
		_material.set_shader_parameter("completed", _touched)
	else:
		_material.albedo_color = color
		_material.emission = color
		_material.emission_energy_multiplier = 0.14 if _active else 0.08


func _play_completion_feedback() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	if _material is StandardMaterial3D:
		_material.emission_energy_multiplier = 0.08
	_check.scale = Vector3.ONE * 0.58
	_feedback_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Keep Camiel visible while the completed goal settles onto its pedestal.
	_feedback_tween.tween_property(_mesh, "scale", Vector3.ONE * COMPLETED_SCALE, 0.22)
	_feedback_tween.parallel().tween_property(_mesh, "position:y", _mesh_center_y(COMPLETED_SCALE), 0.22)
	_feedback_tween.parallel().tween_property(_check, "scale", Vector3.ONE * 1.08, 0.22)
	_feedback_tween.tween_property(_check, "scale", Vector3.ONE * 0.88, 0.16)


func _play_rejection_feedback() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_mesh, "scale", Vector3.ONE * 0.92, 0.15)
	_feedback_tween.tween_property(_mesh, "scale", Vector3.ONE, 0.15)
