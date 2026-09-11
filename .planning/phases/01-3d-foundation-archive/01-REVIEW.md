---
phase: 01-3d-foundation-archive
reviewed: 2026-09-11T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/release.yml
  - .gitignore
  - CONTRIBUTING.md
  - project.godot
  - scenes/camiel.tscn
  - scenes/test_space.tscn
  - scripts/camiel_controller.gd
  - scripts/tools/probe_camiel_movement.gd
  - scripts/tools/run_headless_check.sh
  - scripts/tools/test_headless_check.sh
  - scripts/tools/verify_3d_project.gd
  - tests/test_ci_workflows.py
findings:
  critical: 2
  warning: 2
  info: 1
  total: 5
status: fixed
fixed_at: 2026-09-11T00:00:00Z
fix_report: 01-REVIEW-FIX.md
---

# Phase 01: Code Review Report

**Reviewed:** 2026-09-11
**Depth:** standard
**Files Reviewed:** 12 (13 listed; `tests/test_ci_workflows.py` counted with the workflow pair it guards)
**Status:** fixed — see `01-REVIEW-FIX.md` for the fix commits and verification.

## Summary

This phase's core safety-net design is sound: the four previously-found defects (camera-relative spin, lambda-capture-by-value in the probe, `resolve_godot`'s silent engine substitution, and the silently-skipped PyYAML test) are all fixed correctly and completely — I traced each fix against its described failure mode and found no residual gap. The supply-chain hardening in `ci.yml`/`release.yml` (SHA512-verify-before-extract, fail-closed on an empty or mismatched hash) is implemented correctly in all four download sites, and the release tag glob (`alpha-v*`, `v*`) cannot match the archived `archive/2d-alpha-v0.0.3` tag, since GitHub Actions tag-glob matching does not let a bare `*` cross a `/` — confirmed by inspection of the trigger and the tag's structure.

However, two real gaps remain in `run_headless_check.sh` itself — the project's stated safety net — that let it report `Headless check passed.` on a genuinely broken project, exactly the failure class this phase exists to close. Both are untested by the 11-case self-test, which is itself evidence they were not deliberately accepted risks.

## Critical Issues

### CR-01: Deleting or renaming the movement probe makes the check silently pass with zero behaviour verification

**File:** `scripts/tools/run_headless_check.sh:202-215`
**Issue:** The probe step discovers behaviour probes with `find "$ROOT/scripts/tools" -maxdepth 1 -type f -name 'probe_*.gd'`. If that glob matches nothing — the probe file is deleted, renamed, moved to a subdirectory, or a future refactor changes the naming convention — the script takes the `[ -z "$PROBE_FILES" ]` branch, prints `No behaviour probes found.`, and falls straight through to `echo "Headless check passed."` / `exit 0`. No probe ever runs, and the check still reports full success. This is the same class of "vacuity" bug the verifier (`verify_3d_project.gd`) explicitly guards against for `.gd`/`.tscn` resources (`_check_resources` fails loudly with `No .gd files found under res://.` / `No .tscn files found under res://.` when its lists are empty), but the exact same guard is missing for the probe-discovery step. None of the 11 cases in `test_headless_check.sh` exercises this direction, which is corroborating evidence this is an oversight rather than an intentional "probes are optional" design (the plan and summaries describe the probe as the check's final, load-bearing behaviour gate, run automatically "as the final step" — not an optional extra).
**Fix:** Fail when no probe file is found, mirroring the existing non-vacuity pattern used elsewhere in the same script and in `verify_3d_project.gd`:
```bash
PROBE_FILES="$(find "$ROOT/scripts/tools" -maxdepth 1 -type f -name 'probe_*.gd' 2>/dev/null | sort)"
if [ -z "$PROBE_FILES" ]; then
	echo "CHECK FAILED: no behaviour probes found under scripts/tools/probe_*.gd."
	exit 1
fi
while IFS= read -r PROBE_PATH; do
	...
done <<<"$PROBE_FILES"
```
Add a 12th self-test case in `test_headless_check.sh` that temporarily removes `scripts/tools/probe_*.gd` from the copied tree and asserts exit 1.

### CR-02: The import step's error-log scan omits the generic `ERROR:` pattern used everywhere else, masking real import failures

**File:** `scripts/tools/run_headless_check.sh:176-180` vs. `:185-190`, `:195-197`, `:211-213`
**Issue:** Every other log-scanning gate in this script checks for all three error markers:
```bash
if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$MAIN_LOG"; then   # main scene, line 188
if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$VERIFY_LOG"; then # verifier, line 195
if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$PROBE_LOG"; then  # probe, line 211
```
but the import step (`--headless --editor --path "$ROOT" --quit`) only checks two of the three:
```bash
if grep -qE 'SCRIPT ERROR|Parse Error' "$IMPORT_LOG"; then
	fail "import" "error pattern found in import log" "$IMPORT_LOG"
fi
```
A generic engine-level import failure that prints as `ERROR: Failed to import resource ...` or `ERROR: Cannot load ...` (not phrased as `SCRIPT ERROR:` or `Parse Error:`) — e.g. a corrupted or unsupported asset that has no `.gd`/`.tscn` extension and is not reachable via `ext_resource` from any tracked scene, so it is never re-touched by `_check_resources()` in `verify_3d_project.gd` — will print during the import pass, be silently ignored by this narrower pattern, and never surface again in any later step. The check would still print `Headless check passed.` Godot's own process exit code for the editor import pass does not reflect such an error (per this phase's own F9 finding that runtime/import script errors don't change exit codes), so the log-scan is the only backstop, and it has a hole here. This is not hypothetical special-casing: nothing in the plan or summaries explains why the import step's pattern set is a strict subset of the other three steps' pattern sets.
**Fix:** Use the same three-pattern scan for the import log as for the other three logs:
```bash
if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$IMPORT_LOG"; then
	fail "import" "error pattern found in import log" "$IMPORT_LOG"
fi
```
If a specific known-benign `ERROR:` line needs to be tolerated during import (verify there is one before assuming so), exclude it by name rather than dropping the whole pattern.

## Warnings

### WR-01: `.gitignore` no longer covers the pre-existing `.planning/state.json`/`.planning/config.json` churn seen at session start, risking noisy diffs

**File:** `.gitignore:22-25`
**Issue:** This phase's `.gitignore` only ignores `.planning/milestone.lock` and `.planning/state.json`, but the git status captured at the start of this session shows both `.planning/config.json` and `.planning/state.json` as untracked working-tree files — `.planning/config.json` is not covered by any of the existing rules. This isn't a defect introduced by code under review, but it is a gap in the exact area (`.gitignore` GSD runtime-state hygiene) that plan 01-01 explicitly patched in this phase ("Added `.gitignore` entries for GSD runtime state"), and it will keep resurfacing as an uncommitted/untracked file in every future `git status`.
**Fix:** Add `.planning/config.json` alongside the existing `.planning/state.json` line if it is genuinely session/PID-scoped runtime state (matching the comment above it), or confirm it is meant to be tracked and remove it from the untracked set intentionally.

### WR-02: `verify_3d_project.gd`'s renderer check accepts a project with no discoverable Jolt-hint fallback silently for `.mobile`/`.web` overrides that aren't written to `project.godot`

**File:** `scripts/tools/verify_3d_project.gd:49-74`
**Issue:** `_check_renderer()` iterates `ProjectSettings.get_property_list()` and only inspects properties whose *name* begins with `rendering/renderer/rendering_method` that the engine actually registers in the running process — this correctly matches the documented F4 behaviour (unset overrides still report their engine default via `get_property_list()`), so the check itself is not wrong. However, the currently committed `project.godot` explicitly writes `renderer/rendering_method.mobile="gl_compatibility"` (line 84) but no `.web` override, which is the opposite asymmetry described in the phase's own engine-facts finding F5 ("only the base key was written ... the `.web` and `.mobile` override keys were not written"). This divergence from the documented baseline is not itself a bug (the verifier still checks the live property list, not the file), but it means the checked-in `project.godot` no longer matches the engine-observed baseline this phase pinned in `01-ENGINE-FACTS.md`, and nothing catches that drift if it becomes meaningful later (e.g. if a future Godot update changes the `.mobile` default away from `gl_compatibility`, only the explicit key would protect against it, while `.web` — with no explicit key — would silently start rendering with a different renderer).
**Fix:** No code change required for correctness today. Consider either (a) explicitly writing all three keys (base, `.mobile`, `.web`) for symmetry and future-update safety, or (b) documenting in `01-ENGINE-FACTS.md`/a follow-up note why `.mobile` is explicit and `.web` is not, so a future contributor doesn't assume this was accidental.

## Info

### IN-01: Redundant script re-assignment on the instanced `Camiel` node in `test_space.tscn`

**File:** `scenes/test_space.tscn:59-61`
**Issue:** The instanced `Camiel` node already carries `script = ExtResource("1_c7np5")` (pointing at `camiel_controller.gd`) from its own scene definition in `camiel.tscn`. `test_space.tscn` re-declares the identical script as an instance override (`script = ExtResource("3_frqla")`, importing the same `res://scripts/camiel_controller.gd` path under a different resource id). This is harmless (same script, same behaviour) but is dead weight from the scene-generation script and slightly obscures scene diffs.
**Fix:** Drop the redundant `script = ExtResource("3_frqla")` override and the now-unused `[ext_resource type="Script" ... id="3_frqla"]` declaration from `test_space.tscn`; the instanced scene already supplies the script.

---

_Reviewed: 2026-09-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
