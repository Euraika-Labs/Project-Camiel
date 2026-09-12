# Audio Assets — Camiel alpha

This directory holds all audio files used by the game.

## Required Files

| File | Purpose | Format | Notes |
|------|---------|--------|-------|
| `bgm_ambient.ogg` | Looping background music for menus and gameplay | OGG Vorbis, stereo, ~8 s | Two low sine voices (220 Hz, 330 Hz), 50 ms fade in/out so the loop seam does not click |
| `sfx_collect.ogg` | Collectible pickup sound | OGG Vorbis | Short bright chime |
| `sfx_finish.ogg` | Level complete / flag reached fanfare | OGG Vorbis | Short warm rising success tone |

## Every file here must be genuine Ogg Vorbis, not Opus

An Ogg container carrying Opus data (`OggS` then `OpusHead` in the first bytes)
fails Godot's Vorbis importer. The failure is silent after the first attempt:
the `.ogg.import` sidecar records `valid=false` and the engine treats that
sidecar as an already-processed import on every subsequent load, so
`load()` returns `null` with a loud `ERROR:` line forever, on every fresh
checkout, with no re-import ever attempted. If this ever happens again,
delete the stale `.ogg.import` sidecar (a sidecar recording an unsuccessful
import is skipped forever, not retried) and reimport from a genuine Vorbis
file.

`bgm_ambient.ogg` was generated with:

```
ffmpeg -y -f lavfi -i "sine=frequency=220:duration=8" -f lavfi -i "sine=frequency=330:duration=8" \
  -filter_complex "[0:a]afade=t=in:st=0:d=0.05,afade=t=out:st=7.95:d=0.05[a0];[1:a]afade=t=in:st=0:d=0.05,afade=t=out:st=7.95:d=0.05[a1];[a0][a1]amix=inputs=2:duration=first:dropout_transition=0,volume=0.5[aout]" \
  -map "[aout]" -ac 2 -threads 1 -c:a vorbis -strict -2 -qscale:a 4 assets/audio/bgm_ambient.ogg
```

`-ac 2` (stereo) is mandatory — ffmpeg's native `vorbis` encoder only accepts
2 channels; a mono `-ac 1` input errors outright.

## Looping is a stream property, not a player property

`AudioStreamPlayer` (the node) has no `loop` property in Godot 4. Looping is
set on the imported stream resource itself, in the `.ogg.import` sidecar's
`[params] loop=true` line, which the engine's importer bakes into the
resulting `AudioStreamOggVorbis`. Only `bgm_ambient.ogg.import` sets
`loop=true` — a one-shot sound effect that looped would never stop.

## Implementation

Files are loaded via `AudioManager` (autoload singleton). See `scripts/audio_manager.gd`
for the loading logic and bus routing.

## Licensing

All audio files must be royalty-free or produced for this project. If using
third-party assets, ensure the licence is compatible with the project's MIT
 licence.
