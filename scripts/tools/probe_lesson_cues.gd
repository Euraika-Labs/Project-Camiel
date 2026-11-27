extends SceneTree
## Reads the same cue state that the HUD draws after real target collisions.

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	await _frames(3)
	var colors := await _open("res://scenes/lesson_1.tscn")
	var color_hud := colors.get_node("%Hud")
	var color_cues := color_hud.get_node("%LessonCues")
	var color_prompt: Label = color_hud.get_node("%HintLabel")
	var voice := root.get_node("VoiceManager")
	var sfx: AudioStreamPlayer = root.get_node("AudioManager/SFX")
	var expected := PackedStringArray(["red", "blue", "count_1", "count_2", "count_3"])
	_check(color_cues.active_target_ids() == expected, "every color and stone must be available")
	_check(not color_hud.get_node("%StepLabel").is_visible_in_tree(), "free-order tasks should use their own check marks as visible progress")
	_check(color_prompt.text.contains("3 telstenen"), "the color lesson must show three stones at the start")
	await _check_lesson_movement_hint(colors, color_hud, voice)
	await _touch(colors, colors.get_node("%CountGroup/Count2"))
	_check(color_cues.is_complete("count_2"), "the second stone needs its own check mark")
	_check(colors.get_node("%CountGroup/Count2/Check").visible, "the collected stone needs a mark in the field")
	_check(sfx.stream != null and sfx.stream.resource_path.ends_with("sfx_collect.ogg"), "a correct touch in a free-order lesson must play the pickup cue")
	_check(color_cues.active_target_ids() == PackedStringArray(["red", "blue", "count_1", "count_3"]), "a collected stone was still offered")
	_check(color_hud.get_node("%StepLabel").text == "Stap: 0 / 3", "one stone completed the whole counting task")
	_check(voice.current_cue == "counted_1", "the middle stone must be spoken as one when collected first")
	_check(color_prompt.text.contains("2 telstenen"), "the text must show only two stones left")
	var red: Area3D = colors.get_node("RedTarget")
	var red_mesh: MeshInstance3D = red.get_node("Mesh")
	var red_paint := red_mesh.get_surface_override_material(0) as ShaderMaterial
	_check(red_mesh.mesh is ArrayMesh and red_paint != null and red_paint.get_shader_parameter("pigment") == red.target_color,
		"the rounded block must use the same pigment as its lesson pictogram")
	var red_initial_height := red_mesh.position.y
	var mesh_base := red_mesh.mesh.get_aabb().position.y
	await _touch(colors, red)
	_check(red_paint != null and red_paint.get_shader_parameter("completed") == true, "completion must update the painted surface")
	_check(color_prompt.text.begins_with("Raak blauw aan."), "a collected color remained in the instructions")
	color_hud.get_node("%ListenButton").pressed.emit()
	_check(voice.current_cue == "color_blue" and voice._queue == ["goal_stones"], "Listen should name only the remaining tasks")
	await _touch(colors, colors.get_node("%CountGroup/Count3"))
	_check(voice.current_cue == "counted_2" and voice._queue.is_empty(), "a pickup must replace the old help")
	_check(color_prompt.text.contains("één telsteen"), "the text must show one stone left")
	await _frames(18)
	_check(red_mesh.scale.y < 0.7, "a completed block must leave room to see Camiel")
	var settled_base := red_mesh.position.y + mesh_base * red_mesh.scale.y
	_check(is_equal_approx(settled_base, red_initial_height + mesh_base), "the completed block moved off its pedestal")
	red.reset()
	_check(red_mesh.scale.is_equal_approx(Vector3.ONE) and is_equal_approx(red_mesh.position.y, red_initial_height), "reset must restore the block's scale and height")
	_check(red_paint != null and red_paint.get_shader_parameter("completed") == false, "reset must restore the original paint")
	colors.queue_free()
	await _frames(3)
	sfx.stop()
	sfx.stream = null

	var numbers := await _open("res://scenes/lesson_6.tscn")
	var number_hud := numbers.get_node("%Hud")
	var number_cues := number_hud.get_node("%LessonCues")
	var prompt: Label = number_hud.get_node("%HintLabel")
	_check(number_cues.active_target_ids() == PackedStringArray(["step_1"]), "only the first number may be offered")
	_check(number_hud.get_node("%StepLabel").is_visible_in_tree(), "a lesson with a fixed order should show its step counter")
	_check(prompt.text == "Loop naar 1.", "the task card must name the current number")
	for number in range(1, 6):
		var token := numbers.get_node("Step%dTarget" % number)
		_check(token.get_count_pips().size() == number, "the dots and number on a token differ")
		var sign: MeshInstance3D = token.get_node("GoalSign")
		_check(sign.mesh.get_surface_count() == 3 and sign.visible == (number == 1), "only the current number should show a sign")
	var ring: MeshInstance3D = numbers.get_node("Step1Target/GuideRing")
	var check: MeshInstance3D = numbers.get_node("Step1Target/Check")
	await _touch(numbers, numbers.get_node("Step3Target"))
	_check(number_cues.active_target_ids() == PackedStringArray(["step_1"]), "an out-of-order touch advanced the cues")
	_check(numbers.get_node("Step1Target/GoalSign").visible and not numbers.get_node("Step3Target/GoalSign").visible,
		"an out-of-order touch moved the active sign")
	_check(voice.current_cue == "goal_step_1", "a wrong touch must name the current number")
	_check(ring.scale.x > 1.07, "the first goal did not respond visually to a wrong touch")
	_check(not check.visible and sfx.stream == null, "an incorrect touch gave completion feedback")
	await _touch(numbers, numbers.get_node("Step1Target"))
	_check(number_cues.is_complete("step_1"), "the completed number did not get a check mark")
	_check(number_cues.active_target_ids() == PackedStringArray(["step_2"]), "the next number was skipped")
	_check(prompt.text == "Loop naar 2.", "the task card did not advance to the next number")
	_check(not ring.visible and ring.scale.is_equal_approx(Vector3.ONE), "the previous goal kept pulsing after collection")
	_check(check.visible and not numbers.get_node("Step1Target/Label").visible, "the world did not mark the completed number")
	_check(not numbers.get_node("Step1Target/GoalSign").visible and numbers.get_node("Step2Target/GoalSign").visible,
		"the next number must take over the active sign")
	_check(sfx.stream != null and sfx.stream.resource_path.ends_with("sfx_collect.ogg"), "a correct touch in an ordered lesson must play the pickup cue")

	root.size = Vector2i(320, 568)
	await _frames(6)
	var layout := root.get_node("ScreenLayout")
	_check(layout.portrait, "portrait layout did not respond when the window turned")
	_check(number_hud.get_node_or_null("%LessonCues") == number_cues, "turning the window detached the task cues")
	_check(number_cues.active_target_ids() == PackedStringArray(["step_2"]), "turning the window reset the lesson cue")
	_check(not number_hud.get_node("%ProgressCard").visible, "portrait layout still has a separate side card")
	var visible := root.get_visible_rect()
	_check(visible.encloses(number_cues.get_global_rect()), "the portrait layout clipped the task cues")
	_check(visible.encloses(number_hud.get_node("%ListenButton").get_global_rect()), "the audio button overflowed the portrait layout")
	var listen := InputEventAction.new()
	listen.action = "listen_again"
	listen.pressed = true
	root.push_input(listen)
	_check(voice.current_cue == "goal_step_2", "the listen action must name the active number")
	root.size = Vector2i(390, 844)
	await _frames(6)
	var pointer := number_hud.get_node("%GoalDirection")
	_check(pointer.indicated_target_id() == "step_2", "the goal beyond the portrait edge needs a pointer")
	_check(pointer.pointing_direction().x > 0.85, "the pointer does not point right from the first stone")
	var player := numbers.get_node("Camiel")
	player.teleport_to(Vector3(2.8, 0.1, -4.7))
	await _frames(8)
	_check(pointer.indicated_target_id() == "step_2", "a goal behind the camera lost its pointer")
	_check(pointer.pointing_direction().y > 0.95, "the pointer does not point down toward a goal behind Camiel")
	player.teleport_to(numbers.get_node("PlayerSpawn").global_position)
	await _frames(8)
	_check(pointer.indicated_target_id().is_empty(), "a visible goal still has an edge pointer")

	root.size = Vector2i(1280, 720)
	await _frames(5)
	_check(not layout.portrait and number_hud.get_node("%ProgressCard").visible, "the wide layout was not restored")
	_check(number_cues.is_complete("step_1"), "the completed cue was lost on return to landscape")
	await _check_pause(numbers, number_hud)
	numbers.queue_free()
	await _frames(2)
	await _check_intro_guidance()
	if not _failed:
		print("Goal guidance and completion feedback verified for the intro and lessons.")
	quit(1 if _failed else 0)


func _check_lesson_movement_hint(lesson: Node, hud: CanvasLayer, voice: Node) -> void:
	var hint: Control = hud.get_node("%MovementHint")
	var tracker := root.get_node("ProgressTracker")
	var fresh: bool = not tracker.has_completed_intro() and tracker.completed_lesson_ids().is_empty()
	_check(hint.visible == fresh, "movement help must follow the player's existing progress")
	if not fresh:
		return

	var player: CharacterBody3D = lesson.get_node("Camiel")
	var pad: Control = player.get_node("TouchLayer/TouchControls")
	var touch: bool = player.has_touch_controls()
	var label: Label = hud.get_node("%MovementLabel")
	var keys: Control = hud.get_node("%MovementKeys")
	var expected_text := "Sleep het gele rondje." if touch else "Loop met de pijltjes."
	var expected_cue := "move_touch" if touch else "move_keyboard"
	_check(label.text == expected_text and keys.visible != touch, "movement help must use the active input labels")
	_check(pad.is_processing() == touch, "the touch demonstration must start in a direct first lesson")
	var spawn := player.global_position
	await _frames(70)
	var drift := player.global_position - spawn
	_check(Vector2(drift.x, drift.z).is_zero_approx(), "the demonstration moved Camiel")
	_check(voice.current_cue == "lesson_1", "movement help interrupted the lesson introduction")
	voice.stop()
	await _frames(3)
	_check(voice.current_cue == expected_cue, "standing still after the lesson introduction must announce movement help")
	voice.stop()
	await _frames(3)
	_check(voice.current_cue.is_empty(), "the spoken movement help repeated while idle")
	Input.action_press("move_right")
	await _frames(28)
	Input.action_release("move_right")
	_check(not hint.visible and not pad.is_processing(), "walking must dismiss the movement help")
	_check(hud.get_node("%HintLabel").text.contains("3 telstenen"), "walking changed the live lesson goal")


func _check_pause(lesson: Node, hud: CanvasLayer) -> void:
	var button: Button = hud.get_node("%PauseButton")
	button.pressed.emit()
	await process_frame
	var dialog := button.get_node_or_null("Settings")
	_check(paused and dialog != null, "pause must open the settings dialog")
	if dialog == null:
		return
	var player: CharacterBody3D = lesson.get_node("Camiel")
	var position := player.global_position
	var elapsed: float = hud.elapsed_play_time()
	Input.action_press("move_forward")
	for frame in 20:
		await process_frame
	Input.action_release("move_forward")
	_check(player.global_position.is_equal_approx(position), "Camiel moved during pause")
	_check(is_equal_approx(hud.elapsed_play_time(), elapsed), "the lesson clock included paused time")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	root.push_input(cancel)
	await process_frame
	await process_frame
	_check(not paused and button.get_node_or_null("Settings") == null, "Escape did not resume the lesson")
	_check(hud.get_node("%LessonCues").is_complete("step_1"), "resuming discarded a completed step")


func _check_intro_guidance() -> void:
	root.size = Vector2i(390, 844)
	await _frames(6)
	var intro := await _open("res://scenes/intro_level.tscn")
	var ball: Area3D = intro.get_node("%Collectible")
	var finish: Area3D = intro.get_node("%FinishMarker")
	var task: Label = intro.get_node("%Task")
	var hint: Control = intro.get_node("%ControlHints")
	var controls: Label = intro.get_node("%Controls")
	var player: CharacterBody3D = intro.get_node("Camiel")
	var pad: Control = player.get_node("TouchLayer/TouchControls")
	var keyboard: Control = intro.get_node("%ArrowKeys")
	var touch_enabled: bool = player.has_touch_controls()
	var marker: MeshInstance3D = intro.get_node("%TrailMarker")
	var pointer := intro.get_node("%GoalDirection")
	var walk_text := "Sleep het gele rondje." if touch_enabled else "Pijltjes om te lopen"
	var jump_text := "Tik op de pijl om te springen." if touch_enabled else "Spatie om te springen"
	_check(hint.visible and task.text.contains("bol"), "intro should show how to move and point to the ball")
	_check(controls.text == walk_text + "\n" + jump_text, "intro should explain walking and jumping")
	_check(keyboard.visible != touch_enabled and pad.is_processing() == touch_enabled, "intro should show the help for the active controls")
	var spawn := player.global_position
	await _frames(24)
	var drift := player.global_position - spawn
	_check(Vector2(drift.x, drift.z).is_zero_approx() and pad.movement == Vector2.ZERO, "the touch demonstration must not move Camiel")
	_check(marker.mesh != null and absf(marker.position.x - ball.position.x) < 0.1, "the trail marker is not over the ball")
	await _touch(intro, ball)
	_check(not hint.visible and not pad.is_processing() and task.text.contains("ring"), "picking up the ball did not advance the intro cue")
	_check(absf(marker.position.x - finish.position.x) < 0.1, "the trail marker did not move to the ring")
	intro.get_node("Camiel").teleport_to(Vector3(5.1, 0.1, 2.4))
	await _frames(8)
	_check(pointer.indicated_target_id() == "finish" and pointer.pointing_direction().x < -0.5, "a child outside the trail lost the finish direction")
	await _touch(intro, finish)
	_check(not marker.visible and pointer.indicated_target_id().is_empty(), "the win screen kept the trail guidance")
	intro.get_node("%ReplayButton").pressed.emit()
	await _frames(5)
	_check(hint.visible and marker.visible and task.text.contains("bol") and pad.is_processing() == touch_enabled, "replaying did not restore the first goal and movement help")
	Input.action_press("move_right")
	await _frames(28)
	Input.action_release("move_right")
	_check(hint.visible and controls.text == jump_text and not keyboard.visible, "walking dismissed the unused jump hint")
	_check(pad.is_processing() == touch_enabled, "touch jump demonstration stopped as soon as the player walked")
	await _jump_in_intro(pad, touch_enabled)
	_check(player.velocity.y > 0.0, "intro jump input did not lift Camiel")
	_check(not hint.visible and not pad.is_processing(), "both hints must clear after walking and jumping")

	await _touch(intro, finish)
	intro.get_node("%ReplayButton").pressed.emit()
	await _frames(12)
	_check(controls.text == walk_text + "\n" + jump_text, "replay did not reset both hints")
	await _jump_in_intro(pad, touch_enabled)
	_check(player.velocity.y > 0.0 and hint.visible and controls.text == walk_text, "jumping before walking discarded the movement hint")
	_check(keyboard.visible != touch_enabled and pad.is_processing() == touch_enabled, "jump-first replay lost the active movement demonstration")
	intro.queue_free()
	await _frames(2)


func _jump_in_intro(pad: Control, touch_enabled: bool) -> void:
	if touch_enabled:
		var touch := InputEventScreenTouch.new()
		touch.position = pad.jump_center()
		touch.pressed = true
		root.push_input(touch, true)
		await _frames(2)
		touch.pressed = false
		root.push_input(touch, true)
	else:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_SPACE
		key.pressed = true
		Input.parse_input_event(key)
		await _frames(2)
		key.pressed = false
		Input.parse_input_event(key)


func _open(path: String) -> Node:
	var lesson := (load(path) as PackedScene).instantiate()
	root.add_child(lesson)
	await _frames(4)
	return lesson


func _touch(lesson: Node, target: Area3D) -> void:
	var player := lesson.get_node("Camiel")
	player.teleport_to(target.global_position - Vector3(0, 0.4, 0))
	await _frames(12)


func _frames(count: int) -> void:
	for index in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)
