# collectible.gd
# The intro level's one collectible (D-18, D-19): a floating, slowly
# spinning, gently bobbing sphere with an Area3D trigger. Emits `collected`
# exactly once via a one-shot latch plus a player-group guard, and plays no
# sound of its own — the archived pair (a collectible with its own unset
# AudioStreamPlayer, plus a heads-up display separately playing the same
# event) is the recorded cause of "collect sound plays twice or not at all"
# (CONCERNS.md). One listener, intro_level.gd, decides what the signal
# means; this script only emits it.
extends Area3D

signal collected

@export var spin_speed_degrees := 30.0
@export var bob_amplitude := 0.1
@export var bob_period := 2.0

@onready var _mesh: MeshInstance3D = $Mesh

var _touched := false
var _rest_height := 0.0
var _elapsed := 0.0
var _pickup_tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_rest_height = _mesh.position.y


func _process(delta: float) -> void:
	if _touched:
		return

	_elapsed += delta
	# Spin and bob move the mesh child only, never the area itself, so the
	# trigger volume stays put while the object appears to float.
	_mesh.rotate_y(deg_to_rad(spin_speed_degrees * delta))
	_mesh.position.y = _rest_height + sin(_elapsed * TAU / bob_period) * bob_amplitude


func _on_body_entered(body: Node3D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	_touched = true
	# Area3D forbids toggling monitoring synchronously from inside its own
	# body-entered callback ("Function blocked during in/out signal") since
	# the callback still holds the physics engine's lock, so the whole
	# reaction — monitoring = false, the pickup feedback, and the collected
	# signal itself — is deferred together as one atomic step.
	_apply_pickup.call_deferred()


func _apply_pickup() -> void:
	# Switching monitoring off and hiding, rather than queue_free()-ing this
	# node, is what makes the D-28 in-place replay possible without
	# re-instancing the scene.
	monitoring = false
	_play_pickup_feedback()
	collected.emit()


func _play_pickup_feedback() -> void:
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(_mesh, "scale", Vector3.ONE * 1.15, 0.15)
	_pickup_tween.tween_property(_mesh, "transparency", 1.0, 0.15)
	_pickup_tween.tween_callback(hide)


## Clears the one-shot latch and restores the mesh to its pre-pickup state
## so a replayed lap meets the collectible exactly as it first appeared.
## Kills any in-flight pickup tween first -- otherwise a replay during the
## ~0.3s pickup-feedback window would let the tween's own queued
## tween_callback(hide) fire after this reset's show(), leaving the
## collectible re-armed but permanently invisible (WR-01).
func reset() -> void:
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	_touched = false
	_elapsed = 0.0
	_mesh.scale = Vector3.ONE
	_mesh.transparency = 0.0
	_mesh.position.y = _rest_height
	monitoring = true
	show()
