# Beta 1 Orchestration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move Project Camiel from the current alpha state to a locally verified Beta 1 candidate.

**Architecture:** Keep the Godot game self-contained and offline. Add a lesson selector, complete a five-lesson first pack, make progress persistence reliable, expose adult-facing local progress guidance, and verify exports without adding cloud services or accounts.

**Tech Stack:** Godot 4.6 GDScript, `.tscn` scenes, Python repository quality gate, GitHub Actions export workflows.

---

## Files And Responsibilities

- `project.godot`: version label, autoloads, input actions, main scene.
- `scripts/title_screen.gd`: title flow and version constant.
- `scenes/title_screen.tscn`: visible Beta 1 version label.
- `scripts/main_menu.gd` and `scenes/main_menu.tscn`: entry points to intro, lesson selector, and adult progress note.
- `scripts/lesson_select.gd` and `scenes/lesson_select.tscn`: five-lesson selection surface.
- `scripts/progress_tracker.gd`: reliable local progress JSON.
- `scripts/lesson_manager.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd`, `scripts/lesson_4.gd`, `scripts/lesson_5.gd`: consistent completion recording and return flow.
- `scenes/lesson_4.tscn` and `scenes/lesson_5.tscn`: real playable lessons.
- `scripts/mobile_controller.gd`, `scenes/ui/mobile_controller.tscn`, `scenes/main.tscn`: touch controls integrated with keyboard controls.
- `docs/roadmap.md`, `docs/parent-teacher-notes.md`, `docs/accessibility-report.md`, `CHANGELOG.md`, `README.md`: Beta 1 candidate status and verification notes.

## Task 1: Runtime Foundation

- [x] Fix title screen node paths.
- [x] Update visible version constants to `beta-1-candidate`.
- [x] Fix `ProgressTracker` JSON writing and add helper methods for lesson completion summaries.
- [x] Add missing input actions used by mobile or UI flow.
- [x] Run repository quality gate.

## Task 2: Lesson Pack Flow

- [x] Add a lesson selector scene with five large lesson buttons and a back button.
- [x] Route main menu lesson button to the selector.
- [x] Complete Lesson 4 with a simple size-comparison task.
- [x] Complete Lesson 5 with a simple review task that combines color and sequence recognition.
- [x] Record lesson completion for lessons 1 through 5.
- [x] Run repository quality gate and Godot resource verifier.

## Task 3: Mobile And Accessibility Controls

- [x] Integrate `scenes/ui/mobile_controller.tscn` into `scenes/main.tscn`.
- [x] Make `camiel_controller.gd` read both keyboard keys and input actions.
- [x] Add mute and reduced-motion state to `Accessibility` or a lightweight settings script.
- [x] Expose adult-safe controls in the menu without adding complex child-facing settings.
- [x] Run repository quality gate and Godot resource verifier.

## Task 4: Parent And Teacher Beta Notes

- [x] Update parent/teacher notes for five lessons.
- [x] Add a local progress viewing section with stored fields and reset guidance.
- [x] Update accessibility report with Beta 1 candidate checks.
- [x] Update changelog and README status.
- [x] Run repository quality gate.

## Task 5: Build And Verification

- [x] Locate or install Godot 4.6.3 CLI.
- [x] Import the project headlessly.
- [x] Run `res://scripts/tools/verify_camiel_resources.gd`.
- [x] Smoke-test startup headlessly.
- [x] Export at least one local desktop build.
- [x] Capture build output paths and known limitations.
- [x] Update roadmap status based on verified evidence.
