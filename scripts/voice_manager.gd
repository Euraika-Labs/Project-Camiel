# Offline Dutch narration. Playback never invokes OS TTS or a network service.
extends Node

signal cue_started(cue: String)
signal narration_stopped

const VOICE_BUS := "Voice"
const CATALOG_PATH := "res://assets/audio/speech_nl/catalog.json"
const AUDIO_DIRECTORY := "res://assets/audio/speech_nl/"
const SETTINGS_PATH := "user://voice.cfg"

var current_cue := ""
var _player: AudioStreamPlayer
var _bus := -1
var _queue: Array[String] = []
var _catalog: Dictionary = {}
var _owner: Node
var _generation := 0
var _played := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bus = AudioServer.get_bus_index(VOICE_BUS)
	if _bus < 0:
		push_error("[VoiceManager] Voice bus missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Dictionary:
		_catalog = parsed.get("clips", {})
	_player = AudioStreamPlayer.new()
	_player.name = "Narration"
	_player.bus = VOICE_BUS
	add_child(_player)
	_player.finished.connect(_on_finished)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		set_volume(float(config.get_value("voice", "volume", 0.8)), false)
	else:
		set_volume(0.8, false)


# Scene lifetime is the cancellation boundary, including queued/deferred cues.
func bind_scene(scene: Node, cue: String) -> void:
	stop()
	_owner = scene
	scene.tree_exiting.connect(_on_owner_exiting.bind(scene), CONNECT_ONE_SHOT)
	if scene.has_signal("transition_requested"):
		scene.connect("transition_requested", _on_transition)
	_connect_feedback(scene)
	_play_bound.call_deferred(scene, cue, _generation)


func _connect_feedback(node: Node) -> void:
	if node.has_signal("rejected"):
		node.connect("rejected", _on_rejected)
	for child: Node in node.get_children():
		_connect_feedback(child)


func _on_rejected() -> void:
	# Holding a wrong target cannot repeatedly restart the same sentence.
	if current_cue != "retry":
		play("retry")


func _play_bound(scene: Node, cue: String, generation: int) -> void:
	if generation == _generation and is_instance_valid(scene) and scene == _owner and scene.is_inside_tree():
		play(cue)


func _on_owner_exiting(scene: Node) -> void:
	if scene == _owner:
		stop()
		_owner = null


func _on_transition(_target: String) -> void:
	stop()


func has_cue(cue: String) -> bool:
	return _catalog.has(cue) and ResourceLoader.exists(AUDIO_DIRECTORY + cue + ".wav")


func play(cue: String) -> void:
	stop()
	_start(cue)


func enqueue(cue: String) -> void:
	if not has_cue(cue):
		push_warning("[VoiceManager] Missing cue: " + cue)
		return
	if is_playing():
		_queue.append(cue)
	else:
		_start(cue)


func stop() -> void:
	_generation += 1
	_queue.clear()
	current_cue = ""
	if _player != null:
		_player.stop()
	narration_stopped.emit()


func is_playing() -> bool:
	return _player != null and _player.playing


func set_volume(value: float, persist: bool = true) -> void:
	if _bus < 0:
		return
	var volume := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(_bus, linear_to_db(volume))
	if persist:
		var config := ConfigFile.new()
		config.set_value("voice", "volume", volume)
		var error := config.save(SETTINGS_PATH)
		if error != OK:
			push_warning("[VoiceManager] Volume could not be saved: %s" % error)


func get_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(_bus)) if _bus >= 0 else 0.0


func _start(cue: String) -> void:
	if _player == null or not has_cue(cue):
		push_warning("[VoiceManager] Missing cue or player: " + cue)
		return
	var stream := load(AUDIO_DIRECTORY + cue + ".wav") as AudioStream
	if stream == null:
		return
	_player.stream = stream
	current_cue = cue
	_player.play()
	_played = true
	cue_started.emit(cue)


func _on_finished() -> void:
	current_cue = ""
	if not _queue.is_empty():
		_start(_queue.pop_front())


func _exit_tree() -> void:
	stop()
	if _played:
		OS.delay_msec(250)
