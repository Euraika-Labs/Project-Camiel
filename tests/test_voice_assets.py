"""Validate bundled offline narration bytes against the shipped cue catalog."""
import json
from pathlib import Path
import struct
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets/audio/speech_nl"


class VoiceAssets(unittest.TestCase):
    def test_required_cues_are_bundled_and_audible_pcm(self):
        catalog = json.loads((AUDIO / "catalog.json").read_text())
        cues = catalog["clips"]
        required = {"title", "main_menu", "lesson_select", "intro", "correct",
                    "retry", "complete", "intro_complete", "collected"}
        required.update(f"lesson_{i}" for i in range(1, 7))
        self.assertTrue(required.issubset(cues))
        for cue, text in cues.items():
            with self.subTest(cue=cue):
                self.assertTrue(text.strip())
                with wave.open(str(AUDIO / f"{cue}.wav")) as wav:
                    self.assertEqual((wav.getnchannels(), wav.getsampwidth()), (1, 2))
                    self.assertEqual(wav.getframerate(), 22050)
                    self.assertGreater(wav.getnframes() / wav.getframerate(), 0.5)
                    raw = wav.readframes(wav.getnframes())
                samples = struct.unpack(f"<{len(raw)//2}h", raw)
                self.assertGreater(max(abs(s) for s in samples), 1000)
                self.assertGreater(sum(s*s for s in samples)/len(samples), 10000)
