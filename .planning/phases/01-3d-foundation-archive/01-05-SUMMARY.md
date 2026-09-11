---
phase: 01-3d-foundation-archive
plan: 05
subsystem: infra
tags: [github-actions, ci, release, godot, sha512, tdd]

# Dependency graph
requires:
  - phase: 01-3d-foundation-archive
    provides: "01-03 built scripts/tools/run_headless_check.sh (the single project check this plan wires into CI/release) and scripts/tools/verify_3d_project.gd"
provides:
  - "ci.yml and release.yml pinned to Godot 4.7.2 (D-02), with the retired 2D verifier/quit-after smoke test replaced by scripts/tools/run_headless_check.sh (D-10)"
  - "SHA512 verification of every Godot engine and export-template download in ci.yml and release.yml, against the release's SHA512-SUMS.txt, before extraction (T-01-SC2)"
  - "tests/test_ci_workflows.py: 10 structural regression tests pinning ci.yml/release.yml shape, run by the repository-hygiene CI job"
  - "CONTRIBUTING.md naming Godot 4.7.2 and the run_headless_check.sh pre-commit command"
affects: ["Phase 4 (CI-01 to CI-05, action SHA pinning, export.yml, single version source)"]

# Actuals (#2632)
actuals:
  tokens: 4520
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Structural (non-YAML-parsing) test helper _job_steps() scans GitHub Actions workflow YAML by fixed indentation to extract each job's step names and run: block text, so tests work even when PyYAML is unavailable; a separate YAML-parse test is skipUnless(PyYAML)"
    - "SHA512-verify-before-extract: every curl download of a .zip/.tpz is followed by a second curl for SHA512-SUMS.txt, an awk lookup of the expected hash by filename, and a sha512sum comparison that exits 1 with ::error:: on mismatch or missing entry, all before the unzip call"

key-files:
  created:
    - tests/test_ci_workflows.py
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - CONTRIBUTING.md

key-decisions:
  - "SHA512 lookup accepts a leading '*' on the filename in SHA512-SUMS.txt (awk pattern matches name or \"*\"name), per the plan's spec for the release asset's checksum-file convention"
  - "release.yml's Verify project step keeps doing its own import pass (now via run_headless_check.sh) rather than skipping it, since the plan notes the check's import creates the .godot/ cache the following Build Windows release step depends on"

requirements-completed: [FOUND-04, FOUND-06]

coverage:
  - id: D1
    description: "CI pins Godot 4.7.2 and runs the single headless project check in place of the retired 2D verifier and quit-after smoke test, with checksum-verified engine/template downloads"
    requirement: "FOUND-04"
    verification:
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_ci_env_pins_godot_4_7_2"
        status: pass
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_verify_job_runs_headless_check"
        status: pass
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_no_2d_verifier_or_quit_after"
        status: pass
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_ci_downloads_verify_sha512"
        status: pass
    human_judgment: true
    rationale: "A real GitHub Actions run needs a push to origin, which only the user authorizes; the plan's own <human-check> defers this to the PR Checks tab after push (end-of-phase UAT), not something this executor can trigger"
  - id: D2
    description: "release.yml verifies through the same check on the same pinned engine, with the same checksum verification on its downloads"
    requirement: "FOUND-04"
    verification:
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_release_env_pins_godot_4_7_2"
        status: pass
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_release_verify_step_runs_headless_check"
        status: pass
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_release_downloads_verify_sha512"
        status: pass
    human_judgment: true
    rationale: "A release run requires a tag push, which only the user authorizes; not exercised in this session"
  - id: D3
    description: "CONTRIBUTING.md names Godot 4.7.2 and the run_headless_check.sh pre-commit command; repository-hygiene CI job runs tests.test_ci_workflows"
    requirement: "FOUND-06"
    verification:
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_contributing_names_check"
        status: pass
      - kind: unit
        ref: "tests/test_ci_workflows.py#test_hygiene_runs_workflow_tests"
        status: pass
      - kind: other
        ref: "python3 -m unittest -v tests.test_ci_workflows (10/10 pass, none skipped)"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-09-11
status: complete
---

# Phase 1 Plan 5: CI and Release Pinned to Godot 4.7.2 with the Headless Check Summary

**ci.yml and release.yml now pin Godot 4.7.2, verify every engine/export-template download by SHA512 before extraction, and run scripts/tools/run_headless_check.sh in place of the retired 2D verifier and quit-after smoke test, backed by 10 new structural regression tests.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-11T15:05:00Z (approx.)
- **Completed:** 2026-09-11T15:30:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 edited)

## Accomplishments

- Wrote `tests/test_ci_workflows.py` with a text-based `_job_steps()` step-splitter (works without PyYAML) and 10 tests pinning: the Godot 4.7.2 env pins in both workflows, the single headless-check step in `verify-godot` and `release-windows`, the absence of `verify_camiel_resources`/`--quit-after`, SHA512 verification on every archive download, the hygiene job running this new test module, both workflows parsing as valid YAML, and CONTRIBUTING.md's wording.
- `ci.yml`: env pinned to 4.7.2; `verify-godot`'s `Import project`/`Verify resources`/`Smoke test main scene` steps replaced by one `Run headless project check` step calling `scripts/tools/run_headless_check.sh`; both `Download Godot` steps and `export-windows`'s `Install export templates` step now verify SHA512 against `SHA512-SUMS.txt` before unzip; `repository-hygiene` now runs `tests.test_ci_workflows` alongside `tests.test_quality_gate`.
- `release.yml`: same env pin, same SHA512 verification on its `Download Godot` and `Install export templates` steps, and `Verify project` now runs the single check command (its import pass still produces the `.godot/` cache the following build step needs).
- `CONTRIBUTING.md`: Godot version updated to 4.7.2; the Windows-only PowerShell verifier snippet replaced with `bash scripts/tools/run_headless_check.sh` plus guidance on `GODOT=` and running from Git Bash on Windows; the assets bullet updated from the removed `assets/camiel/` path to `assets/` with committed `.import` files.
- `.github/workflows/export.yml` left untouched (confirmed byte-identical to `archive/2d-alpha-v0.0.3` both before and after this plan) — it remains Phase 4's responsibility (CI-01, CI-02).

## Task Commits

Each task was committed atomically, following RED-GREEN TDD:

1. **Task 1 RED: CI workflow structure tests** - `21f2946` (test)
2. **Task 1 GREEN: pin CI to Godot 4.7.2, run the headless check** - `4df63fe` (feat)
3. **Task 2 RED: release workflow and CONTRIBUTING tests** - `f852cab` (test)
4. **Task 2 GREEN: release workflow and CONTRIBUTING.md updated** - `c6f663d` (feat)

**Plan metadata:** committed separately after this SUMMARY.

## RED Evidence

**Task 1** — before editing `ci.yml`, the 6 new tests were run against the pre-existing 4.6.2-pinned file: `test_ci_env_pins_godot_4_7_2`, `test_verify_job_runs_headless_check`, `test_ci_downloads_verify_sha512`, and `test_hygiene_runs_workflow_tests` failed as expected (wrong version pins, old 2D steps present, no SHA512 checks, hygiene job not yet running the new module); `test_no_2d_verifier_or_quit_after` also failed since the old steps were still present; `test_workflows_parse_as_yaml` passed trivially (the pre-existing file was already valid YAML — this test guards structure, not the version change).

**Task 2** — before editing `release.yml`/`CONTRIBUTING.md`, all 4 new tests failed as expected: wrong version pins, `Verify project` still calling the 2D verifier, no SHA512 checks on `release.yml`'s downloads, and `CONTRIBUTING.md` still naming `4.6.2` and `verify_camiel_resources`.

## Files Created/Modified

- `tests/test_ci_workflows.py` - new; 10-test structural regression suite for `ci.yml`/`release.yml`, plus the `_job_steps()` helper
- `.github/workflows/ci.yml` - Godot 4.7.2 pin, SHA512-verified downloads, single headless-check step, hygiene job runs the new tests
- `.github/workflows/release.yml` - Godot 4.7.2 pin, SHA512-verified downloads, single headless-check `Verify project` step
- `CONTRIBUTING.md` - Godot 4.7.2, `run_headless_check.sh` pre-commit instruction, updated assets guidance

## Decisions Made

- SHA512 lookup in the download steps matches the release asset name with or without a leading `*` (the common `sha512sum`-style checksum-file convention), per the plan's spec.
- `release.yml`'s `Verify project` step keeps its own import pass (now delivered via `run_headless_check.sh`'s own import step) because the following `Build Windows release` step depends on the `.godot/` cache it produces — removing it would break the build step, not just the check.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. A real CI/release run requires the user to push this branch and open a pull request (or push a tag for release.yml) — see Next Phase Readiness.

## Next Phase Readiness

- All four project-wide checks pass on the current tree: `bash scripts/tools/run_headless_check.sh`, `bash scripts/tools/test_headless_check.sh` (11/11), `python3 scripts/tools/quality_gate.py --root .`, and `python3 -m unittest tests.test_quality_gate`.
- `python3 -m unittest -v tests.test_ci_workflows` passes 10/10, none skipped.
- The plan's `<human-check>` (pushing this branch and confirming the "Repository hygiene" and "Verify Godot project" jobs go green on GitHub, with the "Run headless project check" log ending "Headless check passed.") is deferred to end-of-phase UAT per `workflow.human_verify_mode: end-of-phase` — only the user can authorize the push that exercises it.
- Phase 4 (CI-01 through CI-05) still owns `export.yml`, the Linux tar export path, the duplicate-release race in `release.yml`, action SHA pinning (REL-03), and consolidating to a single version source across workflows/docs — none of that is touched here.
- No blockers for the next plan in this phase; this was the last plan (01-05 of 01-3d-foundation-archive).

## Self-Check: PASSED

- All created/modified files verified present on disk (`tests/test_ci_workflows.py`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `CONTRIBUTING.md`, this SUMMARY).
- All four task commits verified present in `git log` (`21f2946`, `4df63fe`, `f852cab`, `c6f663d`).
- Plan-level `<verification>` re-run: `python3 -m unittest -v tests.test_ci_workflows` → 10 tests, all "... ok"; `python3 scripts/tools/quality_gate.py --root .` → "Quality gate passed."; `git diff --quiet archive/2d-alpha-v0.0.3 -- .github/workflows/export.yml` → exits 0 (no diff).
- Orchestrator-required baseline checks re-run and passing: `bash scripts/tools/run_headless_check.sh` → "Headless check passed."; `bash scripts/tools/test_headless_check.sh` → 11/11 PASS, "Headless check self-test passed."; `python3 -m unittest tests.test_quality_gate` → OK (4 tests).

---
*Phase: 01-3d-foundation-archive*
*Completed: 2026-09-11*
