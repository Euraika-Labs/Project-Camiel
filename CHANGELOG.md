# Changelog

## [alpha-v0.0.4] — geïntegreerd op 2026-09-19, release nog niet gepubliceerd

- 3D-herbouw op Godot 4.7.2; oude 2D-runtime gearchiveerd.
- Titelscherm, intro, zes lessen, lesselectie en lokale voortgang.
- Camiel GLB met idle-, loop- en springanimaties; Nederlandse offline spraak.
- Hoogcontrastinstelling, onafhankelijke audiovolumes en gedeelde touchbediening.
- Lokaal ouderdashboard en exports voor Windows, Linux, macOS en Web.
- CI-foutinjectietests en compatibele verplichte Windows-exportcheck.
- Gemergd via PR #10 (`c00504d`); menselijke speeltest, fysieke touchtest, native Windows/Linux-tests en getagde publicatie blijven open.

Onderstaande secties zijn historische 2D-releasenotities en bewijzen geen actuele 3D-functionaliteit.


## [alpha-v0.0.3] — 2026-06-05
### Added
- Educational micro-tasks: red block, blue target, count challenge (lesson_1.tscn)
- Lesson manager with progress tracking (scripts/lesson_manager.gd)
- Red block task (scripts/red_block.gd, scenes/red_block.tscn)
- Blue target task (scripts/blue_target.gd, scenes/blue_target.tscn)
- Count challenge (scripts/count_challenge.gd, scenes/count_challenge.tscn)
- Parent/teacher notes (docs/parent-teacher-notes.md)
- Accessibility report, WCAG 2.1 AA audit (docs/accessibility-report.md)
- GitHub Actions export pipeline (.github/workflows/export.yml)
- Code signing documentation (docs/code-signing.md)
- Title screen (scenes/title_screen.tscn, scripts/title_screen.gd)
- Reusable version label (scenes/ui/version_label.tscn, scripts/ui/version_label.gd)
- Accessibility Autoload (scripts/accessibility.gd)

### Changed
- project.godot main scene: title_screen.tscn
- Main menu: Lesson button added

## [alpha-v0.0.2] — 2026-06-05
### Added
- Main menu with Start button (scenes/main_menu.tscn, scripts/main_menu.gd)
- Audio manager Autoload (scripts/audio_manager.gd)
- Collectible star (scripts/collectible.gd, scenes/collectible.tscn)
- HUD with star counter (scripts/hud.gd)
- Finish marker (scripts/finish_marker.gd, scenes/finish_marker.tscn)
- Audio asset documentation (assets/audio/README.md)

## [alpha-v0.0.1] — 2025
- Initial release. Playable intro scene with Camiel character.
