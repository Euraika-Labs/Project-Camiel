---
phase: "1"
slug: "3d-foundation-archive"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-11"
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `01-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None for GDScript (no GUT/GdUnit4 — out of scope per D-09). Python stdlib `unittest` for `tests/test_quality_gate.py`. |
| **Config file** | none — Wave 0 adds the headless check wrapper and verifier script |
| **Quick run command** | `python3 scripts/tools/quality_gate.py --root .` (no Godot needed) |
| **Full suite command** | `scripts/tools/run_headless_check.sh` (import pass + timed main-scene run + log grep + `--script` verifier; exact name at planner discretion) |
| **Estimated runtime** | ~60 seconds (bounded by the `timeout 60` wrapper, D-03) |

---

## Sampling Rate

- **After every task commit:** Run `python3 scripts/tools/quality_gate.py --root .`, plus the headless check once Godot 4.7.2 is installed locally
- **After every plan wave:** Run the full headless check (import + timed run + verifier script)
- **Before `/gsd-verify-work`:** Full headless check must be green, plus the D-11 manual playtest
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

Task IDs are assigned by the planner; rows below are seeded per requirement and are refined once PLAN.md files exist.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01-01 | 1 | FOUND-01 | T-01-02, T-01-03 | Annotated tag whose name matches no release trigger | smoke (git) | `test "$(git cat-file -t archive/2d-alpha-v0.0.3)" = tag && git merge-base --is-ancestor archive/2d-alpha-v0.0.3 HEAD` | ✅ | ⬜ pending |
| 01-01-T3 | 01-01 | 1 | FOUND-02 | T-01-01, T-01-04 | Removal only after the blocking-human checkpoint; no dangling res:// paths | automated (existing tool) | `python3 scripts/tools/quality_gate.py --root .` | ✅ | ⬜ pending |
| 01-02-T1 | 01-02 | 1 | FOUND-04 | T-01-SC | Engine zip SHA512 and code signature verified | smoke (CLI) | `/Applications/Godot.app/Contents/MacOS/Godot --version` (starts with 4.7.2.stable) | ✅ | ⬜ pending |
| 01-02-T2 | 01-02 | 1 | FOUND-06 | T-01-06 | Stall soak runs under a watchdog (D-03) | smoke (facts file) | `grep -qx 'Soak verdict: no-stall' .planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md` | ❌ W0 | ⬜ pending |
| 01-03-T1 | 01-03 | 2 | FOUND-03, FOUND-04, FOUND-06 | T-01-09 | Check fails on a planted parse error (red proof) | automated (new script) | `bash scripts/tools/run_headless_check.sh` | ❌ W0 | ⬜ pending |
| 01-03-T2 | 01-03 | 2 | FOUND-03, FOUND-04, FOUND-06 | T-01-09, T-01-10, T-01-11 | Every failure direction of the check proven | automated (self-test) | `bash scripts/tools/test_headless_check.sh` | ❌ W0 | ⬜ pending |
| 01-04-T1 | 01-04 | 3 | FOUND-05 | — | N/A | automated (headless probe) | `bash scripts/tools/run_headless_check.sh` (PASS lines from probe_camiel_movement.gd) | ❌ W0 | ⬜ pending |
| 01-04-T2 | 01-04 | 3 | FOUND-05 | T-01-14, T-01-15, T-01-16 | Fall return cannot loop; steering argument parsing bounded | automated (headless probe) | `bash scripts/tools/run_headless_check.sh` | ❌ W0 | ⬜ pending |
| 01-05-T1 | 01-05 | 3 | FOUND-06 | T-01-SC2, T-01-18 | CI engine downloads SHA512-verified; check step pinned by test | automated (unittest) | `python3 -m unittest -v tests.test_ci_workflows` | ❌ W0 | ⬜ pending |
| 01-05-T2 | 01-05 | 3 | FOUND-04, FOUND-06 | T-01-SC2 | Release verifies with the same check | automated (unittest) | `python3 -m unittest -v tests.test_ci_workflows` | ❌ W0 | ⬜ pending |
| 01-06-T1 | 01-06 | 4 | FOUND-05, FOUND-06 | — | N/A | automated (final gate) | `bash scripts/tools/run_headless_check.sh && bash scripts/tools/test_headless_check.sh` | ❌ W0 | ⬜ pending |
| 01-06-T2 | 01-06 | 4 | FOUND-05 | T-01-21 | Playtest cannot be auto-approved | manual-only (D-11 playtest) | N/A, closed by the D-11 playtest | — | ⬜ pending |
| 01-06-T3 | 01-06 | 4 | FOUND-05 | — | N/A | automated | `bash scripts/tools/run_headless_check.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Godot 4.7.2 local install (D-08) — blocks running any headless command below
- [ ] `scripts/tools/run_headless_check.sh` (or equivalent name) — FOUND-06 import + timeout + log-grep steps
- [ ] `scripts/tools/verify_3d_project.gd` (or equivalent `verb_noun.gd` name) — FOUND-06 `--script` loader/instantiator, generalizing `verify_camiel_resources.gd`

*No GDScript unit-test framework install is needed for Phase 1.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Capsule Camiel moves freely in all directions; camera follows behind | FOUND-05 | Movement feel for a ~3-year-old is not meaningfully automatable; D-11 mandates a human playtest | Run the 3D test scene in Godot 4.7.2, move Camiel in every direction with the mapped controls, confirm the camera stays behind Camiel and does not clip through walls |
| User confirms removal of 2D content before deletion | FOUND-02 | Explicit human confirmation is part of the requirement | Checkpoint before the removal task: confirm the archive tag exists, then approve removal |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
