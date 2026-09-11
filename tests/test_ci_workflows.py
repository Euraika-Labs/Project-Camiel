from __future__ import annotations

import re
import unittest
from pathlib import Path

try:
    import yaml

    _HAS_YAML = True
except ImportError:  # pragma: no cover - environment dependent
    yaml = None  # type: ignore[assignment]
    _HAS_YAML = False


REPO_ROOT = Path(__file__).resolve().parents[1]
CI_PATH = REPO_ROOT / ".github" / "workflows" / "ci.yml"
RELEASE_PATH = REPO_ROOT / ".github" / "workflows" / "release.yml"
CONTRIBUTING_PATH = REPO_ROOT / "CONTRIBUTING.md"


def _job_steps(workflow_text: str, job_id: str) -> list[tuple[str, str]]:
    """Return (step_name, run_text) tuples for every step under the given
    top-level job id in a GitHub Actions workflow file.

    Scans by fixed indentation (2 spaces for the job id line, 6 spaces for
    each "- name:" step entry, 8+ spaces for a step's body) rather than
    parsing YAML, so the structural tests here work even without PyYAML.
    """
    lines = workflow_text.splitlines()
    job_header = "  {}:".format(job_id)

    start = None
    for index, line in enumerate(lines):
        if line.rstrip() == job_header:
            start = index + 1
            break
    if start is None:
        return []

    end = len(lines)
    for index in range(start, len(lines)):
        line = lines[index]
        if line.strip() == "":
            continue
        indent = len(line) - len(line.lstrip(" "))
        if indent <= 2:
            end = index
            break

    job_lines = lines[start:end]

    step_starts = [
        i for i, line in enumerate(job_lines) if line.startswith("      - name:")
    ]

    steps: list[tuple[str, str]] = []
    for position, step_index in enumerate(step_starts):
        step_name = job_lines[step_index].split("- name:", 1)[1].strip()
        body_end = (
            step_starts[position + 1]
            if position + 1 < len(step_starts)
            else len(job_lines)
        )
        body_lines = job_lines[step_index:body_end]

        run_text_lines: list[str] = []
        capturing = False
        capture_indent = None
        inline_run = None
        for body_line in body_lines:
            if not capturing:
                stripped = body_line.strip()
                if stripped == "run: |":
                    capturing = True
                    continue
                match = re.match(r"^\s*run:\s*(.+)$", body_line)
                if match:
                    inline_run = match.group(1)
                    break
                continue
            if body_line.strip() == "":
                run_text_lines.append("")
                continue
            indent = len(body_line) - len(body_line.lstrip(" "))
            if capture_indent is None:
                capture_indent = indent
            if indent < capture_indent:
                break
            run_text_lines.append(body_line)

        run_text = inline_run if inline_run is not None else "\n".join(run_text_lines)
        steps.append((step_name, run_text))

    return steps


class CiWorkflowTests(unittest.TestCase):
    def setUp(self) -> None:
        self.ci_text = CI_PATH.read_text(encoding="utf-8")
        self.release_text = RELEASE_PATH.read_text(encoding="utf-8")

    def _assert_downloads_verify_sha512(
        self, workflow_text: str, job_ids: list[str]
    ) -> None:
        checked_any = False
        for job_id in job_ids:
            for name, run in _job_steps(workflow_text, job_id):
                if ".zip" not in run and ".tpz" not in run:
                    continue
                if "curl" not in run:
                    continue
                checked_any = True
                self.assertIn(
                    "SHA512-SUMS.txt",
                    run,
                    f"{job_id}/{name} downloads an archive without SHA512 verification",
                )
                self.assertIn(
                    "sha512sum",
                    run,
                    f"{job_id}/{name} downloads an archive without a sha512sum check",
                )
                sha_pos = run.find("sha512sum")
                unzip_pos = run.find("unzip")
                self.assertNotEqual(
                    -1, unzip_pos, f"{job_id}/{name} has no unzip step to guard"
                )
                self.assertLess(
                    sha_pos,
                    unzip_pos,
                    f"{job_id}/{name} verifies the hash after extracting, not before",
                )
        self.assertTrue(checked_any, "no downloading steps were found to check")

    def test_ci_env_pins_godot_4_7_2(self) -> None:
        self.assertIn("GODOT_VERSION: 4.7.2", self.ci_text)
        self.assertIn("GODOT_STATUS: stable", self.ci_text)
        self.assertIn("GODOT_TEMPLATE_VERSION: 4.7.2.stable", self.ci_text)
        self.assertIn("GODOT_BIN: Godot_v4.7.2-stable_linux.x86_64", self.ci_text)

    def test_verify_job_runs_headless_check(self) -> None:
        steps = _job_steps(self.ci_text, "verify-godot")
        matches = [
            (name, run)
            for name, run in steps
            if "bash scripts/tools/run_headless_check.sh" in run
        ]
        self.assertEqual(
            1, len(matches), f"expected exactly one matching step, got {matches}"
        )
        _, run_text = matches[0]
        self.assertIn('GODOT="$RUNNER_TEMP/godot/${GODOT_BIN}"', run_text)

    def test_no_2d_verifier_or_quit_after(self) -> None:
        self.assertNotIn("verify_camiel_resources", self.ci_text)
        self.assertNotIn("--quit-after", self.ci_text)

    def test_ci_downloads_verify_sha512(self) -> None:
        self._assert_downloads_verify_sha512(
            self.ci_text, ["verify-godot", "export-windows"]
        )

    def test_hygiene_runs_workflow_tests(self) -> None:
        steps = _job_steps(self.ci_text, "repository-hygiene")
        matches = [
            run
            for _, run in steps
            if "python3 -m unittest tests.test_quality_gate tests.test_ci_workflows"
            in run
        ]
        self.assertTrue(
            matches, "repository-hygiene job does not run tests.test_ci_workflows"
        )

    @unittest.skipUnless(_HAS_YAML, "PyYAML not installed")
    def test_workflows_parse_as_yaml(self) -> None:
        yaml.safe_load(self.ci_text)
        yaml.safe_load(self.release_text)

    def test_release_env_pins_godot_4_7_2(self) -> None:
        self.assertIn("GODOT_VERSION: 4.7.2", self.release_text)
        self.assertIn("GODOT_STATUS: stable", self.release_text)
        self.assertIn("GODOT_TEMPLATE_VERSION: 4.7.2.stable", self.release_text)
        self.assertIn(
            "GODOT_BIN: Godot_v4.7.2-stable_linux.x86_64", self.release_text
        )

    def test_release_verify_step_runs_headless_check(self) -> None:
        steps = _job_steps(self.release_text, "release-windows")
        matches = [(name, run) for name, run in steps if name == "Verify project"]
        self.assertEqual(1, len(matches))
        _, run_text = matches[0]
        self.assertIn(
            'GODOT="$RUNNER_TEMP/godot/${GODOT_BIN}" bash scripts/tools/run_headless_check.sh',
            run_text,
        )
        self.assertNotIn("verify_camiel_resources", self.release_text)

    def test_release_downloads_verify_sha512(self) -> None:
        self._assert_downloads_verify_sha512(self.release_text, ["release-windows"])

    def test_contributing_names_check(self) -> None:
        text = CONTRIBUTING_PATH.read_text(encoding="utf-8")
        self.assertIn("4.7.2", text)
        self.assertIn("bash scripts/tools/run_headless_check.sh", text)
        self.assertNotIn("4.6.2", text)
        self.assertNotIn("verify_camiel_resources", text)


if __name__ == "__main__":
    unittest.main()
