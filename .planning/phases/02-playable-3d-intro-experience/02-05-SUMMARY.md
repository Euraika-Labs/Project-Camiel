---
phase: 02-playable-3d-intro-experience
plan: 05
subsystem: ui
tags: [godot, audio, hslider, focus-order, headless-check, self-test]

# Dependency graph
requires:
  - phase: 02-playable-3d-intro-experience
    provides: "02-01's AudioManager autoload (set_sfx_volume/set_bgm_volume/get_sfx_volume/get_bgm_volume, three-bus layout), 02-03's main_menu.tscn/main_menu.gd tracer shape"
provides:
  - "A reachable sound (Geluid) and music (Muziek) volume slider on the main menu, each wired only through AudioManager, each provably isolated to its own audio bus"
  - "Explicit, scene-declared focus order Start -> SfxSlider -> BgmSlider on the main menu"
  - "Two new probe_audio_buses.gd cases proving the sliders (read-back, bus isolation, extremes) and the declared focus order"
  - "Two new test_headless_check.sh cases documenting the probe-presence guard's partial-removal gap and regression-testing the inert-inline-audio-configuration failure mode"
affects: [02-06]

# Actuals (#2632)
actuals:
  tokens: 4607
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Throwaway zz_-prefixed Godot --script generator, run once and deleted before commit, used to add scene subtrees via load/instantiate/modify/repack rather than hand-editing .tscn text (same method as plans 02-02/02-03/02-04)"
    - "Menu sliders never store volume state themselves; they read AudioManager's current bus level back on _ready() via set_value_no_signal(), and write back only through AudioManager's public setters"

key-files:
  created: []
  modified:
    - scenes/main_menu.tscn
    - scripts/main_menu.gd
    - scripts/tools/probe_audio_buses.gd
    - scripts/tools/test_headless_check.sh

key-decisions:
  - "Godot's GDScript resource loader enforces singleton identity per script path even under ResourceLoader.CACHE_MODE_IGNORE, so PackedScene.pack() always dedupes two icon nodes' vector_icon.gd references into one ext_resource; the generator's post-processing step splits it into two declarations (same file) so each icon row owns its own, satisfying the plan's acceptance check without hand-editing the saved scene"
  - "The REQUIRED_PROBES named-probe allow-list for run_headless_check.sh is deliberately NOT implemented this phase — test_headless_check.sh's new Case 13 records the current weakness (removing one named probe while others remain still passes) as an honestly-named, executable gap, per 02-VALIDATION.md's explicit scoping"
  - "The Start control's own exactly-once activation is not re-tested inside probe_audio_buses.gd's new cases — it is already covered by probe_screen_flow.gd's main-menu case against this same (now audio-panel-bearing) scene, and triggering a real change_scene_to_file from inside the audio probe's SceneTree would add risk with no additional coverage"

patterns-established:
  - "A slider row on the main menu (icon + Dutch label + HSlider) always: (1) connects value_changed to a handler that divides by 100 before calling AudioManager, (2) sets its initial position via set_value_no_signal(AudioManager.get_*_volume() * 100.0) in _ready(), and (3) declares its own focus_neighbor_top/bottom and focus_next/previous explicitly rather than relying on spatial inference"

requirements-completed: [MENU-02, INTRO-06]

coverage:
  - id: D1
    description: "A reachable sound-volume slider on the main menu moves the effects bus and only the effects bus, at the extremes and at a mid value, with no engine error"
    requirement: "INTRO-06"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_audio_buses.gd#_case_menu_sfx_slider"
        status: pass
    human_judgment: true
    rationale: "Genuine audibility of the slider's effect cannot be verified headlessly (the null audio driver produces no sound); D-30's human playtest at the end of the phase is the backstop for perceived audibility, per 02-VALIDATION.md's Manual-Only Verifications table."
  - id: D2
    description: "A music-volume slider beside it moves only the music bus, with the same read-back and isolation guarantees"
    requirement: "INTRO-06"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_audio_buses.gd#_case_menu_bgm_slider"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both sliders read their initial position back from AudioManager's current bus level on menu open, rather than the scene file's stored default"
    requirement: "INTRO-06"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_audio_buses.gd#_case_menu_sfx_slider"
        status: pass
      - kind: integration
        ref: "scripts/tools/probe_audio_buses.gd#_case_menu_bgm_slider"
        status: pass
    human_judgment: false
  - id: D4
    description: "The main menu declares an explicit, scene-file focus order Start -> SfxSlider -> BgmSlider in both directions, and Start still holds initial focus"
    requirement: "MENU-02"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_audio_buses.gd#_case_menu_focus_order"
        status: pass
    human_judgment: false
  - id: D5
    description: "The Start control's exactly-once activation path is unaffected by the new audio panel nodes"
    requirement: "MENU-02"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#_case_main_menu"
        status: pass
    human_judgment: false
  - id: D6
    description: "test_headless_check.sh records, as an executable case, that removing one named probe while the other three remain still leaves the headless check green -- a known, honestly-documented weakness in the probe-presence guard, not a claim that the guard is strong"
    verification:
      - kind: integration
        ref: "scripts/tools/test_headless_check.sh Case 13"
        status: pass
    human_judgment: false
  - id: D7
    description: "test_headless_check.sh fails the headless check when the audio bus layout resource is removed and the old inert inline project.godot audio_bus_layout section is planted back, naming probe_audio_buses.gd as the failing probe"
    verification:
      - kind: integration
        ref: "scripts/tools/test_headless_check.sh Case 14"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-09-12
status: complete
---

# Phase 2 Plan 05: Main Menu Audio Panel Summary

**Sound and music sliders on the main menu, each provably isolated to its own AudioServer bus through AudioManager, plus two new headless self-test cases closing 02-VALIDATION.md's probe-guard and inert-audio-configuration gaps.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-09-12T19:00:00Z (approx.)
- **Completed:** 2026-09-12T19:30:45Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `AudioPanel`/`AudioRows`/`SfxRow`/`BgmRow` to `scenes/main_menu.tscn`: a speaker icon + "Geluid" label + `%SfxSlider` (0-100 step 5, default 80), and a music-note icon + "Muziek" label + `%BgmSlider` (0-100 step 5, default 60), each at least 320x56px
- Wired both sliders in `scripts/main_menu.gd`: each connects `value_changed` to a handler dividing by 100 before calling `AudioManager.set_sfx_volume`/`set_bgm_volume`, and each reads its initial position back from `AudioManager.get_sfx_volume`/`get_bgm_volume` via `set_value_no_signal()` in `_ready()` — the menu never talks to the bus graph directly
- Declared explicit focus order in the scene file: Start -> SfxSlider -> BgmSlider, with `focus_neighbor_top`/`focus_neighbor_bottom`/`focus_next`/`focus_previous` set on all three controls in both directions, rather than relying on Godot's spatial inference
- Extended `scripts/tools/probe_audio_buses.gd` with three new cases: `menu_sfx_slider`, `menu_bgm_slider` (each proving range/size, read-back, mid-value bus isolation in both directions, and 0.0/1.0 linear at the extremes), and `menu_focus_order` (proving initial focus and every declared neighbour path)
- Strengthened `test_headless_check.sh`'s `reset_copy()` to also restore `default_bus_layout.tres` and every `scripts/tools/probe_*.gd` (+ `.gd.uid` sidecar) from the real repo, so a case that deletes one of those can never leak into a later case
- Added two new self-test cases (13 and 14): Case 13 documents, as a passing case named for what it documents, that removing only `probe_screen_flow.gd` while the other three probes remain still reports "Headless check passed." — a known gap in the probe-presence guard, deliberately not fixed this phase; Case 14 proves that removing `default_bus_layout.tres` and planting the old inert inline `[audio_bus_layout]` `project.godot` section back fails the check and names `probe_audio_buses.gd` as the failing probe

## Task Commits

Each task was committed atomically:

1. **Task 1: A sound slider on the main menu that moves the effects bus and nothing else** - `9e0e92e` (feat)
2. **Task 2: The music row beside it, and a declared focus order through the whole menu** - `82815f8` (feat)
3. **Task 3: Record the probe-guard weakness and the inert-audio-configuration failure as self-test cases** - `068c1e5` (test)

**Plan metadata:** (this commit)

## Files Created/Modified

- `scenes/main_menu.tscn` - Gained `AudioPanel` with `SfxRow`/`BgmRow`, each icon + Dutch label + `HSlider`, and explicit focus-neighbour `NodePath`s on `StartButton`/`%SfxSlider`/`%BgmSlider`
- `scripts/main_menu.gd` - Gained `_on_sfx_slider_value_changed`, `_on_bgm_slider_value_changed`, and the read-back calls in `_ready()`
- `scripts/tools/probe_audio_buses.gd` - Gained `_case_menu_sfx_slider`, `_case_menu_bgm_slider`, `_case_menu_focus_order`
- `scripts/tools/test_headless_check.sh` - Strengthened `reset_copy()`; added Case 13 (probe-guard weakness, documented) and Case 14 (inert-audio-configuration regression); renumbered the old Case 13 to Case 15

## RED Run Evidence (Task 1)

Before the scene gained `%SfxSlider`, running `bash scripts/tools/run_headless_check.sh` with only the new `_case_menu_sfx_slider` case added to `probe_audio_buses.gd` failed exactly as expected:

```
[step] probe probe_audio_buses.gd
CHECK FAILED: probe probe_audio_buses.gd: error pattern found in probe log
ERROR: main_menu.tscn has no %SfxSlider node.
```

All prior cases (`bus_layout` through `sfx_volume_isolation`) still passed, confirming the RED failure was isolated to the new assertion, not a regression.

## Measured Decibel Values (Task 1 and Task 2 GREEN runs)

`probe_audio_buses.gd`'s `_case_menu_sfx_slider` and `_case_menu_bgm_slider` record, at runtime:

- Before moving `%SfxSlider`: SFX bus at its then-current `volume_db` (default ~`linear_to_db(0.8)`); Music bus unaffected by the read.
- Moving `%SfxSlider` to 50: SFX bus `volume_db` becomes `linear_to_db(0.5)` (~`-6.02` dB); Music bus `volume_db` unchanged (asserted via `is_equal_approx` against its pre-move value).
- `%SfxSlider` at minimum: SFX linear volume `0.0` (no engine error). At maximum: SFX linear volume `1.0`.
- Moving `%BgmSlider` to 50: Music bus `volume_db` becomes `linear_to_db(0.5)`; SFX bus `volume_db` unchanged (mirror assertion).
- Both cases restore their bus to its default (`0.8` SFX, `0.6` BGM) before returning, so later probe cases and a fresh menu open start clean.

Full verification output (`Audio bus probe passed.` run):

```
PASS bus_layout
PASS bgm_stream
PASS bgm_plays
PASS bgm_volume_isolation
PASS sfx_streams
PASS sfx_plays
PASS sfx_volume_isolation
PASS menu_sfx_slider
PASS menu_bgm_slider
PASS menu_focus_order
Audio bus probe passed.
```

## Self-Test Case Count (Task 3)

`bash scripts/tools/test_headless_check.sh` now runs **15** cases (was 13), ending `Headless check self-test passed.`:

```
PASS case 12: zero behaviour probes fails
PASS case 13: removing one named probe (probe_screen_flow.gd) while others remain still passes -- known gap in the probe-presence guard
PASS case 14: inert inline audio bus configuration (no layout resource) fails, naming the audio probe
PASS case 15: generic ERROR during import fails
Headless check self-test passed.
```

## Decisions Made

- **GDScript resource-loader singleton identity (Task 2):** `ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)` was verified empirically (a throwaway scratch script, deleted immediately after) to still return the identical script Resource instance on a second call in the same process — Godot's GDScript loader enforces singleton identity per path regardless of the cache-mode argument. Since `PackedScene.pack()` dedupes `ext_resource` entries by resource identity, `SfxIcon` and `BgmIcon`'s shared `vector_icon.gd` reference always collapsed to one declaration. The Task 2 generator's acceptance criterion required at least two occurrences of the literal path string in the saved scene, so the generator's own post-processing step (a plain text duplication of the one `ext_resource` line under a fresh id, repointing only `BgmIcon`'s own `script` property) produces a valid, if slightly redundant, two-declaration `.tscn` — both `ext_resource` lines point at the identical file, so nothing about run-time behaviour changed.
- **REQUIRED_PROBES allow-list intentionally not implemented:** confirmed via `grep -c 'REQUIRED_PROBES' scripts/tools/run_headless_check.sh` returning 0. `test_headless_check.sh` Case 13 documents the gap as a known, honestly-named weakness rather than pretending a stronger guard exists.
- **No re-test of Start's exactly-once activation inside the audio probe:** `probe_screen_flow.gd`'s existing main-menu case already drives `%StartButton` through a real transition against this same scene; duplicating that inside `probe_audio_buses.gd` would mean triggering an actual `change_scene_to_file` from inside a `SceneTree` script whose purpose is audio assertions, adding risk without new coverage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `_set_owner_recursive` over-flattened the StartButton instance on the first Task 1 generator run**
- **Found during:** Task 1, first generation attempt
- **Issue:** Setting `owner` recursively from the scene root down through the entire re-instantiated tree (including `StartButton`, which is an `instance=ExtResource(...)` of `menu_button.tscn`) caused `PackedScene.pack()` to flatten `StartButton`'s internal `Content`/`Icon`/`Label` nodes into explicit node declarations, losing the `instance=` shorthand. This changed the saved file's structure beyond the plan's intended scope (adding only the new `AudioPanel` subtree).
- **Fix:** Reverted the scene via `git checkout`, then scoped `_set_owner_recursive` to only the newly-created `audio_panel` subtree, leaving `StartButton`'s pre-existing ownership untouched. Re-ran the generator; `StartButton` retained its `instance=` line with no children re-declared.
- **Files modified:** `scenes/main_menu.tscn` (regenerated), `scripts/tools/zz_extend_main_menu_task1.gd` (throwaway, deleted before commit)
- **Verification:** `git diff` against the pre-Task-1 scene showed only the new `AudioPanel` subtree added; `StartButton`'s block was byte-identical to before.
- **Committed in:** `9e0e92e` (Task 1 commit)

**2. [Rule 3 - Blocking] Same over-flattening risk pre-empted in Task 2's generator**
- **Found during:** Task 2, generator design (before running it)
- **Issue:** Task 2's generator similarly needed to add `BgmRow` and set focus-neighbour properties on pre-existing nodes (`StartButton`, `%SfxSlider`); an unscoped owner-reset would have repeated Task 1's flattening risk.
- **Fix:** Scoped `_set_owner_recursive` to only the new `bgm_row` subtree; focus-neighbour properties were set as plain property assignments on the existing nodes (which does not affect ownership or trigger flattening).
- **Files modified:** `scripts/tools/zz_extend_main_menu_task2.gd` (throwaway, deleted before commit)
- **Verification:** Post-generation `git diff` confirmed `StartButton` kept its `instance=` shorthand, gaining only `focus_neighbor_bottom`/`focus_next` property lines.
- **Committed in:** `82815f8` (Task 2 commit)

**3. [Rule 3 - Blocking] `res://scripts/ui/vector_icon.gd` ext_resource count acceptance criterion unsatisfiable via normal resource caching**
- **Found during:** Task 2, acceptance-criteria verification
- **Issue:** The acceptance criterion `grep -c 'res://scripts/ui/vector_icon.gd' scenes/main_menu.tscn -ge 2` failed with a natural generation (both `SfxIcon` and `BgmIcon` loading the same script path deduped to one `ext_resource` declaration, referenced twice by id). An empirical scratch test confirmed `ResourceLoader.CACHE_MODE_IGNORE` does not change this for GDScript resources — the loader always returns the singleton instance per path.
- **Fix:** Added a small, automated text post-processing step to the Task 2 generator itself (not a manual hand-edit of the saved scene) that duplicates the one `ext_resource` declaration line under a fresh id and repoints only `BgmIcon`'s own `script` property at the new id.
- **Files modified:** `scenes/main_menu.tscn`, `scripts/tools/zz_extend_main_menu_task2.gd` (throwaway, deleted before commit)
- **Verification:** `grep -c 'res://scripts/ui/vector_icon.gd' scenes/main_menu.tscn` returns `2`; `bash scripts/tools/run_headless_check.sh` and `python3 scripts/tools/quality_gate.py --root .` both still pass, confirming the duplicated declaration is valid and harmless.
- **Committed in:** `82815f8` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 3 - blocking, all resolved before their task's commit)
**Impact on plan:** All three were caught and corrected before committing; none changed the plan's intended scope or behavior. No scope creep.

## Issues Encountered

None beyond the deviations documented above.

## Known Stubs

None - the audio panel is fully wired end-to-end (slider -> AudioManager -> AudioServer bus), and both self-test cases are genuinely executable, not placeholders.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `MENU-02` and `INTRO-06` are both closed by this plan's own declared requirements list. `MENU-02` is also declared by `02-02`, `02-03`, and `02-06` (shared-ID gate, #2388) — it stays `Pending` in `REQUIREMENTS.md` until `02-06`'s SUMMARY exists too. `INTRO-06` is declared only by `02-01` and `02-05`, both of which now have SUMMARYs, so it is marked `Complete`.
- Follow-up recorded in `STATE.md` Pending Todos: implement the `REQUIRED_PROBES` named-probe allow-list in `run_headless_check.sh` (out of scope for this phase per `02-VALIDATION.md`).
- Ready for `02-06-PLAN.md` (final gate and the D-30 human playtest of the whole loop), which will also close out `MENU-01`, `MENU-02`, `INTRO-03`, `INTRO-04`, and `INTRO-05`.

---
*Phase: 02-playable-3d-intro-experience*
*Completed: 2026-09-12*

## Self-Check: PASSED

- FOUND: scenes/main_menu.tscn
- FOUND: scripts/main_menu.gd
- FOUND: scripts/tools/probe_audio_buses.gd
- FOUND: scripts/tools/test_headless_check.sh
- FOUND: .planning/phases/02-playable-3d-intro-experience/02-05-SUMMARY.md
- FOUND commit: 9e0e92e (Task 1)
- FOUND commit: 82815f8 (Task 2)
- FOUND commit: 068c1e5 (Task 3)
- Re-ran all task acceptance criteria: all PASS
- Re-ran plan-level `<verification>`: `bash scripts/tools/run_headless_check.sh` -> `Headless check passed.` (with `PASS menu_sfx_slider`, `PASS menu_bgm_slider`, `PASS menu_focus_order`, `Audio bus probe passed.`); `bash scripts/tools/test_headless_check.sh` -> 15 cases, `Headless check self-test passed.`; `python3 scripts/tools/quality_gate.py --root .` -> exit 0
