# Project Camiel

## What This Is

Project Camiel is a Godot 4.6.4 2D educational game for children from around age 3, starring the character Camiel. It guides pre-reading children in Dutch through simple touch-and-move lessons (color recognition, shape sequencing, counting) with no reading required, while parents and teachers act as secondary users who co-play, guide, and (in this milestone) will be able to review a child's lesson progress.

## Core Value

A young child can go from the title screen through every lesson, entirely on their own, without hitting a bug or needing adult help — and their progress is remembered afterward.

## Requirements

### Validated

<!-- Confirmed working by .planning/codebase/CONCERNS.md and ARCHITECTURE.md. -->

- Camiel's character art, sprite animations (idle, walk, run, jump, sit, sleep), and `CharacterBody2D` setup exist and are checked by the CI resource verifier — shipped alpha-v0.0.1
- Camiel responds to keyboard input (arrow keys / A-D walk, Shift run, Space/W/Up jump, S/Down sit, X sleep) while inside a level — shipped alpha-v0.0.1
- Windows desktop builds export and have been distributed as GitHub Release assets (unsigned, so Windows SmartScreen warns) — shipped alpha-v0.0.1 through alpha-v0.0.3
- CI runs a repository quality gate and a headless Godot resource/scene verifier on every push and pull request — shipped alpha-v0.0.3

### Active

<!-- This milestone: stabilize the existing build, then deliver the alpha-v0.0.4 feature ideas. Full requirement IDs and detail live in REQUIREMENTS.md. -->

- [ ] Fix the playable intro path (title screen through the free-play intro level) so it runs with no runtime errors or dead buttons — REQUIREMENTS.md `STAB-*`
- [ ] Make Lessons 1 through 5 reachable, correct regardless of task order, and progress-recording — REQUIREMENTS.md `LESSON-*`, `PROGRESS-*`
- [ ] Meet WCAG 2.1 AA contrast and wire the Accessibility toggle, mobile controller, and reusable UI widgets that already exist in the codebase but are never reached during play — REQUIREMENTS.md `ACCESS-*`, `WIRING-*`
- [ ] Stabilize the CI/CD and release pipeline around one pinned Godot version and one version-string source — REQUIREMENTS.md `CI-*`, `DOCS-*`
- [ ] Add Dutch voice-over so pre-reading children are not dependent on on-screen text — REQUIREMENTS.md `VOICE-*`
- [ ] Bring mobile touch controls to production quality across every level and lesson — REQUIREMENTS.md `MOBILE-*`
- [ ] Ship a working, CI-built Web export — REQUIREMENTS.md `WEB-*`
- [ ] Build a local, read-only parent dashboard for lesson progress — REQUIREMENTS.md `DASH-*`
- [ ] Add at least one lesson beyond the original five — REQUIREMENTS.md `MORE-*`

### Out of Scope

<!-- Explicit boundaries for this milestone. -->

- Android APK export — the export preset has no keystore and no CI job; the user-set target runtime for this milestone is Windows primary, Linux secondary, plus the Web and mobile-touch work already scoped above. A distinct Android platform target is not part of this milestone.
- macOS export hardening (code signing / notarization) — macOS is not named as this milestone's primary or secondary target; the existing unsigned preset is left as-is.
- Code signing for Windows/macOS release binaries — requires acquiring and maintaining paid certificates (see `docs/code-signing.md`); deferred to a future milestone.
- Repository hygiene items not named in this milestone's scope: removing committed `.pi/` agent-run data from history, pinning GitHub Actions by commit SHA, and moving large assets to Git LFS — real tech debt documented in `.planning/codebase/CONCERNS.md`, deferred because they do not block the milestone success metric.
- Parent dashboard extensions beyond the documented read-only single-child viewer (multi-child merge via SQLite/Drizzle, passphrase-protected access) — only the core contract in `docs/parent-dashboard.md` (GET /api/progress, GET /api/summary, POST /api/progress/import) is in scope.

## Context

Project Camiel is an existing, public Godot 4 repository (`Euraika-Labs/Project-Camiel`) that has shipped three prior alphas (v0.0.1 intro scene, v0.0.2 menu/audio/collectible, v0.0.3 first lessons and CI/CD). It targets children from around age 3, with all in-game text in Dutch, no ads, no in-app purchases, and no internet requirement after download.

This milestone was scoped from a documentation ingest cross-checked against a fresh codebase audit (see `.planning/codebase/CONCERNS.md`, `ARCHITECTURE.md`, `STACK.md`, `TESTING.md`). The audit found that several capabilities the project's own documentation describes as shipped are not actually reachable or working: the title screen's entry-point node-path bug, a `ProgressTracker` autoload that fails to compile and is never called, an `Accessibility` autoload that is never triggered, computed UI color contrast that fails WCAG AA despite a report claiming compliance, lessons 2 through 5 that exist in the repository but have no menu path to reach them (with lessons 4 and 5 being unfinished placeholders), a mobile touch controller that is never instanced into any scene, and a Web export preset that uses the wrong Godot-4 platform identifier and has never been exercised by CI. Five such doc-versus-code conflicts were confirmed and approved as open requirements rather than satisfied capabilities (see `.planning/INGEST-CONFLICTS.md`).

The milestone therefore runs stabilization phases first — making the existing, already-built content actually work end to end — before adding the alpha-v0.0.4 feature ideas from `docs/roadmap.md` on top of a working foundation.

## Constraints

- **Engine**: Godot 4.6.4, GDScript, desktop-first (Windows primary, Linux secondary) — this milestone pins one Godot version everywhere, resolving drift across CI workflows and docs that currently disagree between 4.6.2, 4.6, and 4.6.4.
- **Audience**: Content and UI must work for pre-reading children from around age 3 — minimal reliance on text, no time pressure, no punishment-heavy failure states, large touch/click targets (per the design principles in `docs/roadmap.md`).
- **Accessibility**: All shipped UI text must meet WCAG 2.1 AA color contrast (4.5:1 normal text, 3:1 qualifying large text).
- **Privacy**: The parent dashboard must never transmit child progress data off the local device (per the design principles in `docs/parent-dashboard.md`).
- **Repo quality gate**: `python3 scripts/tools/quality_gate.py`, run in CI, scans the whole repository (including `.planning/`) and blocks unfinished-work markers, placeholder copy, and broken relative Markdown links — all planning documents must stay clear of these patterns.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| One milestone bundles stabilization phases first, then the alpha-v0.0.4 feature phases | Building new features on top of a broken foundation (dead buttons, a non-compiling autoload, unreachable lessons) would compound the existing gaps | — Pending |
| Godot 4.6.4 is the single pinned engine version across CI and docs | Resolves the version drift documented in `.planning/codebase/CONCERNS.md` (4.6.2 in `ci.yml`/`release.yml` vs 4.6.4 in `export.yml` and most docs) | — Pending |
| The parent dashboard phase is sequenced after the progress-persistence phase | Building a dashboard before the data it reads actually exists would ship a viewer with nothing to view | — Pending |
| Windows is the primary target, Linux secondary; Web and mobile-touch are this milestone's scope, not yet delivered capabilities | User-set target runtime priority for this milestone | — Pending |

---
*Last updated: 2026-09-11 after initial project creation from documentation ingest*
