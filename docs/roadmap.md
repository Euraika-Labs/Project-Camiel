# Roadmap

Project Camiel is a child-friendly Godot game for children around age 3+. The product direction stays narrow: gentle interaction, clear feedback, local privacy, and no pressure mechanics.

## Current Position

Project Camiel is now a `beta-1-candidate`. The first learning pack is playable locally with five lessons, a lesson selector, local progress tracking, an adult progress view, accessibility toggles, mobile touch controls in the intro scene, and desktop export presets.

The candidate has been verified with Godot 4.6.3 and a local macOS export smoke test. It is not yet the official Beta 1 release until the trusted tester package, known-issues note, and feedback loop are prepared.

## Research And Decision Gates

Before each milestone, run the workflow in [Agent Research Workflow](agent-research-workflow.md). Use primary sources for platform, privacy, and accessibility decisions:

- Godot export documentation: https://docs.godotengine.org/en/4.6/tutorials/export/index.html
- FTC children's privacy guidance: https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy
- WCAG 2.2 standard: https://www.w3.org/TR/WCAG22/
- Google Play Families policy: https://support.google.com/googleplay/android-developer/answer/16810878
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- EU child data safeguards: https://commission.europa.eu/law/law-topic/data-protection/rules-business-and-organisations/legal-grounds-processing-data/are-there-any-specific-safeguards-data-about-children_en

## Completed Foundations

- Alpha v0.0.1: Godot project, Camiel character scene, first playable intro, basic movement, animation, and Windows release assets.
- Alpha v0.0.2: main menu, background music, sound effects, collectible star, HUD counter, and finish marker.
- Alpha v0.0.3: Lesson 1, parent/teacher notes, accessibility report, title screen, version label, and CI foundations.

## Beta 1 Candidate - Done

- Five playable lessons: color/counting, shapes, sequence, size comparison, and color order.
- Lesson selector with large child-facing buttons and progress summary.
- Local `user://progress.json` tracking through `ProgressTracker`.
- Adult progress screen with summary, reset, mute, reduced-motion, and high-contrast controls.
- Offline privacy posture: no accounts, ads, telemetry, cloud sync, or child data collection.
- WAV placeholder audio and headless-safe audio autoload behavior.
- Godot 4.6.3 export presets for Windows, Linux, macOS, Android, and HTML5.
- Verification scripts for resources and Beta 1 flow.

## Remaining Beta 1 Release Gate

Beta 1 is the first trusted external testing release for families, teachers, and caregivers. Before tagging it:

- Rebuild release artifacts from a clean checkout.
- Package at least Windows and macOS desktop builds; include Linux, web, or Android only after target-specific QA.
- Add a short known-issues note covering unsigned macOS Gatekeeper behavior and Android SDK requirements.
- Attach parent/teacher notes, privacy note, accessibility note, and feedback instructions.
- Collect feedback through adult-facing forms only.
- Freeze new feature scope until the first feedback review is complete.

Exit gate: Beta 1 feedback should identify polish and content priorities, not basic flow, privacy, or build reliability failures.

## Verification Checklist

Run these before Beta 1 tagging:

```bash
python3 scripts/tools/quality_gate.py --root .
python3 -m unittest tests.test_quality_gate
godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd
godot --headless --path . --script res://scripts/tools/verify_beta1_flow.gd
godot --headless --path . --quit-after 2
godot --headless --path . --export-release "macOS" dist/macos/Camiel.zip
```

## Deferred Until After Beta 1

- Online accounts, cloud sync, multiplayer, ads, in-app purchases, and telemetry.
- Broad app-store release campaigns.
- Advanced adaptive learning.
- User-generated content.
- Classroom administration beyond simple local progress viewing.
