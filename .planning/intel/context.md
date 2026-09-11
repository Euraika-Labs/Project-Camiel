# Context

Running notes from DOC-classified documents, keyed by topic. 14 DOC-classified sources in this ingest set.

## Project Overview & Current Status
- source: docs/project-overview.md
- Project Camiel is a child-friendly educational game concept for children from around 3 years old; long-term idea is fun, gentle learning. `alpha-v0.0.1` scope was intentionally small: only a playable intro/test scene.
- Current alpha (at time of writing): playable intro scene, Camiel as main character, basic physics movement, grass floor + small platform, three colour blocks (`rood`, `geel`, `blauw`), text feedback on walk/jump/sit/sleep.
- Repository: https://github.com/Euraika-Labs/Project-Camiel, public as of 2026-04-26. Release: https://github.com/Euraika-Labs/Project-Camiel/releases/tag/alpha-v0.0.1 (Windows `.exe`/`.zip` as release assets, not committed to git).

- source: docs/README.md
- Documentation index; current status stated as `alpha-v0.0.1`. Alpha described as "a small Godot 4 intro experience for children from around 3 years old." Points to GitHub Wiki (https://github.com/Euraika-Labs/Project-Camiel/wiki) for "broader product vision, safety model, character bible, and long-term architecture notes."

## Target Audience & Design Principles
- source: docs/project-overview.md
- Children from around 3 years old; very simple interactions; large readable text; bright, friendly colours; no complex menus, scores, or pressure in the first alpha.

- source: docs/roadmap.md
- Design Principles (unchanged): one idea at a time; clear colors; large UI; no time pressure; no punishment-heavy failure state; keep controls minimal.

- source: docs/quick-start.md, docs/parent-teacher-notes.md
- "No reading required — Camiel speaks through pictures and sounds" (quick-start.md). Experience described as "calm, colourful, and free of time pressure" (parent-teacher-notes.md).

## Gameplay & Controls
- source: docs/project-overview.md, docs/quick-start.md
- Controls: Left/Right arrows or A/D = walk; Shift = run; Space/W/Up = jump; S/Down = sit; X = sleep.
- Main menu: Play = start intro level; Les (Lesson) = start educational micro-tasks.
- During play: collect stars (walk into them), touch the red block, find blue (camouflaged), count 1-2-3 (touch objects in order).

## Learning Objectives (Parent & Teacher Guidance)
- source: docs/parent-teacher-notes.md
- Touch the Red Block: colour recognition (red), cause-and-effect, physical coordination.
- Find the Hidden Blue Target: visual discrimination/observation, persistence, colour recognition (blue).
- Count 1-2-3: number sense, one-to-one correspondence, sequential thinking (task "requires collecting in any order").
- How to play: Start > Press Start (intro) or Les (three educational micro-tasks); no timer, no failure state; "Goed zo!" (Well done!) on completion, then return to menu.
- Classroom suggestions: 1:1 adult-child pairing recommended; project on large screen for group intro; use as reward/calm-down activity; pause-and-discuss; encourage verbal narration ("tell Camiel where to go").
- Technical: Engine Godot 4 (open source, MIT/GPL — refers to the Godot engine's own licence, not Camiel's); Platform Windows (alpha build), macOS and HTML5 exports "planned"; autoload services `AudioManager`, `Accessibility`; language Dutch throughout.

## Accessibility
- source: docs/accessibility-report.md
- Standard referenced: WCAG 2.1 AA. Report covers alpha-v0.0.3 build (dated 2026-06-05).
- Colour contrast table claims all combinations pass AA (4.5:1 normal text / 3:1 large/UI), including "Start button text" white-on-green ~7.2:1 and "Win overlay" white-on-green ~7.2:1.
- Font sizes, touch/click targets (all ≥40-44px), motion (star bob ~0.4Hz, no flashing), and audio+visual redundancy tables all claim PASS.
- "Applied Fixes from Prior Audit": ColorRect background behind text labels; high-contrast mode via `Accessibility` autoload (`toggle_high_contrast()`); button pressed-state colour correction.
- Outstanding (planned alpha-v0.0.4): reduced-motion toggle, visible mute button; deuteranopia/protanopia simulation pass recommended before beta.
- NOTE: see INGEST-CONFLICTS.md [WARNING] — `.planning/codebase/CONCERNS.md` computes actual contrast ratios of 1.91-2.76:1 for these same colour combinations (fails 4.5:1), and the `Accessibility` autoload's `toggle_high_contrast()`/`_apply_contrast()` has no callers/implementers in the codebase.

- source: docs/parent-teacher-notes.md
- "Accessibility" section: large UI (min 48x48px touch targets), high-contrast colours throughout, audio+visual feedback for every event, no fast animations/flashing/strobing, no time pressure/score penalties, high-contrast toggle via `Accessibility.toggle_high_contrast()`.

## Assets & Animations
- source: docs/assets-and-animations.md
- Canonical asset location: `assets/camiel/` (subfolders: `animations/`, `poses/`, `poses/side/`). SpriteFrames resource: `assets/camiel/camiel_sprite_frames.tres`.
- Animation frame counts: idle_left/right 4, walk_left/right 6, run_left/right 6, jump_left/right 4, sit_left/right 4, sleep_left/right 3.
- Legacy/original asset folders `assets/dogs/`, `assets/dogs_side/` kept as reference/backup; current scene uses canonical `assets/camiel/` assets.
- Transparent PNG workflow: chroma-key generated images converted to transparent PNGs; temp files under `tmp/` (gitignored).
- Jump Color Fix: jump frames had too many semi-transparent pixels (green/dark appearance); rebuilt `jump_right` from magenta chroma sources with cleaner matte, `jump_left` mirrored from fixed right frames; old frames backed up locally (gitignored) at `tmp/jump_frames_before_color_fix/`.
- `.png.import` files are committed intentionally, to reproduce import settings elsewhere.

## Godot Engine, Setup & Version History
- source: docs/godot-setup.md
- States "Current engine: Godot 4.6.2.stable" — project created/tested with this version.
- Main project files: `project.godot`, `scenes/main.tscn`, `scenes/camiel.tscn`, `assets/camiel/camiel_sprite_frames.tres`, `scripts/camiel_controller.gd`, `scripts/intro_scene.gd`.
- Camiel is `CharacterBody2D` with `AnimatedSprite2D` + `CollisionShape2D` children; sprite frames from `res://assets/camiel/camiel_sprite_frames.tres`.
- Controller exposes tunables: `walk_speed`, `run_speed`, `jump_velocity`, `gravity`, `acceleration`, `friction`, `min_x`, `max_x`.
- Verification script `scripts/tools/verify_camiel_resources.gd` checks: SpriteFrames resource exists, expected animation names/frame counts match, `camiel.tscn`/`main.tscn` load, Camiel scene root is `CharacterBody2D`, main scene contains a Camiel instance.
- Notes: "The exported build is not code-signed. Windows may show a SmartScreen warning."

- source: docs/godot-update-notes.md
- Documents project format update from Godot 4.6.2 to 4.6.4: `config_version` bumped 5 -> 6 in `project.godot`; no scene-file syntax changes.
- Release notes summarised for 4.6.3 (2026-02-26) and 4.6.4 (2026-03-19), including web-export/WebAssembly and AudioStreamPlayer fixes.
- Compatibility: existing scenes/scripts/export presets compatible as-is; Android APK "re-export required to pick up engine-level fixes."
- Action required: re-export Android APK; states "CI/CD: `.github/workflows/export.yml` already targets 4.6.4 — no changes needed there"; editor users should update to 4.6.4 and re-download export templates.
- Rollback procedure documented (revert `config_version` to 5, revert CI `godot-version` to 4.6.2).
- NOTE: see INGEST-CONFLICTS.md [WARNING] — this contradicts docs/godot-setup.md (still states 4.6.2 as current) and docs/build-and-release.md (states "4.6 (or current LTS)"); `.planning/codebase/CONCERNS.md` independently documents that `ci.yml`/`release.yml` pin 4.6.2 while `export.yml` pins 4.6.4.

## Development History
- source: docs/development-log.md
- Character asset work: reference image of Camiel (Bernese-Mountain-Dog style, black/white/tan fur, green bandana with name); 10 general + 10 side-view pose images generated on chroma-key backgrounds, converted to transparent PNGs locally.
- Animation asset work: groups created under `assets/camiel/animations/` — idle/walk/run/jump/sit (4-6 frames each direction), sleep (3 frames each direction). Jump frames later repaired (green/dark alpha edges) from original chroma sources.
- Godot project created with Godot Engine 4.6.2 (installed via WinGet): `project.godot`, `scenes/main.tscn`, `scenes/camiel.tscn`, `assets/camiel/camiel_sprite_frames.tres`.
- Player controller: Camiel started as `Node2D` with manual animation control, converted to `CharacterBody2D` with collision, gravity, horizontal movement, jump velocity, state-based animation switching (`scripts/camiel_controller.gd`).
- Intro scene: sky background, clouds, grass floor, small platform, three labelled colour blocks, friendly UI text, live message updates (`scripts/intro_scene.gd`).
- Export setup: 4.6.2.stable export templates installed; Windows export preset added (`export_presets.cfg`); build exported to `builds/alpha-v0.0.1/windows/Camiel-alpha-v0.0.1.exe` (+ zipped copy); build files gitignored, uploaded to GitHub Releases instead.
- GitHub: repository `Euraika-Labs/Project-Camiel` created, source pushed to `main`; release `alpha-v0.0.1` created with Windows `.exe`/`.zip` assets. Made public 2026-04-26 with CodeQL, secret scanning (+push protection), Dependabot alerts/security updates, private vulnerability reporting configured.

## Build & Release Process
- source: docs/build-and-release.md (dated 2026-06-05)
- Prerequisites table: Godot 4 "4.6 (or current LTS)"; Git; `glab` or `git` for "repository access on git.euraika.net"; `gh` CLI optional for GitHub release management.
- Local dev: `godot --path .` (F5 to run); headless play via `godot --headless --path . --script run_quick_test.gd`.
- Local release build: Godot editor Export (Windows Desktop preset) to `builds/alpha-vX.Y.Z/windows/...`; or CLI `godot --headless --path . --export-release "Windows Desktop" builds/alpha-v0.0.3/windows/Camiel-alpha-v0.0.3.exe`; or `scripts/ui/extract_templates.py /tmp/templates.tpz "4.6/stable"` for CI.
- CI/CD pipeline (`.github/workflows/export.yml`): quality-gate -> export-windows -> artefact upload; release job on `v*` tags. Quality gate step runs `scripts/tools/verify_camiel_resources.gd`, checking no committed build artefacts, `project.godot` present with `config_version` set, no unfinished-task markers, all `res://` resource paths exist.
- Export step uses `gobject/godot-action@v3` with `godot-version: 4.6.2` in this doc's example (elsewhere the doc's env-var table defaults `GODOT_VERSION` to `4.6`).
- Output path pattern uses `$GITHUB_REF_NAME`. Artifacts uploaded via `actions/upload-artifact@v4`, retained 30 days. Release created via `softprops/action-gh-release@v1` on `v*` tags, marked draft until manually published.
- Export Presets Reference: only "Windows Desktop" documented as current; "Browser Export (Future)" section shows `godot --headless --path . --export-release "Web" build/web/index.html` and notes Web export needs a server supporting SharedArrayBuffer (COOP/COEP headers).
- Version Numbering: SemVer MAJOR.MINOR.PATCH; alpha pre-releases `0.0.1-alpha.1` style; version string stored in `project.godot` `config/name`, `export_presets.cfg` `application/file_version`, `scenes/main_menu.tscn` `$UI/VersionLabel`.
- Creating a Release: update CHANGELOG.md -> tag (`git checkout develop`/`main`, merge, `git tag -a vX.Y.Z`, push) -> CI runs quality gate, Windows export, code signing if configured, GitHub Release from CHANGELOG.md.
- Post-Release Checklist: CHANGELOG.md updated, docs/roadmap.md marked current version done, tag pushed, release created, export preset paths updated to next version, `project.godot` config/name updated, version label updated, announced.
- NOTE: see INGEST-CONFLICTS.md [WARNING] — `run_quick_test.gd` does not exist in the repo; `git.euraika.net`/`glab` reference does not match the actual GitHub-hosted repo referenced by every other doc; the export-templates curl URL in this doc points at a nonexistent `godot-export-templates` repo; Godot version stated here ("4.6") conflicts with docs/godot-setup.md (4.6.2) and docs/godot-update-notes.md (4.6.4) and with the actual CI pins (per CONCERNS.md).

## CI/CD & Community Standards
- source: docs/ci-and-community-standards.md
- Workflows: `CI` (repo hygiene, Godot import, verification script, main-scene smoke test, Windows artifact export), `CodeQL` (scans GitHub Actions workflow code only — "CodeQL does not currently support GDScript as a CodeQL language"), `Dependency Review`, `Release` (Windows release artifacts on matching tags).
- AI Quality Gate (`scripts/tools/quality_gate.py`): blocks assistant self-disclaimer text, unfinished future-work markers, filler/replace-me copy and unsupported future promises, broken/external local Markdown links, missing `res://` resource paths, empty tracked files, PNG assets without `.import` metadata, accidental removal of required community/security/CI files. Has unittest coverage (`tests/test_quality_gate.py`).
- Community health files present: README.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md, SECURITY.md, SUPPORT.md, LICENSE, issue templates, PR template, Dependabot config.
- Repository settings: public, issues/wiki/discussions/projects enabled, merge commits disabled, squash/rebase merging enabled, auto-merge enabled, delete-branch-on-merge, web commit signoff, release immutability, Dependabot alerts + automated security fixes, private vulnerability reporting, secret scanning + push protection.
- Main branch protection: required checks `Repository hygiene`, `Verify Godot project`, `Export Windows build`, `Analyze GitHub Actions`; PR + 1 approval (not last pusher) required, stale approvals dismissed, branch must be up to date, conversation resolution required, linear history, signed commits, applies to admins, force-push/branch-deletion disabled.
- Binary policy: large exported builds not committed; go to CI artifacts or GitHub Release assets.

## Code Signing
- source: docs/code-signing.md (dated 2026-06-05)
- Explains code signing purpose and Windows SmartScreen behaviour (unsigned = warning; new/unknown cert = warning; established trusted cert = no warning). Reputation build-up takes days-to-weeks for OV certs; EV certs bypass this.
- Free option: SignPath.io (5 signing sessions/month free tier, no CI/CD integration on free tier).
- Paid options: DigiCert OV (~EUR150-300/yr, no instant SmartScreen bypass) / EV (~EUR300-600/yr, instant bypass, REST API for CI/CD); SSL.com (cheaper OV/EV, `escctl` CLI for GitHub Actions integration); Sectigo/Comodo (budget OV from ~EUR80/yr).
- CI env vars: `AUTHENTICODE_CERT_PATH` (path to `.pfx`), `AUTHENTICODE_PASSWORD`; both stored as GitHub Secrets, not available to fork PR runs.
- `.github/workflows/export.yml` signtool step: decodes cert from `AUTHENTICODE_CERT_B64` secret, skips gracefully (exit 0 with notice) if cert absent, so CI still produces an unsigned build when signing isn't configured.
- Local signtool command and prerequisites (Windows SDK) documented; self-signed certs explicitly flagged dev-only, "Never use a self-signed certificate for a release build."
- "DO NOT Commit Certificates" section with explicit wrong/correct examples and `.gitignore` recommendation for `*.pfx`/`*.p12`/`*.pem`.
- Troubleshooting section for common signtool errors.

## Web Export (HTML5)
- source: docs/web-export.md
- Describes exporting Camiel as "a self-contained HTML5 game that runs in any modern desktop browser," with step-by-step export instructions (Godot 4.6.4 editor, Project > Export, HTML5 preset, ~1-2 min export, ~30-50MB output).
- Performance notes: Desktop Chrome/Firefox/Edge "Yes, full performance"; macOS Safari "Caution, some rendering issues"; Mobile browsers "Not recommended, touch works but framerate poor, Android Chrome may crash."
- Hosting options detailed: itch.io (recommended, zip upload, embed iframe example), GitHub Pages (note: no WebAssembly threading support by default), self-hosted (mime.types requirements for wasm/js).
- File structure of a web export documented (`index.html`, `.pck`, `.js`, `.wasm`, `.icon.png`); compression tip (~30MB compressed vs ~50MB uncompressed).
- States CI does not currently build the web export "due to the large export template download (~1 GB) making CI runners slow," and provides a proposed (not yet added) `export-web` GitHub Actions job.
- NOTE: see INGEST-CONFLICTS.md [WARNING] — this doc's framing ("Camiel can be exported...") describes web export as functional/available, while docs/quick-start.md and docs/roadmap.md both list Web (HTML5) as "Planned" / a "Next: Alpha v0.0.4 Idea", and `.planning/codebase/CONCERNS.md` states the Web export preset uses the Godot-3-era platform name `"HTML5"` instead of Godot 4's `"Web"` and is "likely rejected," with no CI job ever exercising it.

## Quick-Start / Installation
- source: docs/quick-start.md
- "5 minutes from download to playing." Install Godot 4.6.4 (Windows/macOS/Linux instructions); open project via Import > select `project.godot` > Import & Run > Play/F5.
- Main menu: Play (intro level), Les (educational micro-tasks). Controls table (walk/jump/sit/run). During-game guidance: collect stars, touch red block, find blue, count 1-2-3.
- Troubleshooting: game doesn't start (wrong Godot version, forgot F5), no sound (check volume; "in-game volume in the AudioManager (future feature)"), screen size (F11 fullscreen or Project Settings override), child can't control Camiel (keyboard required, suggests adult co-play), game too fast/slow (restart, check other apps).
- Cross-references docs/parent-teacher-notes.md (learning objectives) and docs/accessibility-report.md (accessibility features). States: "no ads, no in-app purchases, no internet required after download... Works offline once downloaded."
- Supported Platforms table: Windows 10/11 "Fully tested"; macOS "Tested"; Linux "Tested"; Web (HTML5) "Planned"; Android/iOS "Planned".

## Roadmap (Completed & Planned)
- source: docs/roadmap.md
- Alpha v0.0.1 — Done (2025): Godot project created; Camiel character assets generated/imported; animation resource created; Camiel converted to CharacterBody2D; playable intro scene created; Windows export templates installed; Windows alpha build exported; GitHub repository created; GitHub release created with build assets.
- Alpha v0.0.2 — Done (2026-06-05): simple main menu with Start button; background music + SFX (AudioManager autoload); one collectible (star) with pickup feedback; HUD star count; finish marker for intro completion.
- Alpha v0.0.3 — Done (2026-06-05): first educational micro-tasks (touch red block, find blue, count 1-2-3); lesson scene (`lesson_1.tscn`) with progress tracking; parent/teacher notes created; "Accessibility checks completed, WCAG 2.1 AA compliant"; GitHub Actions CI/CD pipeline; code signing documentation; branded title screen; version label component; Accessibility Autoload singleton added.
- Design Principles (unchanged): one idea at a time, clear colors, large UI, no time pressure, no punishment-heavy failure state, keep controls minimal.
- Known Technical Improvements (backlog): code signing for Windows (cert acquisition required); reduce duplicate legacy assets if repo size becomes an issue; title screen (marked DONE alpha-v0.0.3); version label (marked DONE alpha-v0.0.3); voice-over audio for non-readers; parental dashboard (web-based progress tracking); mobile touch support; web export (HTML5 via Godot).
- Next: Alpha v0.0.4 Ideas: voice-over audio (Dutch) for non-readers; parental dashboard (simple web app); mobile touch controls; web export (HTML5 Godot export); more lesson levels.
- NOTE: see INGEST-CONFLICTS.md [WARNING] — the "Accessibility checks completed, WCAG 2.1 AA compliant" line under Alpha v0.0.3 "Done" is contradicted by computed contrast ratios in `.planning/codebase/CONCERNS.md` (1.91-2.76:1, failing the 4.5:1 AA threshold). This roadmap has no alpha-v0.0.4 section despite lessons 2-5, mobile-controller code, progress-tracker code, and export changes already existing in the repo per CONCERNS.md — those exist as unwired/non-functional code, not completed roadmap items.
