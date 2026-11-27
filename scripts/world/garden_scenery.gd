extends Node3D
## Native garden scenery shared by the intro, lesson rooms and title portrait.
## Decoration has no collision. The scene's authored play boundaries stay in place.

const MEADOW := preload("res://assets/materials/ground.tres")
const SCREEN_ANTIALIAS := preload("res://assets/materials/screen_antialias.gdshader")
const CANOPIES: Array[Color] = [
	Color("#608c4f"), Color("#769758"), Color("#58856a"), Color("#5d9467"),
	Color("#83994e"), Color("#5f8980"), Color("#738f58"),
]

@export var half_extent := 6.0
@export_range(0, 6) var chapter := 0
@export var show_fence := true
@export var show_trail := false
@export var show_pennants := false
@export var north_gate_opening := Vector2.ZERO

var _random := RandomNumberGenerator.new()
var _meshes: Dictionary[StringName, Mesh] = {}
var _placements: Dictionary[StringName, Array] = {}


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_random.seed = 6871 + chapter * 307
	_light_garden()
	_meadow()
	_prepare_meshes()
	_plant_orchard()
	if show_fence:
		_build_fence()
		_decorate_chapter()
	else:
		_plant_portrait_garden()
		if show_pennants:
			_hang_pennants()
	if show_trail:
		_lay_trail()
	_flush_meshes()


func _light_garden() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#82bdcf")
	sky_material.sky_horizon_color = Color("#e8ecd1")
	sky_material.ground_bottom_color = Color("#96b789")
	sky_material.ground_horizon_color = Color("#e8ecd1")
	sky_material.sun_angle_max = 18.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#f3f5e4")
	environment.ambient_light_energy = 0.46
	environment.fog_enabled = true
	environment.fog_light_color = Color("#dce7c9")
	environment.fog_density = 0.016
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-56.0, -31.0, 0.0)
	sun.light_color = Color("#fff1d2")
	sun.light_energy = 0.56
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.74
	sun.directional_shadow_max_distance = 36.0
	var software_browser: bool = (
		OS.has_feature("web")
		and JavaScriptBridge.get_interface("window").camielSoftwareRendering == true
	)
	if software_browser:
		RenderingServer.directional_shadow_atlas_set_size(1024, true)
	if software_browser or RenderingServer.get_video_adapter_name().contains("llvmpipe"):
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		_use_screen_antialias()
	add_child(sun)


func _use_screen_antialias() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	var material := ShaderMaterial.new()
	material.shader = SCREEN_ANTIALIAS

	# Smooth the garden image before the text and controls are drawn.
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var surface := ColorRect.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.material = material
	layer.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _meadow() -> void:
	var meadow := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(102.0, 102.0)
	plane.material = MEADOW
	meadow.mesh = plane
	meadow.position.y = -0.035 if show_fence else 0.0
	add_child(meadow)


func _prepare_meshes() -> void:
	var leaf_color := CANOPIES[chapter]
	_register(&"canopy", _rounded_mesh(), leaf_color)
	_register(&"sunny_leaf", _rounded_mesh(), leaf_color.lightened(0.22))
	_register(&"hill", _rounded_mesh(), leaf_color.lightened(0.36))
	_register(&"shrub", _rounded_mesh(), leaf_color.darkened(0.10))
	_register(&"stone", _rounded_mesh(), Color("#a5a68d"))
	_register(&"lilac", _rounded_mesh(), Color("#bd93b8"))
	_register(&"flower", _rounded_mesh(), Color("#f7d68f"))
	_register(&"cream", _rounded_mesh(), Color("#fff0cf"))
	_register(&"bark", _cylinder(0.33, 0.5), Color("#856348"))
	_register(&"paving", _cylinder(0.44, 0.5), Color("#bd986f"))
	_register(&"paving_light", _cylinder(0.44, 0.5), Color("#d4ae83"))
	_register(&"rail", BoxMesh.new(), Color("#ad8260"))
	_register(&"post", BoxMesh.new(), Color("#c49f74"))


func _plant_orchard() -> void:
	var radius := half_extent
	for index in range(13):
		var x := lerpf(-24.0, 24.0, index / 12.0)
		var z := -radius - _random.randf_range(14.0, 23.0)
		_stamp(&"hill", Vector3(x, -1.0, z), Vector3(8.5, _random.randf_range(5.5, 9.5), 7.0))
	var grove_edge := radius + (4.8 if show_fence and chapter > 0 else 2.0)
	for row in range(2):
		for index in range(12):
			var x := -18.0 + index * 3.25 + _random.randf_range(-0.74, 0.74)
			var z := -grove_edge - row * 4.0 - _random.randf_range(0.0, 2.4)
			_tree(Vector3(x, 0.0, z), _random.randf_range(0.85, 1.55))
	for side: float in [-1.0, 1.0]:
		for index in range(7):
			var x := side * (radius + _random.randf_range(2.4, 5.2))
			var z := lerpf(-radius, radius - 1.8, index / 6.0)
			_tree(Vector3(x, 0, z), _random.randf_range(0.8, 1.28))
		for index in range(16):
			var z := _random.randf_range(-radius + 0.55, radius - 1.1)
			var x := side * (radius - _random.randf_range(0.38, 0.73))
			_border_plant(Vector3(x, 0, z))
	for index in range(15):
		var x := _random.randf_range(-radius + 0.85, radius - 0.85)
		_border_plant(Vector3(x, 0, -radius + _random.randf_range(0.35, 0.64)))


func _tree(at: Vector3, size: float) -> void:
	_stamp(&"bark", at + Vector3(0, 0.93, 0) * size, Vector3(0.3, 1.86, 0.31) * size)
	_stamp(&"canopy", at + Vector3(0, 2.03, 0) * size, Vector3(2.2, 1.95, 1.78) * size, 0.45)
	_stamp(&"sunny_leaf", at + Vector3(-0.49, 2.55, 0.1) * size, Vector3(1.36, 1.40, 1.26) * size)
	_stamp(&"canopy", at + Vector3(0.59, 2.14, 0.42) * size, Vector3(1.44, 1.30, 1.25) * size)


func _plant_portrait_garden() -> void:
	_tree(Vector3(-2.2, 0.0, -2.0), 0.86)
	_tree(Vector3(2.4, 0.0, -2.6), 1.16)
	_tree(Vector3(-0.2, 0.0, -5.0), 0.98)
	for plant: Vector3 in [
		Vector3(0.95, 0, 0.42), Vector3(1.20, 0, 0.12), Vector3(-1.06, 0, -0.3),
		Vector3(-1.56, 0, -0.48), Vector3(0.86, 0, -0.96), Vector3(-0.5, 0, -1.53),
	]:
		_border_plant(plant)


func _hang_pennants() -> void:
	var colors: Array[Color] = [Color("#e0a239"), Color("#53978b"), Color("#cc705f")]
	var flags: Array[StringName] = [&"flag_gold", &"flag_green", &"flag_red"]
	for index in flags.size():
		_register(flags[index], PrismMesh.new(), colors[index])
	var depth := -1.60
	for side: float in [-1.0, 1.0]:
		_stamp(&"post", Vector3(side * 1.75, 0.97, depth), Vector3(0.095, 1.94, 0.10))
	for index in range(10):
		var left := _pennant_line(lerpf(-1.75, 1.75, index / 10.0), depth)
		var right := _pennant_line(lerpf(-1.75, 1.75, (index + 1) / 10.0), depth)
		var segment := right - left
		_stamp(&"rail", (left + right) * 0.5, Vector3(segment.length() + 0.04, 0.026, 0.026),
			0.0, 0.0, atan2(segment.y, segment.x))
		var flag := (left + right) * 0.5 + Vector3(0, -0.146, 0.012)
		_stamp(flags[index % flags.size()], flag, Vector3(0.245, 0.29, 0.045), 0.0, PI)


func _pennant_line(x: float, z: float) -> Vector3:
	return Vector3(x, 1.56 + 0.107 * x * x, z)


func _border_plant(at: Vector3) -> void:
	var shade: StringName = &"stone" if _random.randf() < 0.29 else &"shrub"
	var size := _random.randf_range(0.29, 0.58)
	_stamp(shade, at + Vector3.UP * size * 0.23, Vector3(size, size * 0.65, size * 0.72), _random.randf() * TAU)
	if shade == &"stone":
		return
	for index in range(3):
		var bloom: StringName = [&"cream", &"flower", &"lilac"][(chapter + index) % 3]
		var offset := Vector3(_random.randf_range(-0.23, 0.23), _random.randf_range(0.16, 0.29), _random.randf_range(-0.20, 0.20))
		_stamp(bloom, at + offset, Vector3(0.14, 0.08, 0.14))


func _build_fence() -> void:
	var span := 2.0 * half_extent
	var sections := maxi(1, roundi(span / 1.6))
	for side: float in [-1.0, 1.0]:
		var edge := half_extent * side
		if side < 0.0 and north_gate_opening.x < north_gate_opening.y:
			_fence_row(-half_extent, north_gate_opening.x, edge)
			_fence_row(north_gate_opening.y, half_extent, edge)
		else:
			_fence_row(-half_extent, half_extent, edge)
		for height: float in [0.36, 0.72]:
			_stamp(&"rail", Vector3(edge, height, 0), Vector3(0.12, 0.16, span))
		for index in range(1, sections):
			var offset := lerpf(-half_extent, half_extent, float(index) / sections)
			_stamp(&"post", Vector3(edge, 0.48, offset), Vector3(0.21, 0.96, 0.21))


func _fence_row(start_x: float, end_x: float, z: float) -> void:
	var span := end_x - start_x
	var sections := maxi(1, roundi(span / 1.6))
	for height: float in [0.36, 0.72]:
		_stamp(&"rail", Vector3((start_x + end_x) * 0.5, height, z), Vector3(span, 0.16, 0.12))
	for index in range(sections + 1):
		var x := lerpf(start_x, end_x, float(index) / sections)
		_stamp(&"post", Vector3(x, 0.48, z), Vector3(0.21, 0.96, 0.21))


func _decorate_chapter() -> void:
	# All six landmarks sit behind the north fence.
	var edge := -half_extent
	match chapter:
		1, 4:
			_plant_flower_beds(edge)
		2:
			_build_shape_pavilion(edge - 1.8)
		3:
			_grow_mushrooms(edge - 2.0)
		5:
			_build_pond(edge - 2.3)
		6:
			_plant_apple_trees(edge - 1.9)


func _plant_flower_beds(edge: float) -> void:
	var sunflowers := chapter == 4
	_register(&"soil", BoxMesh.new(), Color("#7d5741"))
	_register(&"stem", _cylinder(0.4, 0.5), Color("#467352"))
	_register(&"petal", _rounded_mesh(), Color("#edb334") if sunflowers else Color("#dc6166"))
	_register(&"blue_petal", _rounded_mesh(), Color("#698ed5"))
	_register(&"flower_center", _rounded_mesh(), Color("#82502d") if sunflowers else Color("#f4ca64"))
	for side: int in [-1, 1]:
		var bed := Vector3(2.35 * side, 0.0, edge - 1.54 - (0.32 if side == 1 else 0.0))
		_stamp(&"rail", bed + Vector3.UP * 0.30, Vector3(3.08, 0.60, 1.60))
		_stamp(&"soil", bed + Vector3.UP * 0.61, Vector3(2.85, 0.06, 1.36))
		for row in 2:
			for index in 4:
				var plant := bed + Vector3(-1.04 + index * 0.68 + row * 0.2, 0.64, 0.34 - row * 0.68)
				var height := (1.24 if sunflowers else 0.58) + row * 0.25 + float(index % 3) * 0.15
				var size := (0.34 if sunflowers else 0.23) + float((index + row) % 2) * 0.07
				var petal := &"petal" if sunflowers or side < 0 else &"blue_petal"
				_stamp_flower(plant, height, size, petal)


func _stamp_flower(base: Vector3, height: float, size: float, petal: StringName) -> void:
	_stamp(&"stem", base + Vector3.UP * height * 0.5, Vector3(0.095, height, 0.095))
	for side: int in [-1, 1]:
		var leaf := base + Vector3(side * 0.12, height * (0.40 + side * 0.1), 0.06)
		_stamp(&"sunny_leaf", leaf, Vector3(0.33, 0.12, 0.17), side * 0.34)
	var center := base + Vector3.UP * height
	for index in 8:
		var angle := TAU * index / 8.0
		var offset := Vector3(cos(angle), sin(angle), 0.0) * size * 0.58
		_stamp(petal, center + offset, Vector3(0.72, 0.72, 0.30) * size)
	_stamp(&"flower_center", center + Vector3.BACK * 0.07, Vector3(0.96, 0.96, 0.36) * size)


func _build_shape_pavilion(z: float) -> void:
	_register(&"roof", BoxMesh.new(), Color("#3d7969"))
	_register(&"circle_sign", _cylinder(0.5, 0.5), Color("#d37766"))
	_register(&"square_sign", BoxMesh.new(), Color("#749aca"))
	_register(&"triangle_sign", PrismMesh.new(), Color("#e4a344"))
	for x: float in [-2.7, 2.7]:
		for depth: float in [-0.7, 0.7]:
			_stamp(&"post", Vector3(x, 1.25, z + depth), Vector3(0.25, 2.50, 0.25))
	_stamp(&"rail", Vector3(0, 1.2, z), Vector3(5.2, 1.62, 0.21))
	_stamp(&"post", Vector3(0, 2.32, z), Vector3(5.74, 0.22, 1.84))
	_stamp(&"roof", Vector3(0, 2.58, z - 0.47), Vector3(5.95, 0.17, 1.08), 0.0, 0.25)
	_stamp(&"roof", Vector3(0, 2.58, z + 0.47), Vector3(5.95, 0.17, 1.08), 0.0, -0.25)
	_stamp(&"circle_sign", Vector3(-1.6, 1.49, z + 0.18), Vector3(1.0, 0.20, 1.0), 0.0, PI * 0.5)
	_stamp(&"square_sign", Vector3(0.0, 1.49, z + 0.18), Vector3(0.91, 0.91, 0.20))
	_stamp(&"triangle_sign", Vector3(1.6, 1.49, z + 0.18), Vector3(1.15, 1.04, 0.22))


func _grow_mushrooms(z: float) -> void:
	_register(&"cap", _rounded_mesh(), Color("#bd6252"))
	_register(&"gold_cap", _rounded_mesh(), Color("#d59557"))
	_register(&"mushroom_stem", _cylinder(0.39, 0.5), Color("#e7cda5"))
	for index in 5:
		var size := 1.12 + float(posmod(index * 3, 5)) * 0.18
		var base := Vector3(-3.2 + index * 1.58, 0.0, z - float(index % 2) * 0.7)
		var cap_height := 0.47 if index % 2 == 0 else 0.58
		_stamp(&"mushroom_stem", base + Vector3.UP * size * 0.49, Vector3(0.42, 0.98, 0.44) * size)
		var cap := base + Vector3.UP * size * 0.98
		_stamp(&"cap" if index % 2 == 0 else &"gold_cap", cap, Vector3(1.28, cap_height, 1.09) * size)
		for spot: Vector3 in [Vector3(-0.31, 0.20, 0.21), Vector3(0.09, 0.24, 0.19), Vector3(0.36, 0.15, 0.27)]:
			_stamp(&"cream", cap + spot * size, Vector3(0.25, 0.11, 0.23) * size)


func _build_pond(z: float) -> void:
	_register(&"pond_bank", _cylinder(0.5, 0.5), Color("#9ea99b"))
	_register(&"water", _cylinder(0.5, 0.5), Color("#559eab"))
	_register(&"lily_pad", _cylinder(0.5, 0.5), Color("#658f63"))
	_stamp(&"pond_bank", Vector3(0, 0.035, z), Vector3(8.26, 0.15, 3.75), 0.04)
	_stamp(&"water", Vector3(0, 0.12, z), Vector3(7.84, 0.09, 3.34), 0.04)
	for offset: Vector2 in [Vector2(-2.2, 0.76), Vector2(-1.7, 0.44), Vector2(1.8, 0.79), Vector2(2.4, -0.59)]:
		var pad := Vector3(offset.x, 0.18, z + offset.y)
		_stamp(&"lily_pad", pad, Vector3(0.62, 0.06, 0.46))
		_stamp(&"lilac", pad + Vector3.UP * 0.08, Vector3(0.24, 0.17, 0.23))
	for index in 13:
		var x := (index - 6) * 0.36
		var height := 1.03 - 0.16 * x * x
		_stamp(&"post", Vector3(x, height, z), Vector3(0.35, 0.13, 1.12))
		for depth: float in [-0.58, 0.58]:
			_stamp(&"rail", Vector3(x, height + 0.45, z + depth), Vector3(0.43, 0.12, 0.13))
			if index % 3 == 0:
				_stamp(&"post", Vector3(x, height + 0.25, z + depth), Vector3(0.12, 0.55, 0.12))


func _plant_apple_trees(z: float) -> void:
	_register(&"apple", _rounded_mesh(), Color("#ac514b"))
	_register(&"basket", _cylinder(0.5, 0.39), Color("#ab7551"))
	for side: int in [-1, 1]:
		var base := Vector3(2.16 * side, 0.0, z - (0.45 if side == 1 else 0.0))
		var size := 1.38 if side == -1 else 1.56
		_tree(base, size)
		for apple: Vector3 in [
			Vector3(-0.65, 1.86, 0.62), Vector3(-0.49, 2.62, 0.67), Vector3(-0.19, 2.16, 0.85),
			Vector3(0.27, 1.73, 0.95), Vector3(0.74, 2.16, 1.02), Vector3(0.52, 2.59, 0.64),
		]:
			_stamp(&"apple", base + apple * size, Vector3(0.32, 0.31, 0.30) * size)
		var basket := base + Vector3(-0.65 * side, 0.25, 1.05)
		_stamp(&"basket", basket, Vector3(1.0, 0.50, 0.82))
		for index in 6:
			var offset := Vector3(0.28 * cos(index * TAU / 6), 0.29, 0.22 * sin(index * TAU / 6))
			_stamp(&"apple", basket + offset, Vector3(0.32, 0.30, 0.3))


func _lay_trail() -> void:
	var turns := PackedVector2Array([
		Vector2(0, 4), Vector2(-0.15, 2.5), Vector2(-1.2, 0.9),
		Vector2(-2.5, -1.0), Vector2(-3.0, -2.8), Vector2(-4.5, -4.4), Vector2(-4.9, -5.7),
	])
	for segment in range(turns.size() - 1):
		for index in range(4):
			var point := turns[segment].lerp(turns[segment + 1], index / 4.0)
			var shade: StringName = &"paving_light" if (index + segment) % 3 == 0 else &"paving"
			var x := point.x + _random.randf_range(-0.18, 0.18)
			var width := _random.randf_range(0.63, 0.85)
			_stamp(shade, Vector3(x, 0.016, point.y), Vector3(width, 0.025, 0.34), _random.randf_range(-0.15, 0.15))


func _rounded_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return mesh


func _cylinder(top: float, bottom: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = 1.0
	mesh.radial_segments = 10
	mesh.rings = 1
	return mesh


func _register(kind: StringName, mesh: PrimitiveMesh, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material = material
	_meshes[kind] = mesh
	_placements[kind] = []


func _stamp(kind: StringName, at: Vector3, size: Vector3, yaw := 0.0, pitch := 0.0, roll := 0.0) -> void:
	var basis := Basis.from_euler(Vector3(pitch, yaw, roll)) * Basis.from_scale(size)
	_placements[kind].append(Transform3D(basis, at))


func _flush_meshes() -> void:
	for kind: StringName in _placements:
		var placements: Array = _placements[kind]
		if placements.is_empty():
			continue
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = _meshes[kind]
		batch.instance_count = placements.size()
		for index in placements.size():
			batch.set_instance_transform(index, placements[index])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = batch
		if kind == &"paving" or kind == &"paving_light":
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
