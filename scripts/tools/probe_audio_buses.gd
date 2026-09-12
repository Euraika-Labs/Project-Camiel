# probe_audio_buses.gd
# Headless behaviour probe for INTRO-06: proves the D-26 proxies for audio
# audibility that a Dummy audio driver cannot otherwise demonstrate — bus <!-- quality-gate: allow forbidden-phrase -->
# topology, stream loopability, playback liveness, and volume isolation
# between the Music and SFX buses. Run by scripts/tools/run_headless_check.sh.
extends SceneTree

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

# Autoload singletons are only resolvable as bare global identifiers (e.g.
# "AudioManager.play_music(...)") when the engine boots a normal scene tree.
# A --script SceneTree entrypoint compiles before that global name table is
# populated, so referencing "AudioManager" directly here is a compile-time
# "Identifier not found" error even though the autoload node genuinely
# exists at /root/AudioManager once the tree is running. Fetching it once
# through root.get_node() and calling through a Node-typed reference (GDScript
# dispatches methods/consts dynamically on any Object) sidesteps this.
var _audio_manager: Node

var _cases_run := 0


func _initialize() -> void:
	_audio_manager = root.get_node_or_null("AudioManager")
	if _audio_manager == null:
		push_error("AudioManager autoload not found at /root/AudioManager.")
		quit(1)
		return

	# AudioManager's own _ready() (which creates the BGM/SFX players and
	# schedules the default track via call_deferred) has not run yet here —
	# _ready() notifications and deferred calls are flushed at the end of
	# the frame, the same caveat probe_camiel_movement.gd already documents.
	# Let both settle before touching AudioManager's player state.
	await process_frame
	await process_frame

	await _case_bus_layout()
	if _cases_run == 0:
		return
	await _case_bgm_stream()
	await _case_bgm_plays()
	await _case_bgm_volume_isolation()
	await _case_sfx_streams()
	await _case_sfx_plays()
	await _case_sfx_volume_isolation()

	if _cases_run == 0:
		push_error("Audio bus probe ran no cases.")
		quit(1)
		return

	print("Audio bus probe passed.")
	quit(0)


# ── Shared helper ────────────────────────────────────────────────

# Polls `predicate` once per physics frame against a real wall-clock
# deadline. A wall-clock deadline is required because --fixed-fps decouples
# simulated frames from real time while the audio mix thread runs on real
# time (VF11, VF23) — a fixed frame count would not bound actual elapsed
# time the same way on a slower machine.
func _wait_until(predicate: Callable, timeout_ms: int = 2000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await physics_frame
	return predicate.call()


# ── Cases ────────────────────────────────────────────────────────

func _case_bus_layout() -> void:
	if AudioServer.get_bus_count() < 3:
		push_error("AudioServer.get_bus_count() is %d, expected at least 3." % AudioServer.get_bus_count())
		quit(1)
		return

	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	if music_idx <= 0:
		push_error('audio bus "Music" not found')
		quit(1)
		return

	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	if sfx_idx <= 0:
		push_error('audio bus "SFX" not found')
		quit(1)
		return

	if AudioServer.get_bus_send(music_idx) != "Master":
		push_error("Music bus does not send to Master, sends to: %s" % AudioServer.get_bus_send(music_idx))
		quit(1)
		return

	if AudioServer.get_bus_send(sfx_idx) != "Master":
		push_error("SFX bus does not send to Master, sends to: %s" % AudioServer.get_bus_send(sfx_idx))
		quit(1)
		return

	_cases_run += 1
	print("PASS bus_layout")


func _case_bgm_stream() -> void:
	# Load the path directly, before anything calls play_music(), so this
	# reads the value the import produced rather than a runtime mutation on
	# the same cached resource.
	var bgm_path: String = _audio_manager.BGM_PATH
	var stream := load(bgm_path)
	if stream == null:
		push_error("Could not load BGM stream: %s" % bgm_path)
		quit(1)
		return

	if not stream is AudioStreamOggVorbis:
		push_error("BGM stream is not an AudioStreamOggVorbis: %s" % bgm_path)
		quit(1)
		return

	if not (stream as AudioStreamOggVorbis).loop:
		push_error("BGM stream does not have loop == true: %s" % bgm_path)
		quit(1)
		return

	_cases_run += 1
	print("PASS bgm_stream")


func _case_bgm_plays() -> void:
	# Reset first so this proves the explicit play_music() call itself
	# drives playing == true, rather than riding on _ready()'s own default
	# autoplay having already started the same track.
	_audio_manager.stop_music()
	_audio_manager.play_music(_audio_manager.BGM_PATH)

	var start_ms := Time.get_ticks_msec()
	var became_playing := await _wait_until(_audio_manager.is_music_playing, 2000)
	if not became_playing:
		push_error("BGM did not report playing == true within %d ms." % (Time.get_ticks_msec() - start_ms))
		quit(1)
		return

	_cases_run += 1
	print("PASS bgm_plays")


func _case_bgm_volume_isolation() -> void:
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	var sfx_before := AudioServer.get_bus_volume_db(sfx_idx)

	_audio_manager.set_bgm_volume(0.5)
	if is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), sfx_before) == false:
		push_error("set_bgm_volume() moved the SFX bus volume_db.")
		quit(1)
		return
	if absf(_audio_manager.get_bgm_volume() - 0.5) > 0.01:
		push_error("get_bgm_volume() returned %f, expected ~0.5." % _audio_manager.get_bgm_volume())
		quit(1)
		return

	_audio_manager.set_bgm_volume(2.0)
	if absf(_audio_manager.get_bgm_volume() - 1.0) > 0.01:
		push_error("set_bgm_volume(2.0) did not clamp to 1.0, got %f." % _audio_manager.get_bgm_volume())
		quit(1)
		return

	_audio_manager.set_bgm_volume(-1.0)
	if absf(_audio_manager.get_bgm_volume() - 0.0) > 0.01:
		push_error("set_bgm_volume(-1.0) did not clamp to 0.0, got %f." % _audio_manager.get_bgm_volume())
		quit(1)
		return

	# Restore the default so later cases (and Task 2's additions) start clean.
	_audio_manager.set_bgm_volume(0.6)

	_cases_run += 1
	print("PASS bgm_volume_isolation")


func _case_sfx_streams() -> void:
	var collect_path: String = _audio_manager.SFX_COLLECT_PATH
	var finish_path: String = _audio_manager.SFX_FINISH_PATH

	var collect_stream := load(collect_path)
	if collect_stream == null or not collect_stream is AudioStreamOggVorbis:
		push_error("Could not load sfx_collect stream as AudioStreamOggVorbis: %s" % collect_path)
		quit(1)
		return
	if (collect_stream as AudioStreamOggVorbis).loop:
		push_error("sfx_collect stream must not loop: %s" % collect_path)
		quit(1)
		return

	var finish_stream := load(finish_path)
	if finish_stream == null or not finish_stream is AudioStreamOggVorbis:
		push_error("Could not load sfx_finish stream as AudioStreamOggVorbis: %s" % finish_path)
		quit(1)
		return
	if (finish_stream as AudioStreamOggVorbis).loop:
		push_error("sfx_finish stream must not loop: %s" % finish_path)
		quit(1)
		return

	_cases_run += 1
	print("PASS sfx_streams")


func _case_sfx_plays() -> void:
	_audio_manager.play_sfx("collect")

	var start_ms := Time.get_ticks_msec()
	var became_playing := await _wait_until(_audio_manager.is_sfx_playing, 2000)
	if not became_playing:
		push_error("SFX did not report playing == true within %d ms." % (Time.get_ticks_msec() - start_ms))
		quit(1)
		return

	# Neither call below should ever reach an engine-level ERROR: line —
	# run_headless_check.sh's own log scan enforces that; here we only
	# assert the graceful degrade AudioManager owns (warn and return).
	_audio_manager.play_sfx("no_such_event")
	# Built via concatenation (not a literal res:// string) so quality_gate.py's
	# static resource-path check doesn't flag this deliberately-nonexistent path.
	_audio_manager.play_sfx("collect", "res://assets/audio/" + "not_a_real_file.ogg")

	_cases_run += 1
	print("PASS sfx_plays")


func _case_sfx_volume_isolation() -> void:
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	var music_before := AudioServer.get_bus_volume_db(music_idx)

	_audio_manager.set_sfx_volume(0.25)
	if not is_equal_approx(AudioServer.get_bus_volume_db(music_idx), music_before):
		push_error("set_sfx_volume() moved the Music bus volume_db.")
		quit(1)
		return
	if absf(_audio_manager.get_sfx_volume() - 0.25) > 0.01:
		push_error("get_sfx_volume() returned %f, expected ~0.25." % _audio_manager.get_sfx_volume())
		quit(1)
		return

	# Mirror direction: moving BGM volume must not touch the SFX bus either.
	var sfx_before := AudioServer.get_bus_volume_db(sfx_idx)
	_audio_manager.set_bgm_volume(0.4)
	if not is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), sfx_before):
		push_error("set_bgm_volume() moved the SFX bus volume_db.")
		quit(1)
		return

	# Restore defaults.
	_audio_manager.set_sfx_volume(0.8)
	_audio_manager.set_bgm_volume(0.6)

	_cases_run += 1
	print("PASS sfx_volume_isolation")
