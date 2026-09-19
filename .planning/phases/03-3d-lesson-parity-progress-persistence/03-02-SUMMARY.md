---
phase: 03-3d-lesson-parity-progress-persistence
plan: 02
subsystem: 3d-gameplay
tags: [godot, gdscript, area3d, headless-probe, ui]

requires:
  - phase: 02-playable-3d-intro-experience
    provides: scripts/collectible.gd's one-shot-latch/player-group-guard/deferred-reaction pattern, scenes/ui/menu_button.tscn, assets/theme/ui_theme.tres
provides:
  - scripts/lesson_target.gd + scenes/lesson_target.tscn — the one @export-parametrized Area3D target every lesson instances (D-45), with the D-37/D-38 structural activation gate (activate/deactivate/is_active/reset, rejected signal)
  - scenes/lesson_room.tscn — the shared 12m enclosed room every lesson instances
  - scripts/ui/lesson_hud.gd + scenes/ui/lesson_hud.tscn — the shared lesson HUD: one set_step(current, total) label form (D-46), Dutch return control, win panel
affects: [03-03, 03-04, 03-05, 03-06, 03-07 (all five lesson orchestrators build directly on this plan's three artifacts)]

actuals:
  tokens: 9134
  tasks: 3
  commits: 3
  plan_head_before: 54d9f85fd8ebf25bee9409fc114e1b935dc2a8a0

tech-stack:
  added: []
  patterns:
    - "One @export-parametrized Area3D script serves every lesson target instead of a script per shape (D-45): task_id, target_color, shape_kind, display_text, requires_activation"
    - "Structural order gate: an inactive target has no code path to task_completed, only to rejected; activate()/deactivate()/is_active()/reset() are all public so no orchestrator reaches into a private member (D-37, D-38)"
    - "Activation defers a get_overlapping_bodies() check so a body already standing inside an area (which never re-fires body_entered) still completes once the target becomes its turn"
    - "One shared HUD label form, set_step(current, total), builds \"Stap: %d / %d\" so the format string exists in exactly one file regardless of a lesson's total step count (D-46)"
    - "A child control's focus_mode must be forced in the PARENT's own _ready(), because child _ready() runs before parent _ready() and menu_button.gd's own _ready() re-asserts FOCUS_ALL every time"

key-files:
  created:
    - scripts/lesson_target.gd
    - scenes/lesson_target.tscn
    - scenes/lesson_room.tscn
    - scripts/ui/lesson_hud.gd
    - scenes/ui/lesson_hud.tscn
    - scripts/tools/probe_lesson_kit.gd
  modified: []

key-decisions:
  - "D-46 resolved exactly as the plan's objective specified: set_step(current, total) parametrizes the total rather than hardcoding /3, so lesson 5's real four-step rule is never misreported. Verified by grep: the string \"Stap: %d / %d\" exists in exactly one .gd file in the repository."
  - "The D-37/D-38 activation gate shipped inside scripts/lesson_target.gd from Task 1 rather than being added in a separate Task 3 pass, because the gate branch lives inside the same _on_body_entered method as the one-shot latch and player-group guard Task 1 also writes -- splitting them would have meant writing and then rewriting the same function. Task 3's own RED/GREEN cycle was preserved by temporarily removing the gate branch, confirming the negative probe case failed for the right reason (\"rejected fired 0 times\", not a missing node), then restoring the file to be byte-identical to Task 1's commit."
  - "Rejection feedback is a tween scale dip only (0.92 and back); nothing ever writes to a target's Label3D text a second time (grep confirms exactly one _label.text = assignment, in _ready()), directly avoiding the archived sequence target's error-flash defect that permanently overwrote a target's label with its order number."

requirements-completed: [LESSON-01, LESSON-02, LESSON-03, LESSON-04, LESSON-05]

coverage:
  - id: D1
    description: "A target instanced into the shared room completes exactly once for a player body carrying its own exported identifier, ignores further overlap, and ignores a non-player body entirely -- proved on a real floor with the real character body, not a stub"
    requirement: LESSON-01
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_kit.gd#_case_target_completes_on_touch"
        status: pass
      - kind: integration
        ref: "bash scripts/tools/run_headless_check.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "An inactive target structurally cannot complete -- it has exactly one branch for a touch while inactive, and that branch emits rejected, never task_completed. Proved by a negative case, not inferred from eventual success."
    requirement: LESSON-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_kit.gd#_case_activation_gate_refuses_then_allows"
        status: pass
    human_judgment: false
  - id: D3
    description: "A rejected target is still completable later once activated, and the earlier refusal did not consume its one-shot latch"
    requirement: LESSON-03
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_kit.gd#_case_activation_gate_refuses_then_allows"
        status: pass
    human_judgment: false
  - id: D4
    description: "Activating a target a body is already standing inside completes it without the body leaving and returning, closing the soft-lock an Area3D's non-re-firing body_entered would otherwise create"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_kit.gd#_case_activation_gate_refuses_then_allows (already-standing sub-case)"
        status: pass
    human_judgment: false
  - id: D5
    description: "One shared @export-parametrized target script and one shared room and HUD exist as the foundation lessons 1-5 (LESSON-04, LESSON-05 included) will build on -- no lesson needs a script per shape or a second progress-label format"
    requirement: LESSON-04
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_kit.gd (all three cases)"
        status: pass
      - kind: unit
        ref: "grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l  =>  1"
        status: pass
    human_judgment: false
  - id: D6
    description: "The shared HUD announces both the in-play return and the win-panel return through signals only, never changing a scene itself, so each lesson decides where back goes (D-34); the in-play control cannot take keyboard focus since jump and ui_accept share the space key"
    requirement: LESSON-05
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_kit.gd#_case_hud_form_and_win_panel"
        status: pass
    human_judgment: false

duration: ~65min
completed: 2026-09-13
status: complete
---

# Phase 3 Plan 2: Lesson Kit Foundation Summary

**One @export-parametrized Area3D target with a structural D-37/D-38 activation gate, a shared 12m room, and a shared HUD whose single `set_step(current, total)` form resolves D-46 without a second format string anywhere.**

## Performance

- **Duration:** ~65 min
- **Tasks:** 3 completed
- **Files created:** 9 (`scripts/lesson_target.gd` + `.uid`, `scenes/lesson_target.tscn`, `scenes/lesson_room.tscn`, `scripts/ui/lesson_hud.gd` + `.uid`, `scenes/ui/lesson_hud.tscn`, `scripts/tools/probe_lesson_kit.gd` + `.uid`)

## Accomplishments

- `scripts/lesson_target.gd`: the single parametrized target script every one of the five lessons will instance -- identity, colour, shape, display text, and whether it needs activation are all exported values, with no subclass and no `class_name`
- The D-37/D-38 order-enforcement gate is structural: an inactive target's `_on_body_entered` has exactly one branch for a touch, and that branch emits `rejected` and returns without touching the one-shot latch -- there is no expected-index counter for an orchestrator to declare and forget to read, which is the exact archived `lesson_2.gd` defect this plan exists to prevent
- Activation closes the "already-standing" soft lock: `activate()` defers a `get_overlapping_bodies()` check, because an `Area3D` never re-fires `body_entered` for a body that never left
- `scenes/lesson_room.tscn`: a calm 12x12m enclosed room (floor + four walls), larger than the intro level's 16x16 footprint's playable interior specifically so lesson targets can sit well apart
- `scripts/ui/lesson_hud.gd` + `scenes/ui/lesson_hud.tscn`: the shared HUD with `set_step(current, total)` as the one place `"Stap: %d / %d"` exists in the repository, a Dutch in-play return control that cannot take keyboard focus, and a win panel that fades in and grabs focus on its own return control
- `scripts/tools/probe_lesson_kit.gd`: three cases proving all of the above against a real physics simulation, including the negative case for the activation gate

## Task Commits

1. **Task 1: A body walks into a target in a real room and one signal comes out** - `f2959ce` (feat)
2. **Task 2: The shared display — one progress-label form, a Dutch return control, and a win panel** - `bdc5069` (feat)
3. **Task 3: An inactive target refuses, says so, and becomes completable only when the lesson activates it** - `c1c3d3a` (test)

**Plan metadata:** committed separately below.

## RED Evidence

**Task 1** — running `bash scripts/tools/run_headless_check.sh` before `scenes/lesson_target.tscn`/`scenes/lesson_room.tscn` existed (the target script and probe already existed) produced, in the verifier step:

```
SCRIPT ERROR: Parse Error: No constructor of "Transform3D" matches the signature ...
ERROR: Failed to load script "res://scripts/tools/zz_generate_lesson_kit_scenes.gd" with error "Parse error".
```

(the throwaway scene generator itself had a GDScript constructor-signature bug, fixed by building the `Transform3D` from a `Basis` instead of 12 raw floats). After fixing the generator and building the scenes, the probe's own first run then surfaced a second, real defect: setting `camiel.global_position` in the same statement as `room.add_child(camiel)` produced `ERROR: Condition "!is_inside_tree()" is true` — the assignment needs one `process_frame` after `add_child()` before the node is queryable. Both fixed before Task 1's commit.

**Task 2** — running the probe with `_case_hud_form_and_win_panel` added, before `scenes/ui/lesson_hud.tscn` existed:

```
ERROR: Cannot open file 'res://scenes/ui/lesson_hud.tscn'.
ERROR: Failed loading resource: res://scenes/ui/lesson_hud.tscn.
SCRIPT ERROR: Cannot call method 'instantiate' on a null value.
```

Confirmed the case fails for the right reason (the scene's absence) before the generator built it.

**Task 3** — the activation-gate branch was temporarily removed from `scripts/lesson_target.gd`'s `_on_body_entered` (falling straight through to the touch reaction, simulating the pre-Task-3 state) and the check re-run:

```
ERROR: activation_gate_refuses_then_allows: rejected fired 0 times within 120 physics frames, expected 1
```

This confirms the negative case measures the gate's absence specifically (zero rejections), not a missing node or a typo. The file was restored immediately afterward; `diff` against the version saved before the edit showed no difference, and `git diff scripts/lesson_target.gd` after Task 3's commit shows no change against Task 1's committed version.

## GREEN Evidence

Direct probe invocation after each fix:

```
[probe_lesson_kit] target_completes_on_touch frames to emission: 4
PASS target_completes_on_touch
PASS hud_form_and_win_panel
[probe_lesson_kit] activation_gate rejection frames: 3
[probe_lesson_kit] activation_gate post-activation completion frames: 3
PASS activation_gate_refuses_then_allows
Lesson kit probe passed.
```

`bash scripts/tools/run_headless_check.sh` passed end-to-end after each task, ending `Headless check passed.` `bash scripts/tools/test_headless_check.sh` passed all 15 self-test cases. `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` — 14 tests, OK. `python3 scripts/tools/quality_gate.py --root .` — `Quality gate passed.`

**Measured frame counts** (fixed 60fps headless): teleport-to-completion for an unrestricted target, 4 physics frames. Teleport-to-rejection for an inactive target, 3 physics frames. Teleport-to-completion immediately after activation, 3 physics frames. All well inside the 120-frame ceiling the shipped `probe_screen_flow.gd` pattern uses.

**Room's final dimensions:** 12m x 12m floor, four walls 3m tall, fully enclosing the floor with no ramp and nothing to climb.

## Files Created/Modified

- `scripts/lesson_target.gd` - The shared parametrized target: 5 exports, `task_completed`/`rejected` signals, `activate`/`deactivate`/`is_active`/`reset` public methods
- `scenes/lesson_target.tscn` - `Area3D` root with a generous `CollisionShape3D` (radius 0.55), an empty `Mesh` the script builds, and a billboard `Label3D`
- `scenes/lesson_room.tscn` - `Node3D` root: `WorldEnvironment`, `Sun`, `Ground` (12x12m), `Walls/{WallNorth,WallSouth,WallEast,WallWest}`
- `scripts/ui/lesson_hud.gd` - `CanvasLayer` script: `set_title`, `set_step`, `show_win`, `is_win_visible`, `back_requested`/`win_back_requested` signals
- `scenes/ui/lesson_hud.tscn` - Title/step labels, `%BackButton` and `%WinBackButton` as `menu_button.tscn` instances, the win panel matching the intro level's cream/border/corner-radius-32 treatment
- `scripts/tools/probe_lesson_kit.gd` - Three cases: `target_completes_on_touch`, `hud_form_and_win_panel`, `activation_gate_refuses_then_allows`

## Decisions Made

- D-46 resolved by parametrizing the total (`set_step(current, total)`), never hardcoding `/3`, per the plan objective's explicit instruction. Verified with the plan's own acceptance command: the string appears in exactly one `.gd` file.
- The activation gate (D-37/D-38) was implemented in full inside `scripts/lesson_target.gd`'s Task 1 commit rather than split across a separate Task 3 diff, since the gate is one branch inside the same method Task 1 also writes. Task 3's RED/GREEN discipline was preserved by a temporary, fully-reverted removal of that branch to produce genuine failing evidence for the negative case — see Deviations below.
- Rejection feedback is a scale-dip tween only; the target's `Label3D` text is written exactly once, in `_ready()`, and never touched by any feedback path — directly avoiding the archived sequence target's label-overwrite defect.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed a Transform3D constructor signature error in the throwaway scene generator**
- **Found during:** Task 1
- **Issue:** `Transform3D(9 floats, 3 floats)` is the `.tscn` text-serialization shape, not an actual GDScript constructor; calling it that way in code raised a parse error
- **Fix:** Built the rotation via `Basis(Vector3, Vector3, Vector3)` then `Transform3D(basis, origin)`
- **Files modified:** the throwaway generator script (deleted after use, never committed)
- **Verification:** generator ran to completion and saved both scenes
- **Committed in:** not committed (generator deleted per plan step E)

**2. [Rule 1 - Bug] Fixed a premature `global_position` assignment before a node entered the tree**
- **Found during:** Task 1
- **Issue:** setting `camiel.global_position` in the same statement block as `room.add_child(camiel)` raised `ERROR: Condition "!is_inside_tree()" is true`, which `run_headless_check.sh`'s log-scan treats as a check failure even though the probe's own assertions still passed
- **Fix:** await one `process_frame` between `add_child()` and the `global_position` assignment
- **Files modified:** `scripts/tools/probe_lesson_kit.gd`
- **Verification:** re-ran `bash scripts/tools/run_headless_check.sh`, no `ERROR:` lines, `Headless check passed.`
- **Committed in:** `f2959ce` (Task 1 commit)

### Structural Deviation (documented, not a bug)

**3. [Sequencing] The D-37/D-38 activation gate shipped with Task 1 instead of Task 3**

The plan structures Task 1 as "targets that do not require activation" and Task 3 as adding the gate branch afterward. Because the gate is a conditional inside the same `_on_body_entered` method Task 1 also writes (alongside the one-shot latch and player-group guard), writing it twice — once without the gate, then rewriting the same function with it — would have produced no functional difference in the shipped code and only cost an extra edit pass. The gate landed in Task 1's commit. Task 3's own RED/GREEN contract was preserved literally: before Task 3's case was finalized, the gate branch was temporarily removed from the already-committed file, the check was re-run and failed with `"rejected fired 0 times"` (proving the case measures the gate's presence, not a coincidental pass), and the file was restored to be byte-identical to Task 1's commit (confirmed via `diff`). `git diff scripts/lesson_target.gd` between Task 1's and Task 3's commits shows no change.

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug) + 1 structural sequencing deviation (documented, no functional impact). **Impact:** None of the three affected the shipped behavior described by the plan's `<behavior>` blocks or acceptance criteria; all acceptance criteria for all three tasks were re-verified and pass.

## Known Stubs

None. Every artifact this plan lists is fully implemented and proven by the probe; no lesson-specific content exists yet, which is correct — that is plans 03-03 through 03-07's scope, not this plan's.

## Issues Encountered

None beyond the two auto-fixed items above, both resolved on the first retry.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The three reusable pieces every lesson orchestrator needs are complete and proven: `scripts/lesson_target.gd` + `scenes/lesson_target.tscn`, `scenes/lesson_room.tscn`, `scripts/ui/lesson_hud.gd` + `scenes/ui/lesson_hud.tscn`.
- Public surface any lesson orchestrator may call on a target: `activate()`, `deactivate()`, `is_active() -> bool`, `reset()`, plus the `task_completed(task_id: String)` and `rejected` signals. On the HUD: `set_title(text)`, `set_step(current, total)`, `show_win()`, `is_win_visible() -> bool`, plus `back_requested` and `win_back_requested` signals.
- A body already inside an area never re-fires `body_entered`; `activate()` already handles this via a deferred `get_overlapping_bodies()` check, so lesson orchestrators do not need their own workaround.
- No blockers for plans 03-03 through 03-07 (the five lesson orchestrators) or the lesson-select/verification-chain plans that follow.

## Self-Check: PASSED

- `scripts/lesson_target.gd` — FOUND
- `scripts/lesson_target.gd.uid` — FOUND
- `scenes/lesson_target.tscn` — FOUND
- `scenes/lesson_room.tscn` — FOUND
- `scripts/ui/lesson_hud.gd` — FOUND
- `scripts/ui/lesson_hud.gd.uid` — FOUND
- `scenes/ui/lesson_hud.tscn` — FOUND
- `scripts/tools/probe_lesson_kit.gd` — FOUND
- `scripts/tools/probe_lesson_kit.gd.uid` — FOUND
- Commit `f2959ce` — FOUND in `git log --oneline --all`
- Commit `bdc5069` — FOUND in `git log --oneline --all`
- Commit `c1c3d3a` — FOUND in `git log --oneline --all`
- All acceptance criteria from Tasks 1, 2, and 3 re-verified via the exact `grep`/`test` commands in `03-02-PLAN.md` — all PASS
- `bash scripts/tools/run_headless_check.sh` — PASSED (exit 0, `Headless check passed.`)
- `bash scripts/tools/test_headless_check.sh` — PASSED (exit 0, `Headless check self-test passed.`, all 15 cases)
- `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` — PASSED (14 tests, OK)
- `python3 scripts/tools/quality_gate.py --root .` — PASSED (`Quality gate passed.`)
- No `zz_*` generator files tracked by git (`git ls-files '*zz_*'` empty)

---
*Phase: 03-3d-lesson-parity-progress-persistence*
*Completed: 2026-09-13*
