# verify_3d_project.gd
# Headless --script verifier: confirms the main scene loads as a Node3D and
# every tracked .gd/.tscn resource under res:// loads and instantiates cleanly.
extends SceneTree

var _script_count := 0
var _scene_count := 0


func _initialize() -> void:
	if not _check_main_scene():
		quit(1)
		return

	if not _check_resources():
		quit(1)
		return

	print("3D project verified: %d scripts, %d scenes." % [_script_count, _scene_count])
	quit(0)


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

	if not instance is Node3D:
		push_error("Main scene root is not a Node3D: %s" % main_scene_path)
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
