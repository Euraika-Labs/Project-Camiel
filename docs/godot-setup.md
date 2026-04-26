# Godot Setup

## Engine Version

Current engine:

`Godot 4.6.2.stable`

The project was created and tested with this version.

## Main Project Files

- `project.godot`: Godot project config.
- `scenes/main.tscn`: Main playable intro scene.
- `scenes/camiel.tscn`: Camiel character scene.
- `assets/camiel/camiel_sprite_frames.tres`: SpriteFrames resource for Camiel.
- `scripts/camiel_controller.gd`: Player movement and animation controller.
- `scripts/intro_scene.gd`: Intro scene message logic.

## Main Scene

The project main scene is:

`res://scenes/main.tscn`

The main scene includes:

- Background color rectangles.
- A grass floor.
- A small platform.
- StaticBody2D collision for the floor, platform, and side walls.
- A Camiel instance.
- A Camera2D.
- A CanvasLayer UI with title, message, and controls.

## Camiel Scene

Camiel is a `CharacterBody2D`.

Child nodes:

- `AnimatedSprite2D`
- `CollisionShape2D`

The AnimatedSprite2D uses:

`res://assets/camiel/camiel_sprite_frames.tres`

## Player Physics

The controller currently exposes:

- `walk_speed`
- `run_speed`
- `jump_velocity`
- `gravity`
- `acceleration`
- `friction`
- `min_x`
- `max_x`

Movement is intentionally simple for the alpha.

## Verification

The project includes a verification script:

`scripts/tools/verify_camiel_resources.gd`

It checks:

- The SpriteFrames resource exists.
- Expected animation names exist.
- Expected frame counts match.
- `scenes/camiel.tscn` and `scenes/main.tscn` load.
- Camiel scene root is a `CharacterBody2D`.
- Main scene contains a Camiel instance.

Example command:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path "." --script "res://scripts/tools/verify_camiel_resources.gd"
```

## Notes

The exported build is not code-signed. Windows may show a SmartScreen warning when running it for the first time.
