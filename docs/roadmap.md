# Roadmap

## Alpha v0.0.1 — Done (2025)
- Godot project created.
- Camiel character assets generated and imported.
- Camiel animation resource created.
- Camiel converted to CharacterBody2D.
- Playable intro scene created.
- Windows export templates installed.
- Windows alpha build exported.
- GitHub repository created.
- GitHub release created with build assets.

## Alpha v0.0.2 — Done (2026-06-05)
- Simple main menu with one big Start button added.
- Gentle background music and soft sound effects implemented (AudioManager Autoload).
- One collectible object (star) with pickup feedback added.
- HUD showing star count added.
- Finish marker added so the child can complete the intro.

## Alpha v0.0.3 — Done (2026-06-05)
- First educational micro-tasks implemented:
  - Touch the red block (color recognition, cause-effect)
  - Find blue (visual discrimination, observation)
  - Count 1, 2, 3 objects (number sense, one-to-one correspondence)
- Lesson scene (lesson_1.tscn) with progress tracking added.
- Parent/teacher notes created (docs/parent-teacher-notes.md).
- Accessibility checks completed, WCAG 2.1 AA compliant (docs/accessibility-report.md).
- GitHub Actions CI/CD pipeline implemented (.github/workflows/export.yml).
- Code signing documentation created (docs/code-signing.md).
- Branded title screen added (scenes/title_screen.tscn).
- Version label component added (scenes/ui/version_label.tscn).
- Accessibility Autoload singleton added (scripts/accessibility.gd).

## Design Principles (unchanged)
- One idea at a time.
- Clear colors.
- Large UI.
- No time pressure.
- No punishment-heavy failure state.
- Keep controls minimal.

## Known Technical Improvements
- Add code signing for Windows (certificate acquisition required).
- Reduce duplicate legacy assets if repository size becomes an issue.
- Add a proper title screen (DONE: alpha-v0.0.3).
- Add a version label inside the game (DONE: alpha-v0.0.3).
- Add voice-over audio for non-readers.
- Parental dashboard (web-based progress tracking).
- Mobile touch support.
- Web export (HTML5 via Godot).

## Next: Alpha v0.0.4 Ideas
- Voice-over audio (Dutch) for non-readers.
- Parental dashboard (simple web app).
- Mobile touch controls.
- Web export (HTML5 Godot export).
- More lesson levels.

---