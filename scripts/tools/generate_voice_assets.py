#!/usr/bin/env python3
"""Regenerate bundled Dutch PCM speech on macOS (build-time only).

Requires the installed Ellen voice, macOS say, and ffmpeg. Run outside a
sandbox that denies the speech service. Never invoked by the game or CI.
"""
import json
from pathlib import Path
import subprocess
import tempfile
import wave


def main():
    directory = Path(__file__).resolve().parents[2] / "assets/audio/speech_nl"
    catalog = json.loads((directory / "catalog.json").read_text())
    with tempfile.TemporaryDirectory(prefix="camiel-voice-") as temp:
        aiff = Path(temp) / "speech.aiff"
        pcm = Path(temp) / "speech.wav"
        for cue, text in catalog["clips"].items():
            subprocess.run(["say", "-v", catalog["voice"], "-r", str(catalog["rate"]),
                            "-o", str(aiff), text], check=True)
            subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(aiff),
                            "-ar", "22050", "-ac", "1", "-c:a", "pcm_s16le", str(pcm)],
                           check=True)
            with wave.open(str(pcm)) as wav:
                if wav.getnframes() < 11025:
                    raise RuntimeError(f"{cue}: empty/short synthesis; check speech service access")
            (directory / f"{cue}.wav").write_bytes(pcm.read_bytes())
            print(cue)


if __name__ == "__main__":
    main()
