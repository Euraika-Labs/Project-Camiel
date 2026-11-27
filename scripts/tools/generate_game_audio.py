#!/usr/bin/env python3
"""Render Camiel's original score and game cues as Ogg Vorbis."""
from __future__ import annotations

import argparse
from math import sqrt, tau
from pathlib import Path

import numpy as np
import soundfile as sf


RATE = 32000
TEMPO = 84
BEAT = 60.0 / TEMPO

# Bass note and four upper notes per measure. Pitches are MIDI note numbers.
CHORDS = (
    (43, (55, 59, 62, 69)), (42, (54, 57, 62, 66)),
    (40, (55, 59, 62, 64)), (36, (55, 59, 60, 64)),
    (47, (55, 59, 62, 67)), (45, (55, 57, 60, 64)),
    (36, (55, 60, 64, 67)), (38, (55, 57, 62, 66)),
    (40, (55, 59, 64, 67)), (36, (55, 60, 64, 69)),
    (38, (55, 59, 62, 67)), (38, (54, 57, 62, 66)),
    (36, (55, 57, 60, 64)), (45, (55, 57, 60, 64)),
    (38, (54, 57, 60, 66)), (43, (55, 59, 62, 69)),
)

# A phrase leaves room for the spoken instructions every few measures.
MELODY = (
    ((0.75, 74), (1.75, 79), (3.0, 81)),
    ((0.50, 78), (2.25, 74)),
    ((1.0, 76), (2.50, 79)),
    ((0.5, 76), (1.75, 72)),
    (),
    ((1.0, 72), (2.0, 76), (3.25, 79)),
    ((0.5, 81), (2.0, 76)),
    ((1.0, 74),),
    ((0.75, 79), (1.75, 83), (3.0, 81)),
    ((1.0, 76), (2.50, 74)),
    (),
    ((0.75, 74), (1.75, 78), (3.0, 81)),
    ((1.0, 79), (2.50, 76)),
    ((0.5, 72), (1.75, 76)),
    ((0.75, 74), (2.0, 78)),
    ((0.75, 79),),
)


def pluck(note: int, duration: float, decay: float, brightness: float) -> np.ndarray:
    """A rounded attack with a short, brighter wooden resonance."""
    time = np.arange(round(duration * RATE)) / RATE
    phase = tau * 440.0 * 2.0 ** ((note - 69) / 12.0) * time
    fundamental = np.sin(phase) * np.exp(-time / decay)
    resonance = 0.34 * np.sin(phase * 2.0) * np.exp(-time / (decay * 0.53))
    resonance += 0.14 * np.sin(phase * 3.01) * np.exp(-time / (decay * 0.27))
    resonance += 0.07 * np.sin(phase * 4.14) * np.exp(-time / (decay * 0.15))
    attack = np.minimum(time / 0.024, 1.0)
    release = np.clip((duration - time) / 0.075, 0.0, 1.0)
    return (fundamental + brightness * resonance) * attack * release


def add_note(
    mix: np.ndarray,
    start: float,
    note: np.ndarray,
    level: float,
    pan: float = 0.0,
    *,
    wrap: bool = False,
) -> None:
    left = sqrt((1.0 - pan) / 2.0)
    right = sqrt((1.0 + pan) / 2.0)
    samples = note[:, None] * np.array([left, right]) * level
    begin = round(start * RATE)
    count = min(len(samples), len(mix) - begin)
    mix[begin:begin + count] += samples[:count]
    if wrap and count < len(samples):
        mix[:len(samples) - count] += samples[count:]


def score() -> np.ndarray:
    music = np.zeros((round(len(CHORDS) * 4 * BEAT * RATE), 2))
    for measure, ((bass, harmony), phrase) in enumerate(zip(CHORDS, MELODY, strict=True)):
        start = measure * 4 * BEAT
        add_note(music, start, pluck(bass, 2.9, 0.85, 0.72), 0.43, wrap=True)
        add_note(music, start + 2.50 * BEAT, pluck(harmony[0], 1.5, 0.61, 0.7), 0.25, wrap=True)
        for offset, note, pan in zip((0.18, 1.10, 2.16, 3.12), harmony, (-0.32, 0.28, -0.20, 0.35), strict=True):
            add_note(music, start + offset * BEAT, pluck(note, 2.1, 0.61, 0.9), 0.21, pan, wrap=True)
        for index, (beat, note) in enumerate(phrase):
            add_note(music, start + beat * BEAT, pluck(note, 1.65, 0.52, 1.55), 0.25, 0.12 - 0.19 * index, wrap=True)
    return music


def pickup() -> np.ndarray:
    mix = np.zeros((round(0.42 * RATE), 2))
    add_note(mix, 0.0, pluck(79, 0.23, 0.10, 1.25), 0.34, -0.10)
    add_note(mix, 0.10, pluck(83, 0.32, 0.13, 1.05), 0.55, 0.12)
    return mix


def celebration() -> np.ndarray:
    mix = np.zeros((round(1.34 * RATE), 2))
    for start, note, pan in ((0.0, 74, -0.20), (0.13, 79, 0.16), (0.27, 83, -0.08), (0.43, 86, 0.18)):
        add_note(mix, start, pluck(note, 0.83, 0.25, 1.20), 0.42, pan)
    add_note(mix, 0.43, pluck(55, 0.91, 0.37, 0.8), 0.24)
    return mix


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    root = Path(__file__).resolve().parents[2]
    parser.add_argument("--output", type=Path, default=root / "assets" / "audio")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for name, mix, peak in (
        ("bgm_ambient", score(), 0.19),
        ("sfx_collect", pickup(), 0.15),
        ("sfx_finish", celebration(), 0.125),
    ):
        path = args.output / f"{name}.ogg"
        gain = peak / np.max(np.abs(mix))
        with sf.SoundFile(path, "w", RATE, 2, format="OGG", subtype="VORBIS") as track:
            for offset in range(0, len(mix), 4096):
                track.write(mix[offset:offset + 4096] * gain)
        print(f"{path.name}  {len(mix) / RATE:.2f} s")


if __name__ == "__main__":
    main()
