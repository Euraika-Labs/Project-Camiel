# Accessibility Report - Camiel Beta 1 Candidate

**Reference:** WCAG 2.2 principles where applicable to a small Godot game.

This report covers the local Beta 1 candidate: title screen, main menu, intro scene, lesson selector, five lessons, and adult progress screen.

## Implemented Supports

- Large menu buttons and lesson-selection buttons.
- Keyboard control for desktop play.
- Mobile touch overlay for the intro scene on touch devices.
- Adult-facing mute, reduced-motion, and high-contrast controls.
- Reduced-motion mode disables collectible bobbing.
- Visual feedback accompanies audio feedback for success events.
- No timers, score penalties, flashing, strobing, or punishment-heavy failure states.
- Local-only progress storage; no accounts or online data flow.

## Touch And Input

| Area | Current State | Beta 1 Status |
|------|---------------|---------------|
| Main menu | Large buttons, keyboard focus starts on Start | Ready for trusted testing |
| Lesson selector | Five large lesson buttons plus back button | Ready for trusted testing |
| Intro scene | Keyboard plus touch movement/jump overlay | Needs device playtest |
| Lessons | Keyboard movement with large in-world targets | Needs child playtest |
| Adult screen | Buttons for settings and reset | Adult-only surface |

## Audio And Visual Redundancy

Every success event has a visible state change:

- Collectibles disappear or update counters.
- Colour, size, and sequence targets change label and colour.
- Lesson completion shows a written success message before returning.

Mute is available from the adult screen. Dutch voice-over prompts are still a recommended future improvement for non-readers.

## Motion

The game avoids fast animation. Reduced-motion mode currently stops collectible bobbing. Future animation additions should check `Accessibility.is_reduced_motion_enabled()` before looping decorative motion.

## Contrast

High-contrast state is available through the adult screen and `Accessibility.toggle_high_contrast()`. Existing scenes use large dark text on bright backgrounds, but not every scene consumes `_apply_contrast()`. Treat high contrast as partially implemented until each UI layer responds visually.

## Remaining Gaps Before Wider Release

- Run physical touch-device testing for the mobile overlay.
- Add voice-over prompts for non-reading children.
- Expand high-contrast application across every scene.
- Complete a colour-blindness simulation pass.
- Observe at least three adult-guided child play sessions before moving beyond trusted beta.

*Report generated: 2026-06-06 | Engine target: Godot 4.6.3 | Build: beta-1-candidate*
