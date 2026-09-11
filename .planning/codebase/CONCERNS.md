# Codebase Concerns

**Analysis Date:** 2026-09-11

Scope: full repository. Findings come from reading the code without running it. Godot is not installed on the analysis machine, so the engine-level errors below are flagged "likely" where they could not be confirmed by running the project. Confirm them with `godot --headless --path . --quit-after 60` and check stderr.

## Known Bugs

**Parse error in the `ProgressTracker` autoload (invalid JSON constant):**
- Symptoms: `scripts/progress_tracker.gd:38` calls `JSON.stringify(data, JSON.SINDY_USE_HELPER)`. `JSON.SINDY_USE_HELPER` does not exist. `JSON.stringify` takes `(data, indent: String, sort_keys, full_precision)`. The script fails to compile, so the autoload named in `project.godot` (`ProgressTracker="res://scripts/progress_tracker.gd"`) errors at every startup.
- Files: `scripts/progress_tracker.gd`, `project.godot`
- Trigger: launching the game or the editor.
- Workaround: none. Fix: `JSON.stringify(data, "\t")`. Also type-check the `JSON.parse_string` result (it may not be a `Dictionary`) and check `FileAccess.open` for null in `_load_progress`.

**The game never records progress, so the documented parent dashboard has no data:**
- Symptoms: nothing calls `ProgressTracker.record_lesson_complete(...)` (a grep across `scripts/` and `scenes/` finds only its definition). `user://progress.json` is never written. `docs/parent-dashboard.md` says "The game already writes progress to `user://progress.json`", which is false.
- Files: `scripts/progress_tracker.gd`, `scripts/lesson_manager.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd`, `docs/parent-dashboard.md`
- Fix: call `ProgressTracker.record_lesson_complete(...)` from each lesson's completion handler before `change_scene_to_file`.

**`GameHUD` connects to a signal that does not exist:**
- Symptoms: `scripts/game_hud.gd:34` calls `get_tree().group_added.connect(...)`. `SceneTree` has no `group_added` signal in Godot 4, so `_ready` in the `GameHUD` of `scenes/main.tscn` errors at runtime (likely).
- Files: `scripts/game_hud.gd`
- Fix: remove the dynamic hook, or use `get_tree().node_added` and filter with `node.is_in_group("collectibles")`.

**`AudioManager` assigns a property that does not exist:**
- Symptoms: `scripts/audio_manager.gd:173,177` set `player.loop`. `AudioStreamPlayer` has no `loop` property in Godot 4 (looping is set on the stream, e.g. `AudioStreamOggVorbis.loop`). This likely errors at autoload startup, and background music will not loop.
- Other defects in the same file:
  - `set_sfx_volume` stores the value but never applies it to `_sfx_player`.
  - BGM is routed to the `SFX` bus (line 103), so BGM and SFX cannot be mixed separately.
  - The variables `_bgm_volume_db` / `_sfx_volume_db` actually hold linear values, not dB.
  - The doc comment mentions a `SFX_PATH` that does not exist.
- Files: `scripts/audio_manager.gd`, `assets/audio/bgm_ambient.ogg.import`
- Fix: set `loop=true` in the `.ogg.import`, or set `stream.loop` after `load()`. Add a `BGM` bus in `project.godot`.

**Clicking or tapping the main menu Start button does nothing:**
- Symptoms: `scenes/main_menu.tscn` connects only `LessonButton.pressed`. `StartButton` has no connection. Only Enter works, through `_input` in `scripts/main_menu.gd:13`. Enter also always loads `main.tscn`, even when `LessonButton` has focus.
- Files: `scenes/main_menu.tscn`, `scripts/main_menu.gd`
- Impact: touch users and mouse-only young children cannot start the intro level.
- Fix: add a `pressed` handler for `StartButton`, and replace the raw `KEY_ENTER` check with focus-driven `ui_accept`.

**The title screen changes scene twice and has a dead About button:**
- Symptoms: in `scripts/title_screen.gd`, `_input` handles `ui_accept` and the focused `PlayButton` also emits `pressed`. A single Enter press can call `change_scene_to_file` twice. The `About` button in `scenes/title_screen.tscn` has no connection.
- Files: `scripts/title_screen.gd`, `scenes/title_screen.tscn`

**Lessons 2–5 cannot be reached:**
- Symptoms: no scene or script references `lesson_2.tscn`, `lesson_3.tscn`, `lesson_4.tscn` or `lesson_5.tscn`. The main menu only links to `lesson_1.tscn`.
- Files: `scripts/main_menu.gd`, `scenes/main_menu.tscn`, `scenes/lesson_2.tscn` … `scenes/lesson_5.tscn`

**Lessons 4 and 5 are placeholders that say they are available:**
- Symptoms: `scripts/lesson_4.gd` and `scripts/lesson_5.gd` are 10-line stubs ("Placeholder scene for Lesson 4"). The scenes show the subtitle "Les 4 - Nu beschikbaar" ("now available").
- Files: `scripts/lesson_4.gd`, `scripts/lesson_5.gd`, `scenes/lesson_4.tscn`, `scenes/lesson_5.tscn`
- Note: the quality gate's placeholder patterns (`scripts/tools/quality_gate.py`) do not match "Placeholder", so this passes CI.

**Lesson 2 does not enforce the shape order it promises:**
- Symptoms: the header of `scripts/lesson_2.gd` says the child must touch circle, then square, then triangle. `_expected_order` is declared but never used. Any order completes the lesson.
- Files: `scripts/lesson_2.gd`

**Lesson 1 gets stuck if counting is finished first:**
- Symptoms: `scripts/lesson_manager.gd:_on_lesson_complete` does nothing unless `red_block` and `blue_target` are already done. `count_challenge` emits `task_completed` only once, so completing the count first leaves the lesson permanently unfinishable. The "Taken: N / 3" label also never counts the count task.
- Files: `scripts/lesson_manager.gd`, `scripts/count_challenge.gd`
- Fix: track all three tasks in `_completed_tasks`, and check for completion after each one.

**Collect sound plays twice or not at all:**
- Symptoms: `scripts/collectible.gd` plays its own `AudioStreamPlayer`, whose stream is unset in `scenes/collectible.tscn`, so it is silent. `scripts/game_hud.gd` also plays `"collect"`. `scripts/hud.gd` duplicates `game_hud.gd` and no scene uses it (dead code).
- Files: `scripts/collectible.gd`, `scripts/game_hud.gd`, `scripts/hud.gd`, `scenes/collectible.tscn`

**Finish and replay logic is duplicated:**
- Symptoms: both `scripts/finish_marker.gd` (`_process` + `KEY_ENTER`) and `scripts/intro_scene.gd` (`_process` + `KEY_ENTER`) reload the scene. `scenes/main.tscn:257` connects `FinishMarker.finished` to `_on_finish_reached`, but `finished` is never emitted; the marker calls `main._on_finish_reached()` directly through the `main` group instead.
- Files: `scripts/finish_marker.gd`, `scripts/intro_scene.gd`, `scenes/main.tscn`

**Mobile touch controls are not wired in:**
- Symptoms:
  - `scripts/camiel_controller.gd:22` looks up the group `"mobile_controller"`, but no node ever joins that group.
  - Neither `scenes/ui/mobile_controller.tscn` nor `scenes/ui/mobile_joystick.tscn` is instanced in `main.tscn` or any lesson.
  - The `mobile_jump` input action in `project.godot` has no events.
  - `scenes/ui/mobile_joystick_integration_plan.md` describes an autoload that is not registered.
  - `mobile_controller.gd` normalizes the move vector to ±1, so the joystick has no analog range.
  - A second finger is ignored once `_touch_id` is set, so the player cannot move and jump at the same time.
- Files: `scripts/mobile_controller.gd`, `scripts/camiel_controller.gd`, `scenes/ui/mobile_controller.tscn`, `scenes/ui/mobile_joystick.tscn`, `project.godot`

**The Accessibility autoload has no effect:**
- Symptoms: nothing calls `toggle_high_contrast()`, and no node implements `_apply_contrast`. Its constants are unused, and the setting is not saved.
- Files: `scripts/accessibility.gd`

**Linux export job fails:**
- Symptoms: in `.github/workflows/export.yml` (Export Linux step), `tar -czf "dist/linux/Camiel-linux.tar.gz" Camiel.x86_64` runs from the repo root, but the binary is at `dist/linux/Camiel.x86_64`. `tar` exits with "No such file".
- Fix: `tar -C dist/linux -czf dist/linux/Camiel-linux.tar.gz Camiel.x86_64`.

**Release job in `export.yml` publishes directories, not files:**
- Symptoms: `download-artifact` puts files at `release/camiel-windows-<ref>/Camiel-windows.zip`. The rename step runs `mv camiel-windows-*/...` against the working directory, fails, and `|| true` hides the failure. `softprops/action-gh-release` then receives `release/*`, which are directories, so no assets are uploaded.
- Files: `.github/workflows/export.yml`
- Fix: `mv release/camiel-*/* release/ && rmdir release/camiel-*`, or use `merge-multiple: true`.

## Tech Debt

**Three overlapping build/release workflows with different Godot versions:**
- Issue:
  - `.github/workflows/ci.yml` and `.github/workflows/release.yml` pin Godot `4.6.2`.
  - `.github/workflows/export.yml`, `README.md`, `docs/web-export.md` and `docs/quick-start.md` specify `4.6.4`.
  - `docs/build-and-release.md` says `4.6`, and uses a wrong templates URL (`godot-export-templates` repo).
  - A `v*` tag triggers both `export.yml` (release job) and `release.yml`, so two jobs race to create and upload to the same GitHub release.
  - The Godot download and template install steps are copy-pasted five times.
- Files: `.github/workflows/ci.yml`, `.github/workflows/export.yml`, `.github/workflows/release.yml`, `docs/build-and-release.md`
- Impact: CI checks a different engine than the one used to export. Tag releases are nondeterministic.
- Fix approach: keep one `GODOT_VERSION` source (a reusable workflow or composite action under `.github/actions/setup-godot/`). Delete one of the two release paths. Restrict `release.yml` to `alpha-v*`, or drop the release job from `export.yml`.

**Stale version strings are hardcoded throughout:**
- Issue:
  - `alpha-v0.0.1` is hardcoded in the CI artifact names (`ci.yml`: `Camiel-alpha-v0.0.1.exe`) and in the release notes file (`release.yml`: `--notes-file ALPHA_V0_0_1_NOTES.md`, used for every tag).
  - `alpha-v0.0.3` is hardcoded in:
    - `project.godot` (`config/name`)
    - `scripts/main_menu.gd`, `scripts/title_screen.gd`, `scripts/ui/menu_button.gd` and `scripts/ui/version_label.gd` (its comment claims the text is read from `project.godot`, but it is hardcoded)
    - `scenes/main_menu.tscn` and `scenes/title_screen.tscn`
    - `export_presets.cfg` (paths and `file_version`)
    - `docs/accessibility-report.md` and `docs/parent-dashboard.md`
  - `workflow_dispatch` in `release.yml` defaults to `alpha-v0.0.1`.
- Impact: every release publishes alpha-v0.0.1 notes. Because the version is inside `config/name`, the `user://` directory (`app_userdata/Camiel alpha-v0.0.3/`) changes each version, which would orphan saved progress.
- Fix approach:
  - Add `config/version` to `project.godot` and read it with `ProjectSettings.get_setting("application/config/version")` in `scripts/ui/version_label.gd`.
  - Set `config/name="Camiel"`, and set `application/config/use_custom_user_dir` with a stable name.
  - Generate release notes per tag, or use `CHANGELOG.md`.

**Export presets are unusable or never exercised:**
- Issue:
  - Preset 4 uses `platform="HTML5"`, which is the Godot 3 name; Godot 4 calls it `"Web"`, so the preset is likely rejected.
  - The Android preset has empty keystore fields and `application/icon=""`, and no CI job builds it. It also contains Windows-only keys (`application/file_version`, `company_name`).
  - The macOS export runs on `ubuntu-latest` with `codesign/enable=false`, so the resulting `.app` is unsigned and not notarized, and Gatekeeper will block it.
  - `export_path` values point at `builds/alpha-v0.0.3/...`.
- Files: `export_presets.cfg`, `.github/workflows/export.yml`, `docs/web-export.md`, `docs/code-signing.md`
- Fix approach: recreate the Web and Android presets in the Godot 4.6 editor, add a CI export job for each preset kept, and remove presets that are not supported.

**Scenes use hand-written UIDs, and most scripts have no `.uid` sidecar:**
- Issue:
  - 18 scenes use made-up UIDs, e.g. `uid://blesson4`, `uid://star001` and `uid://lesson1`. These are not valid base-34 Godot UIDs and may collide or be regenerated.
  - Only `camiel_controller.gd`, `intro_scene.gd` and two tool scripts have `.gd.uid` files. Godot 4.4+ generates them on the next editor open, creating noisy diffs.
- Files: `scenes/*.tscn`, `scenes/ui/*.tscn`, `scripts/*.gd`
- Fix approach: open the project in the editor once, let it regenerate UIDs and `.uid` files, and commit the result.

**Hardcoded key polling instead of the InputMap:**
- Issue: `scripts/camiel_controller.gd`, `scripts/intro_scene.gd`, `scripts/finish_marker.gd` and `scripts/main_menu.gd` use `Input.is_key_pressed(KEY_*)`. No gamepad, touch or remapping support exists, and the key set is duplicated between the controller and the intro message logic.
- Fix approach: define `move_left`, `move_right`, `jump`, `run`, `sit` and `sleep` in `[input]` of `project.godot`, and use `Input.is_action_pressed`.

**Leftover debug `print` calls and untyped code:**
- Issue:
  - `print(...)` calls remain in `scripts/red_block.gd`, `scripts/blue_target.gd`, `scripts/shape_target.gd`, `scripts/sequence_target.gd` and `scripts/accessibility.gd`.
  - Untyped `var` and `@onready` without types in `scripts/lesson_2.gd`, `scripts/lesson_3.gd`, `scripts/mobile_controller.gd` and `scripts/progress_tracker.gd`.
  - `scripts/lesson_3.gd` calls the private `_set_inactive()` on its targets.
  - Wrong-order touches in `scripts/sequence_target.gd` overwrite the label with `str(order_number)`, losing the original text.

**Docs overstate what is implemented:**
- `docs/roadmap.md` / `CHANGELOG.md` / `README.md` claim "Accessibility checks completed, WCAG 2.1 AA compliant". Computed contrast ratios for colours in `docs/accessibility-report.md` and the scripts:

  | Text / background | Ratio | AA (4.5:1)? |
  |---|---|---|
  | White on win green `(0.15,0.85,0.15)` | 1.91:1 | Fails |
  | White on start green `(0.43,0.74,0.31)` | 2.33:1 | Fails |
  | White on `menu_button.gd` green `(0.2,0.7,0.2)` | 2.76:1 | Fails |
  | White on sequence amber `(0.8,0.6,0.1)` | 2.58:1 | Fails |

  The report claims ~7.2:1 for the green combinations.
- `README.md` says "Alpha v0.0.4+ — In progress" and lists voice-over, mobile touch, web export and parental dashboard. In the code:
  - No voice-over assets or code exist.
  - Mobile controls are not wired in.
  - The Web preset is invalid.
  - The dashboard is documentation only, a "Future: Next.js" plan.
  - Commit `754b99d` ("implement items 1-10 from alpha-v0.0.4 roadmap") added mostly scaffolding and docs.
- `docs/roadmap.md` has no alpha-v0.0.4 section even though lessons 2–5, mobile, progress tracker and export changes exist. `CHANGELOG.md` has no entry for them.
- `docs/build-and-release.md` references a nonexistent `run_quick_test.gd`, and says `glab`/git.euraika.net although the repo is on GitHub.
- `README.md` is scrambled: the wiki link sits under "Building" and the build commands under "Community And Security". "License: MIT / GPL" contradicts `LICENSE`, which says proprietary, all rights reserved.
- `ALPHA_V0_0_1_NOTES.md` lives at the repo root but is used as notes for every release.
- Fix approach: correct the claims, or implement the missing pieces. Add a roadmap/changelog entry for v0.0.4 work that marks items done only when they are wired and reachable.

**Unused utility script:**
- `scripts/ui/extract_templates.py` is not referenced by any workflow. It defaults to `"4.6/stable"`, a wrong directory format (Godot uses `4.6.4.stable`), and `/tmp/templates.tpz`. Remove it or align it with the workflow's install logic.

## Security Considerations

**`.pi/` agent run data is committed despite being gitignored:**
- Risk: `.gitignore` contains `.pi/`, but commit `c9d8e70` force-added 39 files (`.pi/flow.json`, `.pi/workflows/runs/*.json`, `*.json.bak`, `run-*.log`, ~568 KB). They contain:
  - absolute local machine paths (`/Volumes/T9/Code/projects/Project-Camiel`)
  - a pi `sessionId`
  - `tokenUsage` data
  - full agent scripts and journals
  - duplicated `.bak` copies

  No credential patterns (`ghp_`, `github_pat`, `sk-`, `Bearer`) were found; the only matches were `$GITHUB_PATH` workflow text. The problem is still exposure of internal tooling and machine details, plus noise in history. `scripts/tools/quality_gate.py` skips `.pi` (`IGNORED_DIRS`), so future runs could commit secrets without CI noticing.
- Files: `.pi/`, `.gitignore`, `scripts/tools/quality_gate.py`
- Current mitigation: none; the ignore rule has no effect because the files are already tracked.
- Recommendations:
  - `git rm -r --cached .pi` and commit.
  - Add a CI hygiene check in `.github/workflows/ci.yml` that fails when `git ls-files .pi` is non-empty.
  - Add a secret scan (e.g. gitleaks) that does not exclude `.pi`.
  - Rewriting history is optional, since no secrets were found.

**Unsigned binaries are published:**
- Risk: Windows (`codesign/enable=false`) and macOS builds are released unsigned. SmartScreen and Gatekeeper warnings teach parents to click through security prompts. `docs/code-signing.md` is guidance only.
- Files: `export_presets.cfg`, `.github/workflows/release.yml`, `.github/workflows/export.yml`
- Recommendations: get certificates, or mark releases as pre-release with checksum files (`sha256sum`) attached.

**Workflow permissions and action pinning:**
- Risk:
  - `.github/workflows/release.yml` grants `contents: write` for the whole workflow, not per job.
  - Actions use mutable tags (`actions/checkout@v6`, `softprops/action-gh-release@v2`, `actions/upload-artifact@v4`/`@v7`) rather than commit SHAs.
  - `export.yml` runs on every `pull_request` with no branch filter, including forks.
  - Godot binaries are downloaded with `curl` and no checksum verification.
- Recommendations: pin third-party actions by SHA (Dependabot keeps them updated through `.github/dependabot.yml`), verify the Godot zip/tpz SHA-512 from the release `SHA512-SUMS.txt`, and scope `contents: write` to the publishing job.

**Child data privacy (future):**
- Risk: `docs/parent-dashboard.md` suggests reading `progress.json` from devices, including Android `Android/data/org.godotengine.camiel/`, which is a generic package name. The game targets ages 3+. Any future sync must address GDPR/COPPA.
- Files: `docs/parent-dashboard.md`, `export_presets.cfg` (Android package id)

## Performance Bottlenecks

**Recursive tree walk on accessibility toggle:**
- Problem: `scripts/accessibility.gd:_collect_canvas_layers` walks the whole scene tree on every toggle.
- Cause: brute-force traversal.
- Improvement path: use a signal (`contrast_changed`) or a `high_contrast` group with `get_tree().call_group(...)`. The cost is small at the current scene size.

**Per-frame polling in `_process`:**
- Problem: `scripts/intro_scene.gd` rewrites `message.text` every frame; `scripts/finish_marker.gd` polls Enter every frame after triggering.
- Improvement path: update the label only on input change, and use `_unhandled_input` with actions. Low impact.

**Repository size (105 MB of assets, no LFS):**
- Problem: `assets/` holds 95 PNGs and 3 OGGs, ~105 MB, stored as normal git blobs. `.gitattributes` does not mark PNG/OGG as binary or LFS. The roadmap notes "Reduce duplicate legacy assets" (`assets/dogs/` and `assets/camiel/poses/` overlap).
- Improvement path: remove unused pose sets, add `*.png binary` / `*.ogg binary` to `.gitattributes`, and consider Git LFS before more art lands.

## Fragile Areas

**CI does not catch GDScript runtime or parse errors:**
- Files: `.github/workflows/ci.yml` (Smoke test main scene), `scripts/tools/verify_camiel_resources.gd`
- Why fragile:
  - `--quit-after 2` exits 0 even when autoloads or scripts fail to parse, so the `ProgressTracker` parse error and the `group_added` / `loop` errors pass CI.
  - `verify_camiel_resources.gd` only checks the sprite frames, `camiel.tscn` and `main.tscn`. The title screen (the actual main scene), menu and lessons are never loaded.
- Safe modification:
  - Capture stderr in the smoke test and fail on `SCRIPT ERROR` / `Parse Error` / `ERROR:` lines.
  - Extend the verify script to `load()` and `instantiate()` every `res://scenes/**/*.tscn`.
  - Run the smoke test against `title_screen.tscn` and each lesson.
- Test coverage: no GDScript unit tests.

**The `.import` gitignore rule conflicts with committed import files and the quality gate:**
- Files: `.gitignore` (`*.import`), `assets/**/*.import` (98 tracked), `scripts/tools/quality_gate.py:check_asset_import_metadata`
- Why fragile: 98 `.import` files are tracked, but `*.import` is ignored. A newly added PNG's `.import` is not added by `git add`. Locally the quality gate still passes, because it checks file existence on disk. On a clean CI checkout it fails with `missing-godot-import`, or the asset imports with default settings (which breaks pixel filtering).
- Safe modification: remove the `*.import` line from `.gitignore`, since Godot recommends committing `.import` files.

**Node-path coupling in lesson scripts:**
- Files: `scripts/intro_scene.gd` (`$WinLayer/WinOverlay/VBox/WinTitle`), `scripts/main_menu.gd` (`$ColorRect/VBox/StartButton`), `scripts/title_screen.gd`, `scripts/lesson_manager.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd`
- Why fragile: renaming or reparenting a node in the editor silently breaks `@onready` lookups. Cross-node calls go through groups and underscore-prefixed "private" methods (`main._on_finish_reached()`, `target._set_inactive()`).
- Safe modification: use `%UniqueName` nodes, `@export var` node references, and signals instead of group lookups into private methods.

**Scene transitions after `await` timers:**
- Files: `scripts/lesson_manager.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd`, `scripts/finish_marker.gd`, `scripts/sequence_target.gd`
- Why fragile: `await get_tree().create_timer(...)` followed by `change_scene_to_file` or node access. If the player presses "Terug" (back) or the scene changes during the wait, the coroutine resumes on a freed node and errors.
- Safe modification: check `is_inside_tree()` after the `await`, or use a scene-owned `Timer` node.

## Scaling Limits

**Lesson architecture:**
- Current capacity: 5 lesson scenes (2 of them empty), each with a custom orchestrator script (`lesson_manager.gd`, `lesson_2.gd`, `lesson_3.gd`) that duplicates progress-label, completion and back-navigation logic.
- Limit: each new lesson copies the orchestrator. The menu has no lesson selection, and progress is not recorded.
- Scaling path: add a shared `LessonBase` script (e.g. `scripts/lessons/lesson_base.gd`) with `task_completed` aggregation and `ProgressTracker` recording, plus a data-driven lesson list for the menu.

**Progress file:**
- Current capacity: `scripts/progress_tracker.gd` appends every completion to one JSON array with a full read and rewrite each time, and has no schema version.
- Limit: unbounded growth; one corrupt write loses all history.
- Scaling path: add a `version` field, write to a temp file then rename, and keep per-lesson best results instead of an append log.

## Dependencies at Risk

**Godot engine version drift:**
- Risk: config feature `"4.6"` in `project.godot`; CI uses 4.6.2 and export uses 4.6.4. Scenes contain `unique_id=` attributes (`scenes/main.tscn`) written by a newer editor, which may not load cleanly in 4.6.2.
- Impact: CI can pass on a different engine than the one used for release builds.
- Migration plan: pin one patch version everywhere and document it in `docs/godot-setup.md`.

**GitHub Actions version mix:**
- Risk: `actions/upload-artifact@v4` and `actions/download-artifact@v4` in `export.yml`, versus `@v7` in `ci.yml`. Dependabot bumps each file separately.
- Migration plan: consolidate the workflows (see Tech Debt).

## Missing Critical Features

**Save/settings persistence:** there is no settings save for volume or high contrast, and progress is never written (see Known Bugs). Blocks: parent dashboard, and resuming lessons.

**Voice-over for non-readers:** listed in `docs/roadmap.md` and `README.md` for v0.0.4, with no assets, bus or code. All instructions are Dutch text labels, which the target audience (3+, pre-readers) cannot read. Blocks: the core educational usability goal.

**Touch/mouse-first navigation:** the Start button is unwired and gameplay is keyboard-only. Blocks: tablet use, Android and Web releases.

**Lesson selection menu:** no UI reaches lessons 2–5.

## Test Coverage Gaps

**All GDScript gameplay code is untested:**
- What's not tested: every script in `scripts/*.gd` and `scripts/ui/*.gd`, i.e. movement, collectibles, lesson completion, sequence order, progress saving and audio. The only automated tests are `tests/test_quality_gate.py` (4 tests of the Python repository linter).
- Files: `scripts/`, `tests/`
- Risk: the lesson-1 deadlock, the lesson-2 order bug, the progress parse error and the unwired Start button all ship green.
- Priority: High
- Approach: add GUT or GdUnit4 under `addons/` with tests in `tests/gdscript/`, and run them headless in `.github/workflows/ci.yml`.

**Scene load coverage:**
- What's not tested: `title_screen.tscn` (the configured main scene), `main_menu.tscn`, `lesson_1.tscn` … `lesson_5.tscn`, and `scenes/ui/*.tscn` are never loaded in CI.
- Files: `scripts/tools/verify_camiel_resources.gd`
- Risk: broken `res://` paths inside scripts (not scanned by the gate, which only reads string literals in resource files) or broken node paths go undetected.
- Priority: High

**Export workflow validation:**
- What's not tested: `export.yml` Linux packaging and the release asset upload are broken, but only run on push or tag. Web and Android presets are never exported.
- Files: `.github/workflows/export.yml`, `export_presets.cfg`
- Risk: tag releases fail or publish nothing.
- Priority: Medium

**Quality gate blind spots:**
- What's not tested: `.pi/` is excluded from scanning; "Placeholder" text is not flagged; version-string consistency is not checked; the gate does not verify that docs claims ("WCAG AA compliant", "game writes progress") match the code.
- Files: `scripts/tools/quality_gate.py`, `tests/test_quality_gate.py`
- Priority: Low

---

*Concerns audit: 2026-09-11*
