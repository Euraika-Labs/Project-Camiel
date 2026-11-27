#!/usr/bin/env python3
"""Regenerate the bundled Flemish narration from a local Piper voice model."""
import argparse
import json
from pathlib import Path
import tempfile
import wave

import numpy as np
from piper import PiperVoice, SynthesisConfig


AUDIO_DIRECTORY = Path(__file__).resolve().parents[2] / "assets/audio/speech_nl"
SAMPLE_RATE = 22050
PEAK = 0.72


def render_clip(voice, text, settings, output):
    pieces = []
    for chunk in voice.synthesize(text, syn_config=settings):
        if chunk.sample_rate != SAMPLE_RATE:
            raise RuntimeError(f"Expected {SAMPLE_RATE} Hz from the voice model")
        samples = chunk.audio_float_array.astype(np.float32, copy=False)
        spoken = np.flatnonzero(np.abs(samples) > 0.003)
        if spoken.size:
            margin = round(0.035 * SAMPLE_RATE)
            start = max(0, int(spoken[0]) - margin)
            end = min(len(samples), int(spoken[-1]) + margin)
            pieces.append(samples[start:end])
            pieces.append(np.zeros(round(0.11 * SAMPLE_RATE), dtype=np.float32))
    if not pieces:
        raise RuntimeError(f"The model produced no audible samples for {output.name}")
    signal = np.concatenate(pieces)
    minimum_frames = round(0.56 * SAMPLE_RATE)
    if len(signal) < minimum_frames:
        signal = np.pad(signal, (0, minimum_frames - len(signal)))
    signal *= PEAK / np.max(np.abs(signal))
    pcm = np.rint(signal * 32767).astype("<i2")
    with wave.open(str(output), "wb") as target:
        target.setparams((1, 2, SAMPLE_RATE, len(pcm), "NONE", "not compressed"))
        target.writeframes(pcm.tobytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", type=Path, help="Local Piper .onnx with its .onnx.json beside it")
    parser.add_argument("--output", type=Path, default=AUDIO_DIRECTORY)
    args = parser.parse_args()
    catalog = json.loads((AUDIO_DIRECTORY / "catalog.json").read_text(encoding="utf-8"))
    voice = PiperVoice.load(args.model)
    settings = SynthesisConfig(
        length_scale=catalog["length_scale"],
        noise_scale=0.25,
        noise_w_scale=0.25,
        normalize_audio=False,
    )
    args.output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="camiel-voice-", dir=args.output) as directory:
        staging = Path(directory)
        for cue, text in catalog["clips"].items():
            clip = staging / f"{cue}.wav"
            render_clip(voice, text, settings, clip)
        for clip in staging.iterdir():
            clip.replace(args.output / clip.name)
            print(clip.name)


if __name__ == "__main__":
    main()
