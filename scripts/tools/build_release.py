"""Export and package one platform; fail on Godot errors even with exit status zero."""
from __future__ import annotations

import argparse
import hashlib
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
WINDOWS_PORTABLE = "windows-portable"
# The GUI executable from the official Godot 4.7.2-stable Windows x86_64 ZIP.
WINDOWS_RUNTIME_SHA256 = "ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424"


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
        if not binary.is_file():
            raise ValueError(f"Export did not produce {binary.name}")
        with tarfile.open(archive, "w:gz") as bundle:
            for path in files:
                member = bundle.gettarinfo(path, arcname=path.relative_to(payload))
                if path == binary:
                    member.mode |= 0o111
                with path.open("rb") as source:
                    bundle.addfile(member, source)
    else:
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
            for path in files:
                bundle.write(path, path.relative_to(payload))
    return archive


def _add_windows_portable_files(
    payload: Path, root: Path, runtime: Path | None, godot_notices: Path | None,
) -> None:
    if runtime is None or godot_notices is None:
        raise ValueError("The portable Windows target requires --windows-runtime and --godot-notices")

    executable = payload / "Camiel spelen.exe"
    shutil.copyfile(runtime, executable)
    digest = hashlib.sha256()
    with executable.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    if digest.hexdigest() != WINDOWS_RUNTIME_SHA256:
        raise ValueError("The Windows runtime must match the official Godot 4.7.2-stable x86_64 executable")

    shutil.copyfile(godot_notices, payload / "Godot-licenties.txt")
    shutil.copyfile(root / "LICENSE", payload / "Camiel-licentie.txt")
    (payload / "START HIER.txt").write_text(
        "Pak het hele ziparchief uit en open Camiel spelen.exe.\n"
        "Houd Camiel spelen.exe en Camiel spelen.pck in dezelfde map.\n\n"
        "Het uitvoerbestand bevat de officiële Godot-runtime. Het PCK-bestand bevat Camiel.\n",
        encoding="utf-8",
    )


def build(
    target: str, engine: str, root: Path, output: Path, *,
    windows_runtime: Path | None = None, godot_notices: Path | None = None,
) -> Path:
    version = read_version(root / "project.godot")
    engine_version = subprocess.check_output([engine, "--version"], text=True, timeout=15)
    if not engine_version.startswith("4.7.2.stable"):
        raise ValueError("Godot 4.7.2.stable is required")
    output.mkdir(parents=True, exist_ok=True)
    stem = f"Camiel-{version}"
    # Fresh payload prevents an earlier successful build from masking missing output.
    with tempfile.TemporaryDirectory(prefix="camiel-export-") as directory:
        payload = Path(directory)
        if target == WINDOWS_PORTABLE:
            _add_windows_portable_files(payload, root, windows_runtime, godot_notices)
            preset, _ = TARGETS["windows"]
            entry = payload / "Camiel spelen.pck"
            export_action = "--export-pack"
        else:
            preset, extension = TARGETS[target]
            entry = payload / ("index.html" if target == "web" else stem + extension)
            export_action = "--export-release"
        run_godot(engine, "--headless", "--editor", "--path", str(root), "--quit")
        run_godot(engine, "--headless", "--path", str(root), export_action, preset, str(entry))
        if not entry.is_file() or entry.stat().st_size == 0:
            raise ValueError(f"Export did not produce {entry.name}")
        if target == WINDOWS_PORTABLE:
            with entry.open("rb") as pack:
                if pack.read(4) != b"GDPC":
                    raise ValueError("Portable Windows export is not a Godot pack")
        if target == "web":
            for extension in (".js", ".wasm", ".pck"):
                if not entry.with_suffix(extension).is_file():
                    raise ValueError(f"Web export missing {extension}")
        return package(target, payload, output, stem)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=(*TARGETS, WINDOWS_PORTABLE))
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path, default=ROOT / "builds" / "release")
    parser.add_argument("--windows-runtime", type=Path, help="Official Godot Windows GUI executable for windows-portable")
    parser.add_argument("--godot-notices", type=Path, help="Godot license and third-party notices for windows-portable")
    args = parser.parse_args()
    print(build(
        args.target, args.godot, args.root.resolve(), args.output.resolve(),
        windows_runtime=args.windows_runtime, godot_notices=args.godot_notices,
    ))


if __name__ == "__main__":
    main()
