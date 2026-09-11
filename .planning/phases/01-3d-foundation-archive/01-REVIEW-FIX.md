---
phase: 01-3d-foundation-archive
fixed_at: 2026-09-11T00:00:00Z
review_path: .planning/phases/01-3d-foundation-archive/01-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 01: Code Review Fix Report

**Fixed at:** 2026-09-11
**Source review:** .planning/phases/01-3d-foundation-archive/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (2 Critical, 2 Warning, 1 Info — the Info finding was trivially safe and scoped to one file, so it was fixed rather than skipped)
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Deleting or renaming the movement probe makes the check silently pass with zero behaviour verification

**Files modified:** `scripts/tools/run_headless_check.sh`, `scripts/tools/test_headless_check.sh`
**Commit:** `753eb2b`
**Applied fix:** Reproduced the vacuity bug independently (moving `probe_camiel_movement.gd` out of the tree still printed "Headless check passed." / exit 0). Changed the probe-discovery step to `exit 1` with `CHECK FAILED: no behaviour probes found under scripts/tools/probe_*.gd.` when the `probe_*.gd` glob matches nothing, mirroring the non-vacuity guard `verify_3d_project.gd::_check_resources()` already uses for its `.gd`/`.tscn` lists. Added self-test case 12 (proven RED against the old code, GREEN after the fix) that removes all `probe_*.gd` files from the copied tree and asserts exit 1.

### CR-02: The import step's error-log scan omits the generic `ERROR:` pattern used everywhere else, masking real import failures

**Files modified:** `scripts/tools/run_headless_check.sh`, `scripts/tools/test_headless_check.sh`, `export_presets.cfg`
**Commit:** `8461a6e`
**Applied fix:** Widened the import log grep to `SCRIPT ERROR|Parse Error|ERROR:`, matching the other three log-scanning gates. Reproduced the masked-failure class with a corrupted PNG fixture (unreachable from any tracked scene) — confirmed the check reported "Headless check passed." with exit 0 despite a genuine `ERROR:` import-log line before the fix. Widening the grep uncovered a real, previously-masked pre-existing defect: `export_presets.cfg` used markdown-style `##` comments, which Godot's `ConfigFile` parser (only `;` is valid, per `project.godot`'s own header) fails on with `ERROR: ConfigFile parse error at res://export_presets.cfg:179: Unexpected identifier 'Android'.` on every import pass since alpha-v0.0.4 (`754b99d`). Fixed the 12 `##` comment lines to `;` so the corrected grep does not produce a false failure on an otherwise-clean tree (per the instruction to diagnose real gaps rather than relax the new assertion). Added self-test case 13 (RED against the old code, GREEN after the fix) using the corrupted-PNG fixture.

### WR-01: `.gitignore` no longer covers the pre-existing `.planning/state.json`/`.planning/config.json` churn

**Files modified:** `.gitignore`, `.planning/config.json` (untracked)
**Commit:** `dda3f5d`
**Applied fix:** Investigated current state: `.planning/config.json` was already tracked (committed in `4867824` as an acknowledged stopgap deviation to satisfy a clean-tree precondition for an unrelated task) despite being session/PID-scoped GSD runtime bookkeeping (currently just `{"workflow": {"_auto_chain_active": false}}`) — the same class of file `.planning/state.json` is already ignored for. Added `.planning/config.json` to `.gitignore` alongside `.planning/state.json` and ran `git rm --cached` to stop tracking it, leaving it present on disk for the running session but no longer a source of future noisy diffs.

### WR-02: `verify_3d_project.gd`'s renderer check accepts a `project.godot` that diverges from the pinned F5 baseline for `.mobile`/`.web` overrides

**Files modified:** `project.godot`
**Commit:** `11e5ac6`
**Applied fix:** Confirmed via `git log` that Plan 01-03 intended every F4-listed `rendering/renderer/rendering_method*` key (base, `.mobile`, `.web`) to be set explicitly (per `01-03-PLAN.md`'s own D-04 wording), but only base and `.mobile` were ever written — `.web` was missed. Added `renderer/rendering_method.web="gl_compatibility"` for symmetry with `.mobile` and with the plan's original intent, protecting `.web` against a future engine-default change the same way `.mobile` already is. `config_version=5` and all other pinned settings left untouched. Re-ran `scripts/tools/run_headless_check.sh` after the edit: passes clean.

### IN-01: Redundant script re-assignment on the instanced `Camiel` node in `test_space.tscn`

**Files modified:** `scenes/test_space.tscn`
**Commit:** `53aadc0`
**Applied fix:** Confirmed the instanced `Camiel` node already carries `camiel_controller.gd` from `camiel.tscn`. Dropped the redundant `[ext_resource type="Script" ... id="3_frqla"]` declaration and its `script = ExtResource("3_frqla")` override in `test_space.tscn`; confirmed no remaining references to `3_frqla` anywhere under `scenes/`. This was a single-file, single-line-pair removal with no functional effect (same script, same behaviour), so it was treated as trivially safe and fixed rather than skipped. Re-ran `scripts/tools/run_headless_check.sh` after the edit: passes clean.

## Skipped Issues

None — all findings in scope were fixed.

## Final Gate Verification

All four required gates were run on the finished tree, with real output:

- `bash scripts/tools/run_headless_check.sh` — passes: `[step] import` / `[step] main scene` / `[step] verifier` / `[step] probe probe_camiel_movement.gd` / `Headless check passed.`
- `bash scripts/tools/test_headless_check.sh` — all 13 cases pass (`Headless check self-test passed.`), up from 11 before this fix pass (cases 12 and 13 added for CR-01 and CR-02).
- `python3 scripts/tools/quality_gate.py --root .` — `Quality gate passed.`
- `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` — `Ran 14 tests in 0.007s / OK`.

**Reproduction re-verified and closed:** `probe_camiel_movement.gd` (and its `.uid` sidecar) was moved out of `scripts/tools/` and the check was re-run:

```
[step] import
[step] main scene
[step] verifier
CHECK FAILED: no behaviour probes found under scripts/tools/probe_*.gd.
EXIT=1
```

The probe file was then restored and the check re-run to confirm a clean pass (`EXIT=0`). `git status --short scripts/tools/` showed no diff after restoration — the working tree is clean.

---

_Fixed: 2026-09-11_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
