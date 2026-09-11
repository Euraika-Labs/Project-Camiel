# Codebase Structure

**Analysis Date:** 2026-09-11

## Directory Layout

```
Project-Camiel/
├── project.godot              # Godot 4.6 project config: main scene, autoloads, input, display, audio buses
├── export_presets.cfg         # Export presets: Windows Desktop, Linux/X11, macOS, Android, HTML5
├── scenes/                    # All .tscn scenes (flat) — screens, levels, gameplay components
│   └── ui/                    # Reusable UI scenes + mobile touch overlay (+ one integration plan .md)
├── scripts/                   # All GDScript (flat, mirrors scenes/ names)
│   ├── ui/                    # Scripts for scenes/ui/* + extract_templates.py helper
│   └── tools/                 # Headless SceneTree tools + Python quality gate
├── assets/                    # Imported art/audio (PNG/OGG + Godot .import sidecars)
│   ├── camiel/                # Canonical player art
│   │   ├── animations/<anim>_<dir>/   # Frame PNGs per animation
│   │   ├── poses/ (+ side/)           # Single-pose reference PNGs
│   │   └── camiel_sprite_frames.tres  # Generated SpriteFrames resource
│   ├── dogs/, dogs_side/      # Earlier standalone pose sheets (not referenced by scenes)
│   ├── collectibles/          # star.png
│   └── audio/                 # bgm_ambient.ogg, sfx_collect.ogg, sfx_finish.ogg, README.md
├── tests/                     # Python unittest for the quality gate
├── docs/                      # Project, setup, build/release, accessibility, roadmap docs
├── .github/                   # CI workflows, CodeQL config, Dependabot, issue/PR templates
├── .pi/                       # pi agent tooling (flow.json, workflows/runs/* run logs) — gitignored, not product code
├── .planning/                 # GSD planning artifacts (codebase maps)
├── README.md, CHANGELOG.md, CONTRIBUTING.md, SECURITY.md, SUPPORT.md, CODE_OF_CONDUCT.md, LICENSE
├── ALPHA_V0_0_1_NOTES.md      # Release notes body used by release.yml
├── .editorconfig, .gitattributes, .gitignore
```

## Directory Purposes

**`scenes/`:**
- Purpose: Every packed scene. Screens, levels, and components live side-by-side (no subfolders except `ui/`).
- Contains: `.tscn` text scenes.
- Key files: `scenes/title_screen.tscn` (main scene), `scenes/main_menu.tscn`, `scenes/main.tscn` (intro level), `scenes/lesson_1.tscn`–`scenes/lesson_5.tscn`, `scenes/camiel.tscn` (player), `scenes/collectible.tscn`, `scenes/count_challenge.tscn`, `scenes/finish_marker.tscn`, `scenes/red_block.tscn`, `scenes/blue_target.tscn`, `scenes/shape_target.tscn`, `scenes/sequence_target.tscn`

**`scenes/ui/`:**
- Purpose: Reusable UI and overlays.
- Contains: `dialog_popup.tscn`, `menu_button.tscn`, `progress_bar.tscn`, `version_label.tscn`, `mobile_controller.tscn`, `mobile_joystick.tscn`, `mobile_joystick_integration_plan.md`
- Key files: `scenes/ui/mobile_controller.tscn` (touch joystick + jump, script `scripts/mobile_controller.gd`)

**`scripts/`:**
- Purpose: GDScript for scenes and autoloads.
- Contains: One script per scene, named after the scene or its role; autoload singletons at top level.
- Key files: `scripts/audio_manager.gd`, `scripts/accessibility.gd`, `scripts/progress_tracker.gd` (autoloads); `scripts/camiel_controller.gd`; `scripts/intro_scene.gd` (root of `main.tscn`); `scripts/lesson_manager.gd` (root of `lesson_1.tscn`); `scripts/lesson_2.gd`…`lesson_5.gd`; `scripts/game_hud.gd`

**`scripts/ui/`:**
- Purpose: Scripts backing `scenes/ui/*`.
- Contains: `dialog_popup.gd`, `menu_button.gd`, `progress_bar.gd`, `version_label.gd`, and `extract_templates.py` (export-template extraction helper, misplaced tooling).

**`scripts/tools/`:**
- Purpose: Non-gameplay tooling.
- Contains: `build_camiel_resources.gd` (extends `SceneTree`; regenerates SpriteFrames and re-packs scenes), `verify_camiel_resources.gd` (CI check of animation frame counts), `quality_gate.py` (repo hygiene gate).

**`assets/camiel/animations/`:**
- Purpose: Frame sequences consumed by `build_camiel_resources.gd`.
- Contains: `idle_*` (4), `walk_*` (6), `run_*` (6), `jump_*` (4), `sit_*` (4), `sleep_*` (3) for `left`/`right`.
- Key files: `assets/camiel/camiel_sprite_frames.tres`

**`tests/`:**
- Purpose: Python tests only; no GDScript test framework (GUT/gdUnit) present.
- Key files: `tests/test_quality_gate.py`

**`docs/`:**
- Purpose: Human documentation.
- Key files: `docs/project-overview.md`, `docs/roadmap.md`, `docs/godot-setup.md`, `docs/build-and-release.md`, `docs/web-export.md`, `docs/code-signing.md`, `docs/accessibility-report.md`, `docs/assets-and-animations.md`, `docs/ci-and-community-standards.md`, `docs/parent-dashboard.md`, `docs/development-log.md`

**`.github/`:**
- Purpose: Automation and community templates.
- Key files: `.github/workflows/ci.yml`, `.github/workflows/export.yml`, `.github/workflows/release.yml`, `.github/workflows/codeql.yml`, `.github/workflows/dependency-review.yml`, `.github/codeql/codeql-config.yml`, `.github/dependabot.yml`, `.github/ISSUE_TEMPLATE/*.yml`, `.github/PULL_REQUEST_TEMPLATE.md`

## Key File Locations

**Entry Points:**
- `project.godot`: `run/main_scene="res://scenes/title_screen.tscn"`; `[autoload]` registers `AudioManager`, `Accessibility`, `ProgressTracker`.
- `scenes/title_screen.tscn` + `scripts/title_screen.gd`: first runtime scene.
- `scenes/main_menu.tscn` + `scripts/main_menu.gd`: routes to `scenes/main.tscn` and `scenes/lesson_1.tscn`.

**Configuration:**
- `project.godot`: engine features (4.6, Forward Plus), 1280x720 viewport, input actions, `Master`/`SFX` buses.
- `export_presets.cfg`: platform export targets writing to `builds/alpha-v0.0.3/<platform>/`.
- `.editorconfig`, `.gitattributes`, `.gitignore` (ignores `.godot/`, `tmp/`, `builds/`, `.pi/`, `*.import`).
- `.github/workflows/*.yml`: pinned Godot versions (`ci.yml`/`release.yml` 4.6.2, `export.yml` 4.6.4).

**Core Logic:**
- `scripts/camiel_controller.gd`: player movement and animation.
- `scripts/lesson_manager.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd`: lesson orchestration.
- `scripts/red_block.gd`, `scripts/blue_target.gd`, `scripts/shape_target.gd`, `scripts/sequence_target.gd`, `scripts/count_challenge.gd`, `scripts/collectible.gd`, `scripts/finish_marker.gd`: gameplay components.
- `scripts/intro_scene.gd`, `scripts/game_hud.gd`: intro level win/HUD logic.
- `scripts/audio_manager.gd`: all runtime audio.

**Testing:**
- `tests/test_quality_gate.py`: unittest for `scripts/tools/quality_gate.py`.
- `scripts/tools/verify_camiel_resources.gd`: headless Godot resource check (CI).
- CI smoke test: `godot --headless --path . --quit-after 2` in `.github/workflows/ci.yml`.

## Naming Conventions

**Files:**
- `snake_case` for all scenes, scripts, assets: `sequence_target.tscn`, `camiel_controller.gd`.
- Scene and its script share a base name: `scenes/red_block.tscn` ↔ `scripts/red_block.gd`. Exceptions: `scenes/main.tscn` ↔ `scripts/intro_scene.gd`, `scenes/lesson_1.tscn` ↔ `scripts/lesson_manager.gd`, `scenes/camiel.tscn` ↔ `scripts/camiel_controller.gd`, `scenes/ui/mobile_joystick.tscn` ↔ `scripts/mobile_controller.gd`.
- Lessons: `lesson_<n>.tscn` / `lesson_<n>.gd`.
- Animation frames: `camiel_<action>_<left|right>_<NN>.png` inside `animations/<action>_<left|right>/`.
- Audio: `bgm_<name>.ogg`, `sfx_<event>.ogg` (event names match `AudioManager.play_sfx` keys).
- Scripts start with a header comment `# <file>.gd` + one-line purpose.
- Docs: `kebab-case.md` in `docs/`; root community files UPPERCASE.

**Directories:**
- Lowercase, `snake_case`; `scenes/ui` mirrors `scripts/ui`.

**Nodes (inside .tscn):**
- `PascalCase` node names (`ProgressLabel`, `BackButton`, `CountChallenge`, `WinLayer`); instanced components keep the component name (`RedBlock`, `Camiel`).
- Animation names `<action>_<left|right>` (`idle_right`, `jump_left`).
- Groups lowercase snake_case: `player`, `collectibles`, `count_collectibles`, `main`, `finish`, `mobile_controller`.

## Where to Add New Code

**New lesson:**
- Scene: `scenes/lesson_<n>.tscn` (root `Node2D` named `Lesson<n>`; copy background/ground/`Camiel`/`Camera2D`/`ProgressLabel`/`BackButton` layout from `scenes/lesson_2.tscn`).
- Script: `scripts/lesson_<n>.gd` following `scripts/lesson_2.gd` (connect `task_completed` with `.bind`, emit `lesson_finished`, `_on_back_button_pressed`).
- Wiring: add a button/route in `scenes/main_menu.tscn` + `scripts/main_menu.gd`, otherwise the lesson is unreachable. Call `ProgressTracker.record_lesson_complete(...)` on completion.
- Tests: headless load check in CI (`.github/workflows/ci.yml`); no GDScript test dir exists yet.

**New interactive task/component:**
- Scene: `scenes/<task_name>.tscn` (root `Area2D` with `ColorRect`, `Label`, `CollisionShape2D`).
- Script: `scripts/<task_name>.gd` emitting `signal task_completed(task_name: String)`, guarded by `body.is_in_group("player")`, using `AudioManager.play_sfx(...)`.

**New UI widget / overlay:**
- Scene: `scenes/ui/<widget>.tscn`; Script: `scripts/ui/<widget>.gd`.
- For contrast support on a `CanvasLayer`, implement `_apply_contrast(enabled: bool)`.

**New global service:**
- Script: `scripts/<service_name>.gd` (`extends Node`), registered under `[autoload]` in `project.godot` with a `PascalCase` name.

**New sound:**
- File: `assets/audio/sfx_<event>.ogg`; add a const path and `match` branch in `scripts/audio_manager.gd` `play_sfx`.

**New Camiel animation:**
- Frames: `assets/camiel/animations/<action>_<left|right>/camiel_<action>_<dir>_NN.png`.
- Register in `ANIMATIONS` in `scripts/tools/build_camiel_resources.gd` and `EXPECTED` in `scripts/tools/verify_camiel_resources.gd`; regenerate `assets/camiel/camiel_sprite_frames.tres` (beware the tool also re-packs `scenes/camiel.tscn` and `scenes/main.tscn`).

**Tooling / CI helpers:**
- Godot headless tools: `scripts/tools/<name>.gd` (`extends SceneTree`, `quit(0|1)`).
- Python tools: `scripts/tools/<name>.py` with tests in `tests/test_<name>.py` (unittest).

**Utilities:**
- Shared helpers: no shared utility module exists; place reusable GDScript base classes in `scripts/` with `class_name` (e.g. `scripts/touch_task.gd`).

## Special Directories

**`.godot/`:**
- Purpose: Editor import cache.
- Generated: Yes
- Committed: No (`.gitignore`)

**`*.import` sidecars (throughout `assets/`):**
- Purpose: Godot import metadata for PNG/OGG.
- Generated: Yes
- Committed: Listed in `.gitignore`, but present in the working tree and checked by `quality_gate.py` (`check_asset_import_metadata`).

**`*.gd.uid` (e.g. `scripts/camiel_controller.gd.uid`, `scripts/tools/*.gd.uid`):**
- Purpose: Godot 4.4+ script UIDs.
- Generated: Yes
- Committed: Yes (partial — only some scripts have them)

**`assets/camiel/camiel_sprite_frames.tres`:**
- Purpose: SpriteFrames for Camiel.
- Generated: Yes (by `scripts/tools/build_camiel_resources.gd`)
- Committed: Yes

**`builds/`, `dist/`, `tmp/`:**
- Purpose: Local/CI export outputs and scratch.
- Generated: Yes
- Committed: No

**`.pi/` (incl. `.pi/workflows/runs/*`):**
- Purpose: pi agent tooling state and run logs; not product code.
- Generated: Yes
- Committed: No (`.gitignore`)

**`.planning/`:**
- Purpose: GSD planning/codebase map documents.
- Generated: Yes (by GSD agents)
- Committed: Managed by GSD orchestrator

---

*Structure analysis: 2026-09-11*
