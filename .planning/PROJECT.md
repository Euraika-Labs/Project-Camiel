# Project Camiel

## What This Is

Project Camiel is a Godot 4.7.2 **3D** educational game for children from around age 3, starring the character Camiel. It guides pre-reading children in Dutch through simple 3D lessons (colour recognition, counting, shape order, sequence) with no reading required, while parents and teachers act as secondary users who co-play, guide, and can locally review a child's lesson progress.

This project pivoted from a 2D game to a full 3D game during the discussion of the original Phase 1 (see Key Decisions). The roadmap below is the rebuilt 3D plan; the prior 2D-stabilization plan is retired.

## Core Value

A young child can go from the title screen through every lesson, entirely on their own, without hitting a bug or needing adult help — and their progress is remembered afterward.

## Requirements

### Implemented and technically verified

The 3D foundation, title/menu/intro flow, six lessons, local persistence, character model, Dutch voice, accessibility settings, touch controller, web export and local dashboard are integrated. PR #10 merged as `c00504d` on 19 September 2026. See [requirement traceability](REQUIREMENTS.md) for per-item evidence and [build evidence](../docs/build-and-release.md) for the successful remote CI run.

### Acceptance still open

Human lesson playtesting (03-06), character recognition and movement feel, listening on target devices, physical touch, native Windows/Linux execution and tagged release publication remain unverified. A technical pass does not close these acceptance gates.

### Out of Scope

<!-- Explicit boundaries for this milestone. -->

- Non-primitive lesson-prop art remains outside scope. Camiel himself is included through Phase 03.1: an authored GLB with idle/walk/jump animations is integrated; human visual acceptance remains open.
- Android APK export — the export preset has no keystore and no CI job; the user-set target runtime for this milestone is Windows primary, Linux secondary, plus the Web and mobile-touch work already scoped above.
- macOS export hardening (code signing / notarization) — macOS is not named as this milestone's primary or secondary target; the existing unsigned preset is left as-is.
- Code signing for Windows/macOS release binaries — requires acquiring and maintaining paid certificates (see `docs/code-signing.md`); deferred to a future milestone.
- Repository hygiene items not named in this milestone's scope: removing committed `.pi/` agent-run data from history, pinning GitHub Actions by commit SHA, and moving large assets to Git LFS — real tech debt documented in `.planning/codebase/CONCERNS.md`, deferred because they do not block the milestone success metric.
- Parent dashboard extensions beyond the documented read-only single-child viewer (multi-child merge via SQLite/Drizzle, passphrase-protected access) — only the core contract in `docs/parent-dashboard.md` (GET /api/progress, GET /api/summary, POST /api/progress/import) is in scope.

## Context

Project Camiel is an existing, public Godot 4 repository (`Euraika-Labs/Project-Camiel`) that shipped three 2D alphas (v0.0.1 intro scene, v0.0.2 menu/audio/collectible, v0.0.3 first lessons and CI/CD). During the discussion that opened work on the (then) 2D stabilization Phase 1, the user decided to pivot the project to a full 3D game rather than continue stabilizing the 2D build. This roadmap and its requirements were regenerated for that pivot; the 2D-stabilization plan (commit `4466639`) is obsolete.

**What previously shipped in 2D, kept as history, not as validated 3D capability:** Camiel's 2D character art and sprite animations (idle, walk, run, jump, sit, sleep) on a `CharacterBody2D`; keyboard-driven 2D movement; Windows desktop builds distributed as GitHub Release assets (unsigned); a CI quality gate and headless Godot resource/scene verifier. A fresh codebase audit (`.planning/codebase/CONCERNS.md`, `ARCHITECTURE.md`, `STACK.md`) also found several 2D capabilities the project's own documentation described as shipped were not actually reachable or working (a broken title-screen node path, a non-compiling `ProgressTracker` autoload, an unreachable `Accessibility` autoload, UI contrast that failed WCAG AA despite a report claiming compliance, lessons 2 through 5 with no menu path to reach them, an unwired mobile touch controller, and an invalid Web export preset). None of this 2D code carries forward into the runtime project; it is archived under a git tag (per the locked decisions below) and consulted only as a reference for what gameplay and lesson concepts to port into 3D — for example, the 2D lesson mechanics (touch the red block, find the hidden blue target, count to three, touch shapes in order, touch targets in sequence) describe the *learning* intent that the 3D lessons re-express in a 3D scene.

**Engine version history:** the 2D-era plan and several docs pinned Godot 4.6.4, which does not exist as a Godot release (verified against the GitHub API on 2026-09-11; the 4.6 series ends at 4.6.3, and `.github/workflows/ci.yml` used 4.6.2). The 3D rebuild pins 4.7.2; this is a project version decision, not a moving latest-version recommendation.

The milestone therefore now runs 3D-foundation and lesson-parity phases first — establishing a working 3D game, from title screen through every lesson, with progress saved — before adding the alpha-v0.0.4 feature ideas from `docs/roadmap.md` on top of that foundation.

## Constraints

- **Engine**: Godot 4.7.2 with GDScript only (C# cannot be exported to the Web), desktop-first (Windows primary, Linux secondary) — this milestone pins one Godot version everywhere. The project targets 3D (`Node3D`-based scenes).
- **Renderer**: Compatibility renderer on every platform, so desktop, Web export, and low-end devices share one look and one visual test pass.
- **Audience**: Content and UI must work for pre-reading children from around age 3 — minimal reliance on text, no time pressure, no punishment-heavy failure states, large touch/click targets (per the design principles in `docs/roadmap.md`).
- **Accessibility**: All shipped UI text must meet WCAG 2.1 AA color contrast (4.5:1 normal text, 3:1 qualifying large text).
- **Privacy**: The parent dashboard must never transmit child progress data off the local device (per the design principles in `docs/parent-dashboard.md`); the shipped game includes no telemetry.
- **Repo quality gate**: `python3 scripts/tools/quality_gate.py`, run in CI, scans the whole repository (including `.planning/`) and blocks unfinished-work markers, placeholder copy, and broken relative Markdown links — all planning documents must stay clear of these patterns.

## Key Decisions

Decisions marked **Locked** were made explicitly by the user and should not be re-opened. The Outcome column otherwise tracks execution status.

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pivot to a full 3D world: Camiel moves freely in all directions in 3D space with a following camera; levels and lessons are redesigned for 3D | Decided during the paused (2D) Phase 1 discussion, 2026-09-11 | Locked |
| Fully replace the 2D game: the 3D game is built from scratch in this same repository; 2D scenes/scripts/assets are reference only and are removed from the runtime project after being archived under a git tag (the removal itself is confirmed with the user at that time) | Avoids maintaining two parallel games; the 2D code still documents gameplay and lesson intent worth porting | Locked |
| Start with primitive shapes, then replace Camiel in Phase 03.1 | The later milestone decision pulled MODEL-01 forward; lesson props stay primitive | Supersedes the initial v2 deferral; authored GLB integrated |
| Rebuild the roadmap now, with no feasibility spike | User chose to proceed straight to a rebuilt roadmap rather than validate 3D feasibility first | Locked |
| Stay on Godot with GDScript for the 3D rebuild | Engine research on 2026-09-11 compared Godot, Unity 6, Unreal 5, and web-native Three.js/Babylon.js: Godot has the lowest migration cost, meets Windows/Linux/Web and glTF needs, is MIT-licensed with no runtime telemetry; Unreal has no Web export, Unity collects diagnostic data by default and needs a C# rewrite | Locked |
| Godot 4.7.2 is the single pinned engine version across CI, exports, and docs | The rebuild selected 4.7.2 and verified the downloaded engine/templates; keep the version fixed until an explicitly tested upgrade | Locked |
| Compatibility renderer everywhere | One look across Windows, Linux, Web, and low-end devices; simpler lighting suits primitive-shape visuals | Locked |
| The win screen shows two buttons, "Nog een keer" (replay) and "Naar menu", each with an icon, activated by tap, click, or Enter on the focused button, through one code path | Carried forward from the paused Phase 1 (2D) discussion; applies to whichever phase builds the win screen (Phase 2 in the rebuilt roadmap) | Locked |
| One milestone bundles the 3D-foundation and lesson-parity phases first, then the alpha-v0.0.4 feature phases | Building voice-over, mobile, web, and dashboard features on top of an unproven 3D foundation would compound risk | Implemented; final acceptance remains open |
| The parent dashboard phase is sequenced after the progress-persistence phase | Building a dashboard before the data it reads actually exists would ship a viewer with nothing to view | Implemented; final acceptance remains open |
| Windows is the primary target, Linux secondary; Web and mobile-touch are this milestone's scope, implemented with explicit verification boundaries | User-set target runtime priority for this milestone, unchanged by the pivot | Implemented; final acceptance remains open |

---
*Last updated: 2026-09-19 — synchronized with merged 3D delivery and evidence boundaries*
