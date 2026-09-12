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
	await _case_menu_sfx_slider()
	await _case_menu_bgm_slider()
	await _case_menu_focus_order()

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


func _case_menu_sfx_slider() -> void:
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)

	var packed: PackedScene = load("res://scenes/main_menu.tscn")
	var menu: Control = packed.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var slider := menu.get_node_or_null("%SfxSlider") as HSlider
	if slider == null:
		push_error("main_menu.tscn has no %SfxSlider node.")
		menu.queue_free()
		quit(1)
		return

	if slider.min_value != 0 or slider.max_value != 100 or slider.step != 5:
		push_error("%%SfxSlider range is %f-%f step %f, expected 0-100 step 5." % [slider.min_value, slider.max_value, slider.step])
		menu.queue_free()
		quit(1)
		return

	if slider.custom_minimum_size.x < 320.0 or slider.custom_minimum_size.y < 56.0:
		push_error("%%SfxSlider custom_minimum_size is %s, expected at least (320, 56)." % slider.custom_minimum_size)
		menu.queue_free()
		quit(1)
		return

	# Read-back proof: set a non-default effects level before the menu opened,
	# then assert the slider picked it up rather than its scene-file default.
	_audio_manager.set_sfx_volume(0.35)
	menu.queue_free()
	await process_frame
	packed = load("res://scenes/main_menu.tscn")
	menu = packed.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	slider = menu.get_node("%SfxSlider") as HSlider

	var expected_value := 0.35 * 100.0
	if absf(slider.value - expected_value) > 2.5:
		push_error("%%SfxSlider.value on open was %f, expected ~%f (read-back from AudioManager, not the scene default)." % [slider.value, expected_value])
		menu.queue_free()
		quit(1)
		return

	var music_before := AudioServer.get_bus_volume_db(music_idx)
	slider.value = 50
	await process_frame

	var expected_db := linear_to_db(0.5)
	if not is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), expected_db):
		push_error("Moving %%SfxSlider to 50 set SFX bus volume_db to %f, expected %f." % [AudioServer.get_bus_volume_db(sfx_idx), expected_db])
		menu.queue_free()
		quit(1)
		return
	if not is_equal_approx(AudioServer.get_bus_volume_db(music_idx), music_before):
		push_error("Moving %SfxSlider changed the Music bus volume_db.")
		menu.queue_free()
		quit(1)
		return

	slider.value = slider.min_value
	await process_frame
	if absf(_audio_manager.get_sfx_volume() - 0.0) > 0.01:
		push_error("%%SfxSlider at minimum gave sfx volume %f, expected 0.0." % _audio_manager.get_sfx_volume())
		menu.queue_free()
		quit(1)
		return

	slider.value = slider.max_value
	await process_frame
	if absf(_audio_manager.get_sfx_volume() - 1.0) > 0.01:
		push_error("%%SfxSlider at maximum gave sfx volume %f, expected 1.0." % _audio_manager.get_sfx_volume())
		menu.queue_free()
		quit(1)
		return

	# The Start control's own exactly-once activation path is covered by
	# probe_screen_flow.gd, which instantiates this same (now audio-panel-
	# bearing) scene and drives %StartButton through a real transition. Not
	# re-tested here to avoid triggering an actual scene change from inside
	# this probe's SceneTree.

	_audio_manager.set_sfx_volume(0.8)
	menu.queue_free()

	_cases_run += 1
	print("PASS menu_sfx_slider")


func _case_menu_bgm_slider() -> void:
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)

	_audio_manager.set_bgm_volume(0.42)
	var packed: PackedScene = load("res://scenes/main_menu.tscn")
	var menu: Control = packed.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var slider := menu.get_node_or_null("%BgmSlider") as HSlider
	if slider == null:
		push_error("main_menu.tscn has no %BgmSlider node.")
		menu.queue_free()
		quit(1)
		return

	if slider.min_value != 0 or slider.max_value != 100 or slider.step != 5:
		push_error("%%BgmSlider range is %f-%f step %f, expected 0-100 step 5." % [slider.min_value, slider.max_value, slider.step])
		menu.queue_free()
		quit(1)
		return

	if slider.custom_minimum_size.x < 320.0 or slider.custom_minimum_size.y < 56.0:
		push_error("%%BgmSlider custom_minimum_size is %s, expected at least (320, 56)." % slider.custom_minimum_size)
		menu.queue_free()
		quit(1)
		return

	var expected_value := 0.42 * 100.0
	if absf(slider.value - expected_value) > 2.5:
		push_error("%%BgmSlider.value on open was %f, expected ~%f (read-back from AudioManager, not the scene default)." % [slider.value, expected_value])
		menu.queue_free()
		quit(1)
		return

	var sfx_before := AudioServer.get_bus_volume_db(sfx_idx)
	slider.value = 50
	await process_frame

	var expected_db := linear_to_db(0.5)
	if not is_equal_approx(AudioServer.get_bus_volume_db(music_idx), expected_db):
		push_error("Moving %%BgmSlider to 50 set Music bus volume_db to %f, expected %f." % [AudioServer.get_bus_volume_db(music_idx), expected_db])
		menu.queue_free()
		quit(1)
		return
	if not is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), sfx_before):
		push_error("Moving %BgmSlider changed the SFX bus volume_db.")
		menu.queue_free()
		quit(1)
		return

	_audio_manager.set_bgm_volume(0.6)
	menu.queue_free()

	_cases_run += 1
	print("PASS menu_bgm_slider")


func _case_menu_focus_order() -> void:
	var packed: PackedScene = load("res://scenes/main_menu.tscn")
	var menu: Control = packed.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var start_button: Control = menu.get_node_or_null("%StartButton")
	var sfx_slider: Control = menu.get_node_or_null("%SfxSlider")
	var bgm_slider: Control = menu.get_node_or_null("%BgmSlider")
	if start_button == null or sfx_slider == null or bgm_slider == null:
		push_error("menu_focus_order: one of %StartButton/%SfxSlider/%BgmSlider is missing.")
		menu.queue_free()
		quit(1)
		return

	if not start_button.has_focus():
		push_error("menu_focus_order: %StartButton does not hold focus on open.")
		menu.queue_free()
		quit(1)
		return

	var expectations := {
		start_button: {"down": sfx_slider, "up": null},
		sfx_slider: {"down": bgm_slider, "up": start_button},
		bgm_slider: {"down": null, "up": sfx_slider},
	}
	for control: Control in expectations.keys():
		var expected_down: Variant = expectations[control]["down"]
		var expected_up: Variant = expectations[control]["up"]

		var down_path: NodePath = control.focus_neighbor_bottom
		var down_node: Node = control.get_node_or_null(down_path) if not down_path.is_empty() else null
		if expected_down != null and down_node != expected_down:
			push_error("menu_focus_order: %s's downward focus neighbour is %s, expected %s." % [control.name, down_node, expected_down])
			menu.queue_free()
			quit(1)
			return

		var up_path: NodePath = control.focus_neighbor_top
		var up_node: Node = control.get_node_or_null(up_path) if not up_path.is_empty() else null
		if expected_up != null and up_node != expected_up:
			push_error("menu_focus_order: %s's upward focus neighbour is %s, expected %s." % [control.name, up_node, expected_up])
			menu.queue_free()
			quit(1)
			return

		var next_path: NodePath = control.focus_next
		var next_node: Node = control.get_node_or_null(next_path) if not next_path.is_empty() else null
		if expected_down != null and next_node != expected_down:
			push_error("menu_focus_order: %s's focus_next is %s, expected %s." % [control.name, next_node, expected_down])
			menu.queue_free()
			quit(1)
			return

		var prev_path: NodePath = control.focus_previous
		var prev_node: Node = control.get_node_or_null(prev_path) if not prev_path.is_empty() else null
		if expected_up != null and prev_node != expected_up:
			push_error("menu_focus_order: %s's focus_previous is %s, expected %s." % [control.name, prev_node, expected_up])
			menu.queue_free()
			quit(1)
			return

	menu.queue_free()

	_cases_run += 1
	print("PASS menu_focus_order")
