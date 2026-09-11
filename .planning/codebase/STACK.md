# Technology Stack

**Analysis Date:** 2026-09-11

## Languages

**Primary:**
- GDScript (Godot 4.x dialect) - All game logic under `scripts/` (about 28 `.gd` files, around 1,300 lines). Every script uses `extends <NodeType>` and optional static typing (`var _bgm_player: AudioStreamPlayer`, `-> void`).
- Godot text resource formats (`.tscn`, `.tres`, `.godot`, `.cfg`) - Scenes in `scenes/` and `scenes/ui/`, SpriteFrames in `assets/camiel/camiel_sprite_frames.tres`, project config in `project.godot`, export targets in `export_presets.cfg`.

**Secondary:**
- Python 3 (standard library only; uses `from __future__ import annotations` and `X | None` typing, so it needs Python 3.8+ at runtime and 3.10+ for the annotations to evaluate) - Repository tooling:
  - `scripts/tools/quality_gate.py` (344 lines) - "AI quality gate" linter run in CI
  - `tests/test_quality_gate.py` - `unittest` tests for the gate
  - `scripts/ui/extract_templates.py` - unpacks Godot `.tpz` export templates (a tooling script, despite living in `scripts/ui/`)
- YAML - GitHub Actions workflows in `.github/workflows/`, Dependabot config, CodeQL config, issue templates.
- Bash (inline in workflows) - Downloading Godot, installing templates, exporting, packaging.
- Markdown - Docs in `docs/` and root community files. The quality gate lints these for broken links and banned phrases.

## Runtime

**Environment:**
- Godot Engine 4.6 (`config/features=PackedStringArray("4.6", "Forward Plus")` in `project.godot`, `config_version=6`)
  - Renderer: Forward Plus
  - Viewport: 1280x720 (`display/window/size/*`)
  - Main scene: `res://scenes/title_screen.tscn`
  - Audio buses: `Master` (0) and `SFX` (1, sends to Master). Mobile audio is enabled.
- Pinned engine patch versions don't agree (see Configuration below):
  - `4.6.2-stable`: `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `docs/godot-setup.md`
  - `4.6.4-stable`: `.github/workflows/export.yml`, `README.md`, `docs/web-export.md`, `docs/godot-update-notes.md`
- Treat **Godot 4.6.4-stable** as the target for new work. It is the version the README and update notes name.

**Package Manager:**
- None. There is no `package.json`, `requirements.txt`, `pyproject.toml`, or Godot `addons/` directory, and no Asset Library plugins.
- Lockfile: not applicable.
- Godot binaries and export templates are downloaded straight from `https://github.com/godotengine/godot/releases/download/...` in CI.

## Frameworks

**Core:**
- Godot Engine 4.6 - Scene tree, 2D physics (`CharacterBody2D`, `Area2D`, `StaticBody2D`), `AnimatedSprite2D` + `SpriteFrames`, `AudioStreamPlayer`/`AudioServer`, `CanvasLayer` UI, `FileAccess`/`JSON` persistence.
- Autoload singletons, registered in `project.godot` under `[autoload]`:
  - `AudioManager` → `scripts/audio_manager.gd` (BGM/SFX playback and bus routing)
  - `Accessibility` → `scripts/accessibility.gd` (high-contrast toggle, walks `CanvasLayer`s)
  - `ProgressTracker` → `scripts/progress_tracker.gd` (lesson progress saved to `user://progress.json`)

**Testing:**
- Python `unittest` (stdlib) - `tests/test_quality_gate.py`. Run with `python3 -m unittest tests.test_quality_gate`.
- Godot headless verification script - `scripts/tools/verify_camiel_resources.gd` (`extends SceneTree`). It checks SpriteFrames animation names and frame counts, and that the scenes load. Run with `godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd`.
- Godot headless smoke test - `godot --headless --path . --quit-after 2` (in `ci.yml`).
- No GDScript unit-test framework (GUT, gdUnit4) is installed.

**Build/Dev:**
- Godot headless CLI export (`--export-release "<preset>"`) using `export_presets.cfg`.
- Godot official export templates (`Godot_v<ver>-stable_export_templates.tpz`), installed to `~/.local/share/godot/export_templates/<ver>.stable/`.
- `scripts/tools/build_camiel_resources.gd` - Headless generator (`extends SceneTree`) that builds `assets/camiel/camiel_sprite_frames.tres`, `scenes/camiel.tscn`, and `scenes/main.tscn` through `ResourceSaver.save`.
- `scripts/tools/quality_gate.py --root .` - Repository linter. It checks required files, empty files, banned phrases (unfinished-work markers, placeholder copy, AI disclaimers — pattern list in the script), broken Markdown links, missing `res://` paths, and PNGs under `assets/` that have no `.import` sidecar.
- `.editorconfig` - UTF-8, LF, final newline, trim trailing whitespace.
- `.gitattributes` - `* text=auto`; `.exe`, `.dll`, `.zip` marked binary.

## Key Dependencies

**Critical:**
- Godot Engine 4.6.x editor/runtime - The only runtime dependency. Every scene, script, and export needs it.
- Godot 4.6.x export templates - Required for any `--export-release` (Windows, Linux, macOS, Android, Web).

**Infrastructure (GitHub Actions, managed by Dependabot):**
- `actions/checkout@v6` - All workflows
- `actions/upload-artifact@v7` - `.github/workflows/ci.yml`
- `actions/upload-artifact@v4`, `actions/download-artifact@v4` - `.github/workflows/export.yml` (major version differs from `ci.yml`)
- `softprops/action-gh-release@v2` - `.github/workflows/export.yml` release job
- `github/codeql-action/init@v4`, `github/codeql-action/analyze@v4` - `.github/workflows/codeql.yml`
- `actions/dependency-review-action@v5` - `.github/workflows/dependency-review.yml`
- `gh` CLI (preinstalled on runners) - `.github/workflows/release.yml` and the CodeQL availability check

**Assets (in-repo, no external packages):**
- PNG sprites: `assets/dogs/`, `assets/dogs_side/`, `assets/camiel/poses/`, `assets/camiel/animations/<anim>/`, `assets/collectibles/star.png`
- OGG Vorbis audio: `assets/audio/bgm_ambient.ogg`, `assets/audio/sfx_collect.ogg`, `assets/audio/sfx_finish.ogg`
- `*.import` sidecars are Godot-generated. `.gitignore` excludes them, but the quality gate expects `.import` metadata for PNGs under `assets/`.

## Configuration

**Environment:**
- No `.env` files, and no environment variables are read at runtime. The game has no network or config dependencies.
- CI env vars (non-secret, set in the workflow files): `GODOT_VERSION`, `GODOT_STATUS`, `GODOT_TEMPLATE_VERSION`, `GODOT_BIN` (`ci.yml`, `release.yml`); `REF_SLUG`, `REF_CLEAN` (`export.yml`).
- The version string is duplicated by hand in several places: `project.godot` `config/name="Camiel alpha-v0.0.3"`, every `application/file_version`/`product_version="0.0.3.0"` and `export_path` in `export_presets.cfg`, and the version label in `scenes/main_menu.tscn` / `scripts/ui/version_label.gd`. Update all of them together when bumping versions.
- The `user://` data directory is derived from `config/name`, so renaming the project moves where `progress.json` is saved.

**Build:**
- `project.godot` - Engine config, autoloads, input map (`ui_focus_next`, `ui_focus_prev`, `mobile_jump`), display, audio buses.
- `export_presets.cfg` - Five presets:
  | # | Name | Platform | Arch / Notes | Output |
  |---|------|----------|--------------|--------|
  | 0 | `Windows Desktop` | Windows Desktop | x86_64, embedded PCK, codesign disabled | `builds/alpha-v0.0.3/windows/Camiel-alpha-v0.0.3.exe` |
  | 1 | `Linux/X11` | Linux/X11 | x86_64, embedded PCK | `builds/alpha-v0.0.3/linux/Camiel-alpha-v0.0.3` |
  | 2 | `macOS` | macOS | universal, codesign disabled | `builds/alpha-v0.0.3/macos/Camiel-alpha-v0.0.3.app` |
  | 3 | `Android` | Android | arm64-v8a only, min SDK 24, target SDK 34, keystores empty, `runnable=false` | `builds/alpha-v0.0.3/android/Camiel-alpha-v0.0.3.apk` |
  | 4 | `HTML5` | HTML5 | compressed, no threads, no extensions | `builds/alpha-v0.0.3/web/index.html` |
- The `HTML5` preset uses the Godot 3 platform name. Godot 4 calls this platform `Web`, so the preset will probably fail to resolve in a 4.6 export. Use `platform="Web"` for new or fixed web presets.
- `.github/codeql/codeql-config.yml` - `security-and-quality` queries, limited to `.github/workflows`.
- `.github/dependabot.yml` - `github-actions` ecosystem only, weekly on Monday at 08:00 Europe/Brussels, `ci` commit prefix.
- `.gitignore` - Ignores `.godot/`, `tmp/`, `builds/`, `__pycache__/`, `.pi/`, `*.import`.

## Platform Requirements

**Development:**
- Godot 4.6.4-stable editor (standard build, not .NET/Mono; the project contains no C#).
- Python 3.10+ to run `scripts/tools/quality_gate.py` and `tests/`.
- Export templates matching the editor version for local exports.
- Optional: `gh` CLI for release uploads. Windows SDK `signtool` for code signing (documented in `docs/code-signing.md` but not wired into any workflow). Android SDK/JDK and a keystore for APK export (not configured).

**Production:**
- Distributed as offline desktop binaries attached to GitHub Releases: Windows `.exe` (zipped), Linux `.x86_64` (tar.gz), macOS `.zip`.
- Android APK and HTML5/Web export are defined as presets but are not built in CI.
- Web hosting options (itch.io, GitHub Pages, self-hosted) are documented in `docs/web-export.md` only.
- Builds are unsigned on every platform (`codesign/enable=false`), so Windows SmartScreen warnings are expected.

---

*Stack analysis: 2026-09-11*
