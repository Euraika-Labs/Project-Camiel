---
phase: 01-3d-foundation-archive
plan: 04
subsystem: gameplay
tags: [godot, gdscript, characterbody3d, springarm3d, camera-relative, headless-probe]

# Dependency graph
requires:
  - phase: 01-3d-foundation-archive
    provides: "01-03's engine-written project.godot (gl_compatibility, Jolt Physics, res://scenes/test_space.tscn main scene) and scripts/tools/run_headless_check.sh, which discovers and runs scripts/tools/probe_*.gd as its final gate"
provides:
  - "Five InputMap actions (move_forward, move_back, move_left, move_right, jump) written via the engine's own serializer, each bound by physical keycode (D-07)"
  - "scenes/camiel.tscn: a primitive-shape Camiel (CharacterBody3D, CapsuleShape3D collision, capsule body, nose sphere marker, CameraPivot/SpringArm3D/Camera3D rig, ReturnSound)"
  - "scripts/camiel_controller.gd: camera-relative and turn-and-walk steering (SteeringMode export + --steering= CLI argument), jump, a lazily-following camera with no mouse-look (D-05), safe-spot sampling via four corner raycasts, and a soft fall-and-return with a code-generated tone (D-06)"
  - "scenes/test_space.tscn extended with RaisedStep, BackWall, and a FallBoundary (Area3D) wired to Camiel via a CONNECT_PERSIST body_entered connection, keeping open edges on +X, -X, and +Z"
  - "scripts/tools/probe_camiel_movement.gd: a 12-case headless behaviour probe (idle, forward, same_direction_keys, opposite_keys, jump, camera_behind, early_fall, fall_at_edge, soft_return, wall, turn_and_walk, arguments) driven through the real InputMap via Input.parse_input_event(), run automatically by run_headless_check.sh"
affects: ["01-05 (CI job runs this same probe)", "01-06 (D-11 playtest confirms or switches the steering model this plan built both of)", "Phase 2 (intro level reuses camiel.tscn and camiel_controller.gd)", "Phase 6 (touch controls reuse the same InputMap actions and apply_steering_arguments contract)"]

# Actuals (#2632)
actuals:
  tokens: 7843
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Headless behaviour probe: extends SceneTree, awaits tree.physics_frame in an async _run_cases() coroutine instead of a manual frame-counter callback, feeding real keys via Input.parse_input_event(InputEventKey) — matches F7's confirmed input-injection method"
    - "GDScript lambda pitfall: anonymous functions capture outer locals by value, not by reference; a signal handler that must mutate probe state needs a script-level field plus a real bound method, never a `func(x): outer_var += 1` closure"
    - "Camera-relative steering only turns the character to face travel direction on a genuine forward/back input component, never on pure lateral input — turning to face a direction computed from the same frame that then chases that direction has no fixed point and spins forever"
    - "Steering model selectable at runtime via an @export enum plus OS.get_cmdline_user_args() parsing (apply_steering_arguments), so a later playtest or touch-control phase can switch behaviour with a CLI flag and no code change"

key-files:
  created:
    - scenes/camiel.tscn
    - scripts/camiel_controller.gd
    - scripts/camiel_controller.gd.uid
    - scripts/tools/probe_camiel_movement.gd
    - scripts/tools/probe_camiel_movement.gd.uid
  modified:
    - project.godot
    - scenes/test_space.tscn

key-decisions:
  - "Camera-relative steering (holding W moves Camiel away from the camera) is the CAMERA_RELATIVE default; TURN_AND_WALK is built alongside it and selected via steering_mode or --steering=turn_and_walk, so Plan 01-06's D-11 playtest can switch models with no new code"
  - "Camera tuning at Claude's discretion: walk_speed 2.5 m/s, spring_length 4.0, camera_follow_speed 2.0, turn_to_face_speed 10.0 — slow, forgiving values for a child around age 3"
  - "Safe-spot sampling casts four corner rays (±0.75 m margin) every 0.2 s and only records a spot when all four hit floor, so a return can never place Camiel over open air or on a partial ledge"
  - "The return tone is generated in code (AudioStreamWAV, 22050 Hz mono, 0.35 s, 660→440 Hz sine with a 15 ms attack and exponential decay) rather than a new binary asset, per the plan's 'no new binary audio file' constraint"
  - "F6 (already recorded in 01-ENGINE-FACTS.md): ui_focus_next is physical key Ctrl (keycode 4194326), ui_focus_prev is physical key Shift (keycode 4194325) — left untouched by this plan, recorded here for Phase 2's menu keyboard focus"

patterns-established:
  - "Third-person CharacterBody3D + SpringArm3D rig: CameraPivot (top_level Node3D) tracks the character's position every frame; SpringArm3D's built-in wall collision (get_hit_length()) needs no hand-rolled raycasting"
  - "Fail-soft safe-spot recovery: an Area3D boundary trigger with an _is_returning latch and a call_deferred() return, so a boundary that could re-fire mid-teleport only ever fires the recovery once per fall"

requirements-completed: [FOUND-05]

coverage:
  - id: D1
    description: "Camiel walks in every direction with arrows or WASD via InputMap actions (no raw key polling), with same-direction keys capped at walk_speed and opposite keys cancelling to no movement"
    requirement: "FOUND-05"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_camiel_movement.gd#PASS idle,forward,same_direction_keys,opposite_keys (via bash scripts/tools/run_headless_check.sh)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Camiel jumps with Space (is_on_floor() gated) and returns to the floor"
    requirement: "FOUND-05"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_camiel_movement.gd#PASS jump"
        status: pass
    human_judgment: false
  - id: D3
    description: "A camera behind Camiel lazily swings to follow him, with no mouse-look or camera key, and shortens against a wall via SpringArm3D collision"
    requirement: "FOUND-05"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_camiel_movement.gd#PASS camera_behind,wall"
        status: pass
    human_judgment: false
  - id: D4
    description: "Falling off any open edge softly returns Camiel to his last safe spot with a short generated tone and zero velocity, exactly once per fall, with no penalty or failure screen"
    requirement: "FOUND-05"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_camiel_movement.gd#PASS early_fall,fall_at_edge,soft_return"
        status: pass
    human_judgment: false
  - id: D5
    description: "Turn-and-walk steering (A/D turn in place, W walks forward, camera stays directly behind) is available via steering_mode or --steering=turn_and_walk, so the D-11 playtest can switch models without new code"
    requirement: "FOUND-05"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_camiel_movement.gd#PASS turn_and_walk,arguments"
        status: pass
    human_judgment: false
  - id: D6
    description: "Whether camera-relative or turn-and-walk steering actually feels right for a child around age 3 is a subjective judgment, not something this headless probe can assert"
    verification: []
    human_judgment: true
    rationale: "The plan's own success_criteria defers this to Plan 01-06's D-11 manual playtest; this plan only has to make both steering models mechanically correct and switchable, which the probe proves"

# Metrics
duration: 35min
completed: 2026-09-11
status: complete
---

# Phase 1 Plan 4: Camiel Movement, Camera, and Fall-Return Summary

**A capsule Camiel walks and jumps via InputMap actions with a lazily-following SpringArm3D camera, falls off any open edge to a raycast-verified safe spot with a generated tone, and ships a second turn-and-walk steering mode selectable at runtime for Plan 01-06's playtest.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-11T14:28Z (session start, after reading all required context)
- **Completed:** 2026-09-11T14:54:10Z
- **Tasks:** 2 (both `tdd="true"`, each RED then GREEN)
- **Files modified:** 7 (2 modified, 5 created — see Files Created/Modified)

## Accomplishments

- InputMap actions `move_forward` (W, Up), `move_back` (S, Down), `move_left` (A, Left), `move_right` (D, Right), `jump` (Space) written into `project.godot` by a throwaway engine-serializer generator script (never committed), each event an `InputEventKey` with only `physical_keycode` set — confirmed idempotent on a second run.
- `scenes/camiel.tscn`: `CharacterBody3D` root with a `CapsuleShape3D` collision shape, a capsule `Body` mesh, a `Nose` sphere marker, and a `CameraPivot/SpringArm3D/Camera3D` rig, plus a `ReturnSound` `AudioStreamPlayer` — all built and saved by generator scripts (`PackedScene.pack()` + `ResourceSaver.save()`), never hand-typed.
- `scripts/camiel_controller.gd`: `Input.get_vector` against the InputMap actions drives camera-relative movement; `is_on_floor()` + `is_action_just_pressed("jump")` drives the jump; a `TURN_AND_WALK` branch (A/D turn in place, W/S walk forward/back) is selectable via `steering_mode` or the `--steering=` CLI argument; `_sample_safe_spot` casts four corner rays every 0.2 s and only records a spot when all four hit floor; `return_to_safe_spot()` teleports back, plays a code-generated `AudioStreamWAV` chime, and emits `returned_to_safe_spot`.
- `scenes/test_space.tscn` extended with `RaisedStep`, `BackWall`, and a `FallBoundary` (`Area3D`, `body_entered` connected to `Camiel._on_fall_boundary_body_entered` with `CONNECT_PERSIST`), keeping open edges on +X, -X, and +Z; `OverviewCamera` removed and `Camiel` instanced at (0, 0, 2).
- `scripts/tools/probe_camiel_movement.gd`: a 12-case headless probe (idle, forward, same_direction_keys, opposite_keys, jump, camera_behind, early_fall, fall_at_edge, soft_return, wall, turn_and_walk, arguments), driving the real physical keys through `Input.parse_input_event()`, run automatically as the final step of `scripts/tools/run_headless_check.sh`.
- All 12 probe cases pass; `scripts/tools/run_headless_check.sh` ends `Headless check passed.`; `scripts/tools/test_headless_check.sh` still passes all 11 self-test cases (unaffected by this plan); `python3 scripts/tools/quality_gate.py --root .` and `python3 -m unittest tests.test_quality_gate` both pass.

## Task Commits

Each task followed RED then GREEN (TDD):

1. **Task 1 RED: add failing movement probe** — `1ca1b4c` (test) — probe fails with "Camiel node not found in test_space.tscn"
2. **Task 1 GREEN: Camiel walks, jumps, camera follows** — `1e52ea2` (feat) — all six Task 1 probe cases pass
3. **Task 2 RED: add fall-return, wall, turn-and-walk probe cases** — `748d39f` (test) — probe fails with "Invalid assignment of property or key 'steering_mode'"
4. **Task 2 GREEN: fall-return, safe spots, turn-and-walk** — `c959c19` (feat) — all twelve probe cases pass

_No separate REFACTOR commit: fixes discovered mid-GREEN (the camera-relative spin bug, the probe's lambda-capture bug) were folded into each task's single GREEN commit rather than a follow-up cleanup pass, since they were correctness fixes made before GREEN was reached, not post-GREEN cleanup._

## RED Evidence

**Task 1** — before any implementation, `bash scripts/tools/run_headless_check.sh` failed at the probe step:
```
CHECK FAILED: probe probe_camiel_movement.gd: Godot exited with status 1
ERROR: Camiel node not found in test_space.tscn
```

**Task 2** — before extending `camiel_controller.gd`, the same check failed with:
```
CHECK FAILED: probe probe_camiel_movement.gd: Godot exited with status 1
SCRIPT ERROR: Invalid assignment of property or key 'steering_mode' with value of type 'int' on a base object of type 'CharacterBody3D (camiel_controller.gd)'.
```

## Files Created/Modified

- `project.godot` — five InputMap actions (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`)
- `scenes/camiel.tscn` — CharacterBody3D, CapsuleShape3D, capsule body, nose marker, camera rig, ReturnSound
- `scenes/test_space.tscn` — RaisedStep, BackWall, FallBoundary (+ connection), OverviewCamera removed, Camiel instanced
- `scripts/camiel_controller.gd` — movement, jump, camera follow, fall-return, turn-and-walk, steering CLI argument
- `scripts/camiel_controller.gd.uid` — engine-generated sidecar
- `scripts/tools/probe_camiel_movement.gd` — 12-case headless behaviour probe
- `scripts/tools/probe_camiel_movement.gd.uid` — engine-generated sidecar

## Decisions Made

- Camera-relative steering is the default (up/W moves away from the camera); turn-and-walk is built alongside it, selectable via `steering_mode` or `--steering=turn_and_walk`/`--steering=camera_relative`, per the plan's Claude's-Discretion steering model and D-11 playtest requirement.
- Camera and movement tuning (`walk_speed` 2.5, `spring_length` 4.0, `camera_follow_speed` 2.0, `turn_to_face_speed` 10.0, `safe_spot_margin` 0.75, `safe_spot_sample_interval` 0.2 s) chosen as slow, forgiving values appropriate for a child around age 3, per the plan's discretion.
- The return tone is generated entirely in code as an `AudioStreamWAV` (no new binary asset), matching the plan's explicit "no new binary audio file" acceptance criterion.
- F6 (already recorded in `01-ENGINE-FACTS.md`, restated here per the plan's acceptance criteria): `ui_focus_next` is physical key **Ctrl** (keycode 4194326), `ui_focus_prev` is physical key **Shift** (keycode 4194325). Both left untouched by this plan; Phase 2's menu keyboard focus should account for them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed an infinite circular walk when holding a single lateral key (D-only or A-only)**
- **Found during:** Task 2, GREEN implementation — the `fall_at_edge` probe case failed with "returned_to_safe_spot did not fire within 300 frames"
- **Issue:** The plan's camera-relative algorithm (Task 1, item D) computes `direction` from the camera pivot's basis, then turns Camiel's `rotation.y` to face that same `direction` every frame, while the camera pivot itself lazily follows Camiel's `rotation.y` (D-05). For pure lateral input (no forward/back component), the target yaw is always exactly 90° offset from whatever frame it was computed in — a closed loop with no fixed point. I traced Camiel's actual position with a scratch debug script while holding D from (4, 0, 0): position looped in a tight circle around roughly (3.9, 0, 1) for the full 300-frame window and never approached the edge at x=6, confirming the instability empirically (not just algebraically) before changing anything.
- **Fix:** Camiel now only turns to face the travel direction when there is a genuine forward/back input component (`absf(input_dir.y) > 0.01`); pure lateral input strafes without reorienting, which also breaks the feedback loop since the camera then has nothing new to chase. Re-traced the same scenario after the fix: Camiel now walks a straight line along +X, crosses the edge around frame 60, and returns to a safe spot by frame 150.
- **Files modified:** `scripts/camiel_controller.gd`
- **Verification:** `fall_at_edge`, and all other probe cases, pass; `camera_behind` (pure W, unaffected by this change since target already equalled current facing) still passes unchanged.
- **Committed in:** `c959c19` (Task 2 GREEN commit)

**2. [Rule 1 - Bug] Fixed the probe's own signal-counting bug (GDScript lambda capture-by-value)**
- **Found during:** Task 2, GREEN debugging — after fixing the spin bug above, `fall_at_edge` still reported "did not fire within 300 frames" despite Camiel visibly falling and returning in a scratch trace
- **Issue:** `_case_fall_at_edge()` connected an anonymous lambda (`func(position): fire_count += 1; ...`) to `returned_to_safe_spot`. GDScript lambdas capture outer local variables **by value**, not by reference, so the lambda's `fire_count += 1` mutated a private copy — the outer `fire_count` the probe checked every frame never left 0, even though the signal fired correctly (confirmed by adding a temporary `print()` inside the lambda in a scratch trace, which printed "FIRED" while the surrounding `fire_count` stayed 0).
- **Fix:** Replaced the capturing lambda with two script-level fields (`_fall_fire_count`, `_fall_returned_position`) mutated by a real bound method (`_on_return_for_fall_edge`), which GDScript signal `.connect()` handles correctly.
- **Files modified:** `scripts/tools/probe_camiel_movement.gd`
- **Verification:** `fall_at_edge` now correctly detects the single fire, checks the returned x, velocity, and post-return drift, and passes.
- **Committed in:** `748d39f` (Task 2 RED commit, since this is a probe-only fix folded into finalizing the test file before its RED run was recorded)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — one product-code correctness/UX bug, one probe-only test-harness bug; both discovered by the TDD cycle this task itself asked for).
**Impact on plan:** Both fixes were necessary for the fall-return behaviour to work at all (and to be observable). No scope creep, no architectural change — the fix stayed within `_process_camera_relative`'s existing structure and the probe's existing case shape.

## Issues Encountered

None beyond the two deviations above (which TDD's RED/GREEN cycle and empirical tracing were specifically designed to surface).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `scenes/camiel.tscn` and `scripts/camiel_controller.gd` are ready for Phase 2's intro level to reuse directly.
- The `apply_steering_arguments` / `steering_mode` contract is ready for Plan 01-06's D-11 playtest to confirm camera-relative or switch to turn-and-walk with no code change, and for Phase 6's touch controls to map onto the same five InputMap actions.
- `scripts/tools/probe_camiel_movement.gd` runs automatically inside `run_headless_check.sh`, so Plan 01-05's CI job picks it up unchanged.
- No blockers for the next plan in this phase. The FOUND-05 "feel" judgment (is camera-relative steering actually comfortable for a 3-year-old, or should turn-and-walk be the default) remains open by design — that is Plan 01-06's D-11 playtest, not this plan's job.

## Self-Check: PASSED

- All created/modified files verified present on disk: `scenes/camiel.tscn`, `scripts/camiel_controller.gd`, `scripts/camiel_controller.gd.uid`, `scripts/tools/probe_camiel_movement.gd`, `scripts/tools/probe_camiel_movement.gd.uid`, `project.godot`, `scenes/test_space.tscn`, this SUMMARY.
- All four task commits verified present in `git log` (`1ca1b4c`, `1e52ea2`, `748d39f`, `c959c19`).
- Plan-level `<verification>` re-run: `bash scripts/tools/run_headless_check.sh` → "Headless check passed."; `bash scripts/tools/test_headless_check.sh` → 11/11 PASS, "Headless check self-test passed."
- Prior-wave baseline re-confirmed unbroken: `python3 scripts/tools/quality_gate.py --root .` → "Quality gate passed."; `python3 -m unittest tests.test_quality_gate` → OK (4 tests).

---
*Phase: 01-3d-foundation-archive*
*Completed: 2026-09-11*
