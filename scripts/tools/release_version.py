"""Read the release/filename version from Godot's application settings."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read_version(project: Path) -> str:
    section = ""
    versions = []
    for line in project.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("["):
            section = line
        if section == "[application]" and line.startswith("config/version="):
            versions.append(line.partition("=")[2])
    if len(versions) != 1 or not re.fullmatch(r'"(?:alpha-)?v\d+\.\d+\.\d+"', versions[0]):
        raise ValueError('Expected one application config/version="alpha-vX.Y.Z" or "vX.Y.Z"')
    return versions[0][1:-1]


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
