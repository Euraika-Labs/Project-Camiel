---
phase: 01-3d-foundation-archive
verified: 2026-09-11T00:00:00Z
status: passed
score: 6/6 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".github/workflows/release.yml"
  - ".gitignore"
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/01-3d-foundation-archive/01-01-PLAN.md"
  - ".planning/phases/01-3d-foundation-archive/01-01-SUMMARY.md"
  - ".planning/phases/01-3d-foundation-archive/01-02-PLAN.md"
  - ".planning/phases/01-3d-foundation-archive/01-02-SUMMARY.md"
  - ".planning/phases/01-3d-foundation-archive/01-03-PLAN.md"
  - ".planning/phases/01-3d-foundation-archive/01-03-SUMMARY.md"
  - ".planning/phases/01-3d-foundation-archive/01-04-PLAN.md"
  - ".planning/phases/01-3d-foundation-archive/01-04-SUMMARY.md"
  - ".planning/phases/01-3d-foundation-archive/01-05-PLAN.md"
  - ".planning/phases/01-3d-foundation-archive/01-05-SUMMARY.md"
  - ".planning/phases/01-3d-foundation-archive/01-06-PLAN.md"
  - ".planning/phases/01-3d-foundation-archive/01-06-SUMMARY.md"
  - ".planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md"
  - ".planning/phases/01-3d-foundation-archive/01-REVIEW-FIX.md"
  - ".planning/phases/01-3d-foundation-archive/01-REVIEW.md"
  - "CONTRIBUTING.md"
  - "assets/materials/ground.tres"
  - "export_presets.cfg"
  - "project.godot"
  - "scenes/camiel.tscn"
  - "scenes/test_space.tscn"
  - "scripts/camiel_controller.gd"
  - "scripts/tools/probe_camiel_movement.gd"
  - "scripts/tools/run_headless_check.sh"
  - "scripts/tools/test_headless_check.sh"
  - "scripts/tools/verify_3d_project.gd"
  - "tests/test_ci_workflows.py"
covered_digest: "v1:sha256:7992c25566f88416a5fbfde99931e0d45f0dda193da2f57962a6218a1dfc570f"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 1: 3D Foundation & Archive Verification Report

**Phase Goal:** The pre-pivot 2D game is safely archived and removed from the runtime project, and a new 3D Godot project baseline runs a primitive-shape Camiel moving freely in a small 3D test space with a following camera, verified by a local headless run that surfaces script errors.
**Verified:** 2026-09-11
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|---|---|---|
| 1 | Pre-pivot 2D game state archived under a dedicated git tag before removal | ✓ VERIFIED | `git cat-file -t archive/2d-alpha-v0.0.3` → `tag` (annotated). `git merge-base --is-ancestor archive/2d-alpha-v0.0.3 HEAD` exits 0. `git ls-remote --tags origin refs/tags/archive/2d-alpha-v0.0.3` returns `e48d2fe6...` — tag is pushed to origin. |
| 2 | 2D gameplay scenes/scripts/assets removed once archive tag exists and user confirmed | ✓ VERIFIED | `git ls-files scenes scripts assets` returns exactly the 18 kept 3D/tooling/audio paths — no 2D file remains. 01-01-SUMMARY.md records the checkpoint answer `remove-and-push-tag` (blocking-human gate, task type `checkpoint:decision`). |
| 3 | Renderer (Forward Plus / Compatibility) decided and set consistently | ✓ VERIFIED | `project.godot` lines 83-85: `renderer/rendering_method="gl_compatibility"`, `.mobile="gl_compatibility"`, `.web="gl_compatibility"` — all three keys explicit and consistent (the `.web` gap flagged in 01-REVIEW.md WR-02 is fixed, commit `11e5ac6`). |
| 4 | `Node3D`-based scene/script/asset baseline exists, running on Godot 4.7.2 | ✓ VERIFIED | `scenes/test_space.tscn` root is `Node3D` (via `run/main_scene="res://scenes/test_space.tscn"`). `/Applications/Godot.app/Contents/MacOS/Godot --version` → `4.7.2.stable.official.ed1daf0bf`, matching `01-ENGINE-FACTS.md` F1. |
| 5 | Primitive-shape Camiel (capsule) moves freely in all directions, camera follows | ✓ VERIFIED | Code: `scripts/camiel_controller.gd` is a `CharacterBody3D`; `scenes/camiel.tscn` has a `CapsuleShape3D` collision shape, `SpringArm3D`/`Camera3D` rig. InputMap actions `move_forward/back/left/right/jump` exist in `project.godot`, each bound by physical keycode. Behavioral evidence: `scripts/tools/probe_camiel_movement.gd` (12 real assertions — `idle`, `forward`, `same_direction_keys`, `opposite_keys`, `jump`, `camera_behind`, `early_fall`, `fall_at_edge`, `soft_return`, `wall`, `turn_and_walk`, `arguments`) runs as the final step of `run_headless_check.sh` and passed when I ran it directly (see Behavioral Spot-Checks). Human confirmation: per the orchestrator's established facts, the user physically playtested the build at the D-11 blocking-human checkpoint and gave the verdict "switch to turn-and-walk" (01-06-SUMMARY.md), now reflected as the `steering_mode` default (`SteeringMode.TURN_AND_WALK`, `scripts/camiel_controller.gd:12`). |
| 6 | Local headless run surfaces GDScript parse/runtime script errors before commit | ✓ VERIFIED | `bash scripts/tools/run_headless_check.sh` (run directly by me, GODOT=installed 4.7.2) exits 0, ends `Headless check passed.`. `bash scripts/tools/test_headless_check.sh` — 13/13 self-test cases pass, including case 12 (zero-probes vacuity, CR-01 fix) and case 13 (generic `ERROR:` masking, CR-02 fix) added in `01-REVIEW-FIX.md`. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `refs/tags/archive/2d-alpha-v0.0.3` | Recoverable archive of pre-pivot 2D game | ✓ VERIFIED | Annotated tag, ancestor of HEAD, pushed to origin, target `754b99d4` = origin/main |
| `project.godot` | 3D baseline: gl_compatibility renderer, Jolt physics, `test_space.tscn` main scene, 5 InputMap movement actions, no 2D leftovers | ✓ VERIFIED | Read directly; matches all claims |
| `scenes/camiel.tscn` | Primitive Camiel: CapsuleShape3D, SpringArm3D camera rig, nose marker, ReturnSound | ✓ VERIFIED | Present, wired into `test_space.tscn` |
| `scenes/test_space.tscn` | Node3D test space with open edges, RaisedStep, BackWall, FallBoundary | ✓ VERIFIED | All nodes present; `FallBoundary` `body_entered` signal connected to `Camiel._on_fall_boundary_body_entered` |
| `scripts/camiel_controller.gd` | Movement, jump, camera-follow, fall/return, dual steering models | ✓ VERIFIED | Behaviorally exercised by the probe (see above) |
| `scripts/tools/verify_3d_project.gd` | `--script` verifier: engine pin, renderer, physics, main scene, load/instantiate every `.gd`/`.tscn` | ✓ VERIFIED | Runs as `[step] verifier` in the headless check; passed |
| `scripts/tools/run_headless_check.sh` | Single local+CI project check | ✓ VERIFIED | Ran directly; exits 0, `Headless check passed.` |
| `scripts/tools/test_headless_check.sh` | Self-test proving all failure directions | ✓ VERIFIED | Ran directly; 13/13 cases pass |
| `.github/workflows/ci.yml`, `.github/workflows/release.yml` | Pinned to Godot 4.7.2, run the headless check, SHA512-verify downloads | ✓ VERIFIED | `GODOT_VERSION: 4.7.2`, `GODOT_BIN: Godot_v4.7.2-stable_linux.x86_64`; `verify-godot` job runs `run_headless_check.sh`; all 3 download sites in `ci.yml` and 2 in `release.yml` do SHA512 compare-before-extract |
| `CONTRIBUTING.md` | Names Godot 4.7.2 and the pre-commit check | ✓ VERIFIED | `bash scripts/tools/run_headless_check.sh` present at line 26 |
| `tests/test_ci_workflows.py` | Structural regression tests for CI/release shape | ✓ VERIFIED | 10 tests present, all pass (`test_workflows_parse_as_yaml` hard-imports PyYAML, no silent skip, per 01-06 FOUND-06 fix) |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `archive/2d-alpha-v0.0.3` | removal commit | tag is ancestor of HEAD | ✓ WIRED | `git merge-base --is-ancestor` exits 0 |
| `project.godot` | `scenes/test_space.tscn` | `run/main_scene` | ✓ WIRED | Literal match confirmed |
| `scenes/test_space.tscn` | `assets/materials/ground.tres` | `ext_resource` | ✓ WIRED | `res://assets/materials/ground.tres` referenced at line 3 |
| `scenes/test_space.tscn` (`FallBoundary`) | `scripts/camiel_controller.gd` | `body_entered` signal | ✓ WIRED | `[connection signal="body_entered" from="FallBoundary" to="Camiel" method="_on_fall_boundary_body_entered"]` |
| `scripts/tools/run_headless_check.sh` | `scripts/tools/verify_3d_project.gd` | `--script` invocation | ✓ WIRED | `[step] verifier` printed on run |
| `scripts/tools/run_headless_check.sh` | `scripts/tools/probe_camiel_movement.gd` | `probe_*.gd` discovery | ✓ WIRED | `[step] probe probe_camiel_movement.gd` printed on run |
| `.github/workflows/ci.yml` (`verify-godot` job) | `scripts/tools/run_headless_check.sh` | `GODOT=... bash scripts/tools/run_headless_check.sh` | ✓ WIRED | Line 119, confirmed by `test_verify_job_runs_headless_check` |
| `.github/workflows/release.yml` | `scripts/tools/run_headless_check.sh` | same pattern | ✓ WIRED | Line 89, confirmed by `test_release_verify_step_runs_headless_check` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Godot 4.7.2 installed and pinned | `/Applications/Godot.app/Contents/MacOS/Godot --version` | `4.7.2.stable.official.ed1daf0bf` | ✓ PASS |
| Headless project check (import, main scene, verifier, movement probe) | `GODOT=.../Godot bash scripts/tools/run_headless_check.sh` | 4 steps printed, `Headless check passed.`, exit 0 | ✓ PASS |
| Self-test proves all 13 failure/success directions | `GODOT=.../Godot bash scripts/tools/test_headless_check.sh` | 13/13 `PASS case N`, `Headless check self-test passed.`, exit 0 | ✓ PASS |
| Repository quality gate | `python3 scripts/tools/quality_gate.py --root .` | `Quality gate passed.`, exit 0 | ✓ PASS |
| Regression unit tests | `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` | `Ran 14 tests in 0.007s / OK`, no skips | ✓ PASS |
| Movement/steering assertions | Exercised inside the run above via `probe_camiel_movement.gd` (12 named cases: idle, forward, same_direction_keys, opposite_keys, jump, camera_behind, early_fall, fall_at_edge, soft_return, wall, turn_and_walk, arguments) | All 12 cases pass (part of the `Headless check passed.` run) | ✓ PASS |

Note: the D-11 five-minute hands-on playtest (camera feel, steering-model preference) cannot be independently re-run by this verifier — it is inherently a human-judgment activity. Per the orchestrator's pre-established facts, this was physically performed by the user and its recorded verdict ("switch to turn-and-walk") is already reflected in the shipped code (`steering_mode` default). This is treated as human-confirmed rather than re-flagged for human verification, per explicit verification-note guidance.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| FOUND-01 | 01-01 | Archive 2D state under a dedicated tag before removal | ✓ SATISFIED | Tag verified above |
| FOUND-02 | 01-01 | Remove 2D content only after user confirmation | ✓ SATISFIED | Checkpoint answer recorded; tree confirmed clean of 2D files |
| FOUND-03 | 01-02, 01-03 | Renderer decided and set consistently | ✓ SATISFIED | `project.godot` renderer keys verified |
| FOUND-04 | 01-02, 01-03, 01-05 | Node3D baseline on Godot 4.7.2 | ✓ SATISFIED | Scene root, engine version verified |
| FOUND-05 | 01-04, 01-06 | Capsule Camiel moves freely, camera follows | ✓ SATISFIED | Code + behavioral probe + human playtest verdict |
| FOUND-06 | 01-02, 01-03, 01-05, 01-06 | Local headless run surfaces script errors, runnable before commit | ✓ SATISFIED | `run_headless_check.sh` + 13-case self-test run directly |

No orphaned requirements — REQUIREMENTS.md maps exactly FOUND-01 through FOUND-06 to Phase 1, and every ID is claimed by at least one plan's frontmatter.

### Anti-Patterns Found

Scanned all files touched by this phase (`project.godot`, `scenes/camiel.tscn`, `scenes/test_space.tscn`, `scripts/camiel_controller.gd`, `scripts/tools/probe_camiel_movement.gd`, `scripts/tools/verify_3d_project.gd`, `scripts/tools/run_headless_check.sh`, `scripts/tools/test_headless_check.sh`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `CONTRIBUTING.md`, `tests/test_ci_workflows.py`, `assets/materials/ground.tres`, `.gitignore`, `export_presets.cfg`) for `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, and similar markers.

None found.

Both Critical findings from `01-REVIEW.md` (CR-01 probe-discovery vacuity, CR-02 import-log `ERROR:` masking) and both Warnings (WR-01 `.gitignore` gap, WR-02 renderer-key asymmetry) plus the Info finding (IN-01 redundant script override) are confirmed fixed in the current tree: `.web` renderer key present, `.gitignore` covers `config.json`, `config.json` untracked, no `3_frqla` reference remains in `test_space.tscn`, and self-test cases 12/13 exist and pass.

### Human Verification Required

None. All must-haves resolved to VERIFIED with direct evidence; the one inherently-human item (D-11 movement/camera feel playtest) is treated as already human-confirmed per explicit instruction from the orchestrator (user physically played the build and recorded a verdict that is reflected in the shipped default).

### Gaps Summary

No gaps. All six ROADMAP success criteria for Phase 1 are independently verified against the actual codebase (not merely against SUMMARY.md claims): the git tag and removal are structurally provable via git plumbing, the renderer/physics/main-scene settings are read directly from `project.godot`, the movement/camera/fall-return behavior is both code-inspected and exercised by a real behavioral probe that I ran myself, and the headless check plus its 13-case self-test — the project's actual verification gates — were run directly by this verifier and passed, not merely reported as passing by an executor. The two Critical review findings the orchestrator flagged as fixed-after-execution are confirmed present and covered by tests in the current tree.

---

_Verified: 2026-09-11_
_Verifier: Claude (gsd-verifier)_
