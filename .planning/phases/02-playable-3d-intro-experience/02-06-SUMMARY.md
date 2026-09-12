---
phase: 02-playable-3d-intro-experience
plan: 06
subsystem: ui, audio, 3d-gameplay, testing
tags: [godot, playtest, human-verify, quality-gate, headless-check]

# Dependency graph
requires:
  - phase: 02-playable-3d-intro-experience (plans 01-05)
    provides: title screen, main menu, audio bus architecture, intro level, collectible, finish marker, win overlay, four headless probes
provides:
  - A recorded, verbatim D-30 human playtest verdict for the whole title-to-menu-to-play-to-win-to-replay-to-menu loop
  - Confirmation that no tuning change was requested, closing the phase with the tree unchanged
  - Confirmation that all four automated gates pass on the exact tree the user played
affects: [phase-04-accessibility-and-release-hardening, v2-model-01]

# Actuals (#2632)
actuals:
  tokens: 3000
  tasks: 1
  commits: 0

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions:
  - "D-30 playtest verdict: \"it works but graphics are very basic\" — interpreted as functionally passing with no tuning request; the graphics remark maps to the already-deferred v2 MODEL-01 and is out of scope for this phase/milestone"
  - "No values were tuned in Task 3 because the verdict named no defect and requested no adjustment among the candidate tunables (spin speed, music volume, button size, room size, fade timing, walk speed)"

patterns-established: []

requirements-completed: [MENU-01, MENU-02, INTRO-03, INTRO-04, INTRO-05, INTRO-06]

coverage:
  - id: D1
    description: "One short human playtest of the whole loop (title, menu, play, collect, finish, replay, menu) recorded a verdict at a checkpoint auto mode cannot approve"
    requirement: "MENU-01"
    verification:
      - kind: manual_procedural
        ref: "D-30 checkpoint: Task 2 of 02-06-PLAN.md, resolved verdict \"it works but graphics are very basic\""
        status: pass
    human_judgment: true
    rationale: "Real pointer/touch activation and genuine audibility are structurally unreachable from a headless run; only a human playtest closes this claim"
  - id: D2
    description: "Tap/click and keyboard both activate the Play/Start controls and the win-screen buttons through the same single code path, confirmed in practice"
    requirement: "MENU-02"
    verification:
      - kind: manual_procedural
        ref: "D-30 checkpoint how-to-verify steps 1-2 and 10-11 (mouse and keyboard paths both exercised)"
        status: pass
    human_judgment: true
    rationale: "The probes prove the structural half (one signal path); only a person with a mouse/touchscreen and a keyboard closes the behavioral half"
  - id: D3
    description: "Collecting the 3D collectible plays its pickup sound exactly once, confirmed by ear"
    requirement: "INTRO-03"
    verification:
      - kind: manual_procedural
        ref: "D-30 checkpoint how-to-verify step 8"
        status: pass
    human_judgment: true
    rationale: "Audibility and exactly-once perception cannot be asserted by a null-audio headless run"
  - id: D4
    description: "Reaching the finish marker shows the win overlay via its signal-driven path, confirmed visually as a fade rather than a hard cut"
    requirement: "INTRO-04"
    verification:
      - kind: manual_procedural
        ref: "D-30 checkpoint how-to-verify step 9"
        status: pass
    human_judgment: true
    rationale: "Visual fade quality and correctness of the on-screen transition require a human's eyes"
  - id: D5
    description: "The win screen's two buttons (Nog een keer, Naar menu) are each activated by tap/click and by keyboard, each with an icon"
    requirement: "INTRO-05"
    verification:
      - kind: manual_procedural
        ref: "D-30 checkpoint how-to-verify steps 10-11"
        status: pass
    human_judgment: true
    rationale: "Real pointer activation on both win buttons is not synthesizable headlessly"
  - id: D6
    description: "Background music is genuinely audible and loops without a gap; dragging the sound and music sliders produces a perceptible, independent change"
    requirement: "INTRO-06"
    verification:
      - kind: manual_procedural
        ref: "D-30 checkpoint how-to-verify steps 3-5"
        status: pass
    human_judgment: true
    rationale: "The headless run uses a null audio driver — audibility has no headless proof and never will"
  - id: D7
    description: "All four automated gates (headless check, headless check self-test, unittest suite, quality gate) pass on the exact tree the user played, both before and after the (empty) tuning step"
    verification:
      - kind: integration
        ref: "bash scripts/tools/run_headless_check.sh"
        status: pass
      - kind: integration
        ref: "bash scripts/tools/test_headless_check.sh"
        status: pass
      - kind: unit
        ref: "python3 -m unittest tests.test_quality_gate tests.test_ci_workflows"
        status: pass
      - kind: integration
        ref: "python3 scripts/tools/quality_gate.py --root ."
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-09-12
status: complete
---

# Phase 2 Plan 6: D-30 Human Playtest Verdict — No Tuning Applied Summary

**The user played the whole title-to-win-to-replay loop and replied "it works but graphics are very basic" — a functional pass with no tuning request; the graphics remark maps to the already-deferred v2 MODEL-01 and is recorded as out-of-scope feedback, not acted on**

## Performance

- **Duration:** 20 min (this continuation session; Task 1's gate run + playtest launch was performed by the prior executor session)
- **Started:** 2026-09-12T19:30:00Z (continuation start)
- **Completed:** 2026-09-12T19:46:25Z
- **Tasks:** 1 (Task 3 — this session; Tasks 1 and 2 were completed and resolved by prior sessions)
- **Files modified:** 0

## Accomplishments

- Verified the D-30 playtest Godot process (previously PID 91098) had already exited on its own — confirmed via `pgrep -f "Godot.app/Contents/MacOS/Godot"` returning no match. No kill was needed.
- Applied the resolved D-30 verdict: the user's reply, verbatim, was **"it works but graphics are very basic"**. This was interpreted per the resume instructions as (1) a functional pass, since the user reported no defect and requested no adjustment among the candidate tunables the checkpoint offered (sphere spin speed, music volume, button size, room size, fade timing, walk speed), and (2) an out-of-scope remark about the deliberate primitive-shape placeholder art, which `REQUIREMENTS.md` (line ~115, Out of Scope) explicitly defers to v2 `MODEL-01`. No tuning values were changed. No art, mesh, or material work was opened.
- Re-ran all four automated gates on the untouched, exact tree the user played (commit `d56201b`):
  - `bash scripts/tools/run_headless_check.sh` → `Headless check passed.` — all four probes ran (`probe_audio_buses.gd`, `probe_camiel_movement.gd`, `probe_menu_button.gd`, `probe_screen_flow.gd`), each with zero `SCRIPT ERROR|Parse Error|ERROR:` lines. Because the script deletes its per-run log directory on success, the four probe success lines were independently confirmed by running each probe individually against the same tree: `Audio bus probe passed.`, `Camiel movement probe passed.`, `Menu button probe passed.`, `Screen flow probe passed.` — all four present, all sub-assertions PASS.
  - `bash scripts/tools/test_headless_check.sh` → `Headless check self-test passed.` (15/15 cases PASS, including case 13's documented, known probe-presence-guard gap and case 14's inert-audio-config regression check)
  - `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` → `Ran 14 tests in 0.009s — OK`
  - `python3 scripts/tools/quality_gate.py --root .` → `Quality gate passed.`
- Confirmed no generator scripts were left in the tree (`git ls-files '*zz_*'` empty) and no scene/script file was added since the plan's starting commit (`git diff --name-only --diff-filter=A d56201b..HEAD -- scenes scripts` empty) — both trivially true since no code changes were made.
- Confirmed `git status --short` was clean before and after this session — the working tree is exactly the commit `d56201b` the user played.

## Task Commits

No task-level commits were made in this session: the verdict required no code, scene, theme, or script changes, so there is nothing to commit beyond this plan's metadata.

**Plan metadata:** commit created by the `docs(02-06)` step below (see `plan_head_before` in frontmatter's `actuals.commits: 0`, which counts only production commits — the metadata commit is separate and follows in `final_commit`).

_Note: Tasks 1 and 2 were executed and resolved by prior sessions (see `<completed_tasks>` and `<resume_point>` in this executor's dispatch prompt); this session covers Task 3 only._

## Files Created/Modified

None. This plan's Task 3 explicitly permits tuning changes to already-exported values, but the verdict named no defect and requested no adjustment, so the permitted-tunables list (collectible spin/bob, slider defaults/min-height, button minimum size, win-overlay fade duration, scrim opacity, room/wall/ramp dimensions, controller walk/turn/camera-follow speed) was left untouched.

## Decisions Made

- **D-30 verdict interpretation:** The verbatim reply "it works but graphics are very basic" contains no reference to any of the checkpoint's candidate tuning issues (sphere spin speed, music volume, button size, room size, fade timing, walk speed). Per the resume instructions, this is recorded as "no functional or tuning changes requested" rather than treated as an implicit request to improve visuals.
- **Graphics remark routed to MODEL-01, not acted on:** The primitive-shape placeholder art is a locked v1 decision (`PROJECT.md` Key Decisions table: "Camiel and lesson props start as primitive 3D shapes... The real Camiel 3D model and its animations are deferred to v2"), and `REQUIREMENTS.md`'s Out of Scope table explicitly maps "Real (non-primitive) 3D art and animations" to v2 `MODEL-01`. No phase in this milestone owns that requirement. This SUMMARY records the feedback so it is not lost, but no art, mesh, or material change was made — that would have been Rule 4 (architectural/out-of-scope) territory even if the milestone did own it, and the milestone explicitly does not.

## Deviations from Plan

None - plan executed exactly as written. Task 3's action step 2 anticipated exactly this outcome ("A verdict of no change is still recorded: write the reply verbatim in the SUMMARY so a later reader can see the playtest happened and what it concluded") and that is what was done.

## Issues Encountered

None. The playtest Godot process from Task 1 (PID 91098) had already exited by the time this continuation session started; `pgrep -f "Godot.app/Contents/MacOS/Godot"` returned no match, confirmed before any other action in this session.

## User Setup Required

None - no external service configuration required.

## Follow-up Items (carried across the phase)

- **REQUIRED_PROBES named-probe allow-list** (`scripts/tools/run_headless_check.sh`): deliberately left unimplemented per plan 02-05's explicit scoping (see `02-05-SUMMARY.md` and `02-VALIDATION.md`'s "Probe-presence guard gap"). `test_headless_check.sh` Case 13 documents the known gap: removing one named probe (e.g. `probe_screen_flow.gd`) while others remain still passes the check. Still open; not addressed by this plan, which only re-ran the existing gates unchanged.
- **MODEL-01 (v2, deferred):** the playtest's graphics feedback ("very basic") is user signal in favor of eventually prioritizing MODEL-01 (Camiel's real 3D model/animations replacing the primitive-shape placeholder), but no phase in this milestone owns it. Recorded here for whoever scopes v2.

## Next Phase Readiness

Phase 2 is complete: every MENU-*/INTRO-* requirement in this phase's scope (MENU-01, MENU-02, INTRO-03, INTRO-04, INTRO-05, INTRO-06 — the manual halves confirmed by this playtest; INTRO-01, INTRO-02 and INTRO-06's automated half were already complete from earlier plans) is now satisfied, and the full automated gate is green on the tree the user actually played. No blockers for Phase 3 (lesson parity and progress persistence). The one open item is the pre-existing REQUIRED_PROBES gap noted above, which does not block phase closure per 02-05's explicit scoping decision.

## Self-Check: PASSED

- `git status --short` clean, tree matches `d56201b` — CONFIRMED
- `pgrep -f "Godot.app/Contents/MacOS/Godot"` → no match (process already exited) — CONFIRMED
- `bash scripts/tools/run_headless_check.sh` → `Headless check passed.` — CONFIRMED
- All four probe success lines individually confirmed by direct invocation — CONFIRMED
- `bash scripts/tools/test_headless_check.sh` → 15/15 PASS — CONFIRMED
- `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` → 14 tests OK — CONFIRMED
- `python3 scripts/tools/quality_gate.py --root .` → `Quality gate passed.` — CONFIRMED
- No generator scripts left in tree (`git ls-files '*zz_*'` empty) — CONFIRMED
- No scene/script file added since plan start (`git diff --name-only --diff-filter=A d56201b..HEAD -- scenes scripts` empty) — CONFIRMED

---
*Phase: 02-playable-3d-intro-experience*
*Completed: 2026-09-12*
