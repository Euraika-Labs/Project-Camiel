# Parent & Teacher Notes — Camiel alpha-v0.0.3

## About Camiel

Camiel is a child-friendly educational game for children aged 3+. The game features Camiel, a friendly dog character who guides children through gentle learning challenges. The experience is calm, colourful, and free of time pressure — designed to support early learning in a stress-free environment.

## Learning Objectives

### Touch the Red Block

- **Colour recognition (red):** Children identify the red block among other elements in the scene.
- **Cause and effect:** Touching the block triggers an immediate visual change (it turns green) and a chime sound — teaching children that their actions have consequences.
- **Physical coordination:** Moving Camiel to the target requires directional movement, building early spatial awareness.

### Find the Hidden Blue Target

- **Visual discrimination and observation:** The blue target is deliberately camouflaged against the scene background, encouraging careful looking rather than quick scanning.
- **Persisting to find:** The task resists quick success, teaching children that effort is rewarded even when something is not immediately obvious.
- **Colour recognition (blue):** Children confirm the colour once the target is found.

### Count 1–2–3

- **Number sense (1, 2, 3):** Children see three stars and hear them counted aloud as each is collected.
- **One-to-one correspondence:** Each star collected maps to exactly one count — a foundational mathematical concept.
- **Sequential thinking:** The challenge requires collecting in any order, reinforcing that the count updates after each action.

## How to Play

1. Start from the main menu.
2. Press **Start** to begin the intro scene.
3. Press **Les** (Lesson) from the main menu to access the three educational micro-tasks.
4. Children complete each challenge at their own pace — there is **no timer and no failure state**.
5. On completion a "Goed zo!" (Well done!) message appears and the child returns to the menu.

## Classroom Suggestions

- **1:1 adult-child pairing** is recommended for the best learning dialogue.
- **Project on a large screen** for whole-group introduction to the game mechanics before individual play.
- **Use as a reward or calm-down activity** — the game is deliberately low-arousal.
- **Pause and discuss:** After each micro-task, ask the child to name the colour or count the collected items out loud.
- **Encourage verbal narration:** Ask the child to "tell Camiel where to go" rather than controlling the character for them.

## Accessibility

- Large UI elements (minimum 48×48 px touch targets) — suitable for developing fine motor control.
- High-contrast colours throughout all UI text and game elements.
- Audio + visual feedback for every event — no audio-only cues.
- No fast animations, flashing, or strobing effects.
- No time pressure, score penalties, or negative feedback.
- **High-contrast toggle** available via the Accessibility autoload (`Accessibility.toggle_high_contrast()`).

## Technical

- **Engine:** Godot 4 (open source, MIT/GPL)
- **Platform:** Windows (alpha build), macOS and HTML5 exports planned
- **Project page:** [github.com/Euraika-Labs/Project-Camiel](https://github.com/Euraika-Labs/Project-Camiel)
- **Autoload services:** `AudioManager` (music + SFX), `Accessibility` (contrast settings)
- **Language:** Dutch throughout; English equivalents can be added per locale
