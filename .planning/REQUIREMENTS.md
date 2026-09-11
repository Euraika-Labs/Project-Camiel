# Requirements: Project Camiel

**Defined:** 2026-09-11
**Core Value:** A young child can go from the title screen through every lesson, entirely on their own, without hitting a bug or needing adult help — and their progress is remembered afterward.

## v1 Requirements

Requirements for this milestone (stabilization + alpha-v0.0.4 features). Each maps to exactly one roadmap phase.

### Stabilization: Playable Intro Path

- [ ] **STAB-01**: The title screen's Play control transitions to the main menu exactly once, whether triggered by mouse/tap or by keyboard
- [ ] **STAB-02**: The title screen's About control either performs a defined action or has been removed
- [ ] **STAB-03**: The main menu's Start control responds to a click or tap, not only the Enter key
- [ ] **STAB-04**: The main menu's Enter key triggers only the action of the currently focused control
- [ ] **STAB-05**: The Collectible and Finish Marker signals each connect exactly once (no duplicate-connection runtime errors)
- [ ] **STAB-06**: The Finish Marker emits its `finished` signal, and the intro level's win flow is driven by that signal rather than a direct call into another script
- [ ] **STAB-07**: Background music loops continuously, and the sound-effect volume control has an audible effect
- [ ] **STAB-08**: The in-game HUD's star counter initializes without a runtime script error

### Lesson Correctness, Reachability & Progress Persistence

- [ ] **LESSON-01**: Lesson 1 finishes regardless of which of its three tasks (red block, blue target, counting) the child completes first
- [ ] **LESSON-02**: Lesson 2 only completes after circle, square, and triangle are touched in that specific order
- [ ] **LESSON-03**: The main menu offers a way to start any of Lessons 1 through 5
- [ ] **LESSON-04**: Lesson 4 is a real, completable educational task rather than a placeholder
- [ ] **LESSON-05**: Lesson 5 is a real, completable educational task rather than a placeholder
- [ ] **LESSON-06**: The collect sound effect plays exactly once per pickup
- [ ] **PROGRESS-01**: The `ProgressTracker` autoload loads without a script compile error
- [ ] **PROGRESS-02**: Completing any lesson (1 through 5) writes a matching entry (`lesson_id`, `stars`, `time_seconds`, `completed_at`) to `user://progress.json`

### Accessibility Compliance & Subsystem Wiring

- [ ] **ACCESS-01**: Every text/background color combination in the shipped UI meets WCAG 2.1 AA contrast (4.5:1 normal text, 3:1 for text that qualifies as large), verified by computed ratios
- [ ] **ACCESS-02**: A reachable UI control toggles high-contrast mode, and the visual change applies immediately to on-screen UI
- [ ] **ACCESS-03**: `docs/accessibility-report.md` and `docs/roadmap.md` state only the accessibility status that is actually true of the current build
- [ ] **WIRING-01**: The mobile touch controller is instanced into at least the intro level and joins the group that `camiel_controller.gd` already looks up, so on-screen touch input moves Camiel
- [ ] **WIRING-02**: Each reusable UI widget scene (dialog popup, menu button, progress bar, version label) is instanced in a reachable scene, or removed if superseded

### CI/CD & Release Pipeline Stabilization

- [ ] **CI-01**: A single Godot engine version is pinned and used consistently by the CI workflow, the release workflow, the export workflow, and the Godot setup doc
- [ ] **CI-02**: The version string shown in-game and used in build artifact names comes from one source of truth instead of being hand-edited in multiple files
- [ ] **CI-03**: The Linux export job successfully packages the built binary into a `.tar.gz` artifact
- [ ] **CI-04**: Pushing a version tag creates exactly one GitHub release with the correct Windows, Linux, and macOS files attached as files, not directories
- [ ] **CI-05**: The CI smoke test fails the build when a script parse error or runtime script error occurs during startup
- [ ] **CI-06**: `docs/build-and-release.md` references only scripts, git hosts, and download URLs that actually exist for this project
- [ ] **DOCS-01**: `README.md` and `docs/roadmap.md` describe only capabilities that are actually reachable and working in the current build, with a roadmap section documenting the alpha-v0.0.4 work once it ships
- [ ] **DOCS-02**: `README.md`'s stated license matches the repository's actual `LICENSE` file

### Dutch Voice-Over

- [ ] **VOICE-01**: The title screen, main menu, and every lesson's instructions play a spoken Dutch audio cue in addition to their on-screen text, and task feedback plus the win overlay also play a spoken cue
- [ ] **VOICE-02**: Voice-over audio is mixed through its own bus, adjustable independently of background music and sound effects

### Mobile Touch Controls (Production Quality)

- [ ] **MOBILE-01**: The on-screen joystick provides proportional (analog) movement rather than snapping to full speed
- [ ] **MOBILE-02**: A child can hold the movement joystick and press the jump control at the same time without either input being dropped
- [ ] **MOBILE-03**: The mobile touch controller is instanced in every level and lesson scene, not only the intro level

### Web Export

- [ ] **WEB-01**: The Web export preset uses the correct Godot 4 platform identifier and produces a build via the Godot 4.6.4 editor or CLI
- [ ] **WEB-02**: A CI job builds the Web export, and the resulting build is verified to load
- [ ] **WEB-03**: `docs/web-export.md`, `docs/quick-start.md`, and `docs/roadmap.md` agree with each other, and with the shipped state, on the Web export's actual availability

### Parent Dashboard

- [ ] **DASH-01**: A parent or teacher can view aggregated progress stats (total lessons completed, total stars, total time, star-rating breakdown, last session) for a child's `progress.json` in a local, read-only web dashboard
- [ ] **DASH-02**: The dashboard serves `GET /api/progress` and `GET /api/summary`, and accepts a `progress.json` upload via `POST /api/progress/import`, matching the documented contract
- [ ] **DASH-03**: No child progress data leaves the local device — the dashboard makes no external network calls

### Additional Lesson Levels

- [ ] **MORE-01**: At least one new lesson beyond the original five is reachable from the lesson-select menu, fully completable, and records progress the same way Lessons 1-5 do
- [ ] **MORE-02**: New lessons are built on a shared lesson-base pattern rather than a one-off copy of an existing orchestrator script

## v2 Requirements

Deferred to a future milestone. Tracked but not in this roadmap.

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
| Git LFS / asset repository restructuring | Tech debt tracked in `.planning/codebase/CONCERNS.md`; does not block the milestone success metric |
| Node-path-to-unique-name refactor across scripts | Maintainability improvement, not user-observable behavior; deferred |
| Retrofitting a shared task base class onto the existing Lessons 1-3 scripts | Tech debt; `MORE-02` only requires new lessons to use a shared pattern going forward |

## Traceability

Which phases cover which requirements.

| Requirement | Phase | Status |
|-------------|-------|--------|
| STAB-01 | Phase 1 | Pending |
| STAB-02 | Phase 1 | Pending |
| STAB-03 | Phase 1 | Pending |
| STAB-04 | Phase 1 | Pending |
| STAB-05 | Phase 1 | Pending |
| STAB-06 | Phase 1 | Pending |
| STAB-07 | Phase 1 | Pending |
| STAB-08 | Phase 1 | Pending |
| LESSON-01 | Phase 2 | Pending |
| LESSON-02 | Phase 2 | Pending |
| LESSON-03 | Phase 2 | Pending |
| LESSON-04 | Phase 2 | Pending |
| LESSON-05 | Phase 2 | Pending |
| LESSON-06 | Phase 2 | Pending |
| PROGRESS-01 | Phase 2 | Pending |
| PROGRESS-02 | Phase 2 | Pending |
| ACCESS-01 | Phase 3 | Pending |
| ACCESS-02 | Phase 3 | Pending |
| ACCESS-03 | Phase 3 | Pending |
| WIRING-01 | Phase 3 | Pending |
| WIRING-02 | Phase 3 | Pending |
| CI-01 | Phase 4 | Pending |
| CI-02 | Phase 4 | Pending |
| CI-03 | Phase 4 | Pending |
| CI-04 | Phase 4 | Pending |
| CI-05 | Phase 4 | Pending |
| CI-06 | Phase 4 | Pending |
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
- v1 requirements: 42 total
- Mapped to phases: 42
- Unmapped: 0

---
*Requirements defined: 2026-09-11*
*Last updated: 2026-09-11 after initial roadmap creation*
