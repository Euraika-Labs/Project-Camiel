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
| TBD | TBD | TBD | FOUND-01 | — | N/A | smoke (git) | `git tag -l archive/2d-alpha-v0.0.3 && git rev-parse archive/2d-alpha-v0.0.3` | ✅ | ⬜ pending |
| TBD | TBD | TBD | FOUND-02 | — | N/A | automated (existing tool) | `python3 scripts/tools/quality_gate.py --root .` | ✅ | ⬜ pending |
| TBD | TBD | TBD | FOUND-03 | — | N/A | automated (grep) | `grep -q 'renderer/rendering_method="gl_compatibility"' project.godot && ! grep -q 'Forward Plus' project.godot` | ✅ | ⬜ pending |
| TBD | TBD | TBD | FOUND-04 | — | N/A | automated (headless import) | `godot --headless --editor --path . --quit` (exit 0, no import errors in log) | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FOUND-05 | — | N/A | manual-only | N/A — closed by D-11 playtest | — | ⬜ pending |
| TBD | TBD | TBD | FOUND-06 | — | N/A | automated (new script) | `scripts/tools/run_headless_check.sh` | ❌ W0 | ⬜ pending |

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
