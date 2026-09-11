# Project Camiel

## What This Is

Project Camiel is a Godot 4.6.4 **3D** educational game for children from around age 3, starring the character Camiel. It guides pre-reading children in Dutch through simple 3D lessons (colour recognition, counting, shape order, sequence) with no reading required, while parents and teachers act as secondary users who co-play, guide, and (in this milestone) will be able to review a child's lesson progress.

This project pivoted from a 2D game to a full 3D game during the discussion of the original Phase 1 (see Key Decisions). The roadmap below is the rebuilt 3D plan; the prior 2D-stabilization plan is retired.

## Core Value

A young child can go from the title screen through every lesson, entirely on their own, without hitting a bug or needing adult help — and their progress is remembered afterward.

## Requirements

### Validated

None. The 2D capabilities previously validated here no longer apply to the 3D rebuild — the project is built from scratch. See Context below for what previously shipped, kept only as a record of prior work and as design intent to port.

### Active

<!-- This milestone: build the 3D foundation and reach lesson parity, then deliver the alpha-v0.0.4 feature ideas. Full requirement IDs and detail live in REQUIREMENTS.md. -->

- [ ] Archive the 2D game under a git tag, remove it from the runtime project, and establish the 3D project foundation with a thin playable slice — REQUIREMENTS.md `FOUND-*`
- [ ] Build the 3D title screen, main menu, and full intro level (move, jump, collect, reach goal, win screen) — REQUIREMENTS.md `MENU-*`, `INTRO-*`
- [ ] Port the lesson concepts to 3D, add a lesson-select screen, and persist progress to disk — REQUIREMENTS.md `LESSON-*`, `PROGRESS-*`
- [ ] Meet WCAG 2.1 AA contrast and stabilize the CI/release pipeline around one pinned Godot version — REQUIREMENTS.md `ACCESS-*`, `CI-*`, `DOCS-*`
- [ ] Add Dutch voice-over so pre-reading children are not dependent on on-screen text — REQUIREMENTS.md `VOICE-*`
- [ ] Bring mobile touch controls to production quality across every level and lesson — REQUIREMENTS.md `MOBILE-*`
- [ ] Ship a working, CI-built Web export — REQUIREMENTS.md `WEB-*`
- [ ] Build a local, read-only parent dashboard for lesson progress — REQUIREMENTS.md `DASH-*`
- [ ] Add at least one lesson beyond the original five — REQUIREMENTS.md `MORE-*`

### Out of Scope

<!-- Explicit boundaries for this milestone. -->

- Real (non-primitive) 3D art and animations for Camiel and lesson props — v1 ships with primitive shapes (capsule, boxes, spheres) per a locked decision; the real model is v2 (`MODEL-01`), with its source still a pending decision.
- Android APK export — the export preset has no keystore and no CI job; the user-set target runtime for this milestone is Windows primary, Linux secondary, plus the Web and mobile-touch work already scoped above.
- macOS export hardening (code signing / notarization) — macOS is not named as this milestone's primary or secondary target; the existing unsigned preset is left as-is.
- Code signing for Windows/macOS release binaries — requires acquiring and maintaining paid certificates (see `docs/code-signing.md`); deferred to a future milestone.
- Repository hygiene items not named in this milestone's scope: removing committed `.pi/` agent-run data from history, pinning GitHub Actions by commit SHA, and moving large assets to Git LFS — real tech debt documented in `.planning/codebase/CONCERNS.md`, deferred because they do not block the milestone success metric.
- Parent dashboard extensions beyond the documented read-only single-child viewer (multi-child merge via SQLite/Drizzle, passphrase-protected access) — only the core contract in `docs/parent-dashboard.md` (GET /api/progress, GET /api/summary, POST /api/progress/import) is in scope.

## Context

Project Camiel is an existing, public Godot 4 repository (`Euraika-Labs/Project-Camiel`) that shipped three 2D alphas (v0.0.1 intro scene, v0.0.2 menu/audio/collectible, v0.0.3 first lessons and CI/CD). During the discussion that opened work on the (then) 2D stabilization Phase 1, the user decided to pivot the project to a full 3D game rather than continue stabilizing the 2D build. This roadmap and its requirements were regenerated for that pivot; the 2D-stabilization plan (commit `4466639`) is obsolete.

**What previously shipped in 2D, kept as history, not as validated 3D capability:** Camiel's 2D character art and sprite animations (idle, walk, run, jump, sit, sleep) on a `CharacterBody2D`; keyboard-driven 2D movement; Windows desktop builds distributed as GitHub Release assets (unsigned); a CI quality gate and headless Godot resource/scene verifier. A fresh codebase audit (`.planning/codebase/CONCERNS.md`, `ARCHITECTURE.md`, `STACK.md`) also found several 2D capabilities the project's own documentation described as shipped were not actually reachable or working (a broken title-screen node path, a non-compiling `ProgressTracker` autoload, an unreachable `Accessibility` autoload, UI contrast that failed WCAG AA despite a report claiming compliance, lessons 2 through 5 with no menu path to reach them, an unwired mobile touch controller, and an invalid Web export preset). None of this 2D code carries forward into the runtime project; it is archived under a git tag (per the locked decisions below) and consulted only as a reference for what gameplay and lesson concepts to port into 3D — for example, the 2D lesson mechanics (touch the red block, find the hidden blue target, count to three, touch shapes in order, touch targets in sequence) describe the *learning* intent that the 3D lessons re-express in a 3D scene.

The milestone therefore now runs 3D-foundation and lesson-parity phases first — establishing a working 3D game, from title screen through every lesson, with progress saved — before adding the alpha-v0.0.4 feature ideas from `docs/roadmap.md` on top of that foundation.

## Constraints

- **Engine**: Godot 4.6.4, GDScript, desktop-first (Windows primary, Linux secondary) — this milestone pins one Godot version everywhere. The project now targets 3D (`Node3D`-based scenes) rather than 2D.
- **Renderer**: The project currently uses Forward Plus; the Godot Web export requires the Compatibility renderer, and low-end devices may need it too. This choice must be settled in the phase that builds the 3D foundation, because it affects every 3D visual built afterward.
- **Audience**: Content and UI must work for pre-reading children from around age 3 — minimal reliance on text, no time pressure, no punishment-heavy failure states, large touch/click targets (per the design principles in `docs/roadmap.md`).
- **Accessibility**: All shipped UI text must meet WCAG 2.1 AA color contrast (4.5:1 normal text, 3:1 qualifying large text).
- **Privacy**: The parent dashboard must never transmit child progress data off the local device (per the design principles in `docs/parent-dashboard.md`).
- **Repo quality gate**: `python3 scripts/tools/quality_gate.py`, run in CI, scans the whole repository (including `.planning/`) and blocks unfinished-work markers, placeholder copy, and broken relative Markdown links — all planning documents must stay clear of these patterns.

## Key Decisions

Decisions marked **Locked** were made explicitly by the user during the pivot discussion and should not be re-opened. The Outcome column otherwise tracks execution status.

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pivot to a full 3D world: Camiel moves freely in all directions in 3D space with a following camera; levels and lessons are redesigned for 3D | Decided during the paused (2D) Phase 1 discussion, 2026-09-11 | Locked |
| Fully replace the 2D game: the 3D game is built from scratch in this same repository; 2D scenes/scripts/assets are reference only and are removed from the runtime project after being archived under a git tag (the removal itself is confirmed with the user at that time) | Avoids maintaining two parallel games; the 2D code still documents gameplay and lesson intent worth porting | Locked |
| Camiel and lesson props start as primitive 3D shapes (capsule, boxes, spheres); gameplay does not wait on art | The real Camiel 3D model and its animations are deferred to v2, with the model's source (AI-generated from existing art vs. made/commissioned) left as an open v2 decision | Locked |
| Rebuild the roadmap now, with no feasibility spike | User chose to proceed straight to a rebuilt roadmap rather than validate 3D feasibility first | Locked |
| The win screen shows two buttons, "Nog een keer" (replay) and "Naar menu", each with an icon, activated by tap, click, or Enter on the focused button, through one code path | Carried forward from the paused Phase 1 (2D) discussion; applies to whichever phase builds the win screen (Phase 2 in the rebuilt roadmap) | Locked |
| One milestone bundles the 3D-foundation and lesson-parity phases first, then the alpha-v0.0.4 feature phases | Building voice-over, mobile, web, and dashboard features on top of an unproven 3D foundation would compound risk | — Pending |
| Godot 4.6.4 is the single pinned engine version across CI and docs | Carried forward unchanged from the 2D milestone; still the target engine for the 3D rebuild | — Pending |
| The parent dashboard phase is sequenced after the progress-persistence phase | Building a dashboard before the data it reads actually exists would ship a viewer with nothing to view | — Pending |
| Windows is the primary target, Linux secondary; Web and mobile-touch are this milestone's scope, not yet delivered capabilities | User-set target runtime priority for this milestone, unchanged by the pivot | — Pending |

---
*Last updated: 2026-09-11 after the 2D-to-3D pivot and roadmap rebuild*
