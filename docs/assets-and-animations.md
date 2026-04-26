# Assets And Animations

## Canonical Asset Location

The main Godot-ready character assets live under:

`assets/camiel/`

Important subfolders:

- `assets/camiel/animations/`
- `assets/camiel/poses/`
- `assets/camiel/poses/side/`

## Animation Structure

Each animation has its own folder.

Current animation frame counts:

| Animation | Frames |
| --- | ---: |
| `idle_left` | 4 |
| `idle_right` | 4 |
| `walk_left` | 6 |
| `walk_right` | 6 |
| `run_left` | 6 |
| `run_right` | 6 |
| `jump_left` | 4 |
| `jump_right` | 4 |
| `sit_left` | 4 |
| `sit_right` | 4 |
| `sleep_left` | 3 |
| `sleep_right` | 3 |

## SpriteFrames Resource

Godot animation data is stored in:

`assets/camiel/camiel_sprite_frames.tres`

This resource is assigned to Camiel's `AnimatedSprite2D`.

## Original/Legacy Asset Folders

The project still contains earlier generated sets:

- `assets/dogs/`
- `assets/dogs_side/`

These are useful as reference/backup pose sets. The current game scene uses the canonical `assets/camiel/` assets.

## Transparent PNG Workflow

The generated dog images were created on chroma-key backgrounds, then converted to transparent PNGs.

Temporary chroma/intermediate files are under:

`tmp/`

The `tmp/` folder is ignored by git.

## Jump Color Fix

Some initial jump frames had too many semi-transparent pixels, making Camiel look green or dark when jumping.

The fix:

- Rebuilt `jump_right` frames from original magenta chroma sources.
- Rebuilt alpha with a cleaner matte.
- Recreated `jump_left` by mirroring the fixed right-facing frames.
- Reimported the updated PNGs into Godot.

Backup of old jump frames:

`tmp/jump_frames_before_color_fix/`

This backup is local-only and ignored by git.

## Godot Import Files

The `.png.import` files are committed. They help Godot reproduce the same import settings when the project is opened elsewhere.
