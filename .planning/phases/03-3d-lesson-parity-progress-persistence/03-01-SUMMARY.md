---
phase: 03-3d-lesson-parity-progress-persistence
plan: 01
subsystem: persistence
tags: [godot, gdscript, json, autoload, headless-probe]

requires:
  - phase: 01-playable-intro-path
    provides: run_headless_check.sh's watchdog/log-scan chain and the probe_*.gd case-runner shape (probe_screen_flow.gd)
  - phase: 02-title-menu-intro-level
    provides: AudioManager as the precedent autoload registration pattern in project.godot
provides:
  - ProgressTracker autoload (scripts/progress_tracker.gd) — atomic write, fail-soft read, append-log schema
  - scripts/tools/probe_progress_persistence.gd — headless proof of first-run silence, write-then-reread, second-write, and corrupt-file recovery
affects: [03-03 (lesson tracer calling record_lesson_complete), 08-parent-dashboard (reads this schema)]

actuals:
  tokens: 42000
  tasks: 2
  commits: 2
  plan_head_before: 67061b9

tech-stack:
  added: []
  patterns:
    - "JSON.new().parse(text) for any fail-soft file read, never the static JSON.parse_string() (its ERROR: log line trips this repo's headless check even on correct recovery)"
    - "atomic write: stringify to a .tmp path, then DirAccess.rename_absolute() over the real path"
    - "probe save-file hygiene: rename-aside backup before cases, restore as the first statement of both the success path and _fail()"

key-files:
  created:
    - scripts/progress_tracker.gd
    - scripts/tools/probe_progress_persistence.gd
  modified:
    - project.godot

key-decisions:
  - "D-39/D-40/D-41/D-42 implemented exactly as locked in 03-CONTEXT.md and confirmed 'as locked' at Task 1's checkpoint (resolved before this executor was spawned) — append-log array, top-level version field, flat 3 stars, four fields per entry, no child-identifying data"
  - "RED evidence for the corrupt-file case was produced by temporarily reverting _load_entries() to the archived bug's JSON.parse_string() call, running the full headless check, observing it go CHECK FAILED on the exact 'ERROR: Parse JSON failed' line despite correct recovery, then reverting — confirmed byte-identical to the committed file afterward"
  - "The Task 3 deliberate-failure exercise forced a false assertion (version != 2) to prove the probe's failure funnel actually restores a real save file; verified via a SHA-256 checksum of the pre-existing real progress.json taken before the forced failure and matched byte-identical afterward, with the backup and tmp paths both gone"

requirements-completed: [PROGRESS-01, PROGRESS-02]

coverage:
  - id: D1
    description: "ProgressTracker registered as an autoload; project boots with it present, and neither a missing nor a corrupt progress file produces an engine error line"
    requirement: PROGRESS-01
    verification:
      - kind: integration
        ref: "scripts/tools/probe_progress_persistence.gd#_case_first_run_is_silent"
        status: pass
      - kind: integration
        ref: "scripts/tools/probe_progress_persistence.gd#_case_corrupt_file_recovers_silently"
        status: pass
      - kind: integration
        ref: "bash scripts/tools/run_headless_check.sh (own ERROR:/SCRIPT ERROR:/Parse Error: log scan across every step)"
        status: pass
    human_judgment: false
  - id: D2
    description: "One recorded completion writes lesson_id, stars, time_seconds, completed_at — proved by re-reading user://progress.json from disk, not by a signal firing (D-42)"
    requirement: PROGRESS-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_progress_persistence.gd#_case_write_then_reread"
        status: pass
    human_judgment: false
  - id: D3
    description: "Write is atomic (D-39): a second completion renames over the existing file and the result holds both entries in order, not a merge or truncation"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_progress_persistence.gd#_case_second_write_replaces_and_keeps_both"
        status: pass
    human_judgment: false
  - id: D4
    description: "Schema is a version field plus an append-log array (D-40); stars is a flat, deterministic 3 with no derivation anywhere in the code (D-41)"
    verification:
      - kind: unit
        ref: "grep acceptance criteria on scripts/progress_tracker.gd: zero occurrences of get_ticks_msec|par_time|accuracy, presence of \"version\""
        status: pass
    human_judgment: false
  - id: D5
    description: "The probe's save-file hygiene (backup before cases, restore on both success and failure) actually protects a real child's save, proven by forcing a failure"
    verification:
      - kind: manual_procedural
        ref: "this SUMMARY's Deviations section, 'Deliberate-failure exercise' — SHA-256 checksum of the real progress.json matched before and after a forced check failure"
        status: pass
    human_judgment: true
    rationale: "Executed once interactively this session via a temporary code change that was reverted, not wired into the permanent automated suite (D-38-style design choice: baking a permanent deliberate failure into the probe would itself be a stub). A human should confirm the reasoning holds, not just the exit code."

duration: 55min
completed: 2026-09-12
status: complete
---

# Phase 3 Plan 1: Progress Persistence Summary

**ProgressTracker autoload with atomic tmp-then-rename writes, an append-log schema, and a headless probe that re-reads real disk bytes after every write path — including first-run, second-write, and two shapes of corrupt file.**

## Performance

- **Duration:** ~55 min (continuation from a resolved Task 1 checkpoint; Tasks 2 and 3 only)
- **Tasks:** 2 completed (Task 1's checkpoint was already resolved by the user before this executor was spawned, with zero files written)
- **Files modified:** 5 (`project.godot`, `scripts/progress_tracker.gd` + `.uid`, `scripts/tools/probe_progress_persistence.gd` + `.uid`)

## Accomplishments

- `scripts/progress_tracker.gd`: a from-scratch autoload that does not repeat any of the three archived defects (nonexistent JSON constant, never-called record function, no schema version / no atomic write)
- Registered `ProgressTracker="*res://scripts/progress_tracker.gd"` in `project.godot`'s autoload section, directly after `AudioManager`, as a plain text edit (no `ProjectSettings.save()`, per plan 02-03's precedent)
- `scripts/tools/probe_progress_persistence.gd`: four cases proving first-run silence, a write-then-reread round trip with all four required fields (D-42), a second write that keeps both entries (D-39), and silent recovery from two different corrupt-file shapes — with backup/restore hygiene around a real child's save file on both the success and failure paths

## Task Commits

1. **Task 2: One recorded completion, read back off the disk with all four fields** - `ebb798c` (feat)
2. **Task 3: A missing file and a corrupt file both start clean, and a second write keeps the first** - `3cf0c63` (test)

_Task 3 is a `test(...)`-scoped commit because its only code change was to the probe; `scripts/progress_tracker.gd` is byte-identical to Task 2's commit (confirmed via `git diff`) once this task's RED demonstration was reverted._

## RED Evidence

**Task 2 — RED (tracker does not exist yet):**

A stub probe was written first, referencing `res://scripts/progress_tracker.gd` before it existed. Running the check produced, in the probe's own log:

```
ERROR: Attempt to open script 'res://scripts/progress_tracker.gd' resulted in error 'File not found'.
ERROR: Failed loading resource: res://scripts/progress_tracker.gd.
SCRIPT ERROR: Cannot call method 'new' on a null value.
```

This confirmed the check fails for the right reason (the tracker's absence) before any implementation existed.

**Task 3 — RED (the corrupt-file case actually exercises the load-bearing decision):**

Before writing the new cases as final, `scripts/progress_tracker.gd`'s `_load_entries()` was temporarily reverted to use the static `JSON.parse_string()` (the archived code's shape) instead of the instance parser. Running the full `bash scripts/tools/run_headless_check.sh` with that regression in place produced:

```
[step] probe probe_progress_persistence.gd
CHECK FAILED: probe probe_progress_persistence.gd: error pattern found in probe log
ERROR: Parse JSON failed. Error at line 0: Expected '}'
   at: parse_string (core/io/json.cpp:629)
...
PASS corrupt_file_recovers_silently
Progress persistence probe passed.
Logs kept at: /var/folders/.../tmp.ouXPttG0QL
EXIT:1
```

The probe's own assertions still reported `PASS corrupt_file_recovers_silently` (the tracker's fail-soft recovery *did* work), but the check as a whole went `CHECK FAILED` / exit 1 because `run_headless_check.sh`'s log scan caught the `ERROR:` line — proving PROGRESS-01's "no error" contract depends specifically on the instance parser, not merely on the recovery logic being correct. `_load_entries()` was reverted immediately afterward; `git diff scripts/progress_tracker.gd` showed no change against the committed Task 2 version.

## GREEN Evidence

Direct probe invocation (`godot --headless --fixed-fps 60 --path . --script res://scripts/tools/probe_progress_persistence.gd`) after implementation:

```
PASS first_run_is_silent
[probe_progress_persistence] user data dir: /Users/bert/Library/Application Support/Godot/app_userdata/Camiel alpha-v0.0.3
[probe_progress_persistence] progress.json after write_then_reread: {
	"entries": [
		{
			"completed_at": "2026-09-12T23:45:25",
			"lesson_id": "lesson_1",
			"stars": 3.0,
			"time_seconds": 42.5
		}
	],
	"version": 1.0
}
PASS write_then_reread
PASS second_write_replaces_and_keeps_both
PASS corrupt_file_recovers_silently
Progress persistence probe passed.
```

(`stars`/`version` print as `3.0`/`1.0` because the probe re-parses the file through `JSON.new().parse()` before printing, and Godot's JSON module returns all numbers as float on parse — the on-disk bytes themselves store plain JSON integers, as written by `JSON.stringify()`.)

**Absolute user data directory observed on this machine:**
`/Users/bert/Library/Application Support/Godot/app_userdata/Camiel alpha-v0.0.3`

`bash scripts/tools/run_headless_check.sh` passed end-to-end after Task 2 and again after Task 3, both times printing `Headless check passed.` with all probe steps green.

## Deliberate-Failure Exercise (Task 3, step C)

To prove the probe's failure funnel actually restores a real save file (not just the success path), a real pre-existing `user://progress.json` was present on this machine from an earlier session (two entries, `lesson_1`/`lesson_2`). Its checksum was recorded before the exercise:

```
SHA-256 before: a94b64beb49a8b8310645cc59dcf4788a0c615225743ff1dbb28198df2eb773e
```

A deliberate assertion failure was injected into `_case_write_then_reread()` (`int(data.get("version", -1)) != 2` instead of `!= 1`, correct value commented inline). Running `bash scripts/tools/run_headless_check.sh` produced:

```
CHECK FAILED: probe probe_progress_persistence.gd: Godot exited with status 1
ERROR: write_then_reread: version was 1.0, expected 1
   at: push_error (core/variant/variant_utility.cpp:1023)
   GDScript backtrace (most recent call first):
       [0] _fail (res://scripts/tools/probe_progress_persistence.gd:50)
       [1] _case_write_then_reread (...)
EXIT:1
```

After the failure, the real file's checksum matched exactly, and both transient paths were gone:

```
SHA-256 after:  a94b64beb49a8b8310645cc59dcf4788a0c615225743ff1dbb28198df2eb773e   (identical)
progress.json.probe_backup: gone
progress.json.tmp: gone
```

This confirms `_fail()`'s first statement (`_restore_progress_backup()`) genuinely runs the restore on the failure path, not just on success. The deliberate failure was then removed; the probe file committed in Task 3 carries no trace of it (`grep -n "DELIBERATE-FAILURE-EXERCISE"` finds nothing).

## Files Created/Modified

- `scripts/progress_tracker.gd` - Autoload: `record_lesson_complete`, `get_entries`, atomic `_write_entries`, fail-soft `_load_entries` using `JSON.new().parse()`
- `scripts/tools/probe_progress_persistence.gd` - Four cases plus backup/restore hygiene helpers, run by `run_headless_check.sh`'s `probe_*.gd` glob
- `project.godot` - One new autoload line; `config_version`, `config/name`, and every other line unchanged (verified by `git diff`)

## Decisions Made

- D-39, D-40, D-41, D-42 implemented exactly as locked in `03-CONTEXT.md`; Task 1's checkpoint (already resolved before this executor started, per the resume instructions) confirmed the schema "as locked" with zero files written beforehand.
- RED evidence for the corrupt-file recovery path was produced by a temporary, fully-reverted regression to the archived bug's parser call, rather than skipped — this is the one case in the plan explicitly flagged as needing genuine proof it measures something real.

## Deviations from Plan

None — plan executed exactly as written for Tasks 2 and 3. Task 1's checkpoint was resolved by the user before this executor was spawned; this executor made no schema decisions of its own.

### Accepted, Not Fixed

**Probe-presence guard gap (carried over from Phase 2, `02-05-SUMMARY.md`, and named again in `03-VALIDATION.md`).** `run_headless_check.sh`'s `REQUIRED_PROBES` named-probe allow-list is still deliberately absent. With five probes now on disk (four legacy plus this one), deleting `probe_progress_persistence.gd` entirely would still leave the `probe_*.gd` glob non-empty, and the check would pass green with this plan's whole PROGRESS-01/PROGRESS-02 coverage silently gone. This is explicitly out of scope for Phase 3 per `03-VALIDATION.md`'s sign-off checklist ("The probe-presence guard gap above explicitly accepted by the planner (not implemented this phase)") and remains tracked in `STATE.md`'s Pending Todos.

---

**Total deviations:** 0. **Impact:** None — plan executed as written.

## Issues Encountered

None. Both tasks completed on the first implementation pass; the only non-linear work was the two intentional, fully-reverted regressions used to produce genuine RED/failure-path evidence (documented above), neither of which left any trace in the committed code.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The persistence mechanism (PROGRESS-01, PROGRESS-02's mechanism half) is complete and proven against real disk bytes. Plan 03-03's tracer lesson is the first real caller of `ProgressTracker.record_lesson_complete(...)`, closing PROGRESS-02's full-stack half.
- Cross-phase hazard carried forward unchanged: `project.godot`'s `config/name` still determines `OS.get_user_data_dir()`; this plan's prohibition against touching it while wiring the autoload was honored (`git diff` shows no change to `config/name` or any custom user directory setting). Phase 4's CI-02 work inherits this risk, not this plan.
- No blockers for the next wave.

## Self-Check: PASSED

- `scripts/progress_tracker.gd` — FOUND
- `scripts/progress_tracker.gd.uid` — FOUND
- `scripts/tools/probe_progress_persistence.gd` — FOUND
- `scripts/tools/probe_progress_persistence.gd.uid` — FOUND
- Commit `ebb798c` — FOUND in `git log --oneline --all`
- Commit `3cf0c63` — FOUND in `git log --oneline --all`
- All acceptance criteria from Task 2 and Task 3 re-verified via the exact `grep`/`test` commands in `03-01-PLAN.md` — all PASS
- `bash scripts/tools/run_headless_check.sh` — PASSED (exit 0, `Headless check passed.`)
- `bash scripts/tools/test_headless_check.sh` — PASSED (exit 0, `Headless check self-test passed.`, all 15 cases)
- `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` — PASSED (14 tests, OK)
- `python3 scripts/tools/quality_gate.py --root .` — PASSED (`Quality gate passed.`)

---
*Phase: 03-3d-lesson-parity-progress-persistence*
*Completed: 2026-09-12*
