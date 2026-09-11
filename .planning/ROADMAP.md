# Roadmap: Project Camiel

## Overview

This milestone takes Project Camiel from a documented-but-partially-broken alpha to a build that actually delivers on its own documentation. The first four phases stabilize what already exists — the playable path from title screen through every lesson, progress persistence, accessibility compliance, unreachable subsystem wiring, and the CI/release pipeline — so a young child can complete the game without errors or adult help, with progress saved. The remaining five phases deliver the alpha-v0.0.4 feature ideas from `docs/roadmap.md` on top of that stable foundation: Dutch voice-over, production-quality mobile touch controls, a working Web export, a local parent dashboard, and additional lesson content.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 1: Playable Intro Path** - Title screen through the free-play intro level runs with no runtime errors or dead buttons
- [ ] **Phase 2: Lesson Correctness & Progress Persistence** - Lessons 1-5 are reachable, correct in any task order, and record progress to disk
- [ ] **Phase 3: Accessibility Compliance & Subsystem Wiring** - WCAG AA contrast, a working high-contrast toggle, and unreachable code (mobile controller, UI widgets) wired into live scenes
- [ ] **Phase 4: CI/CD & Release Pipeline Stabilization** - One pinned Godot version, one version-string source, and a release pipeline that produces exactly one correct release
- [ ] **Phase 5: Dutch Voice-Over** - Spoken Dutch audio cues guide pre-reading children through every screen and lesson
- [ ] **Phase 6: Mobile Touch Controls** - Production-quality analog, multi-touch controls available in every level and lesson
- [ ] **Phase 7: Web Export** - A real, CI-built HTML5/Web build that loads and plays in a desktop browser
- [ ] **Phase 8: Parent Dashboard** - A local, read-only web dashboard for a child's lesson progress
- [ ] **Phase 9: Additional Lesson Levels** - At least one new lesson beyond the original five, on a shared lesson pattern

## Phase Details

### Phase 1: Playable Intro Path
**Goal**: A child can go from the title screen through the free-play intro level, using either keyboard or mouse/touch, without hitting a runtime script error or an unresponsive button.
**Depends on**: Nothing (first phase)
**Requirements**: STAB-01, STAB-02, STAB-03, STAB-04, STAB-05, STAB-06, STAB-07, STAB-08
**Success Criteria** (what must be TRUE):
  1. Pressing Play on the title screen (by mouse/tap or by keyboard) transitions to the main menu exactly once, and the About control either performs a defined action or has been removed.
  2. Clicking or tapping Start on the main menu begins the intro level; the Enter key only triggers whichever control currently has focus.
  3. Playing the intro level end to end (walk, collect the star, reach the finish marker) produces no runtime script errors, plays the correct sound effects, and the win overlay and replay both work through one non-duplicated code path.
  4. Background music loops continuously and the sound-effect volume control has an audible effect.
**Plans**: Not yet planned
**UI hint**: yes

### Phase 2: Lesson Correctness & Progress Persistence
**Goal**: Every lesson from 1 through 5 is reachable from the main menu, completes correctly no matter which task is finished first, and its completion is durably recorded to disk.
**Depends on**: Phase 1
**Requirements**: LESSON-01, LESSON-02, LESSON-03, LESSON-04, LESSON-05, LESSON-06, PROGRESS-01, PROGRESS-02
**Success Criteria** (what must be TRUE):
  1. The main menu offers a way to start any of Lessons 1 through 5.
  2. Lesson 1 finishes regardless of which of its three tasks (red block, blue target, counting) the child completes first.
  3. Lesson 2 only completes after circle, square, and triangle are touched in that order.
  4. Lessons 4 and 5 are real, completable educational tasks rather than placeholders, and the collect sound effect plays exactly once per pickup.
  5. Completing any lesson writes a matching entry (lesson_id, stars, time_seconds, completed_at) to user://progress.json, with no compile error from the ProgressTracker autoload.
**Plans**: Not yet planned
**UI hint**: yes

### Phase 3: Accessibility Compliance & Subsystem Wiring
**Goal**: On-screen text meets WCAG 2.1 AA contrast, the high-contrast toggle actually changes the UI, and code already built for the mobile controller and reusable UI widgets is reachable from a live scene instead of sitting unused.
**Depends on**: Phase 2
**Requirements**: ACCESS-01, ACCESS-02, ACCESS-03, WIRING-01, WIRING-02
**Success Criteria** (what must be TRUE):
  1. Every text/background color combination in the shipped UI meets WCAG 2.1 AA contrast (4.5:1 normal text, or 3:1 for text that qualifies as large), verified by computed ratios.
  2. A reachable UI control toggles high-contrast mode and the visual change is applied immediately.
  3. docs/accessibility-report.md and docs/roadmap.md state only the accessibility status that is actually true of the current build.
  4. Touching the on-screen mobile controller moves Camiel in at least the intro level.
  5. Each reusable UI widget scene (dialog popup, menu button, progress bar, version label) is instanced in a reachable scene, or has been removed.
**Plans**: Not yet planned
**UI hint**: yes

### Phase 4: CI/CD & Release Pipeline Stabilization
**Goal**: The build and release pipeline uses one consistent Godot version and version string, and a tagged release reliably produces one correct set of platform artifacts.
**Depends on**: Phase 3
**Requirements**: CI-01, CI-02, CI-03, CI-04, CI-05, CI-06, DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):
  1. The CI workflow, the release workflow, the export workflow, and the Godot setup doc all name the same Godot engine version.
  2. The version shown in-game and used in build artifact names comes from a single source of truth.
  3. The Linux export job produces a valid .tar.gz artifact, and pushing a version tag creates exactly one GitHub release with the Windows, Linux, and macOS files attached as files, not directories.
  4. The CI smoke test fails the build when a script parse error or runtime script error occurs during startup.
  5. README.md, docs/roadmap.md, and docs/build-and-release.md describe only capabilities and instructions that actually exist in this repository, and README's stated license matches LICENSE.
**Plans**: Not yet planned

### Phase 5: Dutch Voice-Over
**Goal**: A pre-reading child can be guided through the whole experience by spoken Dutch audio cues, not just by on-screen text.
**Depends on**: Phase 4
**Requirements**: VOICE-01, VOICE-02
**Success Criteria** (what must be TRUE):
  1. The title screen, main menu, and every lesson's instructions play a spoken Dutch audio cue in addition to their on-screen text.
  2. Task feedback ("Goed zo!") and the win overlay also play a spoken cue.
  3. Voice-over plays through its own audio bus, independently adjustable from background music and sound effects.
**Plans**: Not yet planned
**UI hint**: yes

### Phase 6: Mobile Touch Controls
**Goal**: The game is fully playable by touch on a touchscreen device, matching what keyboard play can do, across every level and lesson.
**Depends on**: Phase 5
**Requirements**: MOBILE-01, MOBILE-02, MOBILE-03
**Success Criteria** (what must be TRUE):
  1. The on-screen joystick moves Camiel at proportional (analog) speed rather than snapping straight to full speed.
  2. A child can hold the movement joystick and press jump at the same time without either input being dropped.
  3. The mobile touch controller is available in the intro level and in every lesson, not only the intro level.
**Plans**: Not yet planned
**UI hint**: yes

### Phase 7: Web Export
**Goal**: Camiel runs as a real, CI-built HTML5/Web build that loads and plays in a desktop browser.
**Depends on**: Phase 6
**Requirements**: WEB-01, WEB-02, WEB-03
**Success Criteria** (what must be TRUE):
  1. The Web export preset uses the correct Godot 4 platform identifier and produces a build from the Godot 4.6.4 editor or CLI.
  2. A CI job builds the Web export on every relevant push or tag, and the resulting build is verified to load.
  3. docs/web-export.md, docs/quick-start.md, and docs/roadmap.md agree with each other, and with the shipped state, on the Web export's actual availability.
**Plans**: Not yet planned

### Phase 8: Parent Dashboard
**Goal**: A parent or teacher can view a child's lesson progress in a local, read-only web dashboard, with no data ever leaving the device. Builds on the progress persistence delivered in Phase 2.
**Depends on**: Phase 7
**Requirements**: DASH-01, DASH-02, DASH-03
**Success Criteria** (what must be TRUE):
  1. A parent or teacher can open the dashboard and see aggregated stats (total lessons completed, total stars, total time, star-rating breakdown, last session) for a given progress.json.
  2. The dashboard serves GET /api/progress and GET /api/summary, and accepts a progress.json upload via POST /api/progress/import, matching the documented contract.
  3. No child progress data is transmitted off the local device; the dashboard makes no external network calls.
**Plans**: Not yet planned
**UI hint**: yes

### Phase 9: Additional Lesson Levels
**Goal**: The game offers educational content beyond the original five lessons, built on a shared lesson pattern so future lessons don't each require a copy-pasted orchestrator.
**Depends on**: Phase 8
**Requirements**: MORE-01, MORE-02
**Success Criteria** (what must be TRUE):
  1. At least one new lesson beyond the original five is reachable from the lesson-select menu and fully completable.
  2. Completing the new lesson records progress the same way Lessons 1-5 do.
  3. The new lesson is built on a shared lesson-base pattern rather than a one-off copy of an existing orchestrator script.
**Plans**: Not yet planned
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Playable Intro Path | 0/0 | Not started | - |
| 2. Lesson Correctness & Progress Persistence | 0/0 | Not started | - |
| 3. Accessibility Compliance & Subsystem Wiring | 0/0 | Not started | - |
| 4. CI/CD & Release Pipeline Stabilization | 0/0 | Not started | - |
| 5. Dutch Voice-Over | 0/0 | Not started | - |
| 6. Mobile Touch Controls | 0/0 | Not started | - |
| 7. Web Export | 0/0 | Not started | - |
| 8. Parent Dashboard | 0/0 | Not started | - |
| 9. Additional Lesson Levels | 0/0 | Not started | - |
