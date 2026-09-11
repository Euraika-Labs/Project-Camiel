# Coding Conventions

**Analysis Date:** 2026-09-11

Project Camiel is a Godot `4.6.2.stable` game for children aged around 3 years. Product code is GDScript under `scripts/` attached to scenes under `scenes/`. Repository tooling is Python 3 under `scripts/tools/` and `scripts/ui/`. Files under `.pi/workflows/runs/` are tooling run logs, not product code; ignore them when deriving conventions.

## Naming Patterns

**Files:**
- GDScript files use `snake_case.gd` and are named after the scene they drive: `scenes/red_block.tscn` uses `scripts/red_block.gd`, `scenes/ui/dialog_popup.tscn` uses `scripts/ui/dialog_popup.gd`.
- Scenes use `snake_case.tscn`. Reusable UI scenes go in `scenes/ui/`, their scripts in `scripts/ui/`.
- Lessons are numbered: `scenes/lesson_N.tscn` with `scripts/lesson_N.gd`. The exception is lesson 1, which uses `scripts/lesson_manager.gd`.
- Headless tool scripts (run with `--script`) live in `scripts/tools/` and are named `verb_noun.gd`, for example `scripts/tools/verify_camiel_resources.gd` and `scripts/tools/build_camiel_resources.gd`.
- Animation frames follow `assets/camiel/animations/<action>_<facing>/camiel_<action>_<facing>_NN.png` (two-digit, 1-based). `scripts/tools/build_camiel_resources.gd` builds these paths with `"%s/%s/camiel_%s_%02d.png"`.
- `.gd.uid` files sit next to some scripts (`scripts/camiel_controller.gd.uid`). Godot generates them; commit them and never edit them by hand.

**Functions:**
- Use `snake_case` for all functions.
- Public API: no prefix (`play_sfx`, `show_message`, `set_progress`, `activate`, `get_star_count`).
- Private helpers: leading underscore (`_update_label`, `_apply_success`, `_play`, `_get_or_create_player`).
- Signal handlers: `_on_<source>_<signal>` (`_on_body_entered`, `_on_ok_button_pressed`, `_on_back_button_pressed`, `_on_mobile_move_vector`).
- Engine callbacks keep their Godot names: `_ready`, `_process`, `_physics_process`, `_input`, `_initialize` (tool scripts that extend `SceneTree`).
- Input-poll helpers are boolean predicates named `_<action>_pressed` (`scripts/camiel_controller.gd`: `_jump_pressed`, `_run_pressed`, `_sit_pressed`).
- Success/completion appliers are named `_apply_<outcome>` (`_apply_success`, `_apply_complete`, `_apply_lesson_complete`).

**Variables:**
- Private state: `_snake_case` with a leading underscore (`_touched`, `_facing`, `_completed_tasks`, `_current_step`).
- Exported tunables: `@export var snake_case` with no underscore (`walk_speed`, `success_color`, `order_number`, `num_to_collect`).
- Node references: `@onready var snake_case` named after the node's role (`color_rect`, `message_label`, `ok_button`).
- Unused parameters get a leading underscore (`_delta`, `_body` in `scripts/finish_marker.gd`).

**Types / constants / signals:**
- Constants: `UPPER_SNAKE_CASE` with `:=` (`const BGM_PATH := "res://assets/audio/bgm_ambient.ogg"`, `const EXPECTED := {...}`).
- Enums: `PascalCase` type, `UPPER_SNAKE_CASE` members (`enum ShapeType { CIRCLE, SQUARE, TRIANGLE }` in `scripts/shape_target.gd`).
- Signals: past-tense `snake_case` (`task_completed`, `lesson_finished`, `collected`, `dismissed`, `progress_saved`). Declare typed arguments when there are any: `signal task_completed(task_name: String)`.
- Autoload singletons use `PascalCase` names registered in `project.godot`: `AudioManager`, `Accessibility`, `ProgressTracker`.
- Node groups are lowercase `snake_case` strings: `"player"`, `"collectibles"`, `"count_collectibles"`, `"main"`, `"mobile_controller"`.
- No script uses `class_name`. Reach other scripts through autoloads, groups, or node paths instead of adding global class names.

## Code Style

**Formatting:**
- No GDScript formatter (`gdformat`) or config is present. `.editorconfig` is the only formatting authority:
  - `charset = utf-8`, `end_of_line = lf`, `insert_final_newline = true`, `trim_trailing_whitespace = true` for every file.
  - `*.png` is exempt from the final newline rule.
- Indent GDScript with **tabs** (every `.gd` file does; no file uses space indentation). Indent Python with 4 spaces (PEP 8).
- Put **two blank lines** between top-level functions. Most scripts do this (`scripts/red_block.gd`, `scripts/audio_manager.gd`). A few use one blank line (`scripts/camiel_controller.gd`, `scripts/intro_scene.gd`, `scripts/mobile_controller.gd`); use two in new code.
- Script layout order, as in `scripts/sequence_target.gd`:
  1. Header comment block (`# file_name.gd` then a one-to-three line purpose summary)
  2. `extends <NodeType>`
  3. `signal` declarations
  4. `enum` / `const`
  5. `@export var`
  6. `@onready var`
  7. private `var _state`
  8. `_ready()` and other engine callbacks
  9. public methods
  10. private helpers

**Typing:**
- Use static typing. Give functions a return type (`-> void`, `-> int`, `-> Error`) and type their parameters. Only `_ready()` in `scripts/mobile_controller.gd` and `scripts/progress_tracker.gd` leave out the return type.
- Prefer `:=` inference for literals (`var _touched := false`) and explicit `: Type` for node references (`@onready var label: Label = $Label`).
- About 130 declarations are typed or inferred and 17 use plain `var x = ...`, mostly in `scripts/mobile_controller.gd` and `scripts/progress_tracker.gd`. Write typed declarations in new code.
- Type arrays when the element type is known: `var _completed_tasks: Array[String] = []`.
- Type loop variables in tool scripts: `for animation_name: String in EXPECTED.keys():`.
- Cast engine loads explicitly: `var stream := load(path) as AudioStream`.

**Linting:**
- No GDScript linter (`gdlint`, `gdtoolkit`) is configured. Python has no linter config (`pyproject.toml`, `setup.cfg`) either.
- The repository-wide lint is the custom quality gate `scripts/tools/quality_gate.py`, run in CI (`.github/workflows/ci.yml`, `.github/workflows/export.yml`). It fails the build on:
  - **Forbidden phrases** in any text file: assistant self-disclaimers, unfinished-work markers (the uppercase to-do, fix-me, and to-be-determined tags), filler copy (lorem ipsum, sample/example text, the word "dum" + "my", replace-me, your-text-here, insert-X-here), and "coming soon" promises. Write complete copy instead. Only when a doc must name one of these phrases, add `<!-- quality-gate: allow forbidden-phrase -->` on that line (see `docs/build-and-release.md:134`).
  - **Broken or out-of-repo relative Markdown links** in any `.md` file.
  - **Missing `res://` paths** in `.gd`, `.tscn`, `.tres`, `.godot`, `.cfg` files.
  - **Empty tracked files.**
  - **PNG under `assets/` without a sibling `.png.import`.**
  - **Missing required community/CI files** (`README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.github/workflows/ci.yml`, and others).
- The gate scans untracked, non-ignored files too, `.planning/` included. Keep planning documents free of forbidden phrases and broken relative links.

**Python style (tooling only):**
- Start files with `#!/usr/bin/env python3` and `from __future__ import annotations` (`scripts/tools/quality_gate.py`).
- Type-hint everything with modern syntax (`list[Path]`, `Iterable[Path] | None`) and use `NamedTuple` for result records (`Finding`).
- Keep module-level constants in `UPPER_SNAKE_CASE` sets (`IGNORED_DIRS`, `FORBIDDEN_PATTERNS`).
- Use small pure `check_*` functions that return `list[Finding]`, and a `main(argv) -> int` wired as `raise SystemExit(main())`.

## Import Organization

GDScript has no imports. Dependencies are resolved like this:

**Order of preference:**
1. Child nodes through `@onready` and `$Path` (`@onready var message_label: Label = $Panel/VBox/Label`).
2. Autoload singletons called by name (`AudioManager.play_sfx("finish")`).
3. Groups for loosely coupled lookup (`get_tree().get_first_node_in_group("mobile_controller")`, `body.is_in_group("player")`).
4. `load("res://...")` with `const` path constants for resources (`scripts/audio_manager.gd`, `scripts/tools/build_camiel_resources.gd`).

**Path aliases:**
- Always use `res://` absolute resource paths. Every `res://` string is validated by the quality gate, so a typo fails CI.
- Save data goes under `user://` (`user://progress.json` in `scripts/progress_tracker.gd`).

**Python imports:** stdlib only. Order `__future__`, then stdlib alphabetically, then `from` imports (`scripts/tools/quality_gate.py`). No third-party packages.

## Error Handling

**Patterns:**
- **Runtime game code fails soft.** Never crash a child's session. Use guard clauses with early `return`, and warn with `push_warning` prefixed with the class tag:
  ```gdscript
  func play_music(path: String) -> void:
  	if not ResourceLoader.exists(path):
  		push_warning("[AudioManager] BGM not found: ", path)
  		return
  	var stream := load(path) as AudioStream
  	if stream == null:
  		push_warning("[AudioManager] Could not load BGM: ", path)
  		return
  ```
- **One-shot triggers** use a boolean latch plus a group check at the top of `_on_body_entered`. Every `Area2D` target (`scripts/red_block.gd`, `scripts/blue_target.gd`, `scripts/shape_target.gd`, `scripts/sequence_target.gd`, `scripts/collectible.gd`, `scripts/finish_marker.gd`) follows this shape:
  ```gdscript
  func _on_body_entered(body: Node2D) -> void:
  	if _touched:
  		return
  	if not body.is_in_group("player"):
  		return
  	_touched = true
  	_apply_success()
  ```
- **Optional collaborators** are null-checked or duck-typed before use:
  ```gdscript
  var main = get_tree().get_first_node_in_group("main")
  if main and main.has_method("_on_finish_reached"):
  	main._on_finish_reached()
  ```
  The same approach appears as `has_signal("collected")` plus `is_connected` in `scripts/game_hud.gd` and `scripts/count_challenge.gd`, and as `get_node_or_null(...) as CanvasLayer` in `scripts/intro_scene.gd`.
- **Headless tool scripts fail hard.** Call `push_error(...)`, then `quit(1)`, then `return` for every failed check, and finish with `print(...)` and `quit(0)` (`scripts/tools/verify_camiel_resources.gd`). This is what makes CI go red.
  ```gdscript
  if not frames.has_animation(animation_name):
  	push_error("Missing animation: %s" % animation_name)
  	quit(1)
  	return
  ```
- **Engine `Error` codes** are propagated from helpers and reported with `error_string(err)` (`scripts/tools/build_camiel_resources.gd`).
- **Child-facing errors are gentle.** Wrong actions show a brief colour flash and friendly Dutch copy ("Nog eens proberen!"), then reset after a timer (`scripts/sequence_target.gd` `_flash_error`). Never show a failure state or punishment.
- **File I/O:** check `FileAccess.file_exists` and whether the handle is truthy before reading or writing (`scripts/progress_tracker.gd`). Note that this file passes `JSON.SINDY_USE_HELPER`, which is not a Godot constant, and it does not check whether `JSON.parse_string` returned null. Don't copy that call; use `JSON.stringify(data, "\t")`.
- **Python tooling:** catch specific exceptions (`FileNotFoundError`, `subprocess.CalledProcessError`) and fall back rather than raise. Report problems as data (`Finding`) and return an exit code from `main`.

## Logging

**Framework:** Godot built-ins (`print`, `push_warning`, `push_error`). No logging library.

**Patterns:**
- `push_error` only in `scripts/tools/*.gd` for CI-failing conditions.
- `push_warning("[ClassTag] message: ", value)` for recoverable runtime problems (`scripts/audio_manager.gd`).
- `print("[ClassTag] ...")` for state changes in autoloads (`scripts/accessibility.gd`).
- Some task scripts `print` debug confirmations (`scripts/red_block.gd:36`, `scripts/sequence_target.gd:30,69`, `scripts/shape_target.gd:55`, `scripts/blue_target.gd:36`). Keep new logs tagged, and don't add per-frame prints.
- The quality gate prints GitHub annotations (`::error file=...,line=...,title=...::`) when `GITHUB_ACTIONS=true`, and `path:line: code: message` otherwise.

## Comments

**When to Comment:**
- Start every gameplay script with a header naming the file and stating its purpose and trigger (`scripts/lesson_3.gd`, `scripts/red_block.gd`). Older scripts without one (`scripts/collectible.gd`, `scripts/hud.gd`, `scripts/main_menu.gd`) are the exception.
  ```gdscript
  # red_block.gd
  # Educational micro-task: touch the red block.
  # On Camiel's first touch the block turns green and plays a chime.
  extends Area2D
  ```
- Use inline trailing comments to explain units and intent (`var _mobile_jump_queued := false  # rising-edge jump flag for mobile`).
- Box-drawing section banners `# ── Section ─────` group long autoloads (`scripts/audio_manager.gd`: Bus names, Default asset paths, Internal state, Lifecycle, Public API, Internal helpers). Use them in files longer than about 60 lines.
- Numbered step comments are fine for multi-step sequences (`scripts/finish_marker.gd` `_reach_finish`).

**Doc comments:**
- Use GDScript `##` doc comments on public autoload API and cross-script entry points:
  ```gdscript
  ## Play a one-shot SFX. Supported event types: "collect", "finish".
  func play_sfx(event: String, custom_path: String = "") -> void:
  ```
  See `scripts/audio_manager.gd`, `scripts/accessibility.gd`, and `scripts/intro_scene.gd` (`## Called by FinishMarker when the player reaches the flag.`).
- Don't put unfinished-work tags in comments. The quality gate rejects them.

## Function Design

**Size:** Keep functions short. Most are under 15 lines, and the largest script is `scripts/audio_manager.gd` at 114 lines. Split behaviour into `_apply_*` / `_update_*` helpers instead of growing `_ready` or `_process`.

**Parameters:**
- Type parameters and use defaults for optional ones (`func show_message(msg: String, button_text: String = "OK") -> void`, `func _play(base_name: String, restart := false) -> void`).
- To pass context from a signal, use `Callable.bind` instead of wrapper lambdas:
  ```gdscript
  red_block.task_completed.connect(_on_task_completed.bind("red_block"))
  ```
- Clamp numeric input at the boundary (`clampf(linear, 0.0, 1.0)` in `scripts/audio_manager.gd`, `clampf(position.x, min_x, max_x)` in `scripts/camiel_controller.gd`).

**Return Values:**
- Return `void` for actions, a typed value for getters (`get_star_count() -> int`), and `Error` for tool helpers that save resources.
- Return empty containers instead of null (`return {}` in `_load_progress`, `return result` for an empty `Array[CanvasLayer]` in `scripts/accessibility.gd`).

**Async:**
- Use `await get_tree().create_timer(seconds).timeout` for celebration and feedback delays, then change the scene:
  ```gdscript
  func _apply_lesson_complete() -> void:
  	progress_label.text = "Goed zo! Alle stappen goed!"
  	AudioManager.play_sfx("finish")
  	await get_tree().create_timer(2.0).timeout
  	lesson_finished.emit()
  	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
  ```

## Module Design

**Exports / public surface:**
- Scripts talk upward through **signals** (`task_completed`, `collected`, `lesson_finished`) and downward through **direct method calls** on `@onready` children (`target_2.activate()`).
- Lesson orchestrators (`scripts/lesson_manager.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd`) connect child task signals in `_ready`, track progress in a private array or counter, update a Dutch progress label, and return to `res://scenes/main_menu.tscn`.
- Connect signals in code inside `_ready` for script-owned wiring (`body_entered.connect(_on_body_entered)`). Use `[connection ...]` entries in `.tscn` for editor-placed buttons (`BackButton` pressed goes to `_on_back_button_pressed` in `scenes/lesson_2.tscn` through `scenes/lesson_5.tscn`).
- Connect each signal one way only. `scenes/collectible.tscn` and `scenes/finish_marker.tscn` connect `body_entered` in the scene file and their scripts connect it again in `_ready`, which gives a duplicate-connection risk.
- Put cross-scene state in the autoloads registered in `project.godot`: `scripts/audio_manager.gd`, `scripts/accessibility.gd`, `scripts/progress_tracker.gd`. Add new global services there, not as `class_name` statics.
- Don't call another script's private (`_`-prefixed) method. `scripts/lesson_3.gd` calls `target_2._set_inactive()` and `scripts/accessibility.gd` calls `layer._apply_contrast(...)`; expose a public method instead.

**Barrel Files:** Not applicable (GDScript).

**Child-facing copy:**
- Write on-screen text in Dutch, short and encouraging ("Goed zo!", "Nog eens proberen!", "Stap: %d / 3"). Some older HUD strings are still English (`"Stars: %d"` in `scripts/hud.gd` and `scripts/game_hud.gd`, `"Count: %d"` in `scripts/count_challenge.gd`).
- Per `CONTRIBUTING.md`: simple, friendly, low pressure, visually clear. Discuss complex interactions before adding them.

**Version strings:**
- `"alpha-v0.0.3"` is hard-coded in `scripts/title_screen.gd`, `scripts/main_menu.gd`, `scripts/ui/menu_button.gd`, `scripts/ui/version_label.gd`, and `project.godot` (`config/name`). Update all of them together when bumping the version.

---

*Convention analysis: 2026-09-11*
