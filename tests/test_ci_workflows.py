from __future__ import annotations

import re
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml


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
        self.export_text = (CI_PATH.parent / "export.yml").read_text(encoding="utf-8")

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
            self.ci_text, ["verify-godot"]
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

    def test_workflows_parse_as_yaml(self) -> None:
        yaml.safe_load(self.ci_text)
        yaml.safe_load(self.release_text)

    def test_export_env_pins_godot_4_7_2(self) -> None:
        workflow = yaml.safe_load(self.export_text)
        self.assertEqual("4.7.2", workflow["env"]["GODOT_VERSION"])
        self.assertEqual("stable", workflow["env"]["GODOT_STATUS"])
        self.assertEqual("4.7.2.stable", workflow["env"]["GODOT_TEMPLATE_VERSION"])

    def test_export_downloads_verify_sha512(self) -> None:
        self._assert_downloads_verify_sha512(self.export_text, ["export"])

    def test_release_reuses_full_ci_before_publication(self) -> None:
        release = yaml.safe_load(self.release_text)
        ci = yaml.safe_load(self.ci_text)
        self.assertEqual("./.github/workflows/ci.yml", release["jobs"]["build"]["uses"])
        self.assertEqual(["validate-tag"], release["jobs"]["build"]["needs"])
        self.assertEqual(["validate-tag", "build"], release["jobs"]["publish"]["needs"])
        self.assertEqual(["verify-godot"], ci["jobs"]["export-builds"]["needs"])
        self.assertEqual("./.github/workflows/export.yml", ci["jobs"]["export-builds"]["uses"])
        self.assertIn("test_headless_check.sh", self.ci_text)
        self.assertIn("release_version.py --tag", self.release_text)

    def test_exactly_one_release_creator_with_file_attachments(self) -> None:
        creators = []
        for path in CI_PATH.parent.glob("*.yml"):
            workflow = yaml.safe_load(path.read_text())
            for job in workflow.get("jobs", {}).values():
                for step in job.get("steps", []):
                    if "action-gh-release@" in step.get("uses", "") or "gh release create" in step.get("run", ""):
                        creators.append((path, step))
        self.assertEqual(1, len(creators))
        path, step = creators[0]
        self.assertEqual(RELEASE_PATH, path)
        self.assertRegex(step["uses"], r"@[0-9a-f]{40}$")
        self.assertTrue(step["with"]["fail_on_unmatched_files"])
        files = step["with"]["files"].splitlines()
        self.assertEqual(4, len(files))
        for suffix in ("windows.zip", "linux.tar.gz", "macos.zip", "web.zip"):
            self.assertTrue(any(f.endswith(suffix) for f in files))
        self.assertTrue(all("*" not in f for f in files))
        self.assertNotIn("|| true", self.release_text)
        self.assertIn("merge-multiple: true", self.release_text)

    def test_trigger_and_permission_boundaries(self) -> None:
        # BaseLoader preserves YAML's 'on' key instead of coercing it to True.
        release = yaml.load(self.release_text, Loader=yaml.BaseLoader)
        export = yaml.load(self.export_text, Loader=yaml.BaseLoader)
        ci = yaml.load(self.ci_text, Loader=yaml.BaseLoader)
        self.assertEqual(["push"], list(release["on"]))
        self.assertEqual(["alpha-v*", "v*"], release["on"]["push"]["tags"])
        self.assertEqual(["workflow_call"], list(export["on"]))
        self.assertIn("workflow_call", ci["on"])
        self.assertEqual("false", release["concurrency"]["cancel-in-progress"])
        for workflow in (release, ci, export):
            self.assertEqual("read", workflow["permissions"]["contents"])
        self.assertEqual("write", release["jobs"]["publish"]["permissions"]["contents"])
        self.assertIn("github.workflow", ci["concurrency"]["group"])

    def test_exports_include_web_and_use_versioned_helper(self) -> None:
        export = yaml.safe_load(self.export_text)
        job = export["jobs"]["export"]
        self.assertEqual(["windows", "linux", "macos", "web"], job["strategy"]["matrix"]["target"])
        self.assertIn("build_release.py", self.export_text)
        upload = next(s for s in job["steps"] if "upload-artifact" in s.get("uses", ""))
        self.assertEqual("error", upload["with"]["if-no-files-found"])
        for text in (self.ci_text, self.export_text, self.release_text):
            self.assertNotIn("alpha-v0.0.1", text)
            self.assertNotIn("continue-on-error", text)

    def test_publish_guard_executes_and_rejects_missing_or_directory_attachment(self) -> None:
        workflow = yaml.safe_load(self.release_text)
        step = next(s for s in workflow["jobs"]["publish"]["steps"]
                    if s.get("name") == "Require complete file attachments")
        with tempfile.TemporaryDirectory() as directory:
            release = Path(directory) / "release"
            release.mkdir()
            for suffix in ("windows.zip", "linux.tar.gz", "macos.zip", "web.zip"):
                (release / f"Camiel-v1.2.3-{suffix}").write_bytes(b"archive")
            def run_guard():
                return subprocess.run(["bash", "-e", "-o", "pipefail", "-c", step["run"]],
                                      cwd=directory, env={**os.environ, "VERSION": "v1.2.3"},
                                      capture_output=True).returncode
            self.assertEqual(0, run_guard())
            linux = release / "Camiel-v1.2.3-linux.tar.gz"
            linux.unlink()
            self.assertNotEqual(0, run_guard())
            linux.mkdir()
            self.assertNotEqual(0, run_guard())

    def test_contributing_names_check(self) -> None:
        text = CONTRIBUTING_PATH.read_text(encoding="utf-8")
        self.assertIn("4.7.2", text)
        self.assertIn("bash scripts/tools/run_headless_check.sh", text)
        self.assertNotIn("4.6.2", text)
        self.assertNotIn("verify_camiel_resources", text)


if __name__ == "__main__":
    unittest.main()
