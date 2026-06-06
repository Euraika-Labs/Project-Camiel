# audio_manager.gd
# Autoload singleton — manages BGM (looping) and SFX (one-shot).
# Persists across scene changes. Attach AudioStreamPlayer children to
# "BGM" and "SFX" named children respectively.
extends Node

# ── Bus names (must match Audio buses defined in Project Settings) ──────────
const MASTER_BUS := "Master"
const SFX_BUS    := "SFX"

# ── Default asset paths (relative to res://) ─────────────────────────────────
const BGM_PATH := "res://assets/audio/bgm_ambient.wav"
const SFX_COLLECT_PATH := "res://assets/audio/sfx_collect.wav"
const SFX_FINISH_PATH  := "res://assets/audio/sfx_finish.wav"

# ── Internal state ───────────────────────────────────────────────────────────
var _bgm_player:  AudioStreamPlayer
var _sfx_player:  AudioStreamPlayer
var _master_bus_idx: int = 0
var _sfx_bus_idx:  int = 1
var _bgm_volume_db: float = 0.0   # linear 0-1
var _sfx_volume_db: float = 0.0  # linear 0-1


# ── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Find or create the persistent player nodes.
	# They are named children so Bus assignment by name is stable.
	_bgm_player = _get_or_create_player("BGM", true)
	_sfx_player = _get_or_create_player("SFX", false)

	# Resolve bus indices once the AudioServer is initialised.
	_master_bus_idx = AudioServer.get_bus_index(MASTER_BUS)
	_sfx_bus_idx    = AudioServer.get_bus_index(SFX_BUS)

	# Assign buses by name so project bus configuration remains explicit.
	_bgm_player.bus = MASTER_BUS
	_sfx_player.bus = SFX_BUS

	# Default volume (0 dB = full)
	set_bgm_volume(0.8)
	set_sfx_volume(0.8)

	# Auto-load music during real gameplay, not during headless verification.
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists(BGM_PATH):
		play_music(BGM_PATH)


# ── Public API ───────────────────────────────────────────────────────────────

## Start looping background music from `path`. No-op if path is invalid.
func play_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM not found: %s" % path)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Could not load BGM: %s" % path)
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(_bgm_volume_db)
	_bgm_player.play()


## Stop background music immediately.
func stop_music() -> void:
	_bgm_player.stop()


## Play a one-shot SFX. Supported event types: "collect", "finish".
## Falls back to the generic SFX_PATH if no named file is found.
func play_sfx(event: String, custom_path: String = "") -> void:
	var path := custom_path
	if path.is_empty():
		match event:
			"collect": path = SFX_COLLECT_PATH
			"finish":  path  = SFX_FINISH_PATH
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[AudioManager] SFX not found for event: %s" % event)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Could not load SFX: %s" % path)
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = linear_to_db(_sfx_volume_db)
	_sfx_player.play()


## Set BGM volume (0.0 = silent, 1.0 = full).
func set_bgm_volume(linear: float) -> void:
	_bgm_volume_db = clampf(linear, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(_bgm_volume_db)


## Set SFX volume (0.0 = silent, 1.0 = full).
func set_sfx_volume(linear: float) -> void:
	_sfx_volume_db = clampf(linear, 0.0, 1.0)
	_sfx_player.volume_db = linear_to_db(_sfx_volume_db)


# ── Internal helpers ──────────────────────────────────────────────────────────

## Return an existing named child AudioStreamPlayer or create one.
func _get_or_create_player(node_name: String, loop: bool) -> AudioStreamPlayer:
	var existing := get_node_or_null(node_name) as AudioStreamPlayer
	if existing != null:
		if loop and not existing.finished.is_connected(_on_bgm_finished):
			existing.finished.connect(_on_bgm_finished)
		return existing
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS   # keep playing across scenes
	if loop:
		player.finished.connect(_on_bgm_finished)
	add_child(player)
	return player


func _on_bgm_finished() -> void:
	if _bgm_player and _bgm_player.stream:
		_bgm_player.play()
