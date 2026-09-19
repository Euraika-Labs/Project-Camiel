from __future__ import annotations

import contextlib
import io
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts/tools"))
import build_release
from release_version import read_version


class ReleaseBuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "project.godot"
        self.project.write_text('[application]\nconfig/version="alpha-v0.0.4"\n')
        self.payload = self.root / "payload"
        self.payload.mkdir()
        self.stem = "Camiel-alpha-v0.0.4"

    def test_version_source_and_reject_unsafe_or_missing_values(self):
        self.assertEqual("alpha-v0.0.4", read_version(self.project))
        for value in ('"../bad"', '"$(touch bad)"', '"v1/2"', '""', '4'):
            self.project.write_text(f'[application]\nconfig/version={value}\n')
            with self.assertRaises(ValueError):
                read_version(self.project)
        self.project.write_text('[other]\nconfig/version="v1.2.3"\n')
        with self.assertRaises(ValueError):
            read_version(self.project)
        self.project.write_text('[application]\nconfig/version="v1.2.3"\nconfig/version="v2.3.4"\n')
        with self.assertRaises(ValueError):
            read_version(self.project)

    def test_tag_must_match_checked_out_version(self):
        tool = Path(build_release.__file__).with_name("release_version.py")
        for tag, status in (("alpha-v0.0.4", 0), ("alpha-v0.0.3", 2)):
            result = subprocess.run([sys.executable, str(tool), "--project", str(self.project), "--tag", tag], capture_output=True)
            self.assertEqual(status, result.returncode)

    def test_linux_tar_contains_executable_and_sidecar_at_archive_root(self):
        binary = self.payload / (self.stem + ".x86_64")
        binary.write_bytes(b"ELF test binary")
        (self.payload / (self.stem + ".pck")).write_bytes(b"pack")
        archive = build_release.package("linux", self.payload, self.root, self.stem)
        self.assertEqual(self.stem + "-linux.tar.gz", archive.name)
        with tarfile.open(archive) as bundle:
            self.assertEqual([self.stem + ".pck", self.stem + ".x86_64"], bundle.getnames())
            self.assertTrue(bundle.getmember(binary.name).mode & 0o111)
            self.assertEqual(b"ELF test binary", bundle.extractfile(binary.name).read())

    def test_windows_zip_keeps_sidecars(self):
        for extension in (".exe", ".pck", ".dll"):
            (self.payload / (self.stem + extension)).write_bytes(b"payload")
        archive = build_release.package("windows", self.payload, self.root, self.stem)
        with zipfile.ZipFile(archive) as bundle:
            self.assertEqual(3, len(bundle.namelist()))
            self.assertIn(self.stem + ".exe", bundle.namelist())

    def test_macos_zip_is_not_wrapped_in_another_zip(self):
        path = self.payload / (self.stem + ".zip")
        member = "Camiel.app/Contents/MacOS/Camiel"
        with zipfile.ZipFile(path, "w") as bundle:
            bundle.writestr(member, b"binary")
        archive = build_release.package("macos", self.payload, self.root, self.stem)
        with zipfile.ZipFile(archive) as bundle:
            self.assertEqual([member], bundle.namelist())

    def test_missing_and_empty_payload_fail(self):
        with self.assertRaises(ValueError):
            build_release.package("windows", self.payload, self.root, self.stem)
        (self.payload / "bad.exe").touch()
        with self.assertRaises(ValueError):
            build_release.package("windows", self.payload, self.root, self.stem)

    def test_zero_exit_script_parse_and_engine_errors_fail(self):
        for output in ("SCRIPT ERROR: broken", "Parse Error: broken", "ERROR: import failed"):
            with patch.object(build_release.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, output)):
                with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(RuntimeError):
                    build_release.run_godot("godot", "--headless")

    def test_nonzero_exit_and_timeout_fail(self):
        with patch.object(build_release.subprocess, "run", return_value=subprocess.CompletedProcess([], 1, "failed")):
            with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(RuntimeError):
                build_release.run_godot("godot")
        with patch.object(build_release.subprocess, "run", side_effect=subprocess.TimeoutExpired("godot", 180)):
            with self.assertRaises(subprocess.TimeoutExpired):
                build_release.run_godot("godot")

    def test_missing_export_cannot_reuse_stale_artifact(self):
        (self.root / (self.stem + "-windows.zip")).write_bytes(b"old build")
        with patch.object(build_release.subprocess, "check_output", return_value="4.7.2.stable.official"), patch.object(build_release, "run_godot"):
            with self.assertRaisesRegex(ValueError, "did not produce"):
                build_release.build("windows", "godot", self.root, self.root)

    def test_web_export_requires_complete_payload(self):
        def fake_engine(engine, *args):
            if "--export-release" in args:
                Path(args[-1]).write_text("<html></html>")
        with patch.object(build_release.subprocess, "check_output", return_value="4.7.2.stable"), patch.object(build_release, "run_godot", side_effect=fake_engine):
            with self.assertRaisesRegex(ValueError, "missing .js"):
                build_release.build("web", "godot", self.root, self.root)

    def test_all_targets_build_with_version_derived_names(self):
        def fake_engine(engine, *args):
            if "--export-release" not in args:
                return
            path = Path(args[-1])
            if path.suffix == ".zip":
                with zipfile.ZipFile(path, "w") as bundle:
                    bundle.writestr("Camiel.app/Contents/MacOS/Camiel", b"binary")
            else:
                path.write_bytes(b"export")
                if path.suffix == ".html":
                    for extension in (".js", ".wasm", ".pck"):
                        path.with_suffix(extension).write_bytes(b"web resource")
        self.project.write_text('[application]\nconfig/version="v2.3.4"\n')
        with patch.object(build_release.subprocess, "check_output", return_value="4.7.2.stable"), patch.object(build_release, "run_godot", side_effect=fake_engine):
            for target in build_release.TARGETS:
                archive = build_release.build(target, "godot", self.root, self.root)
                suffix = ".tar.gz" if target == "linux" else ".zip"
                self.assertEqual(f"Camiel-v2.3.4-{target}{suffix}", archive.name)
                self.assertGreater(archive.stat().st_size, 0)
                if target == "web":
                    with zipfile.ZipFile(archive) as bundle:
                        self.assertEqual(["index.html", "index.js", "index.pck", "index.wasm"], bundle.namelist())

    def test_wrong_engine_fails_before_export(self):
        with patch.object(build_release.subprocess, "check_output", return_value="4.6.2.stable"), patch.object(build_release, "run_godot") as run:
            with self.assertRaises(ValueError):
                build_release.build("windows", "godot", self.root, self.root)
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
