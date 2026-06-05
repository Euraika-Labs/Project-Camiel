#!/usr/bin/env python3
# scripts/ui/extract_templates.py
# Extracts Godot export templates from a .tpz (zip) archive.
# Removes the internal 'templates/' prefix so files land directly in the
# Godot templates directory.
import sys
import zipfile
import pathlib
import os

def main() -> None:
    tpz_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/templates.tpz"
    templates_version = sys.argv[2] if len(sys.argv) > 2 else "4.6/stable"
    dest = pathlib.Path(os.path.expanduser(f"~/.local/share/godot/export_templates/{templates_version}"))
    dest.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(tpz_path, "r") as z:
        for member in z.namelist():
            if not member.startswith("templates/"):
                continue
            target = dest / pathlib.Path(member).name
            with z.open(member) as src, open(target, "wb") as dst:
                dst.write(src.read())
            print(f"Extracted: {member}")

if __name__ == "__main__":
    main()
