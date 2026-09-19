extends SceneTree
## Real viewport dispatch plus player physics, without a physical touch device.

var failures := 0
var frames := 0


func _initialize() -> void:
	process_frame.connect(func():
		frames += 1
		if frames > 1200:
			push_error("[probe_touch_controls] watchdog expired")
			quit(1)
	)
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("[probe_touch_controls] FAIL: " + label)


func touch(index: int, position: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)


func drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	root.push_input(event, true)


func _run() -> void:
	var paths: Array[String] = [
		"res://scenes/intro_level.tscn",
		"res://scenes/lesson_1.tscn",
		"res://scenes/lesson_2.tscn",
		"res://scenes/lesson_3.tscn",
		"res://scenes/lesson_4.tscn",
		"res://scenes/lesson_5.tscn",
		"res://scenes/lesson_6.tscn",
	]
	for path in paths:
		var scene: Node = load(path).instantiate()
		root.add_child(scene)
		current_scene = scene
		await process_frame
		var player: CharacterBody3D = get_first_node_in_group("player")
		check(player != null, path + " has player")
		var pad: Control = player.get_node("TouchLayer/TouchControls")
		pad.available = true
		pad.show()
		await process_frame
		for frame in range(20):
			await physics_frame
		var center: Vector2 = pad.stick_center()
		var jump: Vector2 = pad.jump_center()
		check(pad.size.x >= 400 and pad.size.y >= 224, "usable touch layout")
		touch(3, center, true)
		drag(3, center + Vector2(5, 0))
		check(pad.movement == Vector2.ZERO, "deadzone stops drift")
		drag(3, center + Vector2(42, 0))
		check(is_equal_approx(pad.movement.x, (0.5 - 0.12) / 0.88), "proportional half stick")
		touch(8, center + Vector2(-60, 0), true)
		drag(8, center - Vector2(84, 0))
		touch(8, center, false)
		check(pad.movement.x > 0.4, "third finger cannot steal or release stick")
		for frame in range(12):
			await physics_frame
		check(Vector2(player.velocity.x, player.velocity.z).length() > 0.8, "touch moves actual player")
		check(Vector2(player.velocity.x, player.velocity.z).length() < 1.3, "half stick retains partial speed")
		touch(7, jump, true)
		await physics_frame
		await physics_frame
		check(player.velocity.y > 0, "second finger jumps while moving")
		touch(7, Vector2.ZERO, false)
		check(pad.movement.x > 0.4, "jump release preserves movement")
		drag(3, center + Vector2(400, 400))
		check(is_equal_approx(pad.movement.length(), 1.0), "diagonal clamped outside pad")
		touch(3, Vector2.ZERO, false)
		check(pad.movement == Vector2.ZERO, "off-pad release clears movement")
		touch(3, center + Vector2(84, 0), true)
		touch(7, jump, true)
		touch(3, center, false, true)
		check(pad.movement == Vector2.ZERO and pad.jump_finger == 7, "cancellation is independent")
		pad.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(pad.movement == Vector2.ZERO and pad.jump_finger == -1 and not pad.consume_jump(), "focus loss clears all state")
		drag(3, center + Vector2(84, 0))
		check(pad.movement == Vector2.ZERO, "stale drag after focus loss ignored")
		touch(3, center + Vector2(84, 0), true)
		touch(7, jump, true)
		pad.hide()
		check(pad.movement == Vector2.ZERO and not pad.consume_jump(), "hiding clears state")
		pad.show()
		touch(7, jump, true)
		touch(3, center + Vector2(84, 0), true)
		check(pad.consume_jump() and pad.movement.x > 0.99, "jump-first ordering permits movement")
		check(not pad.consume_jump(), "held jump fires only once")
		pad.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		check(pad.movement == Vector2.ZERO and pad.jump_finger == -1, "app suspension clears state")
		touch(7, jump, true)
		player.set_physics_process(false)
		await process_frame
		await process_frame
		check(not pad.visible and not pad.consume_jump(), "win freeze hides pad and clears jump")
		player.set_physics_process(true)
		await process_frame
		await process_frame
		Input.action_press("move_left")
		touch(3, center, true)
		touch(3, center, false)
		check(Input.is_action_pressed("move_left"), "touch release preserves keyboard")
		Input.action_release("move_left")
		touch(3, center + Vector2(84, 0), true)
		scene.queue_free()
		await process_frame
		await process_frame
		check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("jump"), "scene exit leaks no actions")
		print("[probe_touch_controls] checked " + path)
	if failures == 0:
		print("[probe_touch_controls] ALL PASS (%d scenes)" % paths.size())
	quit(1 if failures else 0)
