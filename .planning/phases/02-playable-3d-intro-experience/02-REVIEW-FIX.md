---
phase: 02-playable-3d-intro-experience
fixed_at: 2026-09-12T00:00:00Z
review_path: .planning/phases/02-playable-3d-intro-experience/02-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 2: Code Review Fix Report

**Fixed at:** 2026-09-12
**Source review:** .planning/phases/02-playable-3d-intro-experience/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (0 Critical, 1 Warning, 1 Info — no fix_scope restriction applied, both findings addressed)
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: `Collectible.reset()` does not cancel the pickup tween, so a replay during the ~0.3s pickup-feedback window can leave the collectible invisible after reset

**Files modified:** `scripts/collectible.gd`, `scripts/tools/probe_screen_flow.gd`
**Commit:** `43eb7fd`
**Applied fix:** Stored the tween created in `_play_pickup_feedback()` on a new `_pickup_tween: Tween` field. `_play_pickup_feedback()` now kills any prior tween (guarded by `is_valid()`) before creating a new one, and `reset()` kills the in-flight tween first before restoring mesh/visibility state — matching the review's suggested fix and this file's existing style.

Reproduced the race directly rather than trusting the review's description: added a probe case (`collectible_reset_cancels_tween` in `probe_screen_flow.gd`) that triggers a real pickup, moves Camiel off the trigger volume (to avoid a spurious re-trigger confound from `monitoring` flipping back on), and calls `reset()` immediately afterward — while the 0.3s tween is still in flight — then waits well past the tween's duration and asserts the collectible stays visible. Verified this case genuinely fails against the pre-fix `reset()` (`ERROR: ... the pickup tween's queued hide() fired late because reset() did not cancel it (WR-01)`) and passes with the fix, satisfying the instruction not to add a vacuous case.

The review's stated confirmation that this is unreachable through normal play on the shipped level geometry (~5.6m collectible-to-finish distance vs. 0.3s tween window) was left untouched — no level geometry, `steering_mode`, art, or `REQUIRED_PROBES` allow-list was changed.

### IN-01: Dead assignment in the replay handler

**Files modified:** `scripts/intro_level.gd`
**Commit:** `4fcf4a4`
**Applied fix:** Confirmed `_on_finish_marker_finished()` unconditionally resets `%Scrim.modulate.a = 0.0` before its own fade-in tween on every path that shows the win overlay, so `_on_replay_button_pressed()`'s `%Scrim.modulate.a = 1.0` was always overwritten before it could be observed. Removed the dead line rather than adding a defensive comment, per the review's first option — it documented no real intent beyond an already-guaranteed reset.

## Skipped Issues

None — all findings in scope were fixed.

## Final Gate Verification

All four required gates were run on the finished tree (main checkout, no worktree isolation, `main` branch), with real output:

- `bash scripts/tools/run_headless_check.sh` — passes: `[step] import` / `[step] main scene` / `[step] verifier` / `[step] probe probe_audio_buses.gd` / `[step] probe probe_camiel_movement.gd` / `[step] probe probe_menu_button.gd` / `[step] probe probe_screen_flow.gd` / `Headless check passed.`
- `bash scripts/tools/test_headless_check.sh` — all 15 cases pass, ending `Headless check self-test passed.`
- `python3 scripts/tools/quality_gate.py --root .` — `Quality gate passed.`
- `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` — `Ran 14 tests in 0.008s / OK`.

**Reproduction re-verified and closed (WR-01):** with the `reset()`/`_play_pickup_feedback()` tween-kill guards temporarily reverted, `probe_screen_flow.gd` failed at the new `collectible_reset_cancels_tween` case with:

```
PASS collectible
ERROR: collectible_reset_cancels_tween: %Collectible went invisible again after reset() -- the pickup tween's queued hide() fired late because reset() did not cancel it (WR-01)
```

The fix was then restored and the probe re-run to confirm a clean pass (`PASS collectible_reset_cancels_tween`, `Screen flow probe passed.`). `git diff scripts/collectible.gd` after restoration matched the committed fix exactly — the working tree is clean.

---

_Fixed: 2026-09-12_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
