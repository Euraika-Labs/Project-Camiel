# Audio Assets — Camiel alpha

This directory holds all audio files used by the game.

## Required Files

| File | Purpose | Format | Notes |
|------|---------|--------|-------|
| `bgm_ambient.ogg` | Muziek voor menu en spel | Ogg Vorbis, stereo, 45,71 s | Zestien maten met geplukte klanken en zachte bas. Loopt door (`loop=true`) |
| `sfx_collect.ogg` | Bevestiging bij een opgepakt voorwerp of geraakt lesdoel | Ogg Vorbis, stereo, 0,42 s | Twee korte klanken |
| `sfx_finish.ogg` | Bereikte eindring of afgeronde les | Ogg Vorbis, stereo, 1,34 s | Vier stijgende noten met een zachte slotklank |

`scripts/tools/generate_game_audio.py` bevat de partituur en rendert de drie bestanden op 32 kHz. De staarten van de laatste noten lopen door over het begin van de muziek. Installeer voor het opnieuw genereren NumPy en SoundFile in je ontwikkelomgeving en voer het script uit vanuit de repository.

```bash
python3 -m pip install numpy soundfile==0.13.1
python3 scripts/tools/generate_game_audio.py
```

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

## Looping is a stream property, not a player property

`AudioStreamPlayer` (the node) has no `loop` property in Godot 4. Looping is
set on the imported stream resource itself, in the `.ogg.import` sidecar's
`[params] loop=true` line, which the engine's importer bakes into the
resulting `AudioStreamOggVorbis`. Only `bgm_ambient.ogg.import` sets
`loop=true` — a one-shot sound effect that looped would never stop.

## Nederlandse spraak

`speech_nl/catalog.json` bevat de Nederlandse teksten en de gebruikte modelversie. Alle clips gebruiken de Vlaamse Nathalie-stem. Piper Voices vermeldt MIT voor het modelarchief en CC0 voor de trainingsdataset van Nathalie. [Modelkaart van Nathalie](https://huggingface.co/rhasspy/piper-voices/blob/0ca208afc2a2ee102b1e961e72e0a7e4907be3d0/nl/nl_BE/nathalie/medium/MODEL_CARD)

De meegeleverde bestanden zijn mono PCM WAV op 22.050 Hz en 16 bit. Het spel speelt ze lokaal af via de onafhankelijke Voice-bus. Verstaanbaarheid op doelapparaten vereist menselijke beoordeling.

Installeer voor het opnieuw genereren Piper 1.8.0 in je ontwikkelomgeving. Plaats `nl_BE-nathalie-medium.onnx` en het overeenkomstige `.onnx.json`-bestand uit de modelversie in dezelfde map. Geef het pad naar het lokale model op bij het uitvoeren van de generator. [Modelbestanden van Nathalie](https://huggingface.co/rhasspy/piper-voices/tree/0ca208afc2a2ee102b1e961e72e0a7e4907be3d0/nl/nl_BE/nathalie/medium)

```bash
python3 -m pip install piper-tts==1.8.0
python3 scripts/tools/generate_voice_assets.py /pad/naar/nl_BE-nathalie-medium.onnx
```

## Implementation

Files are loaded via `AudioManager` (autoload singleton). See `scripts/audio_manager.gd`
for the loading logic and bus routing.

## Licensing

Het project is proprietary volgens [LICENSE](../../LICENSE), niet MIT. Controleer bij toekomstige externe audio afzonderlijk de distributierechten; een engine- of toollicentie verleent geen rechten op willekeurige assets.
