# Audio Assets — Camiel alpha

This directory holds all audio files used by the game.

## Required Files

| File | Purpose | Format | Notes |
|------|---------|--------|-------|
| `bgm_ambient.ogg` | Looping background music for menus and gameplay | OGG Vorbis, stereo, ~8 s | Two low sine voices (220 Hz, 330 Hz), 50 ms fade in/out so the loop seam does not click. Loops (`loop=true`) |
| `sfx_collect.ogg` | Collectible pickup sound | OGG Vorbis, stereo, ~0.4 s | Bright 880 Hz chime, short attack, exponential decay. Does not loop |
| `sfx_finish.ogg` | Level complete / flag reached fanfare | OGG Vorbis, stereo, ~1.2 s | Three warm rising tones (523 Hz, 659 Hz, 784 Hz) in sequence, fading out at the end. Does not loop |

## OGG-bestanden moeten echte Vorbis bevatten, geen Opus

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

`sfx_collect.ogg` and `sfx_finish.ogg` were generated the same way, each
with `loop=false` left in the reimported sidecar — a one-shot sound effect
that loops would never stop:

```
ffmpeg -y -f lavfi -i "sine=frequency=880:duration=0.4" \
  -filter_complex "[0:a]volume=0.33,afade=t=in:st=0:d=0.02,afade=t=out:st=0.1:d=0.3[aout]" \
  -map "[aout]" -ac 2 -threads 1 -c:a vorbis -strict -2 -qscale:a 4 assets/audio/sfx_collect.ogg

ffmpeg -y \
  -f lavfi -i "sine=frequency=523:duration=0.35" \
  -f lavfi -i "sine=frequency=659:duration=0.35" \
  -f lavfi -i "sine=frequency=784:duration=0.5" \
  -filter_complex "[0:a]volume=0.35,afade=t=in:st=0:d=0.01,afade=t=out:st=0.3:d=0.05[a0];[1:a]volume=0.35,afade=t=in:st=0:d=0.01,afade=t=out:st=0.3:d=0.05[a1];[2:a]volume=0.35,afade=t=in:st=0:d=0.01,afade=t=out:st=0.35:d=0.15[a2];[a0][a1][a2]concat=n=3:v=0:a=1[aout]" \
  -map "[aout]" -ac 2 -threads 1 -c:a vorbis -strict -2 -qscale:a 4 assets/audio/sfx_finish.ogg
```

## Looping is a stream property, not a player property

`AudioStreamPlayer` (the node) has no `loop` property in Godot 4. Looping is
set on the imported stream resource itself, in the `.ogg.import` sidecar's
`[params] loop=true` line, which the engine's importer bakes into the
resulting `AudioStreamOggVorbis`. Only `bgm_ambient.ogg.import` sets
`loop=true` — a one-shot sound effect that looped would never stop.

## Nederlandse spraak

`speech_nl/catalog.json` bevat de Nederlandse teksten en generatiegegevens (Ellen, nl-BE). De meegeleverde clips zijn PCM WAV, mono, 22050 Hz, 16-bit. `scripts/tools/generate_voice_assets.py` genereert ze op macOS; tijdens het spelen is geen spraakdienst nodig. `scripts/voice_manager.gd` routeert de clips naar de onafhankelijke Voice-bus. Verstaanbaarheid op doelapparaten vereist menselijke beoordeling.

## Implementation

Files are loaded via `AudioManager` (autoload singleton). See `scripts/audio_manager.gd`
for the loading logic and bus routing.

## Licensing

Het project is proprietary volgens [LICENSE](../../LICENSE), niet MIT. Controleer bij toekomstige externe audio afzonderlijk de distributierechten; een engine- of toollicentie verleent geen rechten op willekeurige assets.
