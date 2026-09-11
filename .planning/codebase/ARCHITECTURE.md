<!-- refreshed: 2026-09-11 -->
# Architecture

**Analysis Date:** 2026-09-11

## System Overview

Project Camiel is a small Godot 4.6 (Forward Plus, GDScript) 2D educational game for young children (UI copy in Dutch). The player controls Camiel the dog (`CharacterBody2D`) through a title screen, a menu, an intro "free play" level, and short lesson scenes built from reusable touch-to-complete task scenes.

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                  Autoload singletons (project.godot [autoload])          │
├────────────────────────┬────────────────────────┬────────────────────────┤
│  AudioManager          │  Accessibility         │  ProgressTracker       │
│ `scripts/audio_        │ `scripts/              │ `scripts/progress_     │
│  manager.gd`           │  accessibility.gd`     │  tracker.gd`           │
└───────────┬────────────┴───────────┬────────────┴───────────┬────────────┘
            │ play_sfx()             │ (not called yet)       │ (not called yet)
            ▼                        ▼                        ▼
┌──────────────────────────────────────────────────────────────────────────┐
│            Screen / level scenes (root switched via change_scene_to_file)│
│ title_screen.tscn → main_menu.tscn ─┬─ Enter key → main.tscn (intro)     │
│  `scripts/title_screen.gd`          └─ LessonButton → lesson_1.tscn      │
│  `scripts/main_menu.gd`   lesson_2..5.tscn exist but no link reaches them│
└───────────┬──────────────────────────────────────────────┬───────────────┘
            │ instance                                     │ instance
            ▼                                              ▼
┌───────────────────────────────┐    ┌─────────────────────────────────────┐
│  Player                       │    │  Task / pickup scenes (Area2D)      │
│ `scenes/camiel.tscn`          │    │ red_block, blue_target, shape_target│
│ `scripts/camiel_controller.gd`│◄───│ sequence_target, collectible,       │
│  group "player"               │body│ count_challenge, finish_marker      │
└───────────────────────────────┘ent.│ → emit task_completed / collected   │
                                     └───────────────┬─────────────────────┘
                                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  Level orchestrators (root script of each level scene)                   │
│ `scripts/intro_scene.gd` + `scripts/game_hud.gd` (main.tscn)             │
│ `scripts/lesson_manager.gd` (lesson_1) `scripts/lesson_2.gd` `lesson_3.gd`│
└──────────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  Assets: `assets/camiel/camiel_sprite_frames.tres`, `assets/audio/*.ogg`, │
│  `assets/collectibles/star.png`; persistence: `user://progress.json`     │
└──────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| AudioManager (autoload) | Creates `BGM`/`SFX` `AudioStreamPlayer` children, auto-plays `bgm_ambient.ogg`, `play_sfx("collect"/"finish")`, volume setters | `scripts/audio_manager.gd` |
| Accessibility (autoload) | High-contrast flag; walks the whole tree and calls `_apply_contrast(bool)` on every `CanvasLayer` that defines it | `scripts/accessibility.gd` |
| ProgressTracker (autoload) | Appends lesson results to `user://progress.json`, emits `progress_saved` | `scripts/progress_tracker.gd` |
| Title screen | Plays Camiel idle anim, Play → main menu | `scripts/title_screen.gd`, `scenes/title_screen.tscn` |
| Main menu | Enter key → intro level; LessonButton → lesson 1 | `scripts/main_menu.gd`, `scenes/main_menu.tscn` |
| Camiel player | Keyboard + mobile-signal movement, gravity/jump, clamped X, `<action>_<facing>` animations | `scripts/camiel_controller.gd`, `scenes/camiel.tscn` |
| Intro level controller | Contextual help message, win overlay, reload-on-Enter | `scripts/intro_scene.gd` (root of `scenes/main.tscn`) |
| Game HUD | Counts `collected` signals from group `collectibles`, exposes `get_star_count()` | `scripts/game_hud.gd` (node `GameHUD` in `scenes/main.tscn`) |
| Finish marker | On player contact: SFX, calls `_on_finish_reached()` on group `main`, replay prompt | `scripts/finish_marker.gd`, `scenes/finish_marker.tscn` |
| Collectible star | Bobbing pickup, emits `collected`, joins group `collectibles` | `scripts/collectible.gd`, `scenes/collectible.tscn` |
| Lesson 1 orchestrator | Red block + blue target + count challenge (3 stars) | `scripts/lesson_manager.gd`, `scenes/lesson_1.tscn` |
| Lesson 2 orchestrator | Touch circle/square/triangle shape targets | `scripts/lesson_2.gd`, `scenes/lesson_2.tscn` |
| Lesson 3 orchestrator | Ordered activation of 3 sequence targets | `scripts/lesson_3.gd`, `scenes/lesson_3.tscn` |
| Lessons 4/5 | Placeholder scenes (title, subtitle, back button) | `scenes/lesson_4.tscn`, `scenes/lesson_5.tscn`, `scripts/lesson_4.gd`, `scripts/lesson_5.gd` |
| Mobile controller | Touch joystick + jump button, emits `move_vector(Vector2)` / `jump()` | `scripts/mobile_controller.gd`, `scenes/ui/mobile_controller.tscn`, `scenes/ui/mobile_joystick.tscn` |
| Reusable UI widgets | Dialog popup, styled menu button, progress bar, version label | `scripts/ui/*.gd`, `scenes/ui/*.tscn` |
| Resource builder (editor tool) | Rebuilds `camiel_sprite_frames.tres` from PNG frames; also re-packs `camiel.tscn` and `main.tscn` | `scripts/tools/build_camiel_resources.gd` |
| Resource verifier (CI) | Asserts expected animation names/frame counts in SpriteFrames | `scripts/tools/verify_camiel_resources.gd` |
| Repo quality gate (CI) | Python checks: required files, empty files, forbidden phrases (unfinished-work markers, placeholder copy — full list in `FORBIDDEN_PATTERNS` of the gate script), markdown links, `res://` paths, `.import` metadata | `scripts/tools/quality_gate.py`, `tests/test_quality_gate.py` |

## Pattern Overview

**Overall:** Godot scene-composition architecture — self-contained `.tscn` scenes each with one root script, wired by signals up the tree, with a handful of global autoload services.

**Key Characteristics:**
- One script per scene root; child scenes (tasks, pickups) are dumb components that emit signals and never know their parent.
- Level root scripts act as orchestrators: they grab children via `@onready var x = $NodeName` and connect child signals in `_ready()`, often with `.bind("task_name")`.
- Cross-cutting services (audio, accessibility, persistence) are autoload singletons called by global name (`AudioManager.play_sfx("finish")`).
- Discovery by groups rather than paths when crossing scene boundaries: `"player"`, `"collectibles"`, `"count_collectibles"`, `"main"`, `"mobile_controller"`, `"finish"`.
- Navigation is flat: every transition is `get_tree().change_scene_to_file("res://scenes/<name>.tscn")` or `reload_current_scene()`. No scene stack, no transition manager.
- Visuals are mostly `ColorRect` primitives; only Camiel and the star use textures.

## Layers

**Autoload services:**
- Purpose: Global, scene-change-surviving state and side effects.
- Location: `scripts/audio_manager.gd`, `scripts/accessibility.gd`, `scripts/progress_tracker.gd` (registered in `project.godot` `[autoload]`, in that order)
- Contains: `extends Node` singletons with public methods and (ProgressTracker) a signal.
- Depends on: Godot `AudioServer`, `FileAccess`, `JSON`, asset files under `assets/audio/`.
- Used by: Task scenes and orchestrators (`AudioManager` only). `Accessibility` and `ProgressTracker` have no callers in `scripts/` or `scenes/`.

**Screens / levels:**
- Purpose: Top-level scenes the SceneTree root swaps between.
- Location: `scenes/title_screen.tscn`, `scenes/main_menu.tscn`, `scenes/main.tscn`, `scenes/lesson_1.tscn` … `scenes/lesson_5.tscn`
- Contains: Background `ColorRect`s, `StaticBody2D` ground, `Camera2D`, labels, instanced components; root script orchestrates.
- Depends on: Component scenes, autoloads.
- Used by: `project.godot` `run/main_scene` and `change_scene_to_file` calls.

**Gameplay components:**
- Purpose: Reusable interactive pieces.
- Location: `scenes/camiel.tscn`, `scenes/collectible.tscn`, `scenes/count_challenge.tscn`, `scenes/finish_marker.tscn`, `scenes/red_block.tscn`, `scenes/blue_target.tscn`, `scenes/shape_target.tscn`, `scenes/sequence_target.tscn` with matching `scripts/<name>.gd`
- Contains: `Area2D` + `CollisionShape2D` + `ColorRect`/`Label`; `@export` tuning vars; one-shot `_touched`/`_found` guards.
- Depends on: `AudioManager`, group `"player"`.
- Used by: Level scenes.

**UI widgets:**
- Purpose: Reusable HUD/menu pieces.
- Location: `scenes/ui/`, `scripts/ui/`, plus `scripts/game_hud.gd`, `scripts/hud.gd`, `scripts/mobile_controller.gd`
- Depends on: Nothing global except `AudioManager` (HUDs).
- Used by: Only `game_hud.gd` is used (inline in `scenes/main.tscn`). `dialog_popup`, `menu_button`, `progress_bar`, `version_label`, `mobile_controller`, `mobile_joystick`, and `scripts/hud.gd` are not instanced anywhere.

**Tooling (not shipped gameplay):**
- Purpose: Asset generation, CI verification, repo hygiene.
- Location: `scripts/tools/`, `scripts/ui/extract_templates.py`, `tests/`, `.github/workflows/`
- Runs via: `godot --headless --script res://scripts/tools/<tool>.gd` (`extends SceneTree`) or `python3`.

## Data Flow

### Primary Request Path (boot → play)

1. Engine loads autoloads `AudioManager`, `Accessibility`, `ProgressTracker` (`project.godot` `[autoload]`); `AudioManager._ready()` starts BGM (`scripts/audio_manager.gd:28-45`).
2. Main scene `res://scenes/title_screen.tscn` loads (`project.godot` `run/main_scene`); `title_screen.gd._ready()` focuses Play and plays `idle_right` (`scripts/title_screen.gd:13-15`).
3. Play pressed / `ui_accept` → `change_scene_to_file("res://scenes/main_menu.tscn")` (`scripts/title_screen.gd:23-24`).
4. Main menu: `KEY_ENTER` → `res://scenes/main.tscn` (`scripts/main_menu.gd:13-15`); `LessonButton.pressed` → `res://scenes/lesson_1.tscn` (`scripts/main_menu.gd:18-19`).
5. In a level, `camiel_controller.gd._physics_process` reads keys (A/D/arrows, Shift run, Space/W/Up jump, S sit, X sleep) and moves (`scripts/camiel_controller.gd:33-58`).

### Intro level (main.tscn) win flow

1. `Collectible.body_entered` (player group) → hides, emits `collected` (`scripts/collectible.gd:29-37`).
2. `GameHUD._on_collectible_collected` increments stars and plays `collect` SFX (`scripts/game_hud.gd:22-25`).
3. `FinishMarker.body_entered` → `AudioManager.play_sfx("finish")`, then finds group `"main"` and calls `_on_finish_reached()` directly (`scripts/finish_marker.gd:30-38`).
4. `intro_scene.gd._on_finish_reached` reads `GameHUD.get_star_count()` and shows `WinLayer` (`scripts/intro_scene.gd:45-64`).
5. After 2 s, Enter → `get_tree().reload_current_scene()` (`scripts/intro_scene.gd:17-23`, also `scripts/finish_marker.gd:49-51`).

### Lesson flow (lesson_1 / 2 / 3)

1. Orchestrator `_ready()` connects each task's `task_completed` with `.bind(<id>)` (`scripts/lesson_manager.gd:18-22`, `scripts/lesson_2.gd:18-22`, `scripts/lesson_3.gd:18-32`).
2. Task `Area2D` detects player, recolors, plays SFX, emits `task_completed` (`scripts/red_block.gd:30-35`, `scripts/shape_target.gd:48-53`, `scripts/sequence_target.gd:62-67`).
3. `CountChallenge` counts `collected` from nodes in group `count_collectibles` and emits `task_completed` at 3 (`scripts/count_challenge.gd:22-42`).
4. Orchestrator updates `ProgressLabel`, and on completion awaits a 2 s timer, emits `lesson_finished` (no listeners), and returns to `res://scenes/main_menu.tscn` (`scripts/lesson_manager.gd:34-41`).
5. Lesson 3 gating: orchestrator calls `activate()` on the next `SequenceTarget`; inactive targets call `_flash_error()` (`scripts/lesson_3.gd:35-52`, `scripts/sequence_target.gd:37-58`).

### Signals map

| Signal | Emitter | Listener |
|--------|---------|----------|
| `task_completed(task_name)` | `red_block.gd`, `blue_target.gd`, `shape_target.gd`, `sequence_target.gd` | `lesson_manager.gd`, `lesson_2.gd`, `lesson_3.gd` |
| `task_completed` (no args) | `count_challenge.gd` | `lesson_manager.gd._on_lesson_complete` |
| `collected` | `collectible.gd` | `game_hud.gd`, `count_challenge.gd` |
| `finished` | declared in `finish_marker.gd`, never emitted | `scenes/main.tscn` connection → `_on_finish_reached` (dead) |
| `lesson_finished` | `lesson_manager.gd`, `lesson_2.gd`, `lesson_3.gd` | none |
| `progress_saved` | `progress_tracker.gd` | none |
| `move_vector(v)`, `jump()` | `mobile_controller.gd` | `camiel_controller.gd` (only if a node in group `mobile_controller` exists) |
| `dismissed` | `scripts/ui/dialog_popup.gd` | none |
| `SceneTree.group_added` | engine | `game_hud.gd._on_group_added_collectible` |
| `pressed` (editor connections) | `PlayButton`, `LessonButton`, `BackButton`s, `OkButton` | `.tscn` `[connection]` entries |

**State Management:**
- Per-scene state lives in private vars on root/component scripts (`_completed_tasks`, `_stars`, `_touched`); it is discarded on every scene change.
- Cross-scene state: only autoloads. Audio volume lives in `AudioManager`; contrast flag in `Accessibility` (not persisted); lesson history in `user://progress.json` via `ProgressTracker` (never invoked).

## Key Abstractions

**Touch task (Area2D micro-task):**
- Purpose: One learning interaction completed when Camiel touches it.
- Examples: `scripts/red_block.gd`, `scripts/blue_target.gd`, `scripts/shape_target.gd`, `scripts/sequence_target.gd`
- Pattern: `signal task_completed(task_name: String)`; `body_entered.connect(_on_body_entered)` in `_ready()`; guard `if _touched: return` and `if not body.is_in_group("player"): return`; `_apply_success()` recolors `ColorRect`, sets `Label.text = "Goed zo!"`, calls `AudioManager.play_sfx(...)`, emits. No shared base class — each script duplicates this skeleton.

**Level orchestrator:**
- Purpose: Aggregate task signals into lesson progress and exit.
- Examples: `scripts/lesson_manager.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd`
- Pattern: `extends Node2D`, `signal lesson_finished`, `@onready` child refs, `ProgressLabel` text updates, `await get_tree().create_timer(2.0).timeout` before `change_scene_to_file`, `_on_back_button_pressed()` for `BackButton`.

**Player character:**
- Purpose: The only controllable body; animation naming contract `<action>_<left|right>`.
- Examples: `scripts/camiel_controller.gd`, `assets/camiel/camiel_sprite_frames.tres`
- Pattern: raw `Input.is_key_pressed(KEY_*)` polling (no InputMap actions for movement), `@export` physics tuning, `add_to_group("player")`.

**Contrast-aware CanvasLayer (opt-in duck typing):**
- Purpose: Let UI respond to high-contrast mode.
- Examples: `scripts/accessibility.gd:33-36` (caller); no implementers exist.
- Pattern: Define `func _apply_contrast(enabled: bool)` on a `CanvasLayer` script.

## Entry Points

**Game runtime:**
- Location: `scenes/title_screen.tscn` (`project.godot` → `run/main_scene`)
- Triggers: Launching the game/editor Play, exported builds, CI smoke test (`--headless --quit-after 2`).
- Responsibilities: Branding, route to `scenes/main_menu.tscn`.

**Autoloads:**
- Location: `scripts/audio_manager.gd`, `scripts/accessibility.gd`, `scripts/progress_tracker.gd`
- Triggers: Engine startup, before the main scene.

**Headless tool scripts:**
- Location: `scripts/tools/build_camiel_resources.gd`, `scripts/tools/verify_camiel_resources.gd`
- Triggers: `godot --headless --path . --script res://scripts/tools/<name>.gd`; verifier runs in `.github/workflows/ci.yml` and `.github/workflows/release.yml`.

**Python tooling:**
- Location: `scripts/tools/quality_gate.py` (`python3 scripts/tools/quality_gate.py --root .`), `tests/test_quality_gate.py` (`python3 -m unittest tests.test_quality_gate`), `scripts/ui/extract_templates.py`.

**CI/CD:**
- Location: `.github/workflows/ci.yml` (hygiene → Godot 4.6.2 import/verify/smoke → Windows export), `.github/workflows/export.yml` (Godot 4.6.4 Windows/Linux/macOS exports, release on `v*` tags), `.github/workflows/release.yml` (Windows release on `alpha-v*`/`v*`), `.github/workflows/codeql.yml`, `.github/workflows/dependency-review.yml`.
- Export presets: `export_presets.cfg` (Windows Desktop, Linux/X11, macOS, Android, HTML5 → `builds/alpha-v0.0.3/...`).

## Architectural Constraints

- **Threading:** Single-threaded Godot main loop; logic in `_process`/`_physics_process`/signal callbacks; delays via `await get_tree().create_timer(...)`.
- **Global state:** Autoload singletons `AudioManager`, `Accessibility`, `ProgressTracker` (`project.godot`). Scene-local groups act as a global lookup (`"main"`, `"player"`, `"collectibles"`).
- **Circular imports:** Not applicable (no `preload`/`class_name` cross-references; scripts reference each other only via node paths, groups, and autoload names).
- **Viewport:** Fixed 1280x720 (`project.godot` `[display]`); `camiel_controller.gd` clamps X to `min_x=70`/`max_x=1210` rather than using level bounds.
- **Audio buses:** `Master` and `SFX` defined in `project.godot`; `AudioManager` routes both BGM and SFX through `SFX`.
- **Autoload parse risk:** `scripts/progress_tracker.gd:37` uses `JSON.SINDY_USE_HELPER`, which is not a Godot constant; treat the autoload as non-functional until fixed.
- **Generated overwrite risk:** `scripts/tools/build_camiel_resources.gd` `_save_camiel_scene()`/`_save_main_scene()` re-pack `scenes/camiel.tscn` (root `Node2D`, no controller script) and `scenes/main.tscn` (only Camiel + Camera2D), which would destroy the hand-built scenes.
- **Versioning:** Version string hard-coded in multiple places: `scripts/title_screen.gd` `VERSION`, `scripts/main_menu.gd` `version_label`, `scripts/ui/menu_button.gd` `VERSION`, `scripts/ui/version_label.gd`, `project.godot` `config/name`, `export_presets.cfg` paths, CI artifact names.
- **Repo gate:** `quality_gate.py` fails CI on unfinished-work markers, unfinished-promise phrases and placeholder copy (see the pattern list in `scripts/tools/quality_gate.py`) and broken `res://` paths in tracked text files — do not add such markers.

## Anti-Patterns

### Direct method calls across scenes via groups

**What happens:** `scripts/finish_marker.gd:36-38` looks up group `"main"` and calls the private `_on_finish_reached()`; the declared `finished` signal is never emitted, while `scenes/main.tscn:257` connects that signal anyway.
**Why it's wrong:** Hidden coupling to a specific root script; dead signal wiring; renaming breaks silently.
**Do this instead:** Emit `finished` from the component and let the level scene connect it (as `lesson_manager.gd` does with `task_completed`).

### Duplicate signal connections

**What happens:** `scenes/finish_marker.tscn` and `scenes/collectible.tscn` connect `body_entered` → `_on_body_entered` in the `.tscn`, and the scripts connect it again in `_ready()` (`scripts/finish_marker.gd:19`, `scripts/collectible.gd:19`).
**Why it's wrong:** Godot reports "already connected" errors at runtime.
**Do this instead:** Connect in exactly one place — prefer code in `_ready()` like `scripts/red_block.gd:19`.

### Copy-pasted task skeletons and level backgrounds

**What happens:** Four task scripts repeat the guard/recolor/SFX/emit pattern; every level `.tscn` rebuilds `Sky`/`CloudA`/`CloudB`/`GroundVisual`/`GroundTop`/`Ground`.
**Why it's wrong:** Behavior and look drift between lessons; fixes must be applied N times.
**Do this instead:** Extract a shared base script (e.g. `class_name TouchTask extends Area2D`) and a `scenes/level_background.tscn` to instance.

### Node paths that don't match the scene tree

**What happens:** `scripts/title_screen.gd:6` uses `$UI/PlayButton`, but the node is `UI/VBox/PlayButton` in `scenes/title_screen.tscn`; `scenes/lesson_4.tscn`/`lesson_5.tscn` declare `BackButton.pressed` connections but attach no script.
**Why it's wrong:** `@onready` resolves to null / connection targets missing → runtime errors at the game's entry scene.
**Do this instead:** Use `%UniqueName` access for important nodes, and verify scenes headlessly in CI.

### Built-but-unwired features

**What happens:** `Accessibility`, `ProgressTracker`, `scripts/ui/*`, `scenes/ui/*`, `scripts/hud.gd`, `scripts/mobile_controller.gd`, and `scenes/lesson_2.tscn`–`lesson_5.tscn` are not referenced by any reachable scene; `lesson_finished` and `progress_saved` have no listeners.
**Why it's wrong:** Docs/changelog imply features that players cannot reach.
**Do this instead:** When adding a feature, wire it into a reachable scene in the same change (menu button, instance, signal listener).

## Error Handling

**Strategy:** Defensive early returns and warnings; no error propagation.

**Patterns:**
- `push_warning("[AudioManager] ...")` and return when a resource is missing (`scripts/audio_manager.gd:53-59`).
- `get_node_or_null` + `has_method` / `has_signal` duck-typing checks before calling (`scripts/intro_scene.gd:62-64`, `scripts/count_challenge.gd:24-25`).
- One-shot boolean guards (`_touched`, `_found`, `_triggered`, `_finished`) against repeated `body_entered`.
- Tool scripts: `push_error(...)` then `quit(1)` (`scripts/tools/build_camiel_resources.gd`).

## Cross-Cutting Concerns

**Logging:** `print(...)` for task completion and accessibility toggles; `push_warning`/`push_error` for failures. No logger abstraction.
**Validation:** Player detection via `body.is_in_group("player")`; CI validation via `scripts/tools/verify_camiel_resources.gd` and `scripts/tools/quality_gate.py`.
**Authentication:** Not applicable (offline single-player game).
**Localization:** Dutch strings hard-coded in scripts and `.tscn` labels (`"Goed zo!"`, `"Taken: %d / 3"`); no `TranslationServer` usage.
**Input:** Raw keycodes in `scripts/camiel_controller.gd` and `scripts/intro_scene.gd`; InputMap in `project.godot` only adds `ui_focus_next`, `ui_focus_prev`, `mobile_jump` (unused).

---

*Architecture analysis: 2026-09-11*
