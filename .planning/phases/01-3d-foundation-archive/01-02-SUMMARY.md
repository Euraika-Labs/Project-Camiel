---
phase: 01-3d-foundation-archive
plan: 02
subsystem: infra
tags: [godot, engine-install, macos, codesign, jolt-physics]

# Dependency graph
requires: []
provides:
  - "Verified /Applications/Godot.app (Godot 4.7.2-stable, macOS universal), SHA512- and codesign-checked"
  - ".planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md — engine-reported facts F1-F11 and the D-03 soak verdict"
  - "Discovery that this repo's committed project.godot config_version=6 is invalid for Godot 4.7.2 and is silently discarded on load"
  - "Discovery that the engine's Jolt physics literal is \"Jolt Physics\", not \"JoltPhysics3D\" as research assumed"
affects: [01-03, 01-04]

# Actuals (#2632)
actuals:
  tokens: 1906
  tasks: 2
  commits: 1

# Tech tracking
tech-stack:
  added: ["Godot Engine 4.7.2-stable (macOS universal, installed at /Applications/Godot.app)"]
  patterns:
    - "Engine-fact gathering: settle every project.godot literal and headless-behaviour risk by running the real engine against a throwaway mktemp scratch project before writing real project settings"
    - "Watchdog-wrapped headless invocation: gsd-tools run-with-timeout <seconds> -- <godot invocation> in place of a nonexistent macOS timeout binary, giving a portable exit-124-on-hang contract"

key-files:
  created:
    - .planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md
  modified: []

key-decisions:
  - "Verified the release download against godot-builds' own SHA512-SUMS.txt entry before extracting anything (T-01-SC), matching D-08/D-02 exactly"
  - "Ran the D-03 stall soak before touching any repository file, per the phase objective — the 4.7.1 stall (issue 122707) does not reproduce on 4.7.2 for this workload"
  - "Documented the config_version=6 vs engine-expected config_version=5 mismatch as an out-of-table finding, since it changes how Plan 01-03 must treat the currently-committed project.godot"

patterns-established:
  - "Scratch-project engine probing: build every test scene through PackedScene.pack() + ResourceSaver.save() in a --script SceneTree, never by hand-typing .tscn text, to avoid the exact project.godot/tscn corruption risk research Pitfall 4 warns about"

requirements-completed: []

coverage:
  - id: D1
    description: "Godot 4.7.2-stable installed at /Applications/Godot.app, SHA512-verified against the official godot-builds release and codesign-verified"
    requirement: "FOUND-04"
    verification:
      - kind: other
        ref: "/Applications/Godot.app/Contents/MacOS/Godot --version starts with 4.7.2.stable && codesign --verify --deep --strict /Applications/Godot.app"
        status: pass
    human_judgment: false
  - id: D2
    description: "01-ENGINE-FACTS.md records engine-verified facts F1-F11 and the D-03 soak verdict, replacing research assumptions A1/A2/A4"
    requirement: "FOUND-06"
    verification:
      - kind: other
        ref: "grep -E '^\\| F[1-9]|^\\| F1[01] \\|' .planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md (11 rows) && grep -qx 'Soak verdict: no-stall' .planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md"
        status: pass
      - kind: other
        ref: "python3 scripts/tools/quality_gate.py --root ."
        status: pass
    human_judgment: false
  - id: D3
    description: "D-03 headless-stall soak measured on Godot 4.7.2 before any 3D work was built — no stall observed"
    requirement: "FOUND-06"
    verification:
      - kind: other
        ref: "75s scratch Node3D + Jolt CharacterBody3D soak under a 120s watchdog: 15/15 heartbeats, exit 0, wall time 75s"
        status: pass
    human_judgment: false

# Metrics
duration: 13min
completed: 2026-09-11
status: complete
---

# Phase 01 Plan 02: Install Godot 4.7.2 and Record Engine-Verified Facts Summary

**Installed and integrity-verified Godot 4.7.2-stable at /Applications/Godot.app, then ran it headless against a throwaway scratch project to settle facts F1-F11 (physics engine literal, renderer keys, config/features serialization, keycodes, headless error output) and cleared the D-03 stall risk with a 75-second no-stall soak.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-09-11T11:50:55Z
- **Completed:** 2026-09-11T12:03:35Z
- **Tasks:** 2
- **Files modified:** 1 (new file; no existing repository file touched)

## Accomplishments

- Downloaded `Godot_v4.7.2-stable_macos.universal.zip` over HTTPS from the official `godotengine/godot-builds` release, verified its SHA512 against that release's `SHA512-SUMS.txt` (`38aa16e5bba2083941fc5b3e54be0089bd4cc35e32415f5b9fd9a8a6a7b9818255d44532ea8ef94b5aef56c4b407c2d634fa4f657e4ebe681ebbf59b7bac69ca`, matched exactly), extracted with `ditto -x -k`, and installed to `/Applications/Godot.app`
- `codesign --verify --deep --strict /Applications/Godot.app` exits 0; `TeamIdentifier=6K46PWY5DM`; `spctl --assess --type execute` also passed. No quarantine attribute, Gatekeeper setting, shell profile, or PATH entry was touched.
- Confirmed the installed engine reports `4.7.2.stable.official.ed1daf0bf` via `--version`
- Ran the D-03 75-second headless soak (scratch `Node3D` + `StaticBody3D` floor + `CharacterBody3D`/`CapsuleShape3D` under Jolt Physics gravity) under a 120-second watchdog: all 15 heartbeats printed, exit code 0, wall time 75s — **Soak verdict: no-stall**. Godot issue 122707 does not reproduce on 4.7.2 for this workload.
- Recorded engine-verified facts F1 through F11 in `01-ENGINE-FACTS.md`, replacing research assumptions A1 (physics engine literal), A2 (config/features serialization), and A4 (macOS binary path)
- Discovered and documented two facts beyond the F1-F11 table that directly affect Plan 01-03: (1) the engine's Jolt literal is `Jolt Physics` (with a space), not `JoltPhysics3D` as research guessed; (2) this repository's committed `project.godot` `config_version=6` is rejected by 4.7.2 as "from a more recent and incompatible version," silently falls back to engine defaults on load, and gets rewritten to `config_version=5` the first time `ProjectSettings.save()` runs

## Task Commits

Each task was committed atomically:

1. **Task 1: Install Godot 4.7.2-stable with SHA512 and codesign verification** — *(no repository files changed; the install target `/Applications/Godot.app` is outside the repository, so there is nothing to commit for this task)*
2. **Task 2: Record engine-verified facts and run the D-03 soak** — `dfbf12b` (docs)

**Plan metadata:** commit for this SUMMARY (see below)

## Files Created/Modified

- `.planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md` - Facts F1-F11 table, the `Soak verdict: no-stall` line, and two additional findings (config_version mismatch, Jolt literal) for Plan 01-03 to consume
- `/Applications/Godot.app` (outside the repository) - Godot 4.7.2-stable, macOS universal, installed and verified

## Decisions Made

- Followed D-08's install steps exactly: official release URL, SHA512 check against the release's own `SHA512-SUMS.txt`, `ditto` extraction (preserves the bundle signature), `codesign --verify --deep --strict`, no quarantine/Gatekeeper/PATH changes
- Ran F3/F4/F6 (default-state facts) before applying any project-setting changes, then F5 (post-change facts) after, so the "current value" facts reflect a genuinely untouched project rather than a project already carrying the phase's intended settings
- Used `gsd-tools run-with-timeout <seconds> -- <command>` as the watchdog mechanism in place of the OS-level `timeout` binary, which is not installed on this Mac (`timeout`/`gtimeout` both absent) — it gives the same "kill after N seconds, exit 124" contract the plan's `<action>` specifies
- Set `application/run/main_scene` to `res://main.tscn`, a scene saved via `ResourceSaver.save()` from a script rather than the editor, specifically to observe whether Godot converts a `res://` main-scene path to `uid://` on save when the target scene carries no UID — it does not, confirming `uid://` conversion requires the scene to already have an assigned UID

## Deviations from Plan

None - plan executed exactly as written. The two "Additional Findings" recorded in `01-ENGINE-FACTS.md` are exactly the kind of engine-observed fact the plan's objective calls for (settling literals research could not confirm); they were folded into the facts file as prose alongside the F1-F11 table rather than invented action items, so no code or configuration changed beyond what the plan's Task 2 action already specified.

## Issues Encountered

- The macOS host has no `timeout`/`gtimeout` binary. Resolved by using `gsd-tools run-with-timeout <seconds> -- <command>`, which was already available in this environment and provides an equivalent watchdog (kills the process, exits 124) — not a deviation from the plan's intent, since the plan's own wording ("watchdog that kills the process after the stated limit") does not mandate a specific tool.
- The initial scratch `project.godot`, built exactly as instructed with `config_version=6` (mirroring this repository's real pre-change file), failed to load under Godot 4.7.2 with `Expected config version: 5`. This did not block any fact-gathering step (default settings apply identically whether the file loads or is rejected, since the file set no physics/rendering keys), but it is recorded as a named finding in `01-ENGINE-FACTS.md` because Plan 01-03 needs to know before it edits the repository's actual `project.godot`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `/Applications/Godot.app` is installed, SHA512- and codesign-verified, and reports `4.7.2.stable.official.ed1daf0bf`
- `01-ENGINE-FACTS.md` gives Plan 01-03 the exact literals it needs: `physics/3d/physics_engine="Jolt Physics"`, the `rendering/renderer/rendering_method*` keys and their defaults, verbatim `SCRIPT ERROR:` text for the headless log-scan (D-09), and the `config_version=6` incompatibility Plan 01-03 must resolve before its own `project.godot` edits take effect
- D-03 is closed for this milestone: the 4.7.1 headless stall (issue 122707) does not reproduce on 4.7.2 in a 75-second soak under Jolt Physics; no version-pin or timeout change was needed
- No blockers for Plan 01-03 or 01-04

---
*Phase: 01-3d-foundation-archive*
*Completed: 2026-09-11*

## Self-Check: PASSED

- FOUND: .planning/phases/01-3d-foundation-archive/01-ENGINE-FACTS.md
- FOUND: .planning/phases/01-3d-foundation-archive/01-02-SUMMARY.md
- FOUND: commit dfbf12b (Task 2 commit)
- FOUND: /Applications/Godot.app/Contents/MacOS/Godot
