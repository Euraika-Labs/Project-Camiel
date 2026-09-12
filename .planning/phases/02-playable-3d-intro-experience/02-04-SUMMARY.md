---
phase: 02-playable-3d-intro-experience
plan: 04
subsystem: gameplay
tags: [godot, node3d, area3d, canvaslayer, headless-probe, signals, audio]

requires:
  - phase: 02-playable-3d-intro-experience (plan 03)
    provides: scenes/intro_level.tscn (the enclosed Node3D room, Camiel, PlayerSpawn), scenes/ui/menu_button.tscn, assets/theme/ui_theme.tres, scripts/tools/probe_screen_flow.gd's case-runner/helper shape
provides:
  - "scenes/finish_marker.tscn + scripts/finish_marker.gd — an Area3D goal that emits `finished` exactly once via a one-shot latch plus a player-group guard, with reset() for replay (D-20)"
  - "scenes/collectible.tscn + scripts/collectible.gd — the intro level's one floating, spinning, bobbing collectible; emits `collected` exactly once and plays no sound of its own (D-18, D-19, INTRO-03)"
  - "scripts/intro_level.gd — the sole listener for both area signals, the win-overlay controller, the single caller of AudioManager.play_sfx in the runtime tree, and the in-place replay reset (D-28)"
  - "scenes/intro_level.tscn's %WinLayer overlay — Scrim/CenterContainer/WinPanel/WinContent with the exact Dutch strings \"Goed zo!\", \"Nog een keer\", \"Naar menu\", each win button carrying an icon (INTRO-05)"
  - "scripts/tools/probe_screen_flow.gd — three new cases (finish_marker, collectible, win_buttons) proving the exactly-once signal contracts, the non-player-body edge, the single-listener SFX guarantee, and a full replay-then-second-lap cycle"
affects: [phase-3-lessons, d-30-manual-playtest]

actuals:
  tokens: 8060
  tasks: 3
  commits: 3
plan_head_before: f3b8d43

tech-stack:
  added: []
  patterns:
    - "One-shot Area3D trigger: a private _touched latch plus is_in_group(\"player\") guard, connected to body_entered in the script's own _ready() (never in the .tscn's [connection] block), with a reset() that clears the latch for in-place replay"
    - "Area3D forbids toggling `monitoring` synchronously from inside its own body-entered callback (\"Function blocked during in/out signal\") — the whole pickup reaction (monitoring off, feedback, the signal) is deferred together as one call_deferred step"
    - "CanvasLayer has no `modulate` property; the Motion table's fade-in target is the layer's child Control (%Scrim) instead"
    - "A signal exists purely for headless observability (replay_requested), with no deferred engine call to shadow, so a probe can count \"the handler ran\" from outside exactly like the two flat screens' transition_requested signals"

key-files:
  created:
    - scenes/finish_marker.tscn
    - scripts/finish_marker.gd
    - scenes/collectible.tscn
    - scripts/collectible.gd
  modified:
    - scenes/intro_level.tscn
    - scripts/intro_level.gd
    - scripts/tools/probe_screen_flow.gd

key-decisions:
  - "The fade-in target for the win overlay is %WinLayer/Scrim (a Control), not %WinLayer itself — CanvasLayer has no modulate property in Godot 4.7.2, discovered by property-list inspection before writing the generator, not assumed from the UI-SPEC's literal wording"
  - "Collectible pickup defers monitoring=false, the pulse/fade tween, and the collected signal together into one call_deferred callback, because Area3D raises a hard engine error (\"Function blocked during in/out signal\") when monitoring is toggled synchronously inside its own body-entered handler — this is a new engine fact this plan's research did not anticipate"
  - "probe_screen_flow.gd's collectible case drains the finish_marker case's own SFX playback (via a bounded wait-until-idle) before asserting a clean baseline, since both cases share the one AudioManager autoload instance across the whole probe run and Task 2 wires the finish handler to play a real sound for the first time"
  - "Finish marker and collectible were placed away from the ramp and from each other (finish at (-5,0,-6), collectible at (-2.5,0.8,-1), spawn at (0,0,4)) so a straight walk from spawn meets the collectible on the way to the finish, per Claude's Discretion on exact intro-level geometry"

patterns-established:
  - "A pickup/goal Area3D's full reaction is deferred as a single call_deferred callback when the reaction includes toggling monitoring, since Godot forbids that specific mutation synchronously inside the triggering signal's own callback"

requirements-completed: [INTRO-03, INTRO-04, INTRO-05]

coverage:
  - id: D1
    description: "Reaching the finish marker fires `finished` exactly once through a single signal-driven path (no cross-script method call), fades the win overlay in, and freezes Camiel's own physics instead of pausing the tree"
    requirement: "INTRO-04"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#finish_marker"
        status: pass
      - kind: other
        ref: "grep -Fq 'signal finished' + 'finished.emit()' scripts/finish_marker.gd; zero get_first_node_in_group/call_group hits"
        status: pass
    human_judgment: false
  - id: D2
    description: "A non-player body (the ground shares the default collision layer) entering the finish marker's area triggers nothing"
    requirement: "INTRO-04"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#finish_marker (StaticBody3D intrusion case)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The intro level holds exactly one collectible; its pickup latches once, plays the collect sound exactly once, and no script other than intro_level.gd calls AudioManager.play_sfx"
    requirement: "INTRO-03"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#collectible"
        status: pass
      - kind: other
        ref: "grep -REl 'AudioManager\\.play_sfx\\(' scripts --include='*.gd' outside scripts/tools/ and scripts/intro_level.gd returns empty"
        status: pass
    human_judgment: false
  - id: D4
    description: "The win screen shows exactly two Dutch, icon-carrying buttons (\"Nog een keer\", \"Naar menu\"), each activated only through the inherited pressed signal; the return-to-menu button carries the same one-shot guard as the two flat screens"
    requirement: "INTRO-05"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#finish_marker (return-to-menu one-shot assertions), #win_buttons"
        status: pass
    human_judgment: false
  - id: D5
    description: "Nog een keer resets the level in place (no scene change/reload): hides the overlay, restores Camiel to PlayerSpawn with zero velocity, resumes his physics, and re-arms both the collectible and the finish marker so a second lap reaches the win screen again"
    requirement: "INTRO-05"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_screen_flow.gd#win_buttons"
        status: pass
    human_judgment: false
  - id: D6
    description: "The finish marker is not gated on the collectible — free play, reachable either way"
    verification:
      - kind: other
        ref: "scripts/tools/probe_screen_flow.gd#finish_marker never touches %Collectible; #collectible never touches %FinishMarker; both pass independently"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-09-12
status: complete
---

# Phase 2 Plan 4: Finish Marker, One Collectible, and Win Overlay Summary

**A finish-marker Area3D and a collectible Area3D, each proven to emit exactly once, feeding a single-listener intro_level.gd that owns the win overlay's Dutch buttons and an in-place "Nog een keer" replay — closing the loop a child plays.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-12T18:50:00Z (approx.)
- **Completed:** 2026-09-12T19:10:29Z
- **Tasks:** 3 completed
- **Files modified:** 10 (4 created, 3 modified across three commits; 3 `.uid` sidecars auto-generated)

## Accomplishments

- `scenes/finish_marker.tscn` + `scripts/finish_marker.gd`: a standing sage-green
  `TorusMesh` goal ring over a cylinder `Area3D` trigger. `signal finished` is
  declared and genuinely emitted (the archived marker declared it but never
  emitted it, reaching into another script's method instead — the exact defect
  INTRO-04 exists to prevent). A one-shot `_touched` latch plus
  `is_in_group("player")` guard makes the ground and walls (which share the
  default collision layer) inert, and `reset()` re-arms it for replay.
- `scenes/collectible.tscn` + `scripts/collectible.gd`: a warm-orange, slowly
  spinning, gently bobbing `SphereMesh` with its own `Area3D` trigger.
  `intro_level.tscn` holds exactly one instance (D-19). The pickup reaction
  (`monitoring = false`, a 1.15× scale pulse then a fade, and the `collected`
  signal) is deferred as a single `call_deferred` step, because Area3D raises
  a hard engine error when `monitoring` is toggled synchronously from inside
  its own `body_entered` callback — a new engine fact this plan discovered.
  The collectible never plays a sound itself.
- `scripts/intro_level.gd`: the sole listener for both signals.
  `_on_collectible_collected()` and `_on_finish_marker_finished()` are the
  only two call sites of `AudioManager.play_sfx` in the entire runtime tree —
  structurally closing the "collect sound plays twice or not at all" defect
  rather than merely avoiding it by convention. The finish handler fades
  `%WinLayer/Scrim` in over 0.3s (CanvasLayer itself has no `modulate`
  property — discovered by inspecting the engine, not assumed), grabs focus
  on `%ReplayButton`, and freezes Camiel's own physics instead of pausing the
  scene tree. `_on_replay_button_pressed()` hides the overlay, resumes
  Camiel's physics, calls the existing `teleport_to(PlayerSpawn)` (already
  zeroing velocity and snapping the camera), and calls `reset()` on both the
  collectible and the finish marker — no scene change, no scene reload, no
  one-shot guard (replay is repeatable by design).
- `scenes/intro_level.tscn`: gains `%FinishMarker`, `%Collectible`, and the
  `%WinLayer` overlay subtree (`Scrim` → `ColorRect` + `CenterContainer` →
  `WinPanel` → `WinContent` → `WinTitle` ("Goed zo!") + `ButtonRow` holding
  `%ReplayButton` ("Nog een keer", icon "replay") and `%GoToMenuButton`
  ("Naar menu", icon "home"), each an instance of `scenes/ui/menu_button.tscn`.
  The two buttons' focus order is wired explicitly
  (`focus_neighbor_right`/`focus_neighbor_left`) rather than left to spatial
  inference.
- `scripts/tools/probe_screen_flow.gd`: three new cases — `finish_marker`,
  `collectible`, `win_buttons` — each following RED-first TDD, each proving
  the exactly-once contract, the non-player-body edge, and (for
  `win_buttons`) a full replay-then-second-lap cycle with both buttons'
  activation counts proved independently.

## Task Commits

Each task was committed atomically:

1. **Task 1: Reaching the finish emits a signal, the level listens, and the win overlay appears with both buttons** - `413f051` (feat)
2. **Task 2: One collectible, one latch, one listener, one sound** - `445275e` (feat)
3. **Task 3: Nog een keer restarts the level in place, and both win buttons are proved one-shot** - `1e1c311` (feat)

_All three tasks carried `tdd="true"`; RED evidence for each is recorded below rather than as a separate commit, matching this plan's own action text (a commit only at the GREEN step)._

## RED Evidence

**Task 1 RED** — `probe_screen_flow.gd`'s `finish_marker` case added before `finish_marker.tscn`/`intro_level.gd` existed:

```
PASS title_screen
PASS main_menu
PASS main_scene_is_title
ERROR: Node not found: "%FinishMarker" (relative to "/root/IntroLevel").
ERROR: Node not found: "%WinLayer" (relative to "/root/IntroLevel").
ERROR: Node not found: "%ReplayButton" (relative to "/root/IntroLevel").
ERROR: Node not found: "%GoToMenuButton" (relative to "/root/IntroLevel").
SCRIPT ERROR: Invalid access to property or key 'finished' on a base object of type 'null instance'.
```

**Task 2 RED** — `collectible` case added before `collectible.tscn`/the `%Collectible` wiring existed:

```
PASS finish_marker
ERROR: Node not found: "%Collectible" (relative to "/root/IntroLevel").
ERROR: collectible: intro_level.tscn contains 0 collectible instances, expected exactly 1 (D-19)
```

(A second, later RED surfaced after the scene wiring landed: Area3D refused a
synchronous `monitoring = false` inside its own `body_entered` callback —
`ERROR: Function blocked during in/out signal. Use set_deferred("monitoring", true/false).`
— see Deviations.)

**Task 3 RED** — `win_buttons` case added before the explicit focus-neighbor wiring existed:

```
PASS collectible
ERROR: win_buttons: %ReplayButton.focus_neighbor_right is not set
```

## Files Created/Modified

- `scenes/finish_marker.tscn` / `scripts/finish_marker.gd` - one-shot Area3D goal, `finished` signal, `reset()`
- `scenes/collectible.tscn` / `scripts/collectible.gd` - one-shot Area3D pickup, `collected` signal, spin/bob, `reset()`
- `scenes/intro_level.tscn` - `%FinishMarker`, `%Collectible`, `%WinLayer` overlay, explicit win-button focus order
- `scripts/intro_level.gd` - sole signal listener, win-overlay controller, sole `AudioManager.play_sfx` caller, in-place replay reset
- `scripts/tools/probe_screen_flow.gd` - `finish_marker`, `collectible`, `win_buttons` cases

## Decisions Made

See `key-decisions` in frontmatter: the `%Scrim` fade target (CanvasLayer has
no `modulate`), the deferred pickup reaction (Area3D's synchronous-toggle
restriction), the probe's cross-case SFX drain, and the collectible/finish
placement geometry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CanvasLayer has no `modulate` property; the UI-SPEC's fade target had to move to a child Control**
- **Found during:** Task 1, step D (writing `_on_finish_marker_finished()`'s fade-in)
- **Issue:** The UI-SPEC and plan both describe tweening `%WinLayer`'s `modulate.a` from 0 to 1. `CanvasLayer` in Godot 4.7.2 has no `modulate` property at all (confirmed by a property-list inspection before writing any code) — only its Control descendants do.
- **Fix:** The tween targets `%WinLayer/Scrim` (marked `unique_name_in_owner` as `%Scrim`) instead, fading the whole visible overlay subtree exactly as the Motion table intends, just one node lower in the tree.
- **Files modified:** `scripts/tools/zz_extend_intro_level_task1.gd` (throwaway generator, deleted before commit), `scenes/intro_level.tscn`, `scripts/intro_level.gd`
- **Verification:** `run_headless_check.sh` passes with no `ERROR:`/`SCRIPT ERROR:` lines from the tween call.
- **Committed in:** `413f051` (Task 1 commit)

**2. [Rule 1 - Bug] Area3D forbids toggling `monitoring` synchronously inside its own `body_entered` callback**
- **Found during:** Task 2, step F (GREEN — running the collectible case)
- **Issue:** `_on_body_entered` set `monitoring = false` directly, which raised `ERROR: Function blocked during in/out signal. Use set_deferred("monitoring", true/false).` — a genuine engine restriction neither `02-RESEARCH.md` nor the plan's Task 2 pseudocode anticipated. A first fix attempt (`set_deferred("monitoring", false)` alone, keeping `_play_pickup_feedback()` and `collected.emit()` synchronous) cleared the engine error but left a second, subtler bug: the probe's `%Collectible.monitoring` assertion — checked in the same frame `collected` fired — still read `true`, because the deferred call had not yet flushed relative to that check.
- **Fix:** The whole pickup reaction — `monitoring = false`, the pulse/fade tween, and `collected.emit()` — moved into one `_apply_pickup()` method invoked via `call_deferred()` from `_on_body_entered`, so all three effects land together atomically in the same deferred step, with no ordering race between them.
- **Files modified:** `scripts/collectible.gd`
- **Verification:** `run_headless_check.sh`'s `probe_screen_flow.gd` step shows `PASS collectible` with no `ERROR:` lines; `grep -Fq 'monitoring = false' scripts/collectible.gd` still holds true (the literal assignment lives inside `_apply_pickup()`, satisfying both the engine's constraint and the plan's acceptance criterion).
- **Committed in:** `445275e` (Task 2 commit)

**3. [Rule 3 - Blocking] The finish_marker probe case's own SFX playback polluted the collectible case's "no effect playing" baseline**
- **Found during:** Task 2, step F (GREEN — running the full probe sequence)
- **Issue:** Task 2 wired `_on_finish_marker_finished()` to also call `AudioManager.play_sfx("finish")`. Since `probe_screen_flow.gd` runs all cases in one process against the one `AudioManager` autoload singleton, and the `finish_marker` case (which now triggers that sound) runs immediately before the `collectible` case, the collectible case's initial "no effect playing" assertion intermittently found the finish sound's player still reporting `playing == true`.
- **Fix:** Before that assertion, the collectible case now waits (bounded, real-time, 2000ms) for `AudioManager.is_sfx_playing()` to become `false`, using the same `_wait_until` polling pattern `probe_audio_buses.gd` already established, rather than asserting an unqualified same-instant baseline.
- **Files modified:** `scripts/tools/probe_screen_flow.gd`
- **Verification:** `probe_screen_flow.gd` passes reliably across repeated runs with `finish_marker` immediately preceding `collectible` in the case order.
- **Committed in:** `445275e` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 — bugs surfaced by genuine engine behavior neither the plan nor its research anticipated; 1 Rule 3 — a blocking test-ordering issue caused directly by this plan's own required change).
**Impact on plan:** All three fixes were necessary for correctness and for the headless check to pass without weakening any assertion. No scope creep — none added new user-facing behavior beyond what the plan specified.

## Issues Encountered

None beyond the three deviations above, both discovered and resolved within their originating task's GREEN step.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The full title screen → main menu → intro level loop is now complete and
  playable end to end: move, jump, collect, reach the finish, see the win
  screen, replay in place or return to the menu.
- All four baseline checks (`run_headless_check.sh`, `test_headless_check.sh`,
  `quality_gate.py`, `python3 -m unittest tests.test_quality_gate
  tests.test_ci_workflows`) pass on the current tree.
- INTRO-03, INTRO-04, and INTRO-05 are closed. D-30's one short human
  playtest (title → menu → play → collect → finish → replay → menu) remains
  the only manual-only verification for this phase, per `02-RESEARCH.md`.
- No blockers for plan 02-05 or for phase close.

## Self-Check: PASSED

- `test -f scenes/finish_marker.tscn` — FOUND
- `test -f scripts/finish_marker.gd` — FOUND
- `test -f scenes/collectible.tscn` — FOUND
- `test -f scripts/collectible.gd` — FOUND
- `test -f scripts/intro_level.gd` — FOUND
- `test -f scripts/tools/probe_screen_flow.gd` — FOUND
- `git log --oneline --all --grep="02-04"` — FOUND (3 matches: `413f051`,
  `445275e`, `1e1c311`)
- All plan-level `<verification>` commands re-run clean:
  `run_headless_check.sh` (`Headless check passed.`, and running
  `probe_screen_flow.gd` directly shows `PASS finish_marker`,
  `PASS collectible`, `PASS win_buttons`, `Screen flow probe passed.`),
  `test_headless_check.sh` (13/13 self-test cases pass), `quality_gate.py`
  (`Quality gate passed.`, exit 0), `python3 -m unittest
  tests.test_quality_gate tests.test_ci_workflows` (14 tests, OK), and the
  repository-wide check that no script outside `scripts/intro_level.gd`
  calls `AudioManager.play_sfx(` (empty result).

---
*Phase: 02-playable-3d-intro-experience*
*Completed: 2026-09-12*
