# Requirements: Project Camiel

**Defined:** 2026-09-11 (regenerated for the 2D-to-3D pivot)
**Core Value:** A young child can go from the title screen through every lesson, entirely on their own, without hitting a bug or needing adult help — and their progress is remembered afterward.

## v1 Requirements

Requirements for this milestone (3D foundation + lesson parity, then the alpha-v0.0.4 features). Each maps to exactly one roadmap phase. These IDs replace the 2D-era requirement set; none carry over unchanged, because the 2D bugs they described (duplicate signal connections, wrong 2D node paths, unwired 2D widgets) do not exist in a project built from scratch.

### 3D Foundation & Archive

- [ ] **FOUND-01**: The pre-pivot 2D game state (scenes, scripts, and assets) is archived under a dedicated git tag before any 2D runtime content is removed
- [ ] **FOUND-02**: The 2D gameplay scenes, scripts, and assets are removed from the runtime project once the archive tag exists and the user has confirmed the removal
- [ ] **FOUND-03**: The project's renderer (Forward Plus or Compatibility) is decided and set consistently in Godot project settings for the 3D build
- [ ] **FOUND-04**: A `Node3D`-based scene, script, and asset folder structure exists as the baseline for all new 3D content, running on Godot 4.6.4
- [ ] **FOUND-05**: A primitive-shape Camiel (capsule) moves freely in all directions in a small 3D test space, viewed through a camera that follows Camiel
- [ ] **FOUND-06**: A local headless run command surfaces any GDScript parse or runtime script error during startup, runnable before every commit

### Title Screen & Main Menu

- [ ] **MENU-01**: The title screen's Play control transitions to the main menu exactly once, whether triggered by tap, click, or keyboard
- [ ] **MENU-02**: The main menu's Start control responds to tap or click as well as keyboard, through one code path

### 3D Intro Level

- [ ] **INTRO-01**: In the intro level, Camiel moves freely in 3D space (forward, back, left, right) under keyboard control, with a camera that follows Camiel
- [ ] **INTRO-02**: Camiel can jump in the intro level
- [ ] **INTRO-03**: A child can collect a 3D collectible object in the intro level; the pickup sound effect plays exactly once per pickup
- [ ] **INTRO-04**: Reaching the 3D finish marker triggers the win screen, driven by a single signal-driven code path rather than a direct cross-script call
- [ ] **INTRO-05**: The win screen shows two buttons, "Nog een keer" (replay) and "Naar menu", each with an icon, activated by tap, click, or Enter on the focused button, through one code path
- [ ] **INTRO-06**: Background music loops continuously in the intro level and lesson scenes, and the SFX volume control has an audible effect

### 3D Lesson Parity & Progress Persistence

- [ ] **LESSON-01**: Lesson 1 (3D colour recognition red/blue and counting to 3) finishes regardless of which of its three tasks the child completes first
- [ ] **LESSON-02**: Lesson 2 (3D shape order) only completes after circle, square, and triangle are touched in that specific order
- [ ] **LESSON-03**: Lesson 3 (3D sequence) only completes after its targets are activated in the defined order
- [ ] **LESSON-04**: Lesson 4 is a real, completable 3D educational task (its concept is a pending decision, to be settled when this requirement is discussed)
- [ ] **LESSON-05**: Lesson 5 is a real, completable 3D educational task (its concept is a pending decision, to be settled when this requirement is discussed)
- [ ] **LESSON-06**: A lesson-select screen, reachable from the main menu, offers a way to start any of Lessons 1 through 5 by tap, click, or keyboard
- [ ] **PROGRESS-01**: The progress-tracking system initializes without a script error
- [ ] **PROGRESS-02**: Completing any lesson (1 through 5) writes a matching entry (`lesson_id`, `stars`, `time_seconds`, `completed_at`) to `user://progress.json`

### Accessibility & Release Pipeline Hardening

- [ ] **ACCESS-01**: Every text/background color combination in the shipped 3D UI meets WCAG 2.1 AA contrast (4.5:1 normal text, 3:1 for text that qualifies as large), verified by computed ratios
- [ ] **ACCESS-02**: A reachable UI control toggles high-contrast mode, and the visual change applies immediately to on-screen UI
- [ ] **CI-01**: A single Godot engine version (4.6.4) is pinned and used consistently by the CI workflow, the release workflow, the export workflow, and the Godot setup doc
- [ ] **CI-02**: The version string shown in-game and used in build artifact names comes from one source of truth instead of being hand-edited in multiple files
- [ ] **CI-03**: The CI pipeline fails the build when a GDScript parse error or runtime script error occurs during startup or scene load, across the new 3D scenes
- [ ] **CI-04**: The Linux export job successfully packages the built binary into a `.tar.gz` artifact
- [ ] **CI-05**: Pushing a version tag creates exactly one GitHub release with the correct Windows, Linux, and macOS files attached as files, not directories
- [ ] **DOCS-01**: `README.md` and `docs/roadmap.md` describe only 3D capabilities that are actually reachable and working in the current build
- [ ] **DOCS-02**: `README.md`'s stated license matches the repository's actual `LICENSE` file

### Dutch Voice-Over

- [ ] **VOICE-01**: The title screen, main menu, and every lesson's instructions play a spoken Dutch audio cue in addition to their on-screen text, and task feedback plus the win overlay also play a spoken cue
- [ ] **VOICE-02**: Voice-over audio is mixed through its own bus, adjustable independently of background music and sound effects

### Mobile Touch Controls

- [ ] **MOBILE-01**: The on-screen joystick maps to 3D movement proportionally (analog) rather than snapping to full speed
- [ ] **MOBILE-02**: A child can hold the movement joystick and press the jump control at the same time without either input being dropped
- [ ] **MOBILE-03**: The touch controller is instanced in every level and lesson scene, not only the intro level

### Web Export

- [ ] **WEB-01**: The Web export preset uses the correct Godot 4 platform identifier and the Compatibility renderer, and produces a build via the Godot 4.6.4 editor or CLI
- [ ] **WEB-02**: A CI job builds the Web export, and the resulting build is verified to load
- [ ] **WEB-03**: `docs/web-export.md`, `docs/quick-start.md`, and `docs/roadmap.md` agree with each other, and with the shipped state, on the Web export's actual availability

### Parent Dashboard

- [ ] **DASH-01**: A parent or teacher can view aggregated progress stats (total lessons completed, total stars, total time, star-rating breakdown, last session) for a child's `progress.json` in a local, read-only web dashboard
- [ ] **DASH-02**: The dashboard serves `GET /api/progress` and `GET /api/summary`, and accepts a `progress.json` upload via `POST /api/progress/import`, matching the documented contract
- [ ] **DASH-03**: No child progress data leaves the local device — the dashboard makes no external network calls

### Additional Lesson Levels

- [ ] **MORE-01**: At least one new lesson beyond the original five is reachable from the lesson-select screen, fully completable, and records progress the same way Lessons 1-5 do
- [ ] **MORE-02**: New lessons are built on a shared 3D lesson-base pattern rather than a one-off copy of an existing orchestrator script

## v2 Requirements

Deferred to a future milestone. Tracked but not in this roadmap.

### Character Art

- **MODEL-01**: Camiel's real 3D model and animations replace the primitive-shape placeholder; the model's source (AI-generated from the existing 2D art vs. made/commissioned) is an open decision not yet settled

### Platform Expansion

- **PLAT-01**: Android APK export builds and installs on a physical device
- **PLAT-02**: macOS export is signed and notarized well enough to avoid a Gatekeeper block

### Release Hardening

- **REL-01**: Windows and macOS release binaries are code-signed
- **REL-02**: Committed `.pi/` agent-run data is removed from git history and excluded from future commits, enforced by a CI check
- **REL-03**: GitHub Actions third-party actions are pinned by commit SHA rather than by mutable version tag

### Parent Dashboard Extensions

- **DASH-EXT-01**: The parent dashboard can merge `progress.json` files from more than one child's device
- **DASH-EXT-02**: The parent dashboard is protected by a passphrase screen for shared-computer use

## Out of Scope

Explicitly excluded from this milestone. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Multiplayer or online features | Camiel is an offline, single-player, single-device experience by design |
| Real (non-primitive) 3D art and animations for Camiel and lesson props | v1 ships with primitive shapes per a locked decision; see v2 `MODEL-01` |
| Android APK export / macOS code-signing hardening | v2 (`PLAT-01`, `PLAT-02`, `REL-01`) |
| Git LFS / asset repository restructuring | Tech debt tracked in `.planning/codebase/CONCERNS.md`; does not block the milestone success metric |
| Parent dashboard extensions beyond the documented read-only single-child viewer | v2 (`DASH-EXT-01`, `DASH-EXT-02`) |

## Traceability

Which phases cover which requirements.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Pending |
| FOUND-02 | Phase 1 | Pending |
| FOUND-03 | Phase 1 | Pending |
| FOUND-04 | Phase 1 | Pending |
| FOUND-05 | Phase 1 | Pending |
| FOUND-06 | Phase 1 | Pending |
| MENU-01 | Phase 2 | Pending |
| MENU-02 | Phase 2 | Pending |
| INTRO-01 | Phase 2 | Pending |
| INTRO-02 | Phase 2 | Pending |
| INTRO-03 | Phase 2 | Pending |
| INTRO-04 | Phase 2 | Pending |
| INTRO-05 | Phase 2 | Pending |
| INTRO-06 | Phase 2 | Pending |
| LESSON-01 | Phase 3 | Pending |
| LESSON-02 | Phase 3 | Pending |
| LESSON-03 | Phase 3 | Pending |
| LESSON-04 | Phase 3 | Pending |
| LESSON-05 | Phase 3 | Pending |
| LESSON-06 | Phase 3 | Pending |
| PROGRESS-01 | Phase 3 | Pending |
| PROGRESS-02 | Phase 3 | Pending |
| ACCESS-01 | Phase 4 | Pending |
| ACCESS-02 | Phase 4 | Pending |
| CI-01 | Phase 4 | Pending |
| CI-02 | Phase 4 | Pending |
| CI-03 | Phase 4 | Pending |
| CI-04 | Phase 4 | Pending |
| CI-05 | Phase 4 | Pending |
| DOCS-01 | Phase 4 | Pending |
| DOCS-02 | Phase 4 | Pending |
| VOICE-01 | Phase 5 | Pending |
| VOICE-02 | Phase 5 | Pending |
| MOBILE-01 | Phase 6 | Pending |
| MOBILE-02 | Phase 6 | Pending |
| MOBILE-03 | Phase 6 | Pending |
| WEB-01 | Phase 7 | Pending |
| WEB-02 | Phase 7 | Pending |
| WEB-03 | Phase 7 | Pending |
| DASH-01 | Phase 8 | Pending |
| DASH-02 | Phase 8 | Pending |
| DASH-03 | Phase 8 | Pending |
| MORE-01 | Phase 9 | Pending |
| MORE-02 | Phase 9 | Pending |

**Coverage:**
- v1 requirements: 44 total
- Mapped to phases: 44
- Unmapped: 0

---
*Requirements defined: 2026-09-11*
*Last updated: 2026-09-11 — regenerated for the 2D-to-3D pivot, replacing the 2D-era requirement set*
