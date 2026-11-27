"""Read the release/filename version from Godot's application settings."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VERSION_NUMBER = r"[0-9]+\.[0-9]+\.[0-9]+"


def read_version(project: Path) -> str:
    section = ""
    settings = {"config/version": [], "config/release_channel": []}
    for line in project.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("["):
            section = line
        key, _, value = line.partition("=")
        key = key.strip()
        if section == "[application]" and key in settings:
            settings[key].append(value.strip())
    versions = settings["config/version"]
    channels = settings["config/release_channel"]
    if len(versions) != 1:
        raise ValueError('Expected one application config/version')
    version = versions[0]
    if not channels and re.fullmatch(rf'"(?:alpha-)?v{VERSION_NUMBER}"', version):
        return version[1:-1]
    if not re.fullmatch(rf'"{VERSION_NUMBER}"', version):
        raise ValueError('Expected application config/version="X.Y.Z"')
    if channels not in ([], ['"stable"'], ['"alpha"']):
        raise ValueError('Expected at most one application config/release_channel of "alpha" or "stable"')
    prefix = "alpha-v" if channels == ['"alpha"'] else "v"
    return prefix + version[1:-1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=ROOT / "project.godot")
    parser.add_argument("--tag", help="Require release tag to match project version")
    args = parser.parse_args()
    version = read_version(args.project)
    if args.tag is not None and args.tag != version:
        parser.error(f"Tag {args.tag!r} does not match project version {version!r}")
    print(version)


if __name__ == "__main__":
    main()
