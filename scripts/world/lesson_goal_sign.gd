extends RefCounted
## Shared geometry for matching the active 3D goal to its lesson pictogram.

const INK := Color("#234638")
const PAPER := Color("#fff1c8")
const DIGIT_X := -0.26

static var _faces: Dictionary[String, ImmediateMesh] = {}
static var _ink: StandardMaterial3D
static var _paper: StandardMaterial3D


static func face(shape: String, pips: PackedVector2Array) -> ImmediateMesh:
	# Each count uses the same dot arrangement from the lesson catalog.
	var numbered := not pips.is_empty()
	var key := str(pips.size()) if numbered else shape
	if _faces.has(key):
		return _faces[key]
	if _ink == null:
		_ink = _billboard(INK)
		_paper = _billboard(PAPER)

	var stretch := 0.235 if numbered else 0.0
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _ink)
	_add_disc(mesh, Vector2.ZERO, 0.285, -0.024, stretch)
	_add_triangle(mesh, Vector2(-0.094, -0.254), Vector2(0.094, -0.254), Vector2(0, -0.391), -0.024)
	mesh.surface_end()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _paper)
	_add_disc(mesh, Vector2.ZERO, 0.247, -0.012, stretch)
	mesh.surface_end()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _ink)
	if numbered:
		for pip: Vector2 in pips:
			# The catalog uses screen coordinates and the sign's Y axis points up.
			var position := Vector2(0.23, 0) + Vector2(pip.x, -pip.y) * 0.133
			_add_disc(mesh, position, 0.064, 0)
	else:
		match shape:
			"box":
				_add_triangle(mesh, Vector2(-0.14, 0.14), Vector2(0.14, 0.14), Vector2(0.14, -0.14), 0)
				_add_triangle(mesh, Vector2(-0.14, 0.14), Vector2(0.14, -0.14), Vector2(-0.14, -0.14), 0)
			"prism":
				_add_triangle(mesh, Vector2(0, 0.168), Vector2(0.167, -0.126), Vector2(-0.167, -0.126), 0)
			_:
				_add_disc(mesh, Vector2.ZERO, 0.146, 0)
	mesh.surface_end()
	_faces[key] = mesh
	return mesh


static func _billboard(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_fog = true
	return material


static func _add_disc(mesh: ImmediateMesh, center: Vector2, radius: float, z: float, stretch := 0.0) -> void:
	const SEGMENTS := 24
	for index in SEGMENTS:
		var first := Vector2.from_angle(TAU * index / SEGMENTS) * radius
		var next := Vector2.from_angle(TAU * (index + 1) / SEGMENTS) * radius
		first.x += signf(first.x) * stretch
		next.x += signf(next.x) * stretch
		_add_triangle(mesh, center, center + first, center + next, z)


static func _add_triangle(mesh: ImmediateMesh, a: Vector2, b: Vector2, c: Vector2, z: float) -> void:
	mesh.surface_add_vertex(Vector3(a.x, a.y, z))
	mesh.surface_add_vertex(Vector3(b.x, b.y, z))
	mesh.surface_add_vertex(Vector3(c.x, c.y, z))
