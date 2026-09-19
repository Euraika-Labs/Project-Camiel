---
gsd_state_version: "1.0"
milestone: v0.0.4
current_phase: 03
current_phase_name: 3D Lesson Parity & Progress Persistence
status: verifying
stopped_at: Integrated alpha-v0.0.4 acceptance in progress
last_updated: "2026-09-19T21:22:41Z"
last_activity: 2026-09-19
last_activity_desc: Integrated headless gate and six-lesson process restart verified; final acceptance open
state_head: c00504dc2d4f28a050ac3f31db5f9c84b3190836
progress:
  total_phases: 10
  completed_phases: 2
  total_plans: 18
  completed_plans: 17
---

# Project State

## Current integration evidence — 2026-09-19

Alpha-v0.0.4 implementation is merged via PR #10; final acceptance remains open. The isolated integration run passed the complete Godot headless gate and a real write-process exit followed by a fresh reader process: nine completion entries cover all six lessons, with identical save hashes. Evidence is in the workspace acceptance task `aa38adeb-5b83-4b69-8110-59add2e0c7d5`; local logs and source manifests are under `/private/tmp/camiel-final-aa38adeb/`. A durable workspace copy of the evidence is in `builds/verification/acceptance/`; playable packages are in `builds/release/`.

Technical delivery checks passed: the dashboard transport-test race is fixed, the earlier integration run passed 41 Python tests and 13 Godot probes, and current web/native macOS flows have been checked. Final milestone acceptance remains open for the human/platform boundaries below. Human assessment of child friendliness, character recognition and movement feel is not replaced by automation. Physical touchscreen and Windows/Linux native execution require separate evidence. Earlier phase counters below describe historical plan execution, not completion of the current integrated milestone.

## Project Reference

See: .planning/PROJECT.md (updated 2026-09-19)

**Core value:** A young child can go from the title screen through every lesson, entirely on their own, without hitting a bug or needing adult help — and their progress is remembered afterward.
**Current focus:** Human milestone acceptance and platform verification

## Current Position

Phase 03 plan 6 remains a human playtest gate. Phases 03.1 and 4–9 have integrated implementations; their evidence and remaining limits are recorded in REQUIREMENTS.md and docs/roadmap.md. PR #10 merged; no alpha-v0.0.4 release tag has been published by this workflow.

The 18-plan counter covers the original phase 1–3 plans (17 executed); later integration work is not represented as invented phase-plan completions.

## Performance Metrics

**Velocity:**

- Total original plans completed: 17
- Average duration: - min
- Total execution time: - hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 6 | - | - |
| 02 | 6 | - | - |

**Recent Trend:**

- Last 5 original plans: 03-01 through 03-05
- Trend: Not enough data

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01 P01 | multi-session | 3 tasks | 249 files |
| Phase 01 P02 | 13min | 2 tasks | 1 files |
| Phase 01 P03 | 45min | 2 tasks | 8 files |
| Phase 01 P04 | 35min | 2 tasks | 7 files |
| Phase 01 P05 | 25min | 2 tasks | 4 files |
| Phase 01 P06 | 185min | 3 tasks | 3 files |
| Phase 02 P01 | 30min | 2 tasks | 13 files |
| Phase 02 P02 | 35min | 2 tasks | 8 files |
| Phase 02 P03 | 19min | 2 tasks | 13 files |
| Phase 02 P04 | 20min | 3 tasks | 10 files |
| Phase 02 P05 | 30min | 3 tasks | 4 files |
| Phase 02 P06 | 20 min | 1 tasks | 0 files |
| Phase 03 P01 | 55min | 2 tasks | 5 files |
| Phase 03 P02 | 65min | 3 tasks | 9 files |
| Phase 03 P03 | 75min | 3 tasks | 11 files |
| Phase 03 P04 | ~50min | 2 tasks | 8 files |
| Phase 03 P05 | ~25min | 3 tasks | 10 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Historical decision log; later entries and the current requirement table supersede earlier scope choices:

- Pivot: Project Camiel switches from 2D to a full 3D game, built from scratch in this repository; the 2D code is archived under a git tag and then removed from the runtime project (removal execution confirmed with the user beforehand) — decided during the paused Phase 1 (2D) discussion, 2026-09-11
- Initial primitive-character decision was superseded by Phase 03.1. Camiel now uses an authored GLB with idle/walk/jump; lesson props remain primitive.
- Roadmap rebuilt immediately, without a feasibility spike
- Milestone scoping: the 3D-foundation and lesson-parity phases (1-4) run before the alpha-v0.0.4 feature phases (5-9)
- Parent Dashboard (Phase 8) is sequenced after Progress Persistence (Phase 3)
- [Phase 01]: Archived pre-pivot 2D game under git tag archive/2d-alpha-v0.0.3 (pushed to origin) and removed all 2D scenes/scripts/art from the runtime project after explicit user confirmation (remove-and-push-tag).
- [Phase 01]: [Phase 01-02]: Godot 4.7.2 installed and integrity-verified (SHA512 + codesign); D-03 soak found no headless stall on 4.7.2 (issue 122707 does not reproduce) — Settles the D-03 risk before any 3D work is built, per the phase objective
- [Phase 01]: [Phase 01-02]: Discovered the engine's Jolt physics literal is "Jolt Physics" (not "JoltPhysics3D" as research assumed) and that this repo's committed project.godot config_version=6 is invalid for 4.7.2 (engine expects 5, silently discards the file and rewrites it to 5 on next save) — Plan 01-03 must account for both before editing project.godot
- [Phase 01]: [Phase 01-03]: Hardened the headless check (D-01/D-02/D-03/D-04/D-07 enforcement, HEADLESS_CHECK_MAX_LIMIT_SECONDS cap, behaviour probes) with a committed 11-case self-test; fixed a resolve_godot fallback bug the self-test itself surfaced (an explicit but invalid GODOT env var used to silently succeed via a different engine).
- [Phase 01]: Camera-relative steering only turns Camiel to face travel direction on forward/back input; pure lateral input strafes without reorienting, since turning to face a direction computed from a self-referential frame has no fixed point and spins forever (Rule 1 fix, Plan 01-04) — Discovered via the fall_at_edge probe case and confirmed by tracing Camiel's position while holding D alone before/after the fix
- [Phase 01]: [Phase 01-05]: CI and release workflows pinned to Godot 4.7.2, with SHA512 verification added on every engine/export-template download and the 2D-era verifier/quit-after smoke test replaced by scripts/tools/run_headless_check.sh in both workflows; CONTRIBUTING.md updated to match.
- [Phase 01]: [Phase 01-06]: D-11 playtest verdict (verbatim): "switch to turn-and-walk" - scripts/camiel_controller.gd steering_mode default changed from CAMERA_RELATIVE to TURN_AND_WALK; no tunable values changed since no feel/tuning complaint was raised
- [Phase 01]: [Phase 01-06]: FOUND-06 closed - tests/test_ci_workflows.py's silent PyYAML skipUnless fallback replaced with a hard import, and the repository-hygiene CI job now installs PyYAML before running tests
- [Phase 02]: AudioManager._exit_tree() drains 250ms real time (gated on whether audio ever played) to work around a Godot 4.7.2 engine race releasing AudioStreamOggVorbis playback objects only on the headless null-audio driver's real-time mix cadence
- [Phase 02]: Headless tool scripts (probe_*.gd) must fetch autoloads via root.get_node_or_null() rather than the bare global identifier, which only resolves for a normal scene boot, not a --script SceneTree entrypoint
- [Phase 02]: [Phase 02-02]: Split the six menu-button icons across the tracer/expansion pair — Task 1 implements only "play" (matching its own tested behavior), Task 2 completes walk/replay/home/speaker/music_note, per Task 2's explicit "remaining five kinds" wording
- [Phase 02]: [Phase 02-02]: Label's mouse_filter is written explicitly in menu_button.tscn even though it equals Label's own class default, so all three tap-through nodes show MOUSE_FILTER_IGNORE in the saved scene text, not just two of three
- [Phase 02]: [Phase 02-03]: Camiel already joins the player group via camiel_controller.gd's own ready callback; intro_level.tscn's Camiel instance carries no scene-instance group override — resolves 02-UI-SPEC.md Open Question 1 by confirming the recommended default, not adding one
- [Phase 02]: [Phase 02]: [Phase 02-03]: project.godot's run/main_scene retarget applied as a direct one-line text edit, not ProjectSettings.save() — save() silently dropped the unrelated renderer/rendering_method.web line on this pass
- [Phase 02]: [Phase 02-04]: CanvasLayer has no modulate property in Godot 4.7.2 — the win overlay's fade-in target moved to its child %Scrim Control instead
- [Phase 02]: [Phase 02-04]: Area3D forbids toggling monitoring synchronously inside its own body_entered callback; collectible.gd defers monitoring off, the pickup tween, and the collected signal together as one call_deferred step
- [Phase 02]: [Phase 02-05]: Godot's GDScript loader enforces singleton resource identity per path regardless of ResourceLoader.CACHE_MODE_IGNORE, so packing two icon nodes that both load vector_icon.gd always dedupes to one ext_resource; the scene generator's post-processing step splits it into two declarations pointing at the same file so each icon row owns its own
- [Phase 02]: [Phase 02-05]: Per 02-VALIDATION.md's "Probe-presence guard gap", the REQUIRED_PROBES named-probe allow-list for run_headless_check.sh is deliberately left unimplemented this phase; test_headless_check.sh Case 13 records the current weakness (removing one named probe while others remain still passes) as a known, honestly-named gap rather than a guarantee
- [Phase 02]: [Phase 02]: [Phase 02-06]: D-30 playtest verdict (verbatim): "it works but graphics are very basic" - no functional or tuning changes applied since no defect or adjustment was named; the graphics remark subsequently led to MODEL-01 being pulled into Phase 03.1
- [Phase 03]: [Phase 03-01]: RED evidence for the corrupt-file recovery case was produced by temporarily reverting progress_tracker.gd to the archived bug's JSON.parse_string() call, confirming run_headless_check.sh goes CHECK FAILED on the exact ERROR: Parse JSON failed line even though recovery is correct, then reverted (byte-identical to the committed file)
- [Phase 03]: [Phase 03-01]: Task 3's deliberate-failure exercise forced a false assertion to prove the probe's failure funnel restores a real save file; verified via a SHA-256 checksum of the pre-existing real progress.json matched before and after
- [Phase 03]: [Phase 03-02]: D-37/D-38's activation gate shipped inside lesson_target.gd's Task 1 commit rather than a separate Task 3 diff, since the gate is one branch inside the same _on_body_entered method Task 1 also writes; RED evidence for Task 3's negative case was produced by temporarily removing the gate branch, confirming the failure, then restoring the file byte-identical
- [Phase 03]: 03-03: const LESSONS holds exactly one row until each lesson's scene exists; the lesson-select probe loads every table entry, so a row added before its scene fails loudly (D-33, Pitfall 7)
- [Phase 03]: 03-03: lesson 1's counting task is three objects that together mark ONE of three tasks, keeping D-36's check at three and D-46's label at three steps while still making the child count
- [Phase 03]: 03-03: the bare autoload name ProgressTracker does resolve inside a scene's own script under a --script entry point; the plan's contingency lookup was unnecessary
- [Phase 03]: Lessons 2 and 3 enforce order structurally: an array of the target nodes is read to activate the next one, and neither orchestrator compares an arriving identifier at all (D-37)
- [Phase 03]: Each ordered lesson's probe case drives three distinct orders -- two different wrong-first touches proved to refuse and complete nothing, then the correct order -- because a correct-order-only case would pass on the archived defect
- [Phase 03]: The lesson table holds exactly three appended rows, one per scene that exists; no row, disabled button or not-yet-available caption for lessons 4 and 5
- [Phase 03]: D-46 resolved in practice: the progress-label total is a parameter end to end, so lesson 5 reads Stap: 4 / 4 from the one shared format string with no second form and no reshaping of its four-step rule
- [Phase 03]: Lesson 4 is proved order-independent by being driven from two genuinely different orders, the second interleaving a colour target into the middle of the counting task -- one order proves nothing about order-independence
- [Phase 03]: The cue assertion is two-sided: a colour lesson holds shape and label uniform, an ordered lesson holds colour uniform and its non-cue property uniform too -- in both directions the property being taught is the only discriminator
- [Phase 03]: Lesson 4's counting objects are purple, not lesson 1's orange, because orange sits only 0.239 from this lesson's yellow and a third object in almost-yellow is the trap a yellow-or-green lesson must not set
- [Phase 03]: The closing persistence case builds its expected identifier set from the lesson table rather than a literal list, so a sixth lesson is covered the day its row lands and a lesson filing progress under an unknown identifier fails too

### Pending Todos

- Implement a `REQUIRED_PROBES` named-probe allow-list in `scripts/tools/run_headless_check.sh` so removing a single named probe fails the check by name, not only when the whole `probe_*.gd` glob is empty. Recorded by plan 02-05 (`02-05-SUMMARY.md`) as an executable, documented gap (`test_headless_check.sh` Case 13) rather than a fix, per `02-VALIDATION.md`'s explicit scoping.

### Blockers/Concerns

- `.planning/phases/01-playable-intro-path/` holds the superseded 2D-era discussion checkpoint (`01-DISCUSS-CHECKPOINT.json`); it is retired by the orchestrator, not by this file.
- Human playtest 03-06 and character/voice assessment remain open.
- Physical touch and native Windows/Linux execution remain unverified; Compatibility and turn-and-walk have already been selected.
- Tagged release publication is untested. Lessons 4 (yellow/green/counting) and 5 (1–4 sequence) are implemented.

### Roadmap Evolution

- Phase 03.1 inserted after Phase 3: Camiel 3D model and animations (MODEL-01 pulled forward from v2); placed before the accessibility phase so WCAG contrast is judged on real art, and before later phases so collision/camera proportions are tuned once

## Deferred Items

Items acknowledged and deferred at milestone close, most recent first:

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| *(none)* | | | | |

## Session Continuity

Last session: 2026-09-19
Stopped at: PR #10 merged; remaining human/platform acceptance recorded
Resume file: None

## Bewijs na integratie — 19 september 2026

[PR #10](https://github.com/Euraika-Labs/Project-Camiel/pull/10) is gemergd als `c00504dc2d4f28a050ac3f31db5f9c84b3190836`. [CI-run 35468153825](https://github.com/Euraika-Labs/Project-Camiel/actions/runs/35468153825) slaagde op PR-head `2e84a3a97bee5627ef43c05300c1bbecaa6b07d5`: projectcontrole, 16 foutinjectiegevallen en vier exports. Alle 11 PR-checks waren groen, inclusief de exacte verplichte naam `Export Windows build`.

De eerdere lokale integratierun telde 41 Python-tests en 13 Godot-probes. De latere Windows-gate voegde een Python-regressietest toe. Lokale macOS- en browserflows en opslag na een echte procesherstart zijn getest. De CI-webexport is gebouwd, maar het gedownloade CI-webartifact is niet afzonderlijk in een browser gespeeld; het eerdere browserbewijs betreft de lokaal geëxporteerde runtime. Menselijke speelacceptatie, fysiek touchscreengebruik, native Windows/Linux-uitvoering en een getagde releasepublicatie blijven open. Lokale bewijsbestanden onder `builds/verification/` worden niet in git meegeleverd.
