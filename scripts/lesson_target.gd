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

@export var task_id: String = ""
@export var target_color: Color = Color.WHITE
@export_enum("cylinder", "box", "prism", "sphere") var shape_kind: String = "cylinder"
@export var display_text: String = ""
@export var requires_activation: bool = false

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label

var _touched := false
var _active := true
var _feedback_tween: Tween
var _material: StandardMaterial3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_active = not requires_activation
	_build_mesh()
	_label.text = display_text
	_label.visible = not display_text.is_empty()
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
	_apply_visual_state()


func _check_already_overlapping() -> void:
	if _touched:
		return
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("player"):
			_apply_touch()
			return


func _apply_touch() -> void:
	_touched = true
	if requires_activation:
		_active = false
	_play_completion_feedback()
	task_completed.emit(task_id)


func _build_mesh() -> void:
	var mesh: Mesh
	match shape_kind:
		"box":
			var box := BoxMesh.new()
			box.size = Vector3.ONE * 0.6
			mesh = box
		"prism":
			var prism := PrismMesh.new()
			prism.size = Vector3.ONE * 0.6
			mesh = prism
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.25
			sphere.height = 0.5
			mesh = sphere
		_:
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.3
			cylinder.bottom_radius = 0.3
			cylinder.height = 0.25
			mesh = cylinder
	_mesh.mesh = mesh
	_material = StandardMaterial3D.new()
	_material.emission_enabled = true
	_mesh.set_surface_override_material(0, _material)


## Full colour with a brighter glow while this is the child's turn (or the
# target never required a turn at all); the same hue desaturated toward
## grey with a dim glow while it is not. Never a different hue -- two of the
## five lessons are colour-recognition tasks, and recolouring a target would
## teach the wrong thing.
func _apply_visual_state() -> void:
	if _material == null:
		return
	if _active:
		_material.albedo_color = target_color
		_material.emission = target_color
		_material.emission_energy_multiplier = 1.5
	else:
		var dimmed := target_color.lerp(Color(0.5, 0.5, 0.5), 0.6)
		_material.albedo_color = dimmed
		_material.emission = dimmed
		_material.emission_energy_multiplier = 0.3


func _play_completion_feedback() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_material.emission_energy_multiplier = 0.3
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_mesh, "scale", Vector3.ONE * 1.15, 0.15)
	_feedback_tween.tween_property(_mesh, "scale", Vector3.ONE * 0.85, 0.15)


func _play_rejection_feedback() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_mesh, "scale", Vector3.ONE * 0.92, 0.15)
	_feedback_tween.tween_property(_mesh, "scale", Vector3.ONE, 0.15)
