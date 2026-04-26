# Development Log

## Initial Character Asset Work

The project started from a reference image of Camiel, a cute Bernese Mountain Dog style character with:

- Black, white, and tan fur.
- A green bandana.
- The name `Camiel` on the bandana.

Generated image sets:

- 10 general single-dog pose images.
- 10 side-view pose images.
- A dedicated animation set for Godot.

The images were generated with chroma-key backgrounds and then converted locally into transparent PNG assets.

## Animation Asset Work

The final Godot-facing animation assets live under:

`assets/camiel/animations/`

Created animation groups:

- `idle_left`: 4 frames.
- `idle_right`: 4 frames.
- `walk_left`: 6 frames.
- `walk_right`: 6 frames.
- `run_left`: 6 frames.
- `run_right`: 6 frames.
- `jump_left`: 4 frames.
- `jump_right`: 4 frames.
- `sit_left`: 4 frames.
- `sit_right`: 4 frames.
- `sleep_left`: 3 frames.
- `sleep_right`: 3 frames.

The jump frames were later repaired because some generated alpha edges made Camiel appear green/dark during jumping. The repaired jump frames were rebuilt from original chroma sources with a cleaner matte and reimported into Godot.

## Godot Project Creation

Godot Engine `4.6.2` was installed via WinGet.

The project was created with:

- `project.godot`
- `scenes/main.tscn`
- `scenes/camiel.tscn`
- `assets/camiel/camiel_sprite_frames.tres`

The SpriteFrames resource includes all current Camiel animations.

## Player Controller

Camiel started as a simple `Node2D` with a manual animation controller.

For the alpha intro, Camiel was converted into a real `CharacterBody2D` with:

- Collision.
- Gravity.
- Horizontal movement.
- Jump velocity.
- Animation switching based on state.

Current controller:

`scripts/camiel_controller.gd`

## Intro Scene

The main scene was turned into a simple intro/test scene with:

- Sky background.
- Clouds.
- Grass floor.
- Small platform.
- Three labelled color blocks.
- Friendly UI text.
- Live message updates based on the player's action.

Current intro script:

`scripts/intro_scene.gd`

## Export Setup

Godot export templates for `4.6.2.stable` were downloaded from the official Godot release and installed under Godot's user template directory.

A Windows export preset was added:

`export_presets.cfg`

The Windows build was exported to:

`builds/alpha-v0.0.1/windows/Camiel-alpha-v0.0.1.exe`

A zipped copy was also created:

`builds/alpha-v0.0.1/windows/Camiel-alpha-v0.0.1-windows.zip`

These build files are ignored by git and uploaded to GitHub Releases instead.

## GitHub

A private GitHub repository was created:

`Euraika-Labs/Project-Camiel`

The source project was committed and pushed to `main`.

Release `alpha-v0.0.1` was created with the Windows `.exe` and `.zip` as release assets.
