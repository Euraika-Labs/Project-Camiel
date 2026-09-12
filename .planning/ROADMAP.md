# Roadmap: Project Camiel

## Overview

This roadmap replaces the 2D-stabilization plan after the project pivoted to a full 3D game. The first four phases build the 3D foundation and reach lesson parity with the original 2D design — the 2D game archived and retired, a working 3D project baseline, a fully playable title-screen-through-intro-level experience, all five lessons ported to 3D with progress saved, and a UI/pipeline hardening pass — so a young child can complete the 3D game without errors or adult help, with progress saved. The remaining five phases deliver the alpha-v0.0.4 feature ideas from `docs/roadmap.md` on top of that 3D foundation: Dutch voice-over, production-quality mobile touch controls, a working Web export, a local parent dashboard, and additional lesson content.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: 3D Foundation & Archive** - The 2D game is archived and removed, and a thin playable 3D slice runs on a clean project baseline (completed 2026-09-11)
- [ ] **Phase 2: Playable 3D Intro Experience** - Title screen through the 3D intro level (move, jump, collect, reach goal, win screen) works by tap, click, or keyboard
- [ ] **Phase 3: 3D Lesson Parity & Progress Persistence** - Lessons 1-5 are reachable in 3D, correct, and record progress to disk
- [ ] **Phase 4: Accessibility & Release Pipeline Hardening** - WCAG AA contrast, a working high-contrast toggle, and a release pipeline that produces exactly one correct release
- [ ] **Phase 5: Dutch Voice-Over** - Spoken Dutch audio cues guide pre-reading children through every screen and lesson
- [ ] **Phase 6: Mobile Touch Controls** - Production-quality analog, multi-touch controls available in every level and lesson
- [ ] **Phase 7: Web Export** - A real, CI-built HTML5/Web build that loads and plays in a desktop browser
- [ ] **Phase 8: Parent Dashboard** - A local, read-only web dashboard for a child's lesson progress
- [ ] **Phase 9: Additional Lesson Levels** - At least one new lesson beyond the original five, on a shared 3D lesson pattern

## Phase Details

### Phase 1: 3D Foundation & Archive

**Goal**: The pre-pivot 2D game is safely archived and removed from the runtime project, and a new 3D Godot project baseline runs a primitive-shape Camiel moving freely in a small 3D test space with a following camera, verified by a local headless run that surfaces script errors.
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06
**Success Criteria** (what must be TRUE):

  1. The pre-pivot 2D game state is archived under a dedicated git tag before any 2D runtime content is removed.
  2. The 2D gameplay scenes, scripts, and assets are removed from the runtime project once the archive tag exists and the user has confirmed the removal.
  3. The project's renderer (Forward Plus or Compatibility) is decided and set consistently in Godot project settings.
  4. A `Node3D`-based scene/script/asset folder structure exists as the baseline for all new 3D content, running on Godot 4.7.2.
  5. A primitive-shape Camiel (capsule) moves freely in all directions in a small 3D test space, viewed through a camera that follows Camiel.
  6. Running a local headless command surfaces any GDScript parse or runtime script error before commit.

**Plans**: 6/6 plans executed

Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Archive the 2D game under archive/2d-alpha-v0.0.3 and remove it after user confirmation
- [x] 01-02-PLAN.md — Install Godot 4.7.2 with integrity checks; record engine facts and the headless stall soak

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-03-PLAN.md — Tracer: Compatibility/Jolt Node3D baseline plus the one headless project check and its self-test

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-04-PLAN.md — Primitive Camiel walks, jumps, is followed by the camera, and softly returns after falls
- [x] 01-05-PLAN.md — CI and release run the project check on checksum-verified Godot 4.7.2

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 01-06-PLAN.md — Final gate and the D-11 playtest that confirms the steering model

**Open Questions** (owned by this phase — do not decide during roadmapping):

- Renderer: Forward Plus vs. Compatibility. Must be settled here because it affects every 3D visual built afterward and the later Web export.
- Camera and control scheme for free 3D movement suitable for a child around age 3 (auto-follow vs. manual camera, keyboard/mouse/touch mapping) — this is the phase that first builds movement.

### Phase 2: Playable 3D Intro Experience

**Goal**: A child can go from the title screen through the free-play 3D intro level — moving, jumping, collecting, and reaching the goal — using tap, click, or keyboard, and see a working win screen.
**Depends on**: Phase 1
**Requirements**: MENU-01, MENU-02, INTRO-01, INTRO-02, INTRO-03, INTRO-04, INTRO-05, INTRO-06
**Success Criteria** (what must be TRUE):

  1. Pressing Play on the title screen (tap, click, or keyboard) transitions to the main menu exactly once.
  2. Pressing Start on the main menu (tap, click, or keyboard) begins the 3D intro level through one code path.
  3. In the intro level, Camiel moves freely in 3D space, jumps, and can collect a 3D collectible object with pickup feedback playing exactly once.
  4. Reaching the 3D finish marker shows the win screen with two buttons, "Nog een keer" (replay) and "Naar menu", each with an icon, activated by tap, click, or Enter on the focused button, through one code path.
  5. Background music loops continuously and the SFX volume control has an audible effect.

**Plans**: 6 plans
**UI hint**: yes

Plans:
**Wave 1**

- [ ] 02-01-PLAN.md — Genuine Vorbis audio, a real three-bus layout, and the rebuilt AudioManager autoload
- [ ] 02-02-PLAN.md — The shared icon-and-label menu button, its six drawn icons, and the UI theme

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 02-03-PLAN.md — Tracer: title screen to main menu to an enclosed, walkable 3D intro level, with the 3D assertion retargeted

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 02-04-PLAN.md — The collectible, the finish marker's signal, and the in-place win-and-replay overlay
- [ ] 02-05-PLAN.md — The main menu's audio panel and sliders, plus two new headless self-test cases

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 02-06-PLAN.md — Final gate and the D-30 playtest of the whole loop

### Phase 3: 3D Lesson Parity & Progress Persistence

**Goal**: Every lesson from 1 through 5 is reachable in 3D from a lesson-select screen, completes correctly according to its own rules, and its completion is durably recorded to disk.
**Depends on**: Phase 2
**Requirements**: LESSON-01, LESSON-02, LESSON-03, LESSON-04, LESSON-05, LESSON-06, PROGRESS-01, PROGRESS-02
**Success Criteria** (what must be TRUE):

  1. A lesson-select screen, reachable from the main menu, offers a way to start any of Lessons 1 through 5 by tap, click, or keyboard.
  2. Lesson 1 (3D colour recognition red/blue and counting to 3) finishes regardless of which of its three tasks is completed first.
  3. Lesson 2 (3D shape order circle-square-triangle) only completes after the shapes are touched in that order.
  4. Lesson 3 (3D sequence) only completes after its targets are activated in the defined order.
  5. Lessons 4 and 5 are real, completable 3D educational tasks, and completing any lesson (1-5) writes a matching entry (lesson_id, stars, time_seconds, completed_at) to user://progress.json, with no error from the progress-tracking system.

**Plans**: Not yet planned
**UI hint**: yes

**Open Questions** (owned by this phase — do not decide during roadmapping):

- Design of Lessons 4 and 5 (they were empty placeholders in 2D). Their concrete educational concept is undecided and must be settled while this phase is discussed.

### Phase 4: Accessibility & Release Pipeline Hardening

**Goal**: The 3D build's UI meets WCAG 2.1 AA contrast with a working high-contrast toggle, and the CI/release pipeline uses one consistent Godot version and reliably produces exactly one correct release.
**Depends on**: Phase 3
**Requirements**: ACCESS-01, ACCESS-02, CI-01, CI-02, CI-03, CI-04, CI-05, DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):

  1. Every text/background colour combination in the shipped 3D UI meets WCAG 2.1 AA contrast (4.5:1 normal text, or 3:1 for text that qualifies as large), verified by computed ratios.
  2. A reachable UI control toggles high-contrast mode and the visual change is applied immediately.
  3. The CI workflow, the release workflow, the export workflow, and the Godot setup doc all name Godot 4.7.2 as the single pinned engine version, and the in-game version string and build artifact names are drawn from one source of truth.
  4. The CI pipeline fails the build when a GDScript parse error or runtime script error occurs during startup or scene load, and the Linux export job produces a valid .tar.gz artifact.
  5. Pushing a version tag creates exactly one GitHub release with the Windows, Linux, and macOS files attached as files, not directories, and README.md / docs/roadmap.md describe only 3D capabilities that actually exist, with README's stated license matching LICENSE.

**Plans**: Not yet planned
**UI hint**: yes

### Phase 5: Dutch Voice-Over

**Goal**: A pre-reading child can be guided through the whole 3D experience by spoken Dutch audio cues, not just by on-screen text.
**Depends on**: Phase 4
**Requirements**: VOICE-01, VOICE-02
**Success Criteria** (what must be TRUE):

  1. The title screen, main menu, and every lesson's instructions play a spoken Dutch audio cue in addition to their on-screen text.
  2. Task feedback ("Goed zo!") and the win overlay also play a spoken cue.
  3. Voice-over plays through its own audio bus, independently adjustable from background music and sound effects.

**Plans**: Not yet planned
**UI hint**: yes

### Phase 6: Mobile Touch Controls

**Goal**: The 3D game is fully playable by touch on a touchscreen device, matching what keyboard play can do, across every level and lesson.
**Depends on**: Phase 5
**Requirements**: MOBILE-01, MOBILE-02, MOBILE-03
**Success Criteria** (what must be TRUE):

  1. The on-screen joystick moves Camiel in 3D space at proportional (analog) speed rather than snapping straight to full speed.
  2. A child can hold the movement joystick and press jump at the same time without either input being dropped.
  3. The touch controller is available in the intro level and in every lesson, not only the intro level.

**Plans**: Not yet planned
**UI hint**: yes

### Phase 7: Web Export

**Goal**: Camiel runs as a real, CI-built HTML5/Web 3D build that loads and plays in a desktop browser.
**Depends on**: Phase 6
**Requirements**: WEB-01, WEB-02, WEB-03
**Success Criteria** (what must be TRUE):

  1. The Web export preset uses the correct Godot 4 platform identifier and the Compatibility renderer, and produces a build from the Godot 4.7.2 editor or CLI.
  2. A CI job builds the Web export on every relevant push or tag, and the resulting build is verified to load.
  3. docs/web-export.md, docs/quick-start.md, and docs/roadmap.md agree with each other, and with the shipped state, on the Web export's actual availability.

**Plans**: Not yet planned

### Phase 8: Parent Dashboard

**Goal**: A parent or teacher can view a child's 3D-lesson progress in a local, read-only web dashboard, with no data ever leaving the device. Builds on the progress persistence delivered in Phase 3.
**Depends on**: Phase 7
**Requirements**: DASH-01, DASH-02, DASH-03
**Success Criteria** (what must be TRUE):

  1. A parent or teacher can open the dashboard and see aggregated stats (total lessons completed, total stars, total time, star-rating breakdown, last session) for a given progress.json.
  2. The dashboard serves GET /api/progress and GET /api/summary, and accepts a progress.json upload via POST /api/progress/import, matching the documented contract.
  3. No child progress data is transmitted off the local device; the dashboard makes no external network calls.

**Plans**: Not yet planned
**UI hint**: yes

### Phase 9: Additional Lesson Levels

**Goal**: The 3D game offers educational content beyond the original five lessons, built on a shared lesson pattern so future lessons don't each require a copy-pasted orchestrator.
**Depends on**: Phase 8
**Requirements**: MORE-01, MORE-02
**Success Criteria** (what must be TRUE):

  1. At least one new lesson beyond the original five is reachable from the lesson-select screen and fully completable.
  2. Completing the new lesson records progress the same way Lessons 1-5 do.
  3. The new lesson is built on a shared 3D lesson-base pattern rather than a one-off copy of an existing orchestrator script.

**Plans**: Not yet planned
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. 3D Foundation & Archive | 6/6 | Complete    | 2026-09-11 |
| 2. Playable 3D Intro Experience | 0/6 | Planned     | - |
| 3. 3D Lesson Parity & Progress Persistence | 0/0 | Not started | - |
| 4. Accessibility & Release Pipeline Hardening | 0/0 | Not started | - |
| 5. Dutch Voice-Over | 0/0 | Not started | - |
| 6. Mobile Touch Controls | 0/0 | Not started | - |
| 7. Web Export | 0/0 | Not started | - |
| 8. Parent Dashboard | 0/0 | Not started | - |
| 9. Additional Lesson Levels | 0/0 | Not started | - |
