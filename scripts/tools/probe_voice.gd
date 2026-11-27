extends SceneTree

var _voice: Node
var _failures := 0


func _initialize() -> void:
	await process_frame
	await process_frame
	_voice = root.get_node_or_null("VoiceManager")
	if _voice == null:
		push_error("VoiceManager missing")
		quit(1)
		return
	var index := AudioServer.get_bus_index("Voice")
	_check(index > 0, "Voice bus exists")
	_check(AudioServer.get_bus_send(index) == "Master", "Voice routes independently to Master")
	var music := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	var music_db := AudioServer.get_bus_volume_db(music)
	var sfx_db := AudioServer.get_bus_volume_db(sfx)
	_voice.set_volume(0.25, false)
	_check(is_equal_approx(_voice.get_volume(), 0.25), "Voice volume roundtrip")
	_check(AudioServer.get_bus_volume_db(music) == music_db, "Voice leaves Music unchanged")
	_check(AudioServer.get_bus_volume_db(sfx) == sfx_db, "Voice leaves SFX unchanged")
	AudioServer.set_bus_volume_db(music, -80.0)
	AudioServer.set_bus_volume_db(sfx, -80.0)
	_check(is_equal_approx(_voice.get_volume(), 0.25), "Music/SFX leave Voice unchanged")
	_voice.set_volume(0.0, false)
	_check(is_zero_approx(_voice.get_volume()), "Voice mute")
	_voice.set_volume(0.8, false)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_voice.CATALOG_PATH))
	for cue: String in catalog.clips:
		_check(_voice.has_cue(cue), "Asset " + cue)
		var stream := load(_voice.AUDIO_DIRECTORY + cue + ".wav") as AudioStreamWAV
		_check(stream != null and stream.get_length() > 0.5, "Decodable speech " + cue)
	var capture := AudioEffectCapture.new()
	AudioServer.add_bus_effect(index, capture)
	_voice.play("intro")
	await process_frame
	_check(_voice.is_playing(), "Narration player starts")
	# Audio mixing follows wall-clock time, even with --fixed-fps. A SceneTree
	# timer can expire before the headless audio mixer runs during accelerated CI.
	var deadline := Time.get_ticks_msec() + 3000
	var peak := 0.0
	while peak <= 0.001 and Time.get_ticks_msec() < deadline:
		var frames := capture.get_buffer(capture.get_frames_available())
		for frame: Vector2 in frames:
			peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		if peak <= 0.001:
			await process_frame
	_check(peak > 0.001, "Voice bus outputs non-silent samples")
	AudioServer.remove_bus_effect(index, 0)
	_check(_voice.get_node("Narration").bus == "Voice", "Player routed to Voice")
	_voice.enqueue("correct")
	_voice.play("complete")
	_check(_voice.current_cue == "complete", "Completion interrupts instruction")
	var owner := Node.new()
	root.add_child(owner)
	_voice.bind_scene(owner, "intro")
	await process_frame
	await process_frame
	_check(_voice.current_cue == "intro", "Scene instruction starts")
	_voice.enqueue("correct")
	owner.queue_free()
	await process_frame
	await process_frame
	_check(not _voice.is_playing() and _voice.current_cue.is_empty(), "Scene exit cancels narration")
	_check(_voice._queue.is_empty(), "Scene exit clears pending cues")
	var cancelled := Node.new()
	root.add_child(cancelled)
	_voice.bind_scene(cancelled, "intro")
	_voice.stop()
	await process_frame
	_check(not _voice.is_playing(), "Stop invalidates deferred instruction")
	cancelled.queue_free()
	AudioServer.set_bus_volume_db(music, music_db)
	AudioServer.set_bus_volume_db(sfx, sfx_db)
	await _check_scene_bindings()
	if _failures == 0:
		print("Voice probe passed.")
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error(description)


func _check_scene_bindings() -> void:
	var scenes := {"title_screen": "title", "main_menu": "main_menu", "lesson_select": "lesson_select", "intro_level": "intro", "lesson_1": "lesson_1", "lesson_2": "lesson_2", "lesson_3": "lesson_3", "lesson_4": "lesson_4", "lesson_5": "lesson_5", "lesson_6": "lesson_6"}
	for scene_name: String in scenes:
		var packed := load("res://scenes/" + scene_name + ".tscn") as PackedScene
		var scene := packed.instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		var entry_cue: String = scenes[scene_name]
		if scene_name == "main_menu":
			match scene.get_node("%StartButton").label_text:
				"Verder spelen":
					entry_cue = "menu_continue"
				"Tuinfeest":
					entry_cue = "menu_garden"
		elif scene_name == "intro_level" and scene.get_node("Camiel").has_touch_controls():
			entry_cue = "intro_touch"
		_check(_voice.current_cue == entry_cue, "Scene cue " + scene_name)
		if scene_name == "intro_level":
			var player: CharacterBody3D = scene.get_node("Camiel")
			var listen: Button = scene.get_node("%IntroListenButton")
			listen.pressed.emit()
			_check(_voice.current_cue == entry_cue, "Listen repeats the motion cue for the active controls")
			player.teleport_to(player.global_position + Vector3(0, 0, -0.75))
			for frame in 8:
				await process_frame
			listen.pressed.emit()
			_check(_voice.current_cue == "intro_ball", "Listen names the ball after the player has moved")
			var ball: Area3D = scene.get_node("%Collectible")
			player.teleport_to(ball.global_position - Vector3(0, 0.4, 0))
			for frame in 12:
				await physics_frame
			_check(_voice.current_cue == "collected", "Intro pickup speaks feedback")
			_check("intro_finish" in _voice._queue, "Intro pickup queues the direction to the finish")
			listen.pressed.emit()
			_check(_voice.current_cue == "intro_finish", "Listen repeats the current intro task")
		if scene_name == "main_menu":
			scene._open_settings()
			await process_frame
			var slider := scene.find_child("VoiceVolume", true, false) as HSlider
			_check(slider != null, "Settings exposes voice slider")
			if slider != null:
				_check(is_equal_approx(slider.value / 100.0, _voice.get_volume()), "Slider reflects voice volume")
				if OS.get_user_data_dir().contains("camiel-voice-probe-"):
					slider.value = 35
					_check(is_equal_approx(_voice.get_volume(), 0.35), "Slider controls Voice bus")
					var saved := ConfigFile.new()
					_check(saved.load(_voice.SETTINGS_PATH) == OK, "Volume persisted")
					_check(is_equal_approx(float(saved.get_value("voice", "volume", -1.0)), 0.35), "Saved volume matches slider")
		if scene_name == "lesson_2":
			await _check_narration_pause(scene)
			await _check_shape_guidance(scene)
		if scene_name == "lesson_4" and OS.get_user_data_dir().contains("camiel-voice-probe-"):
			await _check_color_counting(scene)
		scene.emit_signal("transition_requested", "res://scenes/main_menu.tscn")
		_check(not _voice.is_playing(), "Navigation stops " + scene_name)
		scene.queue_free()
		await process_frame
		await process_frame


func _check_narration_pause(scene: Node) -> void:
	var player := _voice.get_node("Narration") as AudioStreamPlayer
	var pause_button := scene.get_node("%Hud").get_node("%PauseButton") as Button
	_voice.play("lesson_2")
	_voice.enqueue("goal_circle")
	var playback := player.get_stream_playback()
	pause_button.pressed.emit()
	await process_frame
	var dialog := pause_button.get_node_or_null("Settings")
	_check(paused and dialog != null, "Pause opens the in-game settings dialog")
	_check(player.stream_paused and player.has_stream_playback(), "Pause suspends the active narration")
	_check(_voice.current_cue == "lesson_2" and _voice._queue == ["goal_circle"], "Pause preserves the narration queue")
	if dialog == null:
		paused = false
		return
	dialog.get_node("%CloseButton").pressed.emit()
	await process_frame
	await process_frame
	_check(not paused and not player.stream_paused, "Continue releases the narration pause")
	_check(player.has_stream_playback() and player.get_stream_playback() == playback, "Continue resumes the same narration playback")

	pause_button.pressed.emit()
	scene.emit_signal("transition_requested", "res://scenes/main_menu.tscn")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	root.push_input(cancel)
	await process_frame
	await process_frame
	_check(not paused and not player.has_stream_playback() and _voice._queue.is_empty(),
		"Navigation during pause discards the old scene's narration")


func _check_shape_guidance(scene: Node) -> void:
	var hud := scene.get_node("%Hud")
	var speaker: Button = hud.get_node("%ListenButton")
	var spoken: Array[String] = []
	var track := func(cue: String) -> void: spoken.append(cue)
	_voice.cue_started.connect(track)
	scene.get_node("SquareTarget").rejected.emit()
	scene.get_node("TriangleTarget").rejected.emit()
	_check(spoken == ["goal_circle"], "Repeated wrong guesses must not restart help for the same shape")
	scene._on_task_completed("circle")
	_check(_voice.current_cue == "correct", "Accepted target speaks feedback")
	var deadline := Time.get_ticks_msec() + 4000
	while _voice.current_cue != "goal_square" and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_voice.current_cue == "goal_square", "Accepted target must announce the next shape after feedback")
	_voice.stop()
	speaker.pressed.emit()
	_check(_voice.current_cue == "goal_square", "Listen must repeat the current shape")
	if OS.get_user_data_dir().contains("camiel-voice-probe-"):
		scene._on_task_completed("square")
		_check(_voice._queue == ["goal_triangle"], "The next shape must replace the previous hint")
		scene._on_task_completed("triangle")
		_check(_voice.current_cue == _win_cue(hud) and _voice._queue.is_empty(), "Finishing replaces in-progress guidance")
		_check(not hud.get_node("%HintLabel").visible, "The win overlay must not keep showing the previous instruction")
	_voice.cue_started.disconnect(track)


func _check_color_counting(scene: Node) -> void:
	var hud := scene.get_node("%Hud")
	var spoken: Array[String] = []
	var track := func(cue: String) -> void: spoken.append(cue)
	_voice.cue_started.connect(track)
	for id: String in ["green", "yellow", "count_2", "count_2", "count_3", "count_1"]:
		scene._on_task_completed(id)
	_check(hud.is_win_visible(), "The colour lesson finishes after both colours and three unique stones")
	var cue := _win_cue(hud)
	var deadline := Time.get_ticks_msec() + 5500
	while _voice.current_cue != cue and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(spoken == ["color_green", "color_yellow", "counted_1", "counted_2", "counted_3", cue],
		"Quick pickups must speak each count once, including the last stone before the celebration")
	_voice.cue_started.disconnect(track)


func _win_cue(hud: CanvasLayer) -> String:
	if hud.get_node("%CelebrationButton").visible:
		return "garden_ready"
	if hud.get_node("%NextButton").visible:
		return "lesson_continue"
	return "complete"
