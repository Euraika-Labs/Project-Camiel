# Audio Assets — Camiel alpha

This directory holds all audio files used by the game.

## Required Files

| File | Purpose | Format | Notes |
|------|---------|--------|-------|
| `bgm_ambient.wav` | Looping background music for menus and gameplay | WAV PCM | Short silent beta placeholder |
| `sfx_collect.wav` | Collectible star pickup sound | WAV PCM | Short cheerful chime |
| `sfx_finish.wav` | Level complete / flag reached fanfare | WAV PCM | Short warm success tone |

## Placeholder Files

Until real assets are produced, use silent WAV files or generate simple tones
with a tool such as [sFXR](https://sfxr.me), Audacity, or the Godot AudioStreamPlayer
tone generator.

## Implementation

Files are loaded via `AudioManager` (autoload singleton). See `scripts/audio_manager.gd`
for the loading logic and bus routing.

## Licensing

All audio files must be royalty-free or produced for this project. If using
third-party assets, ensure the licence is compatible with the project's MIT
 licence.
