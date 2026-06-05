# Audio Assets — Camiel alpha

This directory holds all audio files used by the game.

## Required Files

| File | Purpose | Format | Notes |
|------|---------|--------|-------|
| `bgm_ambient.ogg` | Looping background music for menus and gameplay | OGG Vorbis | ~1–3 min loop, soft & gentle |
| `sfx_collect.ogg` | Collectible star pickup sound | OGG Vorbis | Short (~0.5 s), cheerful chime |
| `sfx_finish.ogg` | Level complete / flag reached fanfare | OGG Vorbis | Short (~1–2 s), warm success tone |

## Placeholder Files

Until real assets are produced, use silent OGG files or generate simple tones
with a tool such as [sFXR](https://sfxr.me), Audacity, or the Godot AudioStreamPlayer
tone generator.

## Implementation

Files are loaded via `AudioManager` (autoload singleton). See `scripts/audio_manager.gd`
for the loading logic and bus routing.

## Licensing

All audio files must be royalty-free or produced for this project. If using
third-party assets, ensure the licence is compatible with the project's MIT
 licence.
