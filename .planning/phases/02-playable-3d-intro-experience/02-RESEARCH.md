---
phase: "2"
slug: "playable-3d-intro-experience"
status: complete
researched: 2026-09-12
engine: "Godot 4.7.2.stable.official.ed1daf0bf (verified, see Verified Facts)"
---

# Phase 2: Playable 3D Intro Experience — Research

**Researched:** 2026-09-12
**Domain:** Godot 4.7 headless UI/audio/gameplay testability for a title screen → main menu → 3D
intro level → win-screen flow.
**Confidence:** HIGH — every load-bearing claim below was reproduced against the installed
Godot 4.7.2 binary in a throwaway `mktemp -d` scratch project this session (never against the
repo's own scenes/scripts, and never against documentation alone). Commands and raw output are
in the Verified Facts table. Nothing in this document is carried over from Phase 1 without
being re-checked for Phase 2's specific scenario (Control UI, CanvasLayer overlay, Area3D
pickups, audio buses).

**Method note:** All scratch tests used `mktemp -d` project directories outside the repository.
Nothing under `scenes/`, `scripts/`, `assets/`, or `project.godot` in this repository was
touched by any test. Every `zz_*` probe file created during research was deleted from its
scratch directory; `git status --short` at the end of this session shows no stray artifacts.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Numbering continues from Phase 1 (which ended at D-12). D-13 through D-30 are LOCKED — this
research does not re-open them, it only establishes how to implement them correctly against
the real engine. Full text is in `02-CONTEXT.md`; summarized for reference:

- **D-13:** Rebuild title screen, main menu, win screen fresh. Take only Dutch strings/layout
  intent from `archive/2d-alpha-v0.0.3`; do not port scripts.
- **D-14:** Tap/click/keyboard collapse into `BaseButton.pressed` only. No script changes
  scenes from `_input`/`_gui_input`.
- **D-15:** Every scene-changing handler carries a one-shot `_transitioning` guard and performs
  the change deferred.
- **D-16:** Rebuild `scenes/ui/menu_button.tscn` + `scripts/ui/menu_button.gd` as the single
  focusable icon+label button.
- **D-17:** `scenes/intro_level.tscn` fully enclosed, one low ramp.
- **D-18:** Collectible is a floating, slowly rotating primitive (sphere, emissive) with
  `Area3D` trigger.
- **D-19:** Exactly one collectible.
- **D-20:** Finish marker is an `Area3D` emitting a `finished` signal; the level listens and
  shows the win screen.
- **D-21:** Finish marker not gated on collecting the object.
- **D-22:** Three audio buses: Master, Music, SFX (Music and SFX both → Master).
- **D-23:** Rebuild `AudioManager` autoload, keep archived public surface
  (`play_music`, `stop_music`, `play_sfx`, `set_bgm_volume`, `set_sfx_volume`), fix bus routing
  and the linear-vs-dB confusion.
- **D-24:** Looping guaranteed via `loop = true` on the imported `.ogg` stream resource, plus a
  probe asserting `playing` after several seconds. Kept files: `bgm_ambient.ogg`,
  `sfx_collect.ogg`, `sfx_finish.ogg`.
- **D-25:** SFX volume control is an `HSlider` on the main menu.
- **D-26:** Headless probe asserts testable proxies: bus indices resolve, BGM player
  `playing == true` after N seconds, stream `loop == true`, `set_sfx_volume()` changes only the
  SFX bus's `volume_db`.
- **D-27:** Retarget `verify_3d_project.gd`'s `Node3D`-root assertion to the gameplay scene
  (`intro_level.tscn`), not the main scene (which becomes the title screen, a `Control`).
- **D-28:** Scene flow `title_screen.tscn` → `main_menu.tscn` → `intro_level.tscn`. Win screen
  is a `CanvasLayer` overlay inside the intro level, not a separate scene.
- **D-29:** Add `scripts/tools/probe_screen_flow.gd`, auto-discovered by the `probe_*.gd` glob.
- **D-30:** Phase 2 closes with one short human playtest.

### Claude's Discretion

- Exact intro-level geometry (floor, ramp, walls, lighting, collectible/finish placement)
  within D-17's enclosed shape.
- Visual styling details already resolved by `02-UI-SPEC.md` (colors, type, spacing) — treat
  the UI-SPEC as locked for this research, not re-litigated here.
- Icon sourcing — resolved by UI-SPEC's procedural `vector_icon.gd` approach.
- Collectible rotation speed, emissive intensity, pickup feedback timing — resolved by UI-SPEC
  (30°/s spin, 0.1m/2s bob, 1.15× pulse over 0.15s).
- SFX/BGM slider range and defaults — resolved by UI-SPEC (0-100 step 5, defaults 80/60).
- Node/signal naming within `CONVENTIONS.md`.
- How many plans the phase splits into and their wave grouping — see Recommended Task
  Decomposition below.

### Deferred Ideas (OUT OF SCOPE)

- **MODEL-01** — real 3D art for Camiel. Not this phase.
- Progress persistence and the five lessons — Phase 3.
- WCAG AA contrast and high-contrast toggle — Phase 4.
- Analog/multi-touch controls — Phase 6.
- Dutch voice-over — Phase 5.
- Web export — Phase 7.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MENU-01 | Title screen Play transitions to main menu exactly once, tap/click/keyboard | RQ1 (headless UI testability), RQ5 (scene routing + exactly-once guard) — VF6-VF9 prove `ui_accept` synthesis, focus, and the `change_scene_to_file` deferral hazard |
| MENU-02 | Main menu Start responds to tap/click/keyboard through one code path | Same as MENU-01; `menu_button.tscn` is shared (D-16) |
| INTRO-01 | Camiel moves freely in 3D, camera follows | Already built in Phase 1 (`camiel_controller.gd`, `probe_camiel_movement.gd`); Phase 2 only re-instances it inside `intro_level.tscn` |
| INTRO-02 | Camiel can jump | Same — Phase 1 `jump` action already probed |
| INTRO-03 | Collect a 3D collectible; pickup SFX plays exactly once | RQ4 (Area3D pickup) — VF10-VF12 prove `body_entered` de-dupes per-body regardless of shape count, and that double `.connect()` of the same signal→method throws a loud `ERROR:`, not a silent double-fire |
| INTRO-04 | Reaching finish triggers win screen via single signal-driven path | RQ4/RQ3 — `finished` signal wiring, CanvasLayer overlay |
| INTRO-05 | Win screen: two icon buttons, tap/click/Enter, one code path | RQ1, RQ3 — same button pattern as menu buttons, `%WinLayer` process_mode |
| INTRO-06 | BGM loops continuously; SFX volume has audible effect | RQ2 (audio) — VF13-VF20 are the load-bearing findings; **the committed `.ogg` files do not currently import** (see Pitfall 1) |

</phase_requirements>

---

## Verified Facts

Every row was produced by running `/Applications/Godot.app/Contents/MacOS/Godot` (4.7.2.stable,
confirmed identical to Phase 1's F1) against a scratch project this session. Commands are
abbreviated for readability; exact invocations used `mktemp -d` scratch dirs.

| ID | Fact | Command | Observed output |
|----|------|---------|------------------|
| VF1 | **The three committed placeholder audio files are Opus-encoded, not Vorbis, and fail Godot's Vorbis importer.** `assets/audio/bgm_ambient.ogg` (and the other two) start with `OggS...OpusHead`, not the Vorbis identification header. | `xxd assets/audio/bgm_ambient.ogg \| head -1` then imported via `--headless --editor --path SCRATCH --quit` on a fresh copy with no pre-existing `.import` sidecar | Header bytes `4f67 6753 ... 4f70 7573 4865 6164` (`OggS`...`OpusHead`). Fresh import produced: `WARNING: Desync during ogg import.` / `ERROR: Ogg Vorbis decoding failed. Check that your data is a valid Ogg Vorbis audio stream.` / `ERROR: Error importing 'res://assets/bgm_ambient.ogg'.` |
| VF2 | **This failure is currently dormant in the repo, not caught by CI.** Because the three `.ogg.import` sidecars are already committed with `valid=false`, a fresh checkout (no `.godot/` cache) does **not** re-attempt the import or re-emit the error — Godot treats the existing `.import` file as already-processed. | rsync'd a full working-tree copy (excluding `.git/`, `.godot/`, `.planning/`, `.pi/`) to a scratch dir, then `--headless --editor --path COPY --quit` | Import stage only logged `_update_scan_actions \| bgm_ambient.ogg` etc., no reimport, no `ERROR:` line. `cat COPY/assets/audio/bgm_ambient.ogg.import` still shows `valid=false`, no `path=`/`dest_files=` keys. |
| VF3 | **Loading the broken resource at runtime returns null and logs an `ERROR:` line** (which trips `run_headless_check.sh`'s log-scan the moment anything actually calls `load()` on it) — even though `ResourceLoader.exists()` reports `true` for the same path (so the CONVENTIONS.md fail-soft `ResourceLoader.exists()` guard alone will not prevent the error line, only the `stream == null` check that follows `load()` will keep it from crashing). | `load("res://assets/audio/bgm_ambient.ogg")` in a `--script` probe against the fresh-checkout copy | `ERROR: Failed loading resource: res://assets/audio/bgm_ambient.ogg.` ; `LOADED: <Object#null>`. Separately: `ResourceLoader.exists(path) == true` and `ResourceLoader.exists(path, "AudioStream") == true`. |
| VF4 | **A genuine Ogg Vorbis file (not Opus) imports cleanly** at the same path/extension. | Generated via `ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ac 2 -threads 1 -c:a vorbis -strict -2 -qscale:a 4 tone.ogg` (ffmpeg's native `vorbis` encoder requires `-ac 2`, stereo — mono errors with "Current FFmpeg Vorbis encoder only supports 2 channels"), then `--headless --editor --quit` | Import log: `reimport \| tone.ogg` with no `ERROR:`/`WARNING:` lines. Resulting `.import`: `valid` key absent (implicitly true), `path="res://.godot/imported/tone.ogg-....oggvorbisstr"`, `dest_files=[...]` populated. |
| VF5 | **`AudioStreamPlayer` (the node) has no `loop` property; loop must be set on the `AudioStream` resource**, confirming CONCERNS.md's claim precisely. | `for prop in AudioStreamPlayer.new().get_property_list(): ...` scanning for `name == "loop"` | `AudioStreamPlayer has 'loop' property: false`. Separately, `stream.loop = true` (on the loaded `AudioStreamOggVorbis`) succeeds and reads back `true`; setting `.import`'s `[params] loop=true` then reimporting also produces `stream.loop == true` on load — **both routes work**; the `.import`-file route is the one D-24 names ("on the imported .ogg stream resource") and is a one-line diff per file. |
| VF6 | **`[audio_bus_layout]` written directly inside `project.godot` is inert in 4.7.2 — it does not create buses.** This repo's own committed `project.godot` already has this section (Master + SFX) and it has **zero effect**: `AudioServer.get_bus_count()` is 1 at runtime. | `--script` probe against the actual repo (not a copy): `AudioServer.get_bus_count()`, `get_bus_name(i)` | `REPO bus count: 1` / `bus 0: Master send= vol=0.0` — the committed "SFX" bus does not exist at runtime. |
| VF7 | **The correct, working mechanism is a committed `res://default_bus_layout.tres` resource** (type `AudioBusLayout`), auto-loaded at the default path with **no** `project.godot` key required. Generated via `AudioServer.add_bus()` + `generate_bus_layout()` + `ResourceSaver.save()` to get the exact on-disk format. | Built 2 buses at runtime, saved layout, then re-launched the same scratch project (unchanged `project.godot`) and re-queried `AudioServer.get_bus_count()` | Generated file verbatim: see Q2 code sample below. Second launch: `bus count: 3` / `bus 0: Master send=` / `bus 1: Music send=Master` / `bus 2: SFX send=Master`; `AudioServer.get_bus_index("Music") == 1`, `("SFX") == 2`. |
| VF8 | **Bus volume isolation works exactly as D-26 requires**: setting one bus's `volume_db` does not touch another's. | `AudioServer.set_bus_volume_db(sfx_idx, -10.0)` then read both | `Music volume_db: 0.0` / `SFX volume_db: -10.0` |
| VF9 | **`AudioStreamPlayer.playing` reports `true` under `--headless`** on this machine (macOS; audio driver reported as `CoreAudio` even in headless mode — see Assumptions for the Linux/CI caveat), immediately after `.play()` and 2 frames later, once the player is genuinely inside the tree. | `player.play()` then check `.playing` same frame and 2 `physics_frame`s later, with `--fixed-fps 60` | `playing right after play(): true` / `playing after 2 frames: true` |
| VF10 | **Headless `Control` focus works with no window/rendering, and `grab_focus()` + a synthesized `ui_accept` action event fires `BaseButton.pressed` exactly once.** No exotic setup needed — `InputEventAction` bound to the action name, fed through `Input.parse_input_event()`, is sufficient (simpler than matching the actual bound keycode). | Instantiate a `Control` scene with one `Button`, `add_child` under `SceneTree.root`, `await process_frame` ×2, `btn.grab_focus()`, then `Input.parse_input_event(InputEventAction{action="ui_accept", pressed=true})` then `pressed=false`, `await process_frame` ×2 | `has_focus before: true` / `focus_owner: PlayButton:<Button#...>` / `PLAY BUTTON PRESSED FIRED` / `fire_count after ui_accept action event: 1` |
| VF11 | **`await process_frame` / `await physics_frame` inside a `--script` `SceneTree` hangs forever without `--fixed-fps 60`.** Confirms the existing convention (`run_headless_check.sh` always launches probes with `--fixed-fps 60`) is load-bearing, not stylistic. | Ran the same probe with plain `--headless --script` (no `--fixed-fps`) | Process never reached `quit()`; killed after 120s timeout. Re-run with `--fixed-fps 60` completed normally. |
| VF12 | **Calling `get_tree().change_scene_to_file(path)` directly (not deferred) from inside the pressed handler removes the calling node from the tree *synchronously*, before the handler returns** — `is_instance_valid()` stays `true` but `is_inside_tree()` becomes `false` immediately, so any subsequent line in the same handler that calls `get_tree()` again throws. The actual scene swap (new scene added, becomes `current_scene`) completes correctly either way; the hazard is only for code written *after* the call in the same handler. | Button's `pressed` handler called `change_scene_to_file()` undeferred, then on the next line printed `is_inside_tree()` and touched `get_tree()` again | `immediately after call, is self still valid/in tree?: true / false` then `ERROR: Parameter "data.tree" is null.` / `SCRIPT ERROR: Invalid access to property or key 'current_scene' on a base object of type 'null instance'.` A version with nothing after the call (`err = change_scene_to_file(...)`, then just `print(err)`) ran clean, `err == 0` (OK), `current_scene` became the target scene next frame. |
| VF13 | **Default `collision_layer`/`collision_mask` for `CharacterBody3D` and `Area3D` are both `1`/`1`** — no explicit layer/mask setup is needed for the collectible/finish-marker `Area3D`s to detect Camiel under Jolt Physics, as long as nothing changes the defaults. | `CharacterBody3D.new().collision_layer` / `.collision_mask`; same for `Area3D.new()` | `player collision_layer/mask: 1 / 1` / `area collision_layer/mask: 1 / 1` |
| VF14 | **`Area3D.body_entered` fires exactly once per body, even when that body has multiple `CollisionShape3D` children overlapping the area simultaneously** (Godot de-dupes at body level via an internal overlap counter; `body_shape_entered` fires per-shape, `body_entered` does not). This *rules out* "multiple collision shapes" as the cause of the archived "collect sound plays twice" bug. | `CharacterBody3D` with 2 overlapping `CapsuleShape3D`s entering one `Area3D`; counted `body_entered` emissions over 10 physics frames | `body_shape_entered` logged twice (`body_shape_idx=1`, `body_shape_idx=0`); `body_entered fired, count=1` only once; `final fire_count (body_entered): 1` |
| VF15 | **Connecting the same signal to the same method twice (once via a `.tscn` `[connection]` block, once via `_ready()` code) does *not* cause a double-fire — Godot 4.7.2 refuses the second `connect()` call outright and raises a loud `ERROR:`.** This corrects `CONVENTIONS.md`'s stated risk for `collectible.tscn`/`finish_marker.tscn`: the actual documented 2D bug ("collect sound plays twice or not at all") was caused by **two independent listeners** (`collectible.gd` and `game_hud.gd` both playing SFX off the same `collected` signal), not by a duplicate connection to the same handler. | Built a scene with both a `[connection signal="body_entered" ... method="_on_body_entered"]` block and a `body_entered.connect(_on_body_entered)` call in `_ready()` | `ERROR: Signal 'body_entered' is already connected to given callable 'Area3D(dup_area.gd)::_on_body_entered' in that object.` ; `is_connected count: 1` (from `get_connections().size()`); one `emit()` → `fired, count=1` (handler ran once, not twice). |
| VF16 | **`SceneTree.paused = true` blocks a `CanvasLayer` button's `pressed` signal unless that node's `process_mode` is `PROCESS_MODE_ALWAYS`** — reproducing the exact pause/UI gotcha the UI-SPEC's Open Question #2 describes, and confirming its recommended default is necessary if pause is ever used. | `CanvasLayer` with one focused `Button`; set `SceneTree.paused = true`; synthesize `ui_accept`; compare fire count with `process_mode` left default vs. set to `PROCESS_MODE_ALWAYS` | Case A (paused, default `process_mode`): `fire_count: 0`. Case B (same, `process_mode = PROCESS_MODE_ALWAYS`): `fire_count: 1`. |
| VF17 | **`Camiel` already joins the `"player"` group itself, in `camiel_controller.gd`'s own `_ready()` — `add_to_group("player")` at line 36.** This directly resolves `02-UI-SPEC.md`'s "Open Question 1": no scene-instance override adding `groups=PackedStringArray("player")` to the `Camiel` node in `intro_level.tscn` is needed. It would be harmless (group membership is idempotent) but is not required. | `Read` of `scripts/camiel_controller.gd` (already in this repo, not a scratch project) | `scripts/camiel_controller.gd:36`: `add_to_group("player")` inside `func _ready() -> void:`. |
| VF18 | **`Button.focus_mode` already defaults to `FOCUS_ALL` (value `2`)** — the UI-SPEC's explicit `focus_mode = Control.FOCUS_ALL` line in `menu_button.gd`'s `_ready()` is redundant-but-harmless, not a required fix. | `Button.new().focus_mode` | `Button default focus_mode: 2 (FOCUS_NONE=0, FOCUS_CLICK=1, FOCUS_ALL=2)` |
| VF19 | `linear_to_db()` / `db_to_linear()` are valid global GDScript functions in 4.7.2 (needed for `AudioManager.set_bgm_volume`/`set_sfx_volume`'s linear-to-dB conversion, matching the archived API contract). | `linear_to_db(0.8)`, `db_to_linear(-1.9382)` | `linear_to_db(0.8) = -1.93820026016113`; `db_to_linear(-1.94) ≈ 0.8` |
| VF20 | `AudioStreamPlayer` node has **no `loop` property but does have a `bus: String` property** used to route to a named bus (`"Music"`, `"SFX"`); routing by bus **name**, not by manually resolved index, is what the archived code already does and what still works. | Same property-list scan as VF5, plus VF9's player which set `.bus = "Music"` and produced correct isolated volume behavior in VF8 | `bus` present in property list (type `String`); `player.bus = "Music"` then playing through that bus was reflected correctly in `AudioServer.set_bus_volume_db` targeting. |
| VF21 | Camiel's existing `teleport_to(target: Vector3)` method (Phase 1, `camiel_controller.gd`) already resets `velocity = Vector3.ZERO` and snaps the camera — it is the correct, already-tested primitive for the win-screen "Nog een keer" replay reset; no new reset code needs to be hand-rolled for position/velocity. | `Read` of `scripts/camiel_controller.gd` (this repo) | `scripts/camiel_controller.gd:163-171`: `func teleport_to(target: Vector3) -> void: global_position = target; velocity = Vector3.ZERO; _snap_camera_behind()` |
| VF22 | **`--headless` always forces the `Dummy` audio driver, on every platform — this resolves Assumption A1 below.** Godot's own `--help` text defines `--headless` as `(--display-driver headless --audio-driver Dummy)`; there is no separate "headless-but-real-driver" code path to worry about, on macOS or Linux. Every audio test in this document (VF5, VF8, VF9, VF20) was already run with `--headless` and therefore already exercised the real `Dummy` driver, on this machine, not a macOS-only shortcut. (`ProjectSettings.get_setting("audio/driver/driver")` prints the project's *configured preference* — `"CoreAudio"` on this machine's default — and does **not** reflect the actually-active runtime driver forced by `--headless`; querying it is a red herring, not evidence of which driver initialized. `AudioServer.get_driver_name()` is the correct call — it reported `"Dummy"` in every test below.) Re-ran the exact VF9 scenario with `--audio-driver Dummy` passed explicitly (redundant with `--headless`, done to remove any doubt) and got identical results. **Caveat added after further testing (VF23): the specific number `0.00290249427781` reported here is a frozen value, not a genuinely-advancing position — see VF23, which corrects the "nonzero and advancing" characterization below.** | `"$GODOT" --help \| grep -A1 'audio-driver'` ; `"$GODOT" --headless --audio-driver Dummy --fixed-fps 60 --script zz_dummy_probe.gd` (explicit stream: genuine-Vorbis `tone.ogg`, `stream.loop = true`, `player.play()`) | `--help`: `--headless  ... Enable headless mode (--display-driver headless --audio-driver Dummy).` Probe: `playing right after play(): true` / `playing after 30 physics frames: true` / `playback_position after 30 frames: 0.00290249427781`. | <!-- quality-gate: allow forbidden-phrase -->
| VF23 | **Correction, prompted by the coordinator's independent finding — `get_playback_position()` does not advance per-frame under Dummy; it is frozen for dozens of consecutive polls and only jumps in discrete steps tied to real wall-clock elapsed time, not physics-frame count.** Confirmed for both `AudioStreamWAV` (8-bit mono, matching the coordinator's exact repro shape) and genuine `AudioStreamOggVorbis`. With no artificial delay between polls (bare `await physics_frame` loop, `--fixed-fps 60`), position stayed at one constant value for 60 consecutive frames straight (WAV: frozen at `0.00580499`; Ogg: frozen at `0.00290249`, matching VF22 exactly). Adding a real 5ms `OS.delay_msec()` between polls revealed the actual mechanism: position advances in discrete steps roughly every ~93ms of *real* elapsed time (`0.00580499` → `0.09868481` at ~33ms real-elapsed → `0.19156462` at ~131ms → `0.28444445` at ~237ms), i.e. tied to the Dummy driver's mix-buffer cadence in wall-clock time, not to `--fixed-fps`-simulated frame count. **I could not reproduce the coordinator's specific "`playing` false at t0/t3, true only at t12" transition, or any negative `get_playback_position()` reading, despite trying 4 configurations: (1) a bare `SceneTree` probe with the node properly settled one frame before `play()` — `playing` was `true` and position non-negative from the very first sample; (2) the same but calling `play()` in the exact same call as `add_child()` with no settling frame — this instead threw `ERROR: Playback can only happen when a node is inside the scene tree` and `playing` stayed permanently `false` (a hard usage error, not a transient lag); (3) an `AudioManager`-shaped pattern where a freshly-`add_child`'d player's own `_ready()` immediately calls `.play()` on itself (mirroring this document's `AudioManager` skeleton exactly) — same result as (1); (4) real-time-paced polling — same result as (1), just with visible position jumps.** This is reported as an honest non-reproduction, not a refutation: the position-advance mechanism I did confirm (real-wall-clock-tied, not frame-tied) is exactly the kind of scheduling-sensitive behavior that could plausibly produce a brief false/negative transient window on a more heavily-loaded machine (e.g. CI) that my faster local loop skipped past between polls — the underlying cause (a real-time-driven mix thread queried from a `--fixed-fps`-accelerated, real-time-*unthrottled* poll loop, per VF11) is the same mechanism either way. **Practical conclusion, safe regardless of whose exact frame numbers apply on a given machine:** neither `playing` immediately after `.play()` nor `get_playback_position()` at any point in the first ~100ms of real time after `.play()` should be trusted at face value; see the Validation Architecture section's retry-loop pattern. | 4 scratch scripts, `--headless --fixed-fps 60`, both `AudioStreamWAV` (8-bit mono, 0.5s, matching the coordinator's setup) and genuine Vorbis `tone.ogg`; one variant added `OS.delay_msec(5)` between polls to correlate position jumps with real elapsed time (`Time.get_ticks_usec()`) | WAV, no delay, 60 samples: `t0..t59 playing=true pos=0.00580499` (constant, never changes). WAV, 5ms real delay between polls: `t0 (elapsed 0.010ms) playing=true pos=0.00580499` ... `t4 (elapsed 33.500ms) ... pos=0.09868481` ... `t17 (elapsed 131.410ms) ... pos=0.19156462` ... `t31 (elapsed 236.904ms) ... pos=0.28444445`. Ogg Vorbis, no delay, 60 samples: `t0..t59 playing=true pos=0.00290249` (constant). The "not inside tree" variant: `ERROR: Playback can only happen when a node is inside the scene tree` then `t0..t29 playing=false pos=0.0` for all 30 samples. No negative value observed in any run. | <!-- quality-gate: allow forbidden-phrase -->

---

## Assumptions and Risks

| # | Claim | Confidence | Impact if wrong | How an executor would detect it |
|---|-------|-----------|------------------|----------------------------------|
| A1 | **RESOLVED — no longer a cross-platform risk** — see VF22. `--headless` is documented by Godot's own `--help` text to force `--audio-driver Dummy` unconditionally, on every platform; there is no macOS-vs-Linux headless-audio divergence to worry about. Every audio assertion in this research (VF5, VF8, VF9, VF20, VF22, VF23) was already exercised under the real `Dummy` driver. Originally flagged MEDIUM pending cross-platform confirmation; the `--help` text plus the explicit `--audio-driver Dummy` re-run in VF22 make this HIGH. | HIGH (VF22) | — | — | <!-- quality-gate: allow forbidden-phrase -->
| A6 | **`playing` and `get_playback_position()` timing immediately after `.play()` under Dummy is scheduling-sensitive and not fully characterized.** VF23 confirms position is not frame-granular (frozen for dozens of polls, jumps on a real-wall-clock cadence) in every configuration tested, but could not reproduce the coordinator's reported transient `playing == false` window or negative position reading, despite 4 attempts including one structurally identical to the real `AudioManager` pattern. The most likely explanation is genuine machine/load-dependent scheduling variance in a real-time-driven mix thread being polled from an unthrottled `--fixed-fps` loop (VF11's mechanism, applied here) — i.e. probably a real, intermittent race, just not one this session's hardware reproduced on demand. | MEDIUM — the mechanism is understood and independently corroborated, the exact transient is not | If the race is real but rare, a probe that asserts `playing` too early could pass on most CI runs and flake red on a slow/loaded runner — exactly the kind of intermittent failure that erodes trust in the check. If it never actually occurs on real CI hardware, the retry-loop guidance below (Validation Architecture) is simply unnecessary defensive code, not a functional cost. | Adopt the bounded real-time retry loop (Validation Architecture, below) regardless — it is safe whether or not the race is real, and cheap. If it never fires, `playing` will already be `true` on retry attempt 1. | <!-- quality-gate: allow forbidden-phrase -->
| A2 | ffmpeg's `-c:a vorbis -strict -2` native encoder (used in VF4) produces files acceptable for shipping quality (not just "imports without error"). Only import-success and property values were checked, not perceived audio quality or file size at longer durations (D-24's placeholder files are 188 bytes / silent). | HIGH for "imports cleanly", LOW for "sounds acceptable" — untested | A regenerated placeholder that imports fine but is corrupted/silent/clipped would pass every headless assertion in this research and still fail the D-30 human playtest. | The D-30 human playtest is the backstop; also spot-check with `ffprobe generated.ogg` to confirm duration/channels look sane before committing. |
| A3 | The `default_bus_layout.tres` fix (VF7) is additive — no code currently reads `audio/buses/default_bus_layout` from `project.godot`, so simply committing the `.tres` file at the default resource path is sufficient without also adding a `project.godot` key. Verified only that it works with the key *absent*; not verified that adding the key explicitly wouldn't be needed on some other engine build. | HIGH (directly verified, VF7) | Low risk — if wrong, the fix is a one-line addition to `project.godot`'s `[audio]` section (`buses/default_bus_layout="res://default_bus_layout.tres"`), easy to detect via VF6's exact bus-count probe. | Re-run VF6/VF7's `AudioServer.get_bus_count()` probe against the real repo after adding the file; if it still reports 1, add the explicit key. |
| A4 | The exact byte-for-byte content the executor generates for the three replacement `.ogg` files (tone, duration, envelope) is left to Claude's Discretion per `02-CONTEXT.md`'s "Collectible rotation speed, emissive intensity, and pickup feedback timing" / general audio discretion — this research verifies the *pipeline* (ffmpeg → genuine Vorbis → Godot import → loop property), not specific musical content. | N/A — explicitly deferred, not a research gap | None; this is intentionally open | — |
| A5 | `probe_screen_flow.gd`'s design (Q1/Q5 below) recommends adding a `transition_requested(target_path: String)` signal to each of the three screens purely for testability, alongside (not instead of) the UI-SPEC's directly-specified `change_scene_to_file` call. This is a research recommendation, not something `02-UI-SPEC.md` explicitly specifies (the UI-SPEC's screen-by-screen spec only shows the direct call). Flagging per the research brief's explicit instruction to surface this tension. | HIGH that it's *necessary* for a robust exactly-once probe (VF12 shows there is no other reliable way to observe "the transition fired" without either a signal or fragile `current_scene` polling); MEDIUM that this exact signal name/shape is what the planner will choose | If the planner instead has the probe poll `current_scene.scene_file_path` after driving one press, it can prove "a transition happened" but cannot cheaply prove "exactly once" without also re-triggering the guard and re-checking non-mutation — more code, same conclusion. | See Q1/Q5 below for the concrete recommendation and the reasoning. |

---

## Research Questions — Implementation Guidance

### Q1 — Headless testability of Control UI (the highest-risk unknown)

**Verified: it works, cleanly, with no exotic setup (VF10, VF11).** The recipe:

```gdscript
# scripts/tools/probe_screen_flow.gd (pattern, condensed)
extends SceneTree

func _initialize() -> void:
	await _case_title_screen()
	# ... more cases ...
	print("Screen flow probe passed.")
	quit(0)

func _case_title_screen() -> void:
	var packed: PackedScene = load("res://scenes/title_screen.tscn")
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	# _ready() runs at end-of-frame, same caveat probe_camiel_movement.gd already documents.
	await process_frame
	await process_frame

	var fire_count := 0
	screen.transition_requested.connect(func(_target: String): fire_count += 1)

	var btn: Button = screen.get_node("%PlayButton")
	assert(btn.has_focus())  # UI-SPEC: grab_focus() called in _ready()

	_press_focused_button()
	await process_frame
	await process_frame

	if fire_count != 1:
		push_error("title_screen: transition_requested fired %d times, expected 1" % fire_count)
		quit(1)
		return

	# Prove the D-15 guard: fire pressed a second time, confirm no second transition.
	_press_focused_button()
	await process_frame
	if fire_count != 1:
		push_error("title_screen: _transitioning guard did not block a second press")
		quit(1)
		return

	screen.queue_free()
	print("PASS title_screen")


func _press_focused_button() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventAction.new()
	ev2.action = "ui_accept"
	ev2.pressed = false
	Input.parse_input_event(ev2)
```

Must be launched with `--fixed-fps 60` (VF11) — matches `run_headless_check.sh`'s existing
invocation for every `probe_*.gd`, no change needed there.

**Design constraint this forces back onto the screens (flagged per the research brief, see A5):**
`02-UI-SPEC.md`'s screen-by-screen spec has each button handler call
`get_tree().change_scene_to_file.call_deferred(...)` directly — there is no signal in that
spec. VF12 proves there is no clean way to observe "did `change_scene_to_file` get called,
and exactly once" from outside: polling `current_scene` after the fact can show *that* a
transition happened but not cheaply prove it happened *exactly once* (a second, blocked call
would look identical to zero second calls from the outside). The concrete, minimal-diff fix:
each screen emits a signal **immediately before** the deferred call, inside the same
`_transitioning`-guarded branch — this changes no visible behavior, no string, no node name
the UI-SPEC fixed, only adds one internal signal:

```gdscript
# scripts/title_screen.gd
signal transition_requested(target_path: String)

var _transitioning := false

func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_button_pressed)
	%PlayButton.grab_focus()

func _on_play_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit("res://scenes/main_menu.tscn")
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
```

The probe connects to `transition_requested` and counts emissions — it never needs to touch
`change_scene_to_file` or `current_scene` at all, sidestepping VF12's hazard entirely. The same
pattern applies to `main_menu.gd`'s Start handler and `intro_level.gd`'s "Naar menu" handler.
For the win-screen's "Nog een keer" (which does **not** change scenes — D-28 resets in place),
the equivalent observable is a `replay_requested` signal (or simply asserting the observable
side effects: `%WinLayer.visible == false` and `Camiel.global_position` back at
`PlayerSpawn.global_position` — cheaper here since there's no engine API to race against).

**On `change_scene_to_file` and the deferred call (Q5 overlap):** VF12 shows the call is safe
to make either deferred or direct *as long as nothing in the same handler runs after it*. The
UI-SPEC's `.call_deferred(...)` is the more defensive choice and should stay — it fully
sidesteps the "node desynced from tree mid-callback" hazard rather than relying on "don't write
code after this line." The `_transitioning` guard (D-15) is still necessary for a second,
independent reason beyond "exactly once" semantics: without it, a second `pressed` firing
(e.g. from any future double-connection bug) would call `change_scene_to_file` on a node
already removed from the tree, and VF12 shows touching `get_tree()` again on such a node
throws `ERROR: Parameter "data.tree" is null.` — i.e., the guard also prevents a crash, not
just a semantic double-transition.

---

### Q2 — Audio bus setup and its headless assertions (D-22, D-26)

**Buses are not defined inline in `project.godot`.** VF6 proves the repo's existing
`[audio_bus_layout]` section is dead. The correct mechanism is a committed
`res://default_bus_layout.tres` resource (VF7), auto-loaded at that default path with no
`project.godot` key required (A3 flags the small residual risk). Exact file to commit:

```
[gd_resource type="AudioBusLayout" format=3]

[resource]
bus/1/name = &"Music"
bus/1/solo = false
bus/1/mute = false
bus/1/bypass_fx = false
bus/1/volume_db = 0.0
bus/1/send = &"Master"
bus/2/name = &"SFX"
bus/2/solo = false
bus/2/mute = false
bus/2/bypass_fx = false
bus/2/volume_db = 0.0
bus/2/send = &"Master"
```

(`bus/0` = Master is implicit and does not need declaring.) Generate this by running a
one-off engine script (`AudioServer.add_bus(1); set_bus_name(1,"Music"); set_bus_send(1,"Master");
add_bus(2); set_bus_name(2,"SFX"); set_bus_send(2,"Master"); ResourceSaver.save(AudioServer.generate_bus_layout(), "res://default_bus_layout.tres")`)
rather than hand-typing it, so the `&"..."` StringName quoting and key ordering exactly match
what the engine itself expects — this avoids a repeat of the `JSON.SINDY_USE_HELPER`-style
hand-typed-constant mistake documented in `CONCERNS.md`. Remove (or leave as inert dead
weight, but preferably remove) the existing non-functional `[audio_bus_layout]` block from
`project.godot` so a future reader doesn't mistake it for the real configuration.

**Resolving bus index/volume:**

```gdscript
var music_idx := AudioServer.get_bus_index("Music")
var sfx_idx := AudioServer.get_bus_index("SFX")
AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(clampf(linear, 0.0, 1.0)))
```

**Does audio initialize under `--headless`?** Yes (VF9) — bus indices resolve, `.playing`
reports `true`, `set_bus_volume_db` isolation works exactly as D-26 needs (VF8). A1 flags the
one unverified cross-platform caveat (Linux CI driver).

**`loop = true` on the imported `.ogg`:** two working routes, verified (VF5):
1. Edit the committed `.ogg.import` file's `[params] loop=false` → `loop=true`, one line per
   file, then let the engine reimport. This is the literal reading of D-24's wording and the
   smallest diff.
2. Set `stream.loop = true` at runtime in `AudioManager.play_music()` right after `load()`,
   which also works and is resilient to someone re-running the importer with defaults later.

Recommend **both**: the `.import` edit as the source of truth (committable, diffable, matches
D-24's exact phrasing), plus a defensive `if stream is AudioStreamOggVorbis: stream.loop = true`
in code as a belt-and-suspenders (cheap, and protects against a future contributor's editor
reimport silently reverting the `.import` file).

**The actual, must-fix-first blocker (see Pitfall 1 below):** none of this matters until the
three committed `.ogg` files are replaced with genuine Vorbis-encoded audio (VF1-VF4) — they
currently fail to import and `load()` returns `null` with a loud `ERROR:` line that will fail
`run_headless_check.sh` the moment any script actually calls `load()` on them (which
`AudioManager.play_music()`/`play_sfx()` must do to satisfy D-23/D-24 at all).

**Rebuilt `AudioManager` autoload skeleton** (keeps the archived public surface per D-23,
fixes the routing/loop/dB defects documented in `CONCERNS.md`):

```gdscript
# scripts/audio_manager.gd
extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const BGM_PATH := "res://assets/audio/bgm_ambient.ogg"
const SFX_COLLECT_PATH := "res://assets/audio/sfx_collect.ogg"
const SFX_FINISH_PATH := "res://assets/audio/sfx_finish.ogg"

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_bgm_player = _get_or_create_player("BGM")
	_bgm_player.bus = MUSIC_BUS
	_sfx_player = _get_or_create_player("SFX")
	_sfx_player.bus = SFX_BUS
	set_bgm_volume(0.6)
	set_sfx_volume(0.8)
	if ResourceLoader.exists(BGM_PATH):
		play_music(BGM_PATH)


func play_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM not found: ", path)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Could not load BGM: ", path)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_bgm_player.stream = stream
	_bgm_player.play()


func stop_music() -> void:
	_bgm_player.stop()


func play_sfx(event: String, custom_path: String = "") -> void:
	var path := custom_path
	if path.is_empty():
		match event:
			"collect": path = SFX_COLLECT_PATH
			"finish": path = SFX_FINISH_PATH
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[AudioManager] SFX not found for event: ", event)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Could not load SFX: ", path)
		return
	_sfx_player.stream = stream
	_sfx_player.play()


func set_bgm_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(clampf(linear, 0.0, 1.0)))


func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), linear_to_db(clampf(linear, 0.0, 1.0)))


func _get_or_create_player(node_name: String) -> AudioStreamPlayer:
	var existing := get_node_or_null(node_name) as AudioStreamPlayer
	if existing != null:
		return existing
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player
```

Note the deliberate difference from the archive: volume is now stored **only** in the
`AudioServer` bus (via `set_bus_volume_db`), not duplicated into a private
`_bgm_volume_db`/`_sfx_volume_db` field — this is what directly fixes the archived
"linear-vs-dB confusion" (`CONCERNS.md`), since there is now exactly one source of truth per
bus, and `main_menu.gd` reads it back with `db_to_linear(AudioServer.get_bus_volume_db(idx))`
for the slider's `_ready()` sync (per the UI-SPEC's "reads the current volume back... in
`_ready()`" requirement).

---

### Q3 — CanvasLayer win-screen overlay inside a 3D scene (D-28)

Node structure is already fixed by `02-UI-SPEC.md` (`WinLayer: CanvasLayer` → `Scrim: Control`
→ `CenterContainer` → `WinPanel`). Two things this research adds:

**Pause gotcha — validated, not refuted (VF16).** `SceneTree.paused = true` blocks a
`CanvasLayer`'s button input unless `process_mode = PROCESS_MODE_ALWAYS`. The UI-SPEC's
recommended default — **do not pause the tree at all; disable Camiel's own processing
instead** — is the correct call, confirmed by VF16 (pausing is strictly more moving parts for
zero benefit here, since nothing else in `intro_level.tscn` needs pausing). Concretely:

```gdscript
# intro_level.gd, on reaching the finish marker
func _on_finish_marker_finished() -> void:
	%WinLayer.visible = true
	# fade-in per UI-SPEC's Motion table (modulate.a 0->1 over 0.3s) goes here
	%ReplayButton.grab_focus()
	_camiel.set_physics_process(false)
```

`camiel_controller.gd` already exposes `_physics_process` as the sole place movement/gravity/
jump happen (Phase 1), so `set_physics_process(false)` is a complete, one-line freeze with no
new API needed on the controller. `%WinLayer.process_mode = Always` stays set regardless
(per UI-SPEC) as the defensive default VF16 validates, even though nothing pauses the tree in
the chosen design — cheap insurance against a future contributor adding `paused = true`
elsewhere without re-deriving this finding.

**Replay reset ("Nog een keer" — D-28's "restarts without a scene round-trip"):**

```gdscript
func _on_replay_button_pressed() -> void:
	%WinLayer.visible = false
	_camiel.set_physics_process(true)
	_camiel.teleport_to(%PlayerSpawn.global_position)  # VF21: already resets velocity + camera
	%Collectible.reset()  # new public method, see Q4
```

`teleport_to()` already exists on `camiel_controller.gd` (VF21) and already zeroes velocity and
snaps the camera — reuse it rather than hand-rolling a transform/velocity reset.

---

### Q4 — Area3D pickup and finish detection (INTRO-03, INTRO-04)

**Collision setup:** defaults are sufficient (VF13) — `CharacterBody3D` and `Area3D` both
default to `collision_layer = 1`, `collision_mask = 1`, so no layer/mask configuration is
required for the collectible or finish marker to detect Camiel under Jolt Physics. This also
means the `Area3D` will fire `body_entered` for **any** default-layer body that overlaps it
(confirmed in VF13's own test run, where the static floor also triggered `body_entered`) — the
`is_in_group("player")` guard in the one-shot latch pattern is a functional requirement, not
just a style preference.

**Exactly-once, verified mechanism (VF14, VF15):**
- Multiple `CollisionShape3D`s on Camiel do **not** cause a double-fire — ruled out as a cause.
- Double-`connect()` of the same signal→method does **not** cause a double-fire either — it
  throws a loud `ERROR:` and only connects once. Ruled out.
- The actual historical cause (per `CONCERNS.md`'s own description, now corroborated by VF15's
  refutation of the "duplicate connection" theory) was **two independent listeners** both
  playing SFX off the same `collected` signal. The fix is structural: exactly one thing plays
  `"collect"` SFX. Per `02-UI-SPEC.md`, that's `intro_level.gd`'s
  `_on_collectible_collected()` handler — `collectible.gd` itself must **not** also play a
  sound.

```gdscript
# scripts/collectible.gd
extends Area3D
signal collected

var _touched := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)  # connect in code OR in .tscn, never both (VF15)

func _on_body_entered(body: Node3D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	_touched = true
	monitoring = false
	hide()
	collected.emit()

func reset() -> void:
	_touched = false
	monitoring = true
	show()
```

`monitoring = false` (rather than `queue_free()`) is what makes the D-28 in-place replay
possible without re-instancing the scene — matches the research brief's framing directly.
`intro_level.gd` is the **sole** SFX trigger:

```gdscript
# intro_level.gd
func _on_collectible_collected() -> void:
	AudioManager.play_sfx("collect")
```

**Finish marker** follows the identical one-shot shape but has no `reset()` call needed from
replay (D-21: not gated on the collectible; the finish marker itself doesn't need re-arming
for gameplay purposes, though re-enabling its own `_touched` latch on replay is still correct
so a second finish triggers the win screen again):

```gdscript
# scripts/finish_marker.gd
extends Area3D
signal finished

var _touched := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	_touched = true
	finished.emit()

func reset() -> void:
	_touched = false
```

`intro_level.gd` calls `%FinishMarker.reset()` alongside `%Collectible.reset()` in the replay
handler so a second lap can re-trigger the win screen.

---

### Q5 — Scene routing and the exactly-once guard

Covered above under Q1 (they are the same finding: VF12 is the load-bearing fact for both).
Summary: `change_scene_to_file.call_deferred(...)` is safe and is the UI-SPEC's chosen pattern;
the `_transitioning` guard remains necessary both semantically (MENU-01's "exactly once") and
defensively (prevents a crash from touching `get_tree()` on an already-detached node, per
VF12). The probe cannot observe the deferred call directly and needs the
`transition_requested` signal seam described in Q1.

---

### Q6 — Extending the verification chain

**`verify_3d_project.gd`'s `_check_main_scene()` change (D-27).** Currently (read this
session, `scripts/tools/verify_3d_project.gd:103-129`) it loads
`ProjectSettings.get_setting("application/run/main_scene", "")`, instantiates it, and asserts
`instance is Node3D`. Once `run/main_scene` becomes `res://scenes/title_screen.tscn` (a
`Control`), this assertion must retarget to a **specific gameplay scene path** rather than
whatever `main_scene` happens to be, per D-27's explicit rejection of "wrap the title UI in a
`Node3D` shell just to keep the check literal." Concrete diff:

```gdscript
# verify_3d_project.gd
const GAMEPLAY_SCENE_PATH := "res://scenes/intro_level.tscn"

func _check_gameplay_scene_is_3d() -> bool:
	if not ResourceLoader.exists(GAMEPLAY_SCENE_PATH):
		push_error("Gameplay scene does not exist: %s" % GAMEPLAY_SCENE_PATH)
		return false
	var packed: PackedScene = load(GAMEPLAY_SCENE_PATH)
	var instance := packed.instantiate()
	if not instance is Node3D:
		push_error("Gameplay scene root is not a Node3D: %s" % GAMEPLAY_SCENE_PATH)
		instance.free()
		return false
	instance.free()
	return true
```

Replace the call to `_check_main_scene()`'s `Node3D` assertion in `_initialize()` with this new
check (kept as a **separate** function so the main-scene load/instantiate check for
`title_screen.tscn` still runs too — the verifier should still prove the main scene loads and
instantiates cleanly, just without requiring it to be `Node3D`). The `_check_resources()` pass
(loads every tracked `.gd`/`.tscn`) already covers `title_screen.tscn`, `main_menu.tscn`, and
`intro_level.tscn` regardless of which is `main_scene`, so no additional coverage is lost by
narrowing the root-type assertion.

**Probe auto-discovery (D-29):** confirmed still true by reading `run_headless_check.sh` this
session — `PROBE_FILES="$(find "$ROOT/scripts/tools" -maxdepth 1 -type f -name 'probe_*.gd' ...)"`,
sorted, each run individually with `--fixed-fps 60` and a per-probe log scanned for
`SCRIPT ERROR|Parse Error|ERROR:`. Adding `scripts/tools/probe_screen_flow.gd` requires zero
changes to `run_headless_check.sh` itself — it is picked up automatically. The empty-glob guard
(self-test case 12, confirmed present in `test_headless_check.sh` lines 209-217) already fails
the check with `"no behaviour probes found"` if all `probe_*.gd` files are ever removed; Phase
2 does not weaken this guard by adding a new probe (it only strengthens the non-vacuity
argument, since now 2 probes must both be present, not 1).

**New self-test cases in `test_headless_check.sh` warranted for Phase 2's additions:**

1. **Planted duplicate-SFX-listener regression** — not practical as a `run_headless_check.sh`
   self-test (that script only exercises the check's own pass/fail behavior on synthetic
   faults, not gameplay semantics); this belongs in `probe_screen_flow.gd`'s own assertions
   instead (see Q4 — `intro_level.gd` is the sole SFX caller, provable by asserting SFX-bus
   playback state changes exactly once per pickup within the probe itself).
2. **A case proving `probe_screen_flow.gd`'s absence is caught** — technically already covered
   by the existing case 12 (empty glob), but a dedicated case removing *only*
   `probe_screen_flow.gd` (leaving `probe_camiel_movement.gd` in place) would prove the glob
   catches a *partial* removal too, which case 12 does not currently exercise (it removes
   every `probe_*.gd`). Concretely:
   ```bash
   # --- Case N: probe_screen_flow.gd specifically must run (not just "some probe exists") ---
   reset_copy
   rm -f "${WORK_DIR}/scripts/tools/probe_screen_flow.gd"
   assert_result "missing probe_screen_flow.gd still passes (glob non-empty) — documents the gap" 0 "Headless check passed." -- \
   	bash "${CHECK_SCRIPT}"
   ```
   This is worth adding **as a documented gap**, not a fix: the current glob design only
   guarantees *some* `probe_*.gd` exists, not that a *specific* named probe exists. If the
   planner wants D-29's probe to be provably load-bearing (not just "a probe"), the stronger
   guard is a fixed list of required probe basenames checked by name inside
   `run_headless_check.sh`, which is a larger change than this phase's scope — flag it as an
   Open Question for the planner rather than silently fixing it.
3. **A case for the audio-bus non-functional-config regression** — since VF6 proves inline
   `[audio_bus_layout]` silently does nothing, a self-test that plants a `project.godot` with
   only the inert inline section (no `default_bus_layout.tres`) and confirms
   `probe_screen_flow.gd` (or a dedicated `probe_audio_buses.gd`) **fails loudly** is valuable
   regression insurance — this is exactly the kind of silent-fallback failure mode Phase 1's
   `A1`/Jolt-physics-string finding was about.

---

## Pitfalls (tied to `CONCERNS.md`'s documented 2D-era defects)

### Pitfall 1 — The committed placeholder `.ogg` files do not import (NEW finding, blocks D-24 entirely)
**What goes wrong:** `assets/audio/bgm_ambient.ogg`, `sfx_collect.ogg`, `sfx_finish.ogg` are
Opus-encoded inside an Ogg container, but their `.import` sidecars declare
`importer="oggvorbisstr"` / `type="AudioStreamOggVorbis"`. Godot's Vorbis decoder cannot parse
Opus data (VF1). The import is already recorded as `valid=false` and silently skipped on every
subsequent run (VF2) — so this is invisible until something calls `load()` on the path, at
which point it returns `null` and logs `ERROR: Failed loading resource:` (VF3), which fails
`run_headless_check.sh`'s log-scan.
**Why it happens:** the placeholder files were almost certainly produced by a tool (or a
generic "silent placeholder" generator) that defaults to Opus, while the `.import` sidecar was
either hand-written or generated by an older/different importer assumption.
**Structural fix:** regenerate all three files as genuine Ogg Vorbis (VF4's ffmpeg recipe:
`ffmpeg -f lavfi -i "sine=..." -ac 2 -threads 1 -c:a vorbis -strict -2 -qscale:a 4 out.ogg`,
mono sources need `-ac 2` first because the native `vorbis` encoder only supports stereo) at
the exact same paths/filenames D-24 names, then let the editor reimport. This must be an early
task in the phase — nothing depending on `AudioManager.play_music`/`play_sfx` can be probed
until it's done.
**Warning signs:** `run_headless_check.sh`'s import step suddenly shows `ERROR:` lines
mentioning `ogg`/`vorbis`/`Desync`; or a probe that calls `AudioManager.play_music(...)` reports
`playing == false` with no other explanation.

### Pitfall 2 — Inline `[audio_bus_layout]` in `project.godot` is inert (NEW finding, blocks D-22/D-26)
**What goes wrong:** hand-editing `project.godot`'s `[audio_bus_layout]` section (as the
current repo already does, defining a never-materializing "SFX" bus) has zero runtime effect
in Godot 4.7.2 (VF6). A plan that "adds a Music bus" by editing this section the same way the
existing SFX entry was added will silently fail exactly like the SFX one already does.
**Why it happens:** this project-settings section format looks like normal
`project.godot` syntax and appears in some older tutorials/forum answers, but Godot 4's actual
bus-persistence mechanism is a separate `AudioBusLayout` resource file, referenced by
`audio/buses/default_bus_layout` (or auto-loaded from the default path with no key at all,
per VF7).
**Structural fix:** commit `res://default_bus_layout.tres` in the `AudioBusLayout` resource
format shown in Q2, generated via the engine's own `AudioServer`/`ResourceSaver` APIs rather
than hand-typed.
**Warning signs:** `AudioServer.get_bus_count()` stays at 1 no matter what's added to
`project.godot`; `AudioServer.get_bus_index("Music")` returns `-1`.

### Pitfall 3 — Title screen double-transition (`CONCERNS.md`: "changed scene twice")
**What goes wrong (archived):** `_input` handled `ui_accept` directly *and* the focused
`PlayButton` also emitted `pressed` from the same key event, so one Enter press ran
`change_scene_to_file` twice.
**Structural fix (D-14/D-15, this phase):** no script anywhere touches `_input`/`_gui_input`
for scene transitions — activation is `BaseButton.pressed` only (which itself already
absorbs tap, click, *and* `ui_accept`-on-focus for free, per VF10). The `_transitioning`
one-shot guard is the second line of defense per VF12's crash-prevention finding (Q5).
**Warning signs:** `probe_screen_flow.gd`'s "press the focused button twice" case (Q1's
skeleton) is exactly the regression test for this.

### Pitfall 4 — Unwired Start button (`CONCERNS.md`: "Clicking or tapping Start does nothing")
**What goes wrong (archived):** `main_menu.tscn` connected only `LessonButton.pressed`;
`StartButton` had no connection at all, so only keyboard Enter worked, and Enter always loaded
`main.tscn` regardless of which button had focus.
**Structural fix:** every `menu_button.tscn` instance's `pressed` is connected in `_ready()`
(D-14), and per VF10, focus + `ui_accept` already routes through the same `pressed` signal — no
separate keyboard-only path exists to accidentally hardcode a wrong target scene into.
**Warning signs:** a `menu_button` instance that never fires in `probe_screen_flow.gd`'s
per-screen case.

### Pitfall 5 — Two independent SFX listeners (`CONCERNS.md`: "collect sound plays twice or not at all")
**What goes wrong (archived):** `collectible.gd` played its own (unset/silent)
`AudioStreamPlayer` *and* `game_hud.gd` separately played `"collect"` off the same signal —
two listeners, not a duplicate connection (VF15 rules out the duplicate-connection theory
specifically).
**Structural fix:** `collectible.gd` only `emit()`s `collected`; the **single** listener that
calls `AudioManager.play_sfx("collect")` is `intro_level.gd`'s
`_on_collectible_collected()` (Q4). No other script connects to `%Collectible.collected`.
**Warning signs:** grep for `play_sfx(` outside `intro_level.gd` and `finish_marker`'s
equivalent single call site; more than one hit is the regression.

### Pitfall 6 — `GameHUD` connecting to a nonexistent signal (`CONCERNS.md`)
**What goes wrong (archived):** `get_tree().group_added.connect(...)` — `SceneTree` has no
`group_added` signal in Godot 4, so `_ready()` throws at runtime.
**Relevance to Phase 2:** there is no `GameHUD`-equivalent node in the new design (D-13: rebuilt
fresh, UI-SPEC has no HUD node); this defect class cannot recur unless a future phase
reintroduces a similar "watch the tree for X being added" pattern. No action needed now, noted
so nobody re-derives a `get_tree().node_added` group-lookup pattern from the archive without
first checking it against the actual Godot 4 `SceneTree` API surface.

---

## Recommended Task Decomposition

Worktree isolation is **enabled** for this phase — flagging real parallelism opportunities, not
just conceptual ones.

**Strictly ordered (must land before anything can be probed):**
1. **Audio asset fix** (Pitfall 1) — regenerate the three `.ogg` files as genuine Vorbis. Touches
   only `assets/audio/*.ogg` (+ their `.import` sidecars for the `loop=true` edit). No scene/
   script dependency. Should be plan/task 1, or at minimum wave 0, since `AudioManager`
   probing is blocked without it.
2. **Audio bus layout fix** (Pitfall 2) — commit `res://default_bus_layout.tres`. Touches a new
   root-level file only. Independent of task 1's content but both are audio-domain and cheap to
   bundle in the same plan.

**Three genuinely independent surfaces after the audio fixes land (real parallelism, distinct file sets):**

- **A. Title screen + Main menu + `menu_button` component** (`scenes/title_screen.tscn`,
  `scenes/main_menu.tscn`, `scenes/ui/menu_button.tscn`, `scripts/ui/menu_button.gd`,
  `scripts/ui/vector_icon.gd`, `scripts/title_screen.gd`, `scripts/main_menu.gd`,
  `assets/theme/ui_theme.tres`). Self-contained — no dependency on the 3D level. Satisfies
  MENU-01/MENU-02.
- **B. `AudioManager` autoload rebuild** (`scripts/audio_manager.gd`, `project.godot`'s
  autoload registration). Depends only on the two audio fixes above, not on A or C. Satisfies
  the audio half of INTRO-06.
- **C. Intro level geometry + collectible + finish marker + Camiel wiring**
  (`scenes/intro_level.tscn`, `scripts/intro_level.gd`, `scenes/collectible.tscn`,
  `scripts/collectible.gd`, `scenes/finish_marker.tscn`, `scripts/finish_marker.gd`). Depends
  on Phase 1's `camiel.tscn`/`camiel_controller.gd` (already built, read-only dependency) but
  not on A or B's files. Satisfies INTRO-01 through INTRO-04 (movement/jump already exist;
  this wave adds the collectible/finish/enclosure).

**Convergent, strictly after A + B + C:**

- **D. Win-screen overlay + audio slider wiring + full screen-flow assembly**
  (`intro_level.tscn`'s `WinLayer` subtree, `main_menu.tscn`'s `AudioPanel`/sliders wiring to
  `AudioManager`, and the actual `change_scene_to_file` targets connecting A→C). This plan
  necessarily touches files from A (`main_menu.tscn` for the sliders) and C
  (`intro_level.tscn` for `WinLayer`), so it cannot start until both land — the one required
  serialization point.
- **E. `probe_screen_flow.gd` + `verify_3d_project.gd`'s D-27 retarget.** Depends on A, C, and D
  all existing (the probe instantiates all three screens and the win overlay). This is
  necessarily the last plan. `verify_3d_project.gd`'s change is small and could theoretically
  land earlier (it only needs `intro_level.tscn` to exist with *a* `Node3D` root, not the full
  win-screen), but bundling it with the new probe keeps "verification chain" as one coherent
  plan per the research brief's framing.

**File-level overlap warning:** `main_menu.tscn` is touched by both A (creation, Start button,
base layout) and D (adding the `AudioPanel`/sliders and wiring them to `AudioManager`). If A
and D are split into separate plans, sequence D strictly after A for this file (do not attempt
to run D in a wave parallel with A even though D's *other* files, like `intro_level.tscn`'s
`WinLayer`, have no such conflict) — or fold the slider wiring into plan A directly, since the
slider *nodes* are already fully specified by the UI-SPEC as part of `main_menu.tscn`'s
initial build, and only the `AudioManager` *connection* (which requires B to exist) is the
part that must wait.

---

## Validation Architecture

> Seeds `02-VALIDATION.md` (plan-phase §5.5). Shape follows
> `01-VALIDATION.md`/`templates/VALIDATION.md`; content below is Phase 2-specific.

### Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Still none for GDScript (no GUT/GdUnit4 — out of scope, unchanged from Phase 1). Python stdlib `unittest` for `tests/test_quality_gate.py`, unchanged. The de facto GDScript test framework remains the headless check chain: `run_headless_check.sh` (import → main scene → `verify_3d_project.gd` → every `scripts/tools/probe_*.gd`) plus `test_headless_check.sh` (self-test of the check itself). |
| **Config file** | none — same as Phase 1 |
| **Quick run command** | `python3 scripts/tools/quality_gate.py --root .` (no Godot needed, catches forbidden phrases / broken `res://` paths / missing `.import` siblings in seconds) |
| **Full suite command** | `bash scripts/tools/run_headless_check.sh` — **unchanged invocation**, but its content grows: `verify_3d_project.gd` now asserts `intro_level.tscn`'s root is `Node3D` instead of the main scene's (D-27, Q6), and the probe glob now picks up **two** probes instead of one — `probe_camiel_movement.gd` (Phase 1, unchanged) and the new `probe_screen_flow.gd` (D-29). `bash scripts/tools/test_headless_check.sh` (self-test of the check) also grows by the cases proposed in Q6 (probe-glob partial-removal case, inert-audio-bus-config regression case). |
| **Estimated runtime** | Full suite: ~90-150 seconds observed-ceiling (watchdog caps are `IMPORT_LIMIT=180s` + `RUN_LIMIT=60s` + `VERIFY_LIMIT=60s` + `PROBE_LIMIT=120s` **per probe**, so nominally up to ~420s worst-case with 2 probes if every step maxed out its watchdog — in practice every step observed this session completed in low single-digit seconds once assets import cleanly, matching Phase 1's F2/F7 facts of sub-5s real execution against multi-minute ceilings). The one variable that changes the *real* number materially versus Phase 1 is the audio import pass: three real (non-silent-Opus) `.ogg` files reimporting is still a sub-second operation per VF4's ffmpeg-generated file, so no meaningful runtime growth is expected from Pitfall 1's fix itself. |

### Audio assertions under the actual CI driver (precision point #1)

**All four of D-26's assertions are provable under `--headless`, on any platform — but two of
them need a bounded retry loop, not an immediate same-frame assertion, and one candidate
fallback must NOT be used.** This section was revised after the coordinator independently
reproduced a `playing`-lag/negative-`get_playback_position()` transient this research did not
initially account for; see VF23 and A6 for the full reproduction attempt and honest gap.
Concretely, per assertion:

| D-26 assertion | Holds under `--headless`/Dummy? | How to assert it safely | Evidence | <!-- quality-gate: allow forbidden-phrase -->
|---|---|---|---|
| Correct bus indices resolve (`AudioServer.get_bus_index("Music"/"SFX") != -1`) | Yes, immediately, no timing sensitivity | Assert directly, same frame | VF7 |
| BGM player reports `playing == true` "after N seconds" (D-26's own wording already anticipates a delay — take it literally) | Yes, but **not necessarily in the same frame as `.play()`** — see the retry-loop pattern below | **Do not** assert `playing` in the same frame `.play()` was called. Poll in a bounded real-time retry loop (below) and assert only after it returns `true` or the timeout is hit | VF9, VF22 confirm `true` eventually; VF23 + the coordinator's independent report show the transition can lag past the first few polls on at least some machine/load combinations |
| Stream reports `loop == true` | Yes — a property on the `AudioStream` resource, no driver/timing involvement at all | Assert directly, same frame, right after `load()` | VF5 |
| `set_sfx_volume()` changes only the SFX bus's `volume_db` | Yes — `AudioServer.set_bus_volume_db`/`get_bus_volume_db` operate on the bus graph, not on the driver or playback state | Assert directly, same frame | VF8 |

**`get_playback_position()` must NOT be used as a liveness/fallback proxy — retracting the
prior version of this section.** VF23 shows it is frozen across dozens of consecutive polls at
a stretch under fast/no-delay polling (both `AudioStreamWAV` and genuine `AudioStreamOggVorbis`)
and only advances via discrete jumps tied to *real wall-clock* elapsed time, not simulated
frame count — so `> 0.0` can read `false` while the stream is genuinely playing, simply because
no mix-buffer boundary has been crossed yet. Separately, the coordinator's independently
reproduced reading of `-0.00099773239344` while `playing == true` shows the value can also be
*negative* near the start (a plausible latency-compensation artifact in Godot's position
calculation, not a real out-of-range playback position) — this research could not reproduce
the negative reading directly (VF23), but has no basis to rule it out, and the frozen/jumpy
behavior it did reproduce is sufficient on its own to disqualify `get_playback_position()` as a
same-frame or near-frame liveness check. **There is no safe fallback proxy based on playback
position; use the retry loop on `.playing` instead.**

**Recommended assertion pattern (bounded real-time retry, not a fixed frame count):**
`--fixed-fps 60` decouples simulated frame time from real wall-clock time (VF11) — the
Dummy driver's position/state updates are tied to real elapsed time (VF23), so a fixed <!-- quality-gate: allow forbidden-phrase -->
"wait N physics_frames" is not a portable margin across machines of different speed/load. Poll
against a real-time deadline instead:

```gdscript
# In probe_screen_flow.gd or a dedicated probe_audio_buses.gd
func _wait_until_playing(player: AudioStreamPlayer, timeout_ms: int = 2000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		if player.playing:
			return true
		await physics_frame
	return false

# usage:
AudioManager.play_music(BGM_PATH)
if not await _wait_until_playing(AudioManager._bgm_player):
	push_error("BGM did not report playing == true within 2000ms of play()")
	quit(1)
	return
```

2000ms real time is a deliberately generous margin — VF23's observed jump cadence was ~93ms
per step under artificial 5ms-per-poll pacing, so 2000ms is over 20x that with headroom for a
loaded CI runner. This costs nothing when `playing` is already `true` on the first check (the
common case, per VF9/VF22) and only spends real time when the race from A6 actually manifests.

### Probe-presence guard gap (precision point #2)

**Concrete, unresolved gap, recorded here as a validation requirement rather than fixed in this
research (fix is larger than this phase's scope):** `run_headless_check.sh`'s non-vacuity guard
(self-test case 12, `test_headless_check.sh`) only fails when the `probe_*.gd` glob is
**completely empty**. Once Phase 2 adds `probe_screen_flow.gd` alongside Phase 1's
`probe_camiel_movement.gd`, deleting *either one* while the other remains leaves the glob
non-empty — the check stays green while an entire probe's worth of assertions (e.g. every
MENU-01/02/INTRO-03/04/05 assertion, if `probe_screen_flow.gd` is the one lost) silently stops
running. This is the same class of failure this project has already hit twice (the empty-glob
vacuous pass Phase 1's code review caught, and the dormant Opus/Vorbis import mismatch this
research found) — a check that reports green with fewer assertions running than it appears to.

- **Recommended fix (not this phase's scope to implement, but flag for the planner/backlog):**
  replace the bare non-empty-glob check in `run_headless_check.sh` with a fixed allow-list of
  required probe basenames (e.g. a `REQUIRED_PROBES=("probe_camiel_movement.gd" "probe_screen_flow.gd")`
  array checked by name, failing loudly if any listed name is missing from the glob results,
  independently of how many *other* probes exist).
- **Minimum viable Phase 2 action (in scope):** add the `test_headless_check.sh` case from Q6
  (removing only `probe_screen_flow.gd`, leaving `probe_camiel_movement.gd` in place, and
  asserting the check **currently still reports "Headless check passed."** — i.e. document the
  gap as a known-red self-test expectation) so the gap is visible in the test suite itself
  rather than only in this document. Do **not** silently "fix" this by making that assertion
  pass without implementing the allow-list — that would misrepresent the guard's actual
  strength.
- **Wave 0 placement:** this is not a blocking Wave 0 item (nothing else depends on the guard
  being stronger to be verified), but the documentation case above should land in the same
  wave as `probe_screen_flow.gd` itself, so the gap is recorded the moment it becomes possible.

### Sampling Rate

- **After every task commit:** `python3 scripts/tools/quality_gate.py --root .` (seconds,
  no Godot needed)
- **After every plan wave:** `bash scripts/tools/run_headless_check.sh` (full import + main
  scene + verifier + both probes)
- **Before `/gsd-verify-work`:** `bash scripts/tools/run_headless_check.sh && bash scripts/tools/test_headless_check.sh`
  green, plus the D-30 manual playtest (title → menu → play → collect → finish → replay → menu)
- **Max feedback latency:** ~150 seconds (full-suite observed ceiling; see Estimated runtime
  above for the watchdog-cap vs. observed-runtime distinction)

### Per-Task Verification Map (seed — task IDs not yet assigned)

Task IDs will be `02-0X-TY` once PLAN.md files exist; rows below map each in-scope requirement
to a test type and a concrete, already-runnable command so the planner can attach IDs directly.

| Requirement | Test Type | Automated Command | File Exists? | Notes |
|-------------|-----------|--------------------|---------------|-------|
| MENU-01 | automated (headless probe) | `bash scripts/tools/run_headless_check.sh` (asserts `probe_screen_flow.gd`'s title-screen case: `transition_requested` fires exactly once, guard blocks a second press) | ❌ W0 — `probe_screen_flow.gd` does not exist yet | Needs the `transition_requested` signal seam from Q1 |
| MENU-02 | automated (headless probe) | same file, main-menu case | ❌ W0 | Same pattern as MENU-01; also needs `main_menu.tscn`'s Start button wired (Plan A) |
| INTRO-01 | automated (existing probe, needs retargeting) | `bash scripts/tools/run_headless_check.sh` (`probe_camiel_movement.gd`) | ✅ exists, but currently targets `test_space.tscn` not `intro_level.tscn` | Gap: no existing assertion proves movement/camera-follow specifically *inside* `intro_level.tscn`. Recommend either parametrizing `probe_camiel_movement.gd` to also load `intro_level.tscn`, or accepting the Phase 1 coverage as sufficient since `intro_level.tscn` reuses the same `camiel.tscn` instance and structure (`02-CONTEXT.md`'s own framing) — planner's call, flag explicitly either way |
| INTRO-02 | automated (existing probe, same gap as INTRO-01) | same | ✅ exists, same retargeting gap | Jump case (`_case_jump`) already proven against `test_space.tscn`'s floor; same recommendation as INTRO-01 |
| INTRO-03 | automated (new probe) | `bash scripts/tools/run_headless_check.sh` (new case in `probe_screen_flow.gd` or a dedicated `probe_intro_level.gd`: drive Camiel into `%Collectible`, assert `collected` fires exactly once, `AudioManager`'s SFX player transitions to `playing == true` exactly once, `%Collectible.monitoring == false` after) | ❌ W0 | Depends on Pitfall 1 (audio asset fix) landing first — an SFX-playing assertion is meaningless while `load()` on `sfx_collect.ogg` returns `null` |
| INTRO-04 | automated (new probe) | same probe file, finish-marker case: drive Camiel into `%FinishMarker`, assert `finished` fires exactly once, `%WinLayer.visible == true` after | ❌ W0 | Independent of INTRO-03 per D-21 (not gated on collectible) — can be a separate assertion case run either order |
| INTRO-05 | automated (headless probe) | same probe file, win-screen case: `%WinLayer` focus order `[%ReplayButton, %GoToMenuButton]`, synthesize `ui_accept` on each, assert the correct one-shot behavior (`replay_requested`/`transition_requested` fires once each, per Q1/Q3) | ❌ W0 | Reuses the exact `_press_focused_button()` helper from the MENU-01/02 cases (VF10) |
| INTRO-06 | automated (headless probe, **must use the bounded real-time retry loop, not a same-frame assertion**) + manual (D-30) | `bash scripts/tools/run_headless_check.sh` for the 4 D-26 proxy assertions (table above) — the `playing == true` assertion specifically must call `_wait_until_playing()` (Validation Architecture's retry-loop pattern) with a real-time timeout, e.g. 2000ms, **not** `assert(player.playing)` on the frame right after `play()`; D-30 playtest for genuine audibility | ❌ W0 for the probe half | **Hard Wave 0 dependency**: blocked on both Pitfall 1 (regenerate `.ogg` files as genuine Vorbis) and Pitfall 2 (commit `default_bus_layout.tres`) landing first — no D-26 assertion can pass while `AudioManager.play_music("res://assets/audio/bgm_ambient.ogg")` returns `null` from `load()` or while `AudioServer.get_bus_index("Music") == -1`. **Additionally**: do not use `get_playback_position()` anywhere in this assertion (VF23/A6) — it is frozen for many polls at a stretch and can read non-monotonically near start; the retry loop must poll `.playing` only. |

### Wave 0 Requirements

- [ ] **Regenerate the three placeholder `.ogg` files as genuine Ogg Vorbis** (Pitfall 1) —
      blocks every INTRO-06 assertion and any probe that calls `AudioManager.play_music`/
      `play_sfx`. Verified working recipe: `ffmpeg -f lavfi -i "sine=frequency=440:duration=N" -ac 2 -threads 1 -c:a vorbis -strict -2 -qscale:a 4 out.ogg` (native `vorbis` encoder requires stereo, VF4).
- [ ] **Commit `res://default_bus_layout.tres`** defining Music/SFX buses sending to Master
      (Pitfall 2) — blocks every D-26 bus-index/volume-isolation assertion. Generate via the
      engine's own `AudioServer.add_bus()`/`generate_bus_layout()`/`ResourceSaver.save()` calls
      (Q2), not hand-typed, to avoid a repeat of `CONCERNS.md`'s hand-typed-constant mistake
      class. Remove the now-documented-inert `[audio_bus_layout]` block from `project.godot`.
- [ ] **`scripts/tools/probe_screen_flow.gd`** (D-29) — new file, blocks MENU-01, MENU-02,
      INTRO-05, and (if folded into the same file) INTRO-03/04's automated verification.
- [ ] **`verify_3d_project.gd`'s D-27 retarget** — new `_check_gameplay_scene_is_3d()` function
      pointed at `res://scenes/intro_level.tscn` (Q6) — blocks the full suite from passing at
      all once `run/main_scene` becomes `title_screen.tscn` (a `Control`), since the current
      `_check_main_scene()` would otherwise fail every run.
- [ ] **`test_headless_check.sh` additions from Q6** — the probe-glob partial-removal
      documentation case (see Probe-presence guard gap above) should land in the same wave as
      `probe_screen_flow.gd`.
- [ ] Godot 4.7.2 local install — unchanged carry-over from Phase 1 (D-08), still a hard
      prerequisite for every command in this section.

*Everything else (the `menu_button` component, `intro_level.tscn`'s geometry, the
`AudioManager` rebuild's non-bus-layout code) is ordinary plan/task work, not a Wave 0
blocker — it can be verified incrementally as each plan lands, per the Recommended Task
Decomposition above.*

### Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| Full title → menu → play → collect → finish → replay → menu flow feels right on a real pointer/touch device, and audio is genuinely audible with a perceptible volume-slider effect | MENU-01, MENU-02, INTRO-03, INTRO-04, INTRO-05, INTRO-06 | D-30 mandates one short human playtest, for the same reason as Phase 1's D-11: tap/click on a real device and genuine audibility cannot be verified headlessly (a Dummy audio driver, however faithfully it tracks playback *state*, produces no sound to judge slider feel against) | Run the built game (not headless), play through title → menu → intro level → collect the object → reach the finish → click "Nog een keer" → click "Naar menu", using both mouse/touch and keyboard at least once each; drag the SFX slider and confirm an audible volume change | <!-- quality-gate: allow forbidden-phrase -->



