---
phase: 02-playable-3d-intro-experience
plan: 03
subsystem: gameplay
tags: [godot, node3d, control, screen-flow, headless-probe, physics]

requires:
  - phase: 02-playable-3d-intro-experience (plan 01)
    provides: rebuilt AudioManager autoload, genuine-Vorbis audio, default_bus_layout.tres — unrelated but confirms the headless-check baseline this plan builds on
  - phase: 02-playable-3d-intro-experience (plan 02)
    provides: scenes/ui/menu_button.tscn + scripts/ui/menu_button.gd (the single focusable icon-plus-label Button), assets/theme/ui_theme.tres — consumed directly by title_screen.tscn and main_menu.tscn
provides:
  - "scenes/intro_level.tscn — the enclosed Node3D gameplay scene the phase's requirements name, holding Camiel, a PlayerSpawn marker, four walls, and one ramp"
  - "scripts/tools/verify_3d_project.gd retargeted (D-27): the Node3D-root assertion now targets res://scenes/intro_level.tscn by name, and the check still proves the Control-rooted main scene loads and instantiates"
  - "scripts/tools/probe_camiel_movement.gd parametrized: the portable case subset (idle, forward, jump, camera_behind) now also runs against intro_level.tscn, plus a new enclosure case proving D-17's enclosure claim rather than assuming it"
  - "scenes/title_screen.tscn + scripts/title_screen.gd, scenes/main_menu.tscn + scripts/main_menu.gd — the real title-screen-to-main-menu-to-intro-level flow (D-28), each transition guarded one-shot and fired through exactly one code path (D-14, D-15)"
  - "scripts/tools/probe_screen_flow.gd (D-29) — proves MENU-01/MENU-02's exactly-once contract headlessly"
  - "project.godot: application/run/main_scene is now the title screen"
affects: [win-screen, audio-panel-main-menu, phase-4-contrast-pass]

actuals:
  tokens: 8187
  tasks: 2
  commits: 2
plan_head_before: f00461f4615578b5afbce2b5c447dd2eb364363e

tech-stack:
  added: []
  patterns:
    - "Portable vs scene-specific probe case grouping: a case function is written once and re-run against multiple scenes when its assertions depend only on a floor, a camera, and a spawn point — scene-specific geometry (open edges, single back walls) stays in a scene-only group"
    - "A signal (transition_requested) added purely for headless observability, emitted immediately before the deferred engine call it shadows — the probe never touches change_scene_to_file or current_scene directly, sidestepping the detached-node hazard entirely"
    - "Scene and resource files built via a throwaway zz_-prefixed generator script run once through the engine, then deleted before commit (same method as Phase 1 and 02-02)"

key-files:
  created:
    - scenes/intro_level.tscn
    - scenes/title_screen.tscn
    - scenes/main_menu.tscn
    - scripts/title_screen.gd
    - scripts/main_menu.gd
    - scripts/tools/probe_screen_flow.gd
  modified:
    - scripts/tools/verify_3d_project.gd
    - scripts/tools/probe_camiel_movement.gd
    - project.godot
    - scripts/tools/test_headless_check.sh

key-decisions:
  - "Camiel's ready callback already calls add_to_group(\"player\") (engine-verified, camiel_controller.gd:36), so intro_level.tscn's Camiel instance carries no scene-instance group override — resolves 02-UI-SPEC.md's Open Question 1 by confirming the recommended default was already true, not by adding anything"
  - "The enclosure probe case holds move_back (S), not move_right (D): PlayerSpawn sits at (0,0,4) inside a 16m room, so the nearest wall is ~3.75m away along +Z — only that direction contacts a wall within the 120-frame budget at walk_speed 2.5 m/s. Holding a direction that cannot reach a wall in time would pass the assertions vacuously without proving enclosure"
  - "ambient_light_source is set to AMBIENT_SOURCE_COLOR (engine value 2), not AMBIENT_SOURCE_SKY (value 3), on intro_level.tscn's WorldEnvironment — matching test_space.tscn's committed value and 02-UI-SPEC.md's explicit `ambient_light_source=2` line exactly, even though the plan's own prose called it 'the sky-colour source'. Verified against the running engine (Environment.AMBIENT_SOURCE_COLOR == 2) before writing the generator, since a mismatch here silently changes how the flat-colour background lights the room"
  - "project.godot's run/main_scene retarget used a direct one-line text edit, not ProjectSettings.save() — the engine's own save() call silently dropped the unrelated renderer/rendering_method.web line on this pass, which a plain git diff caught immediately; the direct edit changes exactly the one line the plan requires"

patterns-established:
  - "A scene-changing handler emits an internal signal one line before its deferred change_scene_to_file call, purely so a probe can count activations without racing the engine's own scene-swap timing"

requirements-completed: [MENU-01, MENU-02, INTRO-01, INTRO-02]

coverage:
  - id: D1
    description: "scenes/intro_level.tscn is a Node3D-rooted, fully enclosed room (four walls, one ramp) holding Camiel and a PlayerSpawn marker; verify_3d_project.gd asserts it by name (D-27) instead of asserting the main scene's root type"
    requirement: "INTRO-01"
    verification:
      - kind: integration
        ref: "scripts/tools/verify_3d_project.gd — 3D project verified: ... gameplay scene res://scenes/intro_level.tscn."
        status: pass
      - kind: other
        ref: "grep -Fc 'type=\"StaticBody3D\"' scenes/intro_level.tscn == 6 (ground, four walls, ramp); grep -Fq FallBoundary finds nothing"
        status: pass
    human_judgment: false
  - id: D2
    description: "Camiel moves, jumps, and is followed by the camera inside intro_level.tscn itself — not only inside the Phase 1 test space — closing the coverage gap 02-VALIDATION.md named"
    requirement: "INTRO-01, INTRO-02"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_camiel_movement.gd#idle [intro_level], #forward [intro_level], #jump [intro_level], #camera_behind [intro_level]"
        status: pass
      - kind: integration
        ref: "scripts/tools/probe_camiel_movement.gd#enclosure"
        status: pass
    human_judgment: false
  - id: D3
    description: "Activating the title screen's Play control transitions to the main menu exactly once; a second activation after re-focusing changes nothing"
    requirement: "MENU-01"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#title_screen"
        status: pass
    human_judgment: false
  - id: D4
    description: "Activating the main menu's Start control begins intro_level.tscn through the same single handler shape, bound to the inherited pressed signal and nothing else"
    requirement: "MENU-02"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#main_menu"
        status: pass
    human_judgment: false
  - id: D5
    description: "application/run/main_scene is the title screen, and it instantiates as a Control"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#main_scene_is_title"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-09-12
status: complete
---

# Phase 2 Plan 3: Enclosed Intro Level and Guarded Screen Flow Summary

**One real path — title screen through the main menu into an enclosed 3D room Camiel walks and jumps inside — with both transitions proven exactly-once and the project's 3D assertion retargeted to the gameplay scene it now actually needs to check.**

## Performance

- **Duration:** ~19 min
- **Started:** 2026-09-12T18:27:47Z (immediately after 02-02)
- **Completed:** 2026-09-12T18:46:34Z
- **Tasks:** 2 completed
- **Files modified:** 13 (9 created, 4 modified)

## Accomplishments

- `scenes/intro_level.tscn`: a `Node3D`-rooted, fully enclosed 16m room — four
  `StaticBody3D` walls, one `Ramp` to jump onto, a `PlayerSpawn` marker, and a
  `res://scenes/camiel.tscn` instance — built via a throwaway generator script
  and saved through the engine's own serializer, per the established method.
- `scripts/tools/verify_3d_project.gd` retargeted for D-27: a new
  `_check_gameplay_scene_is_3d()` asserts `res://scenes/intro_level.tscn`'s
  root is a `Node3D` by name; `_check_main_scene()` keeps its load/instantiate
  checks and drops the root-type assertion, since the main scene is now the
  `Control`-rooted title screen. The success line names both the counts and
  the gameplay scene path checked.
- `scripts/tools/probe_camiel_movement.gd` parametrized: the full 12-case set
  still runs against `test_space.tscn` first, exactly as before; then the
  portable subset (`idle`, `forward`, `jump`, `camera_behind`) re-runs against
  `intro_level.tscn`, printing `PASS <case> [intro_level]`; a new `enclosure`
  case holds a direction into a wall for 120 frames and asserts Camiel stays
  inside, on the floor, with the fall-return signal never firing — proving
  D-17's enclosure claim rather than assuming it.
- `scenes/title_screen.tscn` + `scripts/title_screen.gd`: a `Control`-rooted
  boot screen with one focusable `%PlayButton` (label "Spelen", icon "play"),
  a one-shot `_transitioning` guard, and a deferred
  `change_scene_to_file` to `main_menu.tscn` — no `_input`/`_gui_input`
  override anywhere, the direct fix for the archived title screen's
  double-transition defect.
- `scenes/main_menu.tscn` + `scripts/main_menu.gd`: the same shape with
  `%StartButton` (label "Start", icon "walk") targeting `intro_level.tscn`.
  Carries its Start control only this plan — the audio panel and its sliders
  are plan 02-05's job.
- `scripts/tools/probe_screen_flow.gd` (D-29): proves MENU-01/MENU-02's
  exactly-once contract for both screens — exactly one `pressed` connection,
  the focused control fires the transition signal once, a second press after
  re-focusing changes nothing — plus a case confirming
  `application/run/main_scene` is the title screen and instantiates as a
  `Control`.
- `project.godot`: `application/run/main_scene` now points at
  `res://scenes/title_screen.tscn` — the one line the plan requires, applied
  as a direct text edit after `ProjectSettings.save()` was caught silently
  dropping an unrelated renderer setting (see Deviations).

## Task Commits

Each task was committed atomically:

1. **Task 1: An enclosed 3D room Camiel walks and jumps inside, with the project's 3D assertion retargeted to it** - `8ec1107` (feat)
2. **Task 2: Title screen to main menu to the intro level, each hop firing exactly once** - `31a3d06` (feat)

_Note: both tasks carried `tdd="true"`; RED evidence for each is recorded below rather than as a separate commit — task_commit_protocol calls for one commit per completed task, and the plan's own action text only instructs a commit at the GREEN step._

## RED Evidence

**Task 1 RED** — before `scenes/intro_level.tscn` existed, with the portable-scene loop already added to the probe:

```
PASS early_fall
PASS idle
PASS forward
PASS same_direction_keys
PASS opposite_keys
PASS jump
PASS camera_behind
PASS fall_at_edge
PASS soft_return
PASS wall
PASS turn_and_walk
PASS arguments
ERROR: Cannot open file 'res://scenes/intro_level.tscn'.
ERROR: Failed loading resource: res://scenes/intro_level.tscn.
ERROR: Could not load res://scenes/intro_level.tscn
```

The full test-space case set (unmodified) still passed; the probe failed for
the intended reason — the intro level not existing yet — not a parser error
or a broken fixture.

**Task 2 RED** — before either screen scene existed:

```
ERROR: Cannot open file 'res://scenes/title_screen.tscn'.
ERROR: Failed loading resource: res://scenes/title_screen.tscn.
ERROR: title_screen: could not load res://scenes/title_screen.tscn
```

## Final Room Dimensions and Spawn (Task 1 acceptance record)

| Property | Value |
|----------|-------|
| Floor | 16m × 1m × 16m, top face at y = 0 |
| Walls | 0.5m thick, 2.5m tall, placed at the four edges of the 16m floor (inner face ≈ ±7.75m) |
| Ramp | 3m × 0.4m × 3m at (4, 0.2, -4); top surface at y = 0.4m |
| PlayerSpawn | (0, 0, 4) |
| Camiel jump clearance over the ramp | jump_velocity 4.5, gravity 9.8 → max jump height ≈ v²/2g ≈ 1.03m, well over the ramp's 0.4m rise |
| Ambient light | `AMBIENT_SOURCE_COLOR` (engine value 2), white, energy 0.5 — matching `test_space.tscn` and `02-UI-SPEC.md`'s literal `ambient_light_source=2` |

## Files Created/Modified

- `scenes/intro_level.tscn` - enclosed Node3D room: WorldEnvironment, Sun, Ground, four walls, one ramp, PlayerSpawn, Camiel
- `scripts/tools/verify_3d_project.gd` - D-27 retarget: `_check_gameplay_scene_is_3d()`, `_check_main_scene()` root-type assertion removed
- `scripts/tools/probe_camiel_movement.gd` - parametrized over test_space.tscn (full set) and intro_level.tscn (portable subset + enclosure)
- `scenes/title_screen.tscn` / `scripts/title_screen.gd` - boot screen, one-shot guarded transition to the main menu
- `scenes/main_menu.tscn` / `scripts/main_menu.gd` - main menu, one-shot guarded transition to the intro level
- `scripts/tools/probe_screen_flow.gd` - exactly-once probe for both screens plus the main-scene assertion
- `project.godot` - `run/main_scene` retargeted to the title screen
- `scripts/tools/test_headless_check.sh` - case 3's fixture sed pattern generalized (see Deviations)

## Decisions Made

See `key-decisions` in frontmatter: the confirmed (not added) player-group
membership, the `move_back` direction choice for the enclosure case, the
`AMBIENT_SOURCE_COLOR` engine-value confirmation, and the direct text edit
for the `project.godot` retarget.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `ProjectSettings.save()` silently dropped an unrelated project.godot line**
- **Found during:** Task 2, step D (pointing the project at the title screen)
- **Issue:** Running a throwaway `zz_set_main_scene.gd` script that called
  `ProjectSettings.set_setting(...)` + `ProjectSettings.save()` rewrote the
  whole file and removed `renderer/rendering_method.web="gl_compatibility"`,
  which nothing in this plan touches. `git diff -- project.godot` caught it
  immediately (2 lines changed instead of 1), exactly the check the plan's
  own acceptance criteria required.
- **Fix:** Reverted `project.godot` with `git checkout --`, then applied the
  retarget as a single-line text `Edit` instead of going through the engine's
  save path. `git diff -- project.godot` then showed exactly the one line
  the plan names, with the inert `audio_bus_layout` section still absent.
- **Files modified:** `project.godot`
- **Verification:** `git diff -- project.godot` shows one line changed; `grep -c audio_bus_layout project.godot` is 0.
- **Committed in:** `31a3d06` (Task 2 commit)

**2. [Rule 3 - Blocking] `test_headless_check.sh` case 3's fixture stopped reproducing its planted fault after the D-28 retarget**
- **Found during:** Task 2, step F (GREEN — running `test_headless_check.sh`)
- **Issue:** Case 3 plants a runtime `SCRIPT ERROR` fixture and points
  `project.godot`'s main scene at it with a `sed` pattern hardcoded to the
  old value `res://scenes/test_space.tscn`. Once this plan retargeted
  `run/main_scene` to `res://scenes/title_screen.tscn`, the `sed` pattern no
  longer matched anything, so the fixture scene was never actually booted —
  the case passed (exit 0) instead of catching the planted error, silently
  losing coverage.
- **Fix:** Generalized the `sed` pattern to match `run/main_scene=".*"`
  regardless of its current value, so the fixture keeps working across future
  main-scene retargets too.
- **Files modified:** `scripts/tools/test_headless_check.sh`
- **Verification:** `bash scripts/tools/test_headless_check.sh` — 13/13 cases pass, including case 3 catching the planted `SCRIPT ERROR` again.
- **Committed in:** `31a3d06` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking issues directly caused by this plan's own required changes).
**Impact on plan:** Both fixes were necessary to keep the four baseline checks green; neither weakens or bypasses a check — the second fix restores a self-test's ability to catch the exact fault it exists to catch, generalized rather than special-cased to this plan's specific values.

## Issues Encountered

None beyond the two deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `scenes/title_screen.tscn`, `scenes/main_menu.tscn`, and
  `scenes/intro_level.tscn` form the complete tracer path: a child can start
  the game, reach the menu, press Start, and walk and jump around a room they
  cannot fall out of.
- Plan 02-04 can build the collectible, finish marker, and win-screen overlay
  directly inside `intro_level.tscn`; plan 02-05 can extend `main_menu.gd`'s
  existing `_ready()` wiring with the audio panel and its sliders without
  restructuring it.
- All four baseline checks (`run_headless_check.sh`, `test_headless_check.sh`,
  `quality_gate.py`, `python3 -m unittest tests.test_quality_gate
  tests.test_ci_workflows`) pass on the current tree.
- No blockers for the next plan in this phase.

## Self-Check: PASSED

- `test -f scenes/intro_level.tscn` — FOUND
- `test -f scenes/title_screen.tscn` — FOUND
- `test -f scenes/main_menu.tscn` — FOUND
- `test -f scripts/title_screen.gd` — FOUND
- `test -f scripts/main_menu.gd` — FOUND
- `test -f scripts/tools/probe_screen_flow.gd` — FOUND
- `git log --oneline --all --grep="02-03"` — FOUND (2 commits: `8ec1107`, `31a3d06`)
- All plan-level `<verification>` commands re-run clean: `run_headless_check.sh`
  (Headless check passed; all `PASS ... [intro_level]` lines, `PASS enclosure`,
  `Camiel movement probe passed.`, `PASS title_screen`, `PASS main_menu`,
  `PASS main_scene_is_title`, `Screen flow probe passed.`, and a
  `3D project verified: ... gameplay scene res://scenes/intro_level.tscn.`
  line all present), `test_headless_check.sh` (13/13 self-test cases pass,
  including the repaired case 3), `quality_gate.py` (Quality gate passed,
  exit 0), `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows`
  (14 tests, OK).

---
*Phase: 02-playable-3d-intro-experience*
*Completed: 2026-09-12*
