extends Node2D

@onready var message: Label = $UI/MessagePanel/Message
@onready var win_layer: CanvasLayer = $WinLayer
@onready var win_title: Label = $WinLayer/WinOverlay/VBox/WinTitle
@onready var win_stars: Label = $WinLayer/WinOverlay/VBox/StarCount
@onready var win_replay: Label = $WinLayer/WinOverlay/VBox/ReplayPrompt

var _finished := false
var _replay_timer := 0.0
var _show_replay := false

func _ready() -> void:
	add_to_group("main")
	win_layer.visible = false

func _process(_delta: float) -> void:
	if _finished:
		_replay_timer += _delta
		if _replay_timer >= 2.0 and not _show_replay:
			_show_replay = true
			win_replay.visible = true
		if _show_replay and Input.is_key_pressed(KEY_ENTER):
			get_tree().reload_current_scene()
		return

	# ── Intro controls ──────────────────────────────────────────────────────
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		message.text = "Spring, Camiel!"
		return
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):
		message.text = "Goed zo, Camiel wandelt!"
		return
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		message.text = "Camiel zit rustig."
		return
	if Input.is_key_pressed(KEY_X):
		message.text = "Slaap lekker, Camiel."
		return
	message.text = "Hallo! Help Camiel op ontdekking."

## Called by FinishMarker when the player reaches the flag.
func _on_finish_reached() -> void:
	if _finished:
		return
	_finished = true

	# Read star count from game_hud if present.
	var stars := _get_star_count()

	message.text = "Goed zo!"
	win_title.text = "Goed zo!"
	win_stars.text = "Sterren: %d / 3" % stars
	win_replay.visible = false
	_replay_timer = 0.0
	_show_replay = false
	win_layer.visible = true

func _get_star_count() -> int:
	# game_hud is a sibling CanvasLayer; read its _stars field.
	var hud := get_node_or_null("GameHUD") as CanvasLayer
	if hud and hud.has_method("get_star_count"):
		return hud.get_star_count()
	return 0
