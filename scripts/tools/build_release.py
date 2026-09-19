"""Export and package one platform; fail on Godot errors even with exit status zero."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import zipfile

from release_version import ROOT, read_version

TARGETS = {
    "windows": ("Windows Desktop", ".exe"),
    "linux": ("Linux", ".x86_64"),
    "macos": ("macOS", ".zip"),
    "web": ("Web", ".html"),
}


def run_godot(engine: str, *args: str, timeout: int = 180) -> None:
    result = subprocess.run([engine, *args], text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=timeout)
    print(result.stdout, end="")
    if result.returncode or re.search(r"SCRIPT ERROR|Parse Error|ERROR:", result.stdout):
        raise RuntimeError("Godot export/import failed; see output above")


def package(target: str, payload: Path, output: Path, stem: str) -> Path:
    files = sorted(path for path in payload.rglob("*") if path.is_file())
    if not files or any(path.stat().st_size == 0 for path in files):
        raise ValueError("Export payload is missing or empty")
    suffix = ".tar.gz" if target == "linux" else ".zip"
    archive = output / f"{stem}-{target}{suffix}"
    if target == "macos":
        source = payload / f"{stem}.zip"
        with zipfile.ZipFile(source) as bundle:
            if bundle.testzip() or not any(".app/Contents/MacOS/" in n for n in bundle.namelist()):
                raise ValueError("macOS export has no valid app executable")
        shutil.copyfile(source, archive)
    elif target == "linux":
        binary = payload / f"{stem}.x86_64"
        binary.chmod(binary.stat().st_mode | 0o111)
        with tarfile.open(archive, "w:gz") as bundle:
            for path in files:
                bundle.add(path, arcname=path.relative_to(payload))
    else:
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
            for path in files:
                bundle.write(path, path.relative_to(payload))
    return archive


def build(target: str, engine: str, root: Path, output: Path) -> Path:
    version = read_version(root / "project.godot")
    engine_version = subprocess.check_output([engine, "--version"], text=True, timeout=15)
    if not engine_version.startswith("4.7.2.stable"):
        raise ValueError("Godot 4.7.2.stable is required")
    output.mkdir(parents=True, exist_ok=True)
    stem = f"Camiel-{version}"
    # Fresh payload prevents an earlier successful build from masking missing output.
    with tempfile.TemporaryDirectory(prefix="camiel-export-") as directory:
        payload = Path(directory)
        preset, extension = TARGETS[target]
        executable = payload / ("index.html" if target == "web" else stem + extension)
        run_godot(engine, "--headless", "--editor", "--path", str(root), "--quit")
        run_godot(engine, "--headless", "--path", str(root), "--export-release", preset, str(executable))
        if not executable.is_file() or executable.stat().st_size == 0:
            raise ValueError(f"Export did not produce {executable.name}")
        if target == "web":
            for extension in (".js", ".wasm", ".pck"):
                if not executable.with_suffix(extension).is_file():
                    raise ValueError(f"Web export missing {extension}")
        return package(target, payload, output, stem)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=TARGETS)
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path, default=ROOT / "builds" / "release")
    args = parser.parse_args()
    print(build(args.target, args.godot, args.root.resolve(), args.output.resolve()))


if __name__ == "__main__":
    main()
