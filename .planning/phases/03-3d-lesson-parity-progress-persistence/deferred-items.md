# Phase 3 — Deferred Items

Out-of-scope discoveries logged during execution rather than fixed. Each names where it
was seen, why it was not this plan's to fix, and what the fix would be if it recurs.

## Intermittent Jolt job-system warning under `probe_lesson_order.gd`

**Found during:** plan 03-04, one run out of six.

One invocation of `probe_lesson_order.gd` printed:

```
WARNING: Jolt Physics job system exceeded the maximum number of jobs. This should not
happen. Please report this. Waiting for jobs to become available...
     at: CreateJob (modules/jolt_physics/spaces/jolt_job_system.cpp:123)
```

**Why it is not a check failure:** it is a `WARNING:` line. `run_headless_check.sh`'s
log scan matches `SCRIPT ERROR`, `Parse Error` and `ERROR:` only, by design, and Jolt
self-recovers by waiting for a job slot. The run in which it appeared still ended
`Lesson order probe passed.` with exit 0.

**Why it was not chased:** it did not reproduce in five subsequent runs, including two
with the probe reverted to its pre-lesson-3 state, so it is not caused by any single
lesson. The probe now instantiates eight full 3D rooms in one process, each with a
character body, five static bodies and three areas, which is the plausible pressure.

**Fix if it becomes frequent:** free each lesson instance decisively — `root.remove_child(lesson)`
then `lesson.free()` — instead of relying on `queue_free()` plus two process frames, so
no two rooms are ever alive in the same physics space. Do not loosen the log scan, and
do not raise the probe watchdog limit.

**Re-checked in plan 03-05 under heavier load: 0 occurrences in 6 consecutive runs.**
The probe now stands up 13 full 3D rooms per process rather than 8 — lessons 4 and 5 add
five more instances between them — which is the pressure that should have made an
instance-count-driven warning more frequent, not less. It did not appear once. The item
stays logged rather than closed, because six clean runs do not disprove an intermittent
warning that already went five runs without appearing in 03-04; but it is now recorded as
not scaling with the number of rooms, which argues against room count being the cause. No
probe, log scan or watchdog limit was changed to accommodate it.

## Probe-presence guard gap

**Carried forward unchanged** from `02-05-SUMMARY.md`, `03-01-SUMMARY.md` and
`03-03-SUMMARY.md`, and explicitly accepted for this phase in `03-VALIDATION.md`'s
sign-off checklist. `run_headless_check.sh` has no `REQUIRED_PROBES` named-probe
allow-list, so deleting any single `probe_*.gd` still leaves the glob non-empty and the
check passes green with that probe's whole coverage silently gone. Tracked in
`STATE.md`'s Pending Todos; not Phase 3 scope.
