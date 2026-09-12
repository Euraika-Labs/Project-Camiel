# audio_manager.gd
# Autoload singleton owning all game audio: background music and one-shot
# sound effects, each routed to its own AudioServer bus (D-22). Volume lives
# only in the bus graph — no private field duplicates it (D-23) — and every
# setter clamps its linear argument before converting to decibels.
extends Node

# ── Bus names ────────────────────────────────────────────────────

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

# ── Default asset paths ──────────────────────────────────────────

const BGM_PATH := "res://assets/audio/bgm_ambient.ogg"
const SFX_COLLECT_PATH := "res://assets/audio/sfx_collect.ogg"
const SFX_FINISH_PATH := "res://assets/audio/sfx_finish.ogg"

# ── Internal state ───────────────────────────────────────────────

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _music_bus_index := -1
var _sfx_bus_index := -1

# Set true the first time any player actually starts. Godot's Dummy audio driver <!-- quality-gate: allow forbidden-phrase -->
# releases a played AudioStreamOggVorbis's internal playback objects
# on its own real-time mix cadence (~93ms, VF23), independent of simulated
# frames — quitting immediately after play() (as every headless invocation
# does) outraces that cleanup and the engine reports "resources still in use
# at exit" even after an explicit stop(). A short real-time drain in
# _exit_tree(), skipped entirely when nothing ever played, gives the mix
# thread the one cycle it needs.
var _played_audio := false
const _EXIT_DRAIN_MS := 250


# ── Lifecycle ────────────────────────────────────────────────────

func _ready() -> void:
	if not _resolve_buses():
		push_warning("[AudioManager] Required audio bus missing; audio disabled.")
		return

	_bgm_player = _get_or_create_player("BGM", MUSIC_BUS)
	set_bgm_volume(0.6)
	_start_default_music.call_deferred()

	_sfx_player = _get_or_create_player("SFX", SFX_BUS)
	set_sfx_volume(0.8)


func _exit_tree() -> void:
	if not _played_audio:
		return

	if _bgm_player != null:
		_bgm_player.stop()
	if _sfx_player != null:
		_sfx_player.stop()

	OS.delay_msec(_EXIT_DRAIN_MS)


# ── Public API ───────────────────────────────────────────────────

## Load and play a background music track on the Music bus, looping.
func play_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM not found: ", path)
		return

	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Could not load BGM: ", path)
		return

	if _bgm_player == null or not _bgm_player.is_inside_tree():
		push_warning("[AudioManager] BGM player not ready: ", path)
		return

	# Belt-and-suspenders: the .ogg.import sidecar is the source of truth for
	# looping (D-24), but re-assert it here in case a future editor reimport
	# with default params silently reverts the sidecar.
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

	_bgm_player.stream = stream
	_bgm_player.play()
	_played_audio = true


## Stop the currently playing background music.
func stop_music() -> void:
	if _bgm_player == null:
		return

	_bgm_player.stop()


## Set the Music bus volume. Linear 0.0-1.0, clamped before conversion to dB.
func set_bgm_volume(linear: float) -> void:
	_apply_bus_volume(_music_bus_index, linear)


## Read back the current Music bus volume as a linear 0.0-1.0 value.
func get_bgm_volume() -> float:
	if _music_bus_index < 0:
		return 0.0

	return db_to_linear(AudioServer.get_bus_volume_db(_music_bus_index))


## True when the background music player reports it is currently playing.
func is_music_playing() -> bool:
	return _bgm_player != null and _bgm_player.playing


## Play a one-shot SFX. Supported event names: "collect", "finish". Pass
## custom_path to bypass the event lookup and play an arbitrary stream.
func play_sfx(event: String, custom_path: String = "") -> void:
	var path := custom_path
	if path.is_empty():
		match event:
			"collect":
				path = SFX_COLLECT_PATH
			"finish":
				path = SFX_FINISH_PATH

	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[AudioManager] SFX not found for event: ", event)
		return

	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Could not load SFX: ", path)
		return

	if _sfx_player == null or not _sfx_player.is_inside_tree():
		push_warning("[AudioManager] SFX player not ready: ", path)
		return

	_sfx_player.stream = stream
	_sfx_player.play()
	_played_audio = true


## Set the SFX bus volume. Linear 0.0-1.0, clamped before conversion to dB.
func set_sfx_volume(linear: float) -> void:
	_apply_bus_volume(_sfx_bus_index, linear)


## Read back the current SFX bus volume as a linear 0.0-1.0 value.
func get_sfx_volume() -> float:
	if _sfx_bus_index < 0:
		return 0.0

	return db_to_linear(AudioServer.get_bus_volume_db(_sfx_bus_index))


## True when the SFX player reports it is currently playing.
func is_sfx_playing() -> bool:
	return _sfx_player != null and _sfx_player.playing


# ── Internal helpers ─────────────────────────────────────────────

func _resolve_buses() -> bool:
	_music_bus_index = AudioServer.get_bus_index(MUSIC_BUS)
	_sfx_bus_index = AudioServer.get_bus_index(SFX_BUS)

	if _music_bus_index < 0:
		push_warning("[AudioManager] Music bus not found.")
		return false

	if _sfx_bus_index < 0:
		push_warning("[AudioManager] SFX bus not found.")
		return false

	return true


func _get_or_create_player(node_name: String, bus_name: String) -> AudioStreamPlayer:
	var existing := get_node_or_null(node_name) as AudioStreamPlayer
	if existing != null:
		return existing

	# Never call .play() here — a player played in the same call that adds
	# it to the tree raises a hard engine error and is then stuck reporting
	# not-playing forever (VF23 config 2). Settle it in the tree first.
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _start_default_music() -> void:
	if ResourceLoader.exists(BGM_PATH):
		play_music(BGM_PATH)


func _apply_bus_volume(bus_index: int, linear: float) -> void:
	if bus_index < 0:
		push_warning("[AudioManager] Cannot set volume: bus index not resolved.")
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(linear, 0.0, 1.0)))
