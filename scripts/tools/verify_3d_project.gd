# verify_3d_project.gd
# Headless --script verifier: confirms the main scene loads and instantiates,
# confirms the gameplay scene (D-27) loads as a Node3D, and every tracked
# .gd/.tscn resource under res:// loads and instantiates cleanly.
extends SceneTree

# D-27: the main scene became the Control-rooted title screen in Phase 2, so
# the Node3D-root assertion retargets here rather than being satisfied by
# wrapping the title UI in a throwaway Node3D shell (explicitly rejected —
# that would make this check pass without checking anything real).
const GAMEPLAY_SCENE_PATH := "res://scenes/intro_level.tscn"

var _script_count := 0
var _scene_count := 0


func _initialize() -> void:
	if not _check_engine_version():
		quit(1)
		return

	if not _check_renderer():
		quit(1)
		return

	if not _check_physics_engine():
		quit(1)
		return

	if not _check_main_scene():
		quit(1)
		return

	if not _check_gameplay_scene_is_3d():
		quit(1)
		return

	if not _check_resources():
		quit(1)
		return

	print("3D project verified: %d scripts, %d scenes, gameplay scene %s." % [_script_count, _scene_count, GAMEPLAY_SCENE_PATH])
	quit(0)


func _check_engine_version() -> bool:
	var info := Engine.get_version_info()
	var major: int = info.get("major", 0)
	var minor: int = info.get("minor", 0)
	var patch: int = info.get("patch", 0)
	var status: String = info.get("status", "")

	if major != 4 or minor != 7 or patch != 2 or status != "stable":
		push_error("Godot 4.7.2-stable required (D-02), running %d.%d.%d-%s" % [major, minor, patch, status])
		return false

	return true


func _check_renderer() -> bool:
	var found_property := false

	for property: Dictionary in ProjectSettings.get_property_list():
		var property_name: String = property.get("name", "")
		if not property_name.begins_with("rendering/renderer/rendering_method"):
			continue

		found_property = true
		var value: String = ProjectSettings.get_setting(property_name, "")
		var hint_string: String = property.get("hint_string", "")
		var hint_values: PackedStringArray = hint_string.split(",")

		if value != "gl_compatibility":
			push_error("%s must be gl_compatibility (D-04), found: %s" % [property_name, value])
			return false

		if not hint_values.has("gl_compatibility"):
			push_error("%s does not offer gl_compatibility (D-04): %s" % [property_name, hint_string])
			return false

	if not found_property:
		push_error("No rendering/renderer/rendering_method property found (D-04).")
		return false

	return true


func _check_physics_engine() -> bool:
	var property_name := "physics/3d/physics_engine"
	var value: String = ProjectSettings.get_setting(property_name, "DEFAULT")

	if value == "DEFAULT":
		push_error("%s must not be DEFAULT; a Jolt entry is required (D-04)." % property_name)
		return false

	var hint_string := ""
	for property: Dictionary in ProjectSettings.get_property_list():
		if property.get("name", "") == property_name:
			hint_string = property.get("hint_string", "")
			break

	var hint_values: PackedStringArray = hint_string.split(",")
	if not hint_values.has(value):
		push_error("%s value is not one of the engine's own options (D-04): %s not in %s" % [property_name, value, hint_string])
		return false

	if not value.to_lower().contains("jolt"):
		push_error("%s must be a Jolt entry (D-04), found: %s" % [property_name, value])
		return false

	return true


func _check_main_scene() -> bool:
	var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene_path.is_empty():
		push_error("application/run/main_scene is not set.")
		return false

	if not ResourceLoader.exists(main_scene_path):
		push_error("Main scene does not exist: %s" % main_scene_path)
		return false

	var packed: PackedScene = load(main_scene_path)
	if packed == null:
		push_error("Main scene did not load as a PackedScene: %s" % main_scene_path)
		return false

	var instance := packed.instantiate()
	if instance == null:
		push_error("Main scene failed to instantiate: %s" % main_scene_path)
		return false

	# No Node3D-root assertion here (D-27): the main scene is now the
	# Control-rooted title screen. Whether the project is genuinely 3D is
	# proved by _check_gameplay_scene_is_3d() against a named gameplay scene
	# instead — this function still proves the main scene loads and
	# instantiates cleanly.
	instance.free()
	return true


func _check_gameplay_scene_is_3d() -> bool:
	if not ResourceLoader.exists(GAMEPLAY_SCENE_PATH):
		push_error("Gameplay scene does not exist: %s" % GAMEPLAY_SCENE_PATH)
		return false

	var packed: PackedScene = load(GAMEPLAY_SCENE_PATH)
	if packed == null:
		push_error("Gameplay scene did not load as a PackedScene: %s" % GAMEPLAY_SCENE_PATH)
		return false

	var instance := packed.instantiate()
	if instance == null:
		push_error("Gameplay scene failed to instantiate: %s" % GAMEPLAY_SCENE_PATH)
		return false

	if not instance is Node3D:
		push_error("Gameplay scene root is not a Node3D: %s" % GAMEPLAY_SCENE_PATH)
		instance.free()
		return false

	instance.free()
	return true


func _collect_paths(dir_path: String, extension: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not (entry == "builds" or entry == "dist" or entry == "tmp"):
				_collect_paths(full_path, extension, out)
		elif entry.ends_with(extension):
			out.append(full_path)

		entry = dir.get_next()
	dir.list_dir_end()


func _check_resources() -> bool:
	var gd_paths := PackedStringArray()
	var tscn_paths := PackedStringArray()
	_collect_paths("res://", ".gd", gd_paths)
	_collect_paths("res://", ".tscn", tscn_paths)

	var gd_list := Array(gd_paths)
	gd_list.sort()
	var tscn_list := Array(tscn_paths)
	tscn_list.sort()

	if gd_list.is_empty():
		push_error("No .gd files found under res://.")
		return false

	if tscn_list.is_empty():
		push_error("No .tscn files found under res://.")
		return false

	for gd_path: String in gd_list:
		var script: GDScript = load(gd_path)
		if script == null or not script.can_instantiate():
			push_error("GDScript failed to load or cannot instantiate: %s" % gd_path)
			return false

	for tscn_path: String in tscn_list:
		var packed: PackedScene = load(tscn_path)
		if packed == null or not packed.can_instantiate():
			push_error("Scene failed to load or cannot instantiate: %s" % tscn_path)
			return false
		var instance := packed.instantiate()
		if instance == null:
			push_error("Scene instantiate() returned null: %s" % tscn_path)
			return false
		instance.free()

	_script_count = gd_list.size()
	_scene_count = tscn_list.size()
	return true
