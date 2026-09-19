---
phase: "3"
slug: "3d-lesson-parity-progress-persistence"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-12"
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `03-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Still none for GDScript — the headless check chain remains the de facto framework: `run_headless_check.sh` (import → main scene → `verify_3d_project.gd` → every `probe_*.gd`) + `test_headless_check.sh` self-test. Python stdlib `unittest` for `tests/test_quality_gate.py`, unchanged. |
| **Config file** | none |
| **Quick run command** | `python3 scripts/tools/quality_gate.py --root .` |
| **Full suite command** | `bash scripts/tools/run_headless_check.sh` (unchanged invocation; probe glob grows from 2 probes to 5) |
| **Estimated runtime** | Same watchdog ceilings as Phase 2 (`IMPORT_LIMIT=180s`, `RUN_LIMIT=60s`, `VERIFY_LIMIT=60s`, `PROBE_LIMIT=120s` per probe); observed real runtime stays low-single-digit-seconds per probe once assets import cleanly (Phase 1/2 precedent) — no new asset-import-heavy work this phase (no new audio/textures), so no material runtime growth expected beyond 3 more probe invocations at ~120s ceiling each (worst case), a few seconds in practice. |

---

## Sampling Rate

- **After every task commit:** Run `python3 scripts/tools/quality_gate.py --root .`
- **After every plan wave:** Run `bash scripts/tools/run_headless_check.sh`
- **Before `/gsd-verify-work`:** `bash scripts/tools/run_headless_check.sh && bash scripts/tools/test_headless_check.sh` green, plus `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows`, plus one short human playtest (all 5 lessons reachable and completable, progress visibly persists across a relaunch — the one thing headless probes cannot observe: a real second process launch reading back the first process's write)
- **Max feedback latency:** ~150-200s (full-suite observed ceiling, 5 probes instead of 2)

---

## Per-Task Verification Map

Task IDs become `03-0X-TY` once PLAN.md files exist (assigned at planning). Rows map each
in-scope requirement to a test type and an already-runnable command; the planner attaches IDs
directly.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| assigned at planning | assigned at planning | Wave 0 | LESSON-01 | — | L1 completes regardless of task order | automated (headless probe) | `bash scripts/tools/run_headless_check.sh` (`probe_lesson_order.gd`'s L1 any-order case) | ❌ Wave 0 — probe doesn't exist | ⬜ pending |
| assigned at planning | assigned at planning | after Wave 0 | LESSON-02 | — | L2 only completes circle→square→triangle in order; an out-of-order touch does nothing (D-38 `rejected` signal) | automated (headless probe, incl. negative case) | same file, L2 case (Q2 shape) | ❌ Wave 0 | ⬜ pending |
| assigned at planning | assigned at planning | after Wave 0 | LESSON-03 | — | L3 only completes in defined order; an out-of-order touch does nothing (D-38 `rejected` signal) | automated (headless probe, incl. negative case) | same file, L3 case | ❌ Wave 0 | ⬜ pending |
| assigned at planning | assigned at planning | after Wave 0 | LESSON-04 | — | Real, completable second colour+count task | automated (headless probe) | same file, L4 case (reuses L1's assertion shape) | ❌ Wave 0 | ⬜ pending |
| assigned at planning | assigned at planning | after Wave 0 | LESSON-05 | — | Real, completable four-step sequence; an out-of-order touch does nothing (D-38 `rejected` signal) | automated (headless probe, incl. negative case) | same file, L5 case (reuses L3's assertion shape, `total=4` per Pitfall 8) | ❌ Wave 0 | ⬜ pending |
| assigned at planning | assigned at planning | convergent (last) | LESSON-06 | — | Lesson-select reachable, all 5 by tap/click/keyboard | automated (headless probe) | `probe_lesson_select.gd` — focus-order traversal + each button's `transition_requested` (Q1's pattern from `02-RESEARCH.md`) | ❌ Wave 0 | ⬜ pending |
| assigned at planning | assigned at planning | Wave 0 | PROGRESS-01 | — | Tracker initializes without script error, including on a corrupt `progress.json` | automated (headless probe + log-scan) | `run_headless_check.sh`'s own `ERROR:`/`SCRIPT ERROR:`/`Parse Error:` grep across every log, plus `probe_progress_persistence.gd`'s first-run/corrupt-file cases (PF4-PF6) | ❌ Wave 0 | ⬜ pending |
| assigned at planning | assigned at planning | convergent (last) | PROGRESS-02 | — | Completion writes all 4 fields (`lesson_id`, `stars`, `time_seconds`, `completed_at`) to `user://progress.json`, verified by re-reading the file from disk (D-42), not by a signal firing | automated (headless probe, re-reads disk per D-42) | `probe_progress_persistence.gd`'s post-completion re-read case (Q1) | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Binding rules any probe touching these requirements must follow

1. **`JSON.parse_string()` must NOT be used for reading `progress.json`.** It prints an engine
   `ERROR:` line on corrupt input even though it returns `null` cleanly, which would fail
   `run_headless_check.sh`'s log scan on *correct* recovery behaviour. Use the instance method
   `JSON.new().parse(text)`, which returns an `Error` code silently. This determines whether
   PROGRESS-01 ("no error from the progress-tracking system") can pass at all under CI.
2. **D-42: the probe must re-read `user://progress.json` from disk** after a real lesson
   completion and assert all four fields (`lesson_id`, `stars`, `time_seconds`, `completed_at`).
   Asserting only that a `progress_saved` signal fired is explicitly rejected — it would pass
   while nothing was written, which is exactly what the 2D code did.
3. **Ordered lessons need a negative case.** For L2, L3 and L5, a deliberately out-of-order touch
   must be proven to do nothing (D-38's `rejected` signal). A case that only asserts eventual
   completion reproduces the check-that-passes-without-checking pattern this phase exists to
   eliminate.

### One gap the planner must explicitly close or accept

**Probe-presence guard gap (carried over from Phase 2, still unresolved).** The `REQUIRED_PROBES`
by-name allow-list that would make `run_headless_check.sh`'s non-vacuity guard fail when a
*specific* probe (not just the whole glob) goes missing is still deliberately absent — a
follow-up is recorded in STATE.md. Do not propose implementing it in this phase. With five probes
instead of two, this gap widens (deleting any one of five leaves the glob non-empty and the check
green with a whole probe's assertions silently gone); accept this as a known, tracked risk rather
than in-scope work.

---

## Wave 0 Requirements

- [ ] `scripts/lesson_target.gd` (Q4) — blocks every lesson build.
- [ ] `scripts/progress_tracker.gd` (Q1) — blocks every lesson's completion handler and both
      PROGRESS probes.
- [ ] `scenes/lesson_select.tscn` + `scripts/lesson_select.gd` (Q3) — blocks LESSON-06's probe
      and the "Lessen" button wiring on `main_menu.tscn`.
- [ ] Godot 4.7.2 local install — unchanged carry-over prerequisite.

*Everything else (the five lesson scenes' exact geometry, icon content, Dutch strings) is
ordinary plan/task work, verified incrementally per lesson as each lands.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| Progress genuinely persists across a real app relaunch (not just within one headless process) | PROGRESS-02 | A `--headless --script` probe writes and reads within the same process; it cannot prove the OS-level file survives a full process exit and a fresh launch reading `user://` fresh, though PF1-PF8 make this very low-risk given the mechanism is plain `FileAccess` on a real path | Launch the built game, complete one lesson, quit fully, relaunch, and (informally, e.g. via a debug print or the eventual Phase 8 dashboard) confirm the entry is still present |
| All 5 lessons feel completable and fair to a real child, tap/click/keyboard | LESSON-01..06 | Feel and pacing cannot be judged headlessly (headless audio/display stand-ins, no real display) | Play through lesson-select → each of the 5 lessons → confirm completion, using both pointer and keyboard at least once |

---

## Known Risk — Not This Phase's Fix

**Cross-phase hazard (reproduced, not theoretical):** changing `project.godot`'s `config/name`
changes `OS.get_user_data_dir()` and orphans a previously written `progress.json` — the new user
data directory starts empty, silently losing the old save. Phase 4's CI-02 work can trigger this
by touching `project.godot`. This phase's `progress_tracker.gd` and probes assume a stable
`config/name`; if Phase 4 renames the project, its own plan must account for migrating or
re-validating `progress.json`, not this phase's.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 200s
- [ ] The probe-presence guard gap above explicitly accepted by the planner (not implemented this phase)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
