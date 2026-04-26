import importlib.util
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory


REPO_ROOT = Path(__file__).resolve().parents[1]
QUALITY_GATE_PATH = REPO_ROOT / "scripts" / "tools" / "quality_gate.py"


spec = importlib.util.spec_from_file_location("quality_gate", QUALITY_GATE_PATH)
quality_gate = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(quality_gate)


class QualityGateTests(unittest.TestCase):
    def run_gate(self, files):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            for relative_path, content in files.items():
                path = root / relative_path
                path.parent.mkdir(parents=True, exist_ok=True)
                if isinstance(content, bytes):
                    path.write_bytes(content)
                else:
                    path.write_text(content, encoding="utf-8")

            return quality_gate.run_checks(root, [Path(name) for name in files])

    def assert_has_code(self, findings, code):
        self.assertIn(code, {finding.code for finding in findings})

    def test_blocks_ai_disclaimer_text(self):
        findings = self.run_gate(
            {
                "README.md": "# Test\n\nAs an AI language model, I cannot verify this.\n",
            }
        )

        self.assert_has_code(findings, "forbidden-phrase")

    def test_blocks_broken_local_markdown_links(self):
        findings = self.run_gate(
            {
                "docs/README.md": "# Docs\n\nRead [Setup](missing-setup.md).\n",
            }
        )

        self.assert_has_code(findings, "broken-markdown-link")

    def test_blocks_missing_godot_resource_paths(self):
        findings = self.run_gate(
            {
                "scenes/main.tscn": (
                    '[gd_scene load_steps=2 format=3]\n'
                    '[ext_resource type="Script" path="res://scripts/missing.gd" id="1"]\n'
                    "[node name=\"Main\" type=\"Node2D\"]\n"
                ),
            }
        )

        self.assert_has_code(findings, "missing-godot-resource")

    def test_accepts_clean_child_friendly_project_files(self):
        findings = self.run_gate(
            {
                "README.md": "# Project Camiel\n\nA small intro game.\n",
                "docs/README.md": "# Docs\n\nRead [Setup](setup.md).\n",
                "docs/setup.md": "# Setup\n\nOpen the project in Godot.\n",
                "scenes/main.tscn": "[gd_scene format=3]\n[node name=\"Main\" type=\"Node2D\"]\n",
            }
        )

        self.assertEqual([], findings)


if __name__ == "__main__":
    unittest.main()
