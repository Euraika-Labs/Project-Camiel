# Build And Release

Last updated: 2026-06-06

## Prerequisites

- Godot `4.6.3.stable`
- Matching export templates under `4.6.3.stable`
- Python 3 for repository quality checks
- GitHub CLI only when uploading releases manually

## Local Verification

Run from the repository root:

```bash
python3 scripts/tools/quality_gate.py --root .
python3 -m unittest tests.test_quality_gate
godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd
godot --headless --path . --script res://scripts/tools/verify_beta1_flow.gd
godot --headless --path . --quit-after 2
```

`verify_camiel_resources.gd` checks Camiel resources and all core Beta 1 scenes. `verify_beta1_flow.gd` checks local progress recording/reset and scene instantiation for the title, menu, lessons, and adult progress view.

## Local Release Exports

The current Beta 1 candidate presets are stored in `export_presets.cfg`.

```bash
mkdir -p dist/macos dist/windows dist/linux dist/web

godot --headless --path . --export-release "macOS" dist/macos/Camiel.zip
godot --headless --path . --export-release "Windows Desktop" dist/windows/Camiel.exe
godot --headless --path . --export-release "Linux/X11" dist/linux/Camiel
godot --headless --path . --export-release "HTML5" dist/web/index.html
```

Android export requires a configured Android SDK, build tools, and keystore. Do not include Android in a release until that target-specific QA passes.

## macOS Smoke Test

After exporting `dist/macos/Camiel.zip`:

```bash
rm -rf /tmp/camiel-export-run
mkdir -p /tmp/camiel-export-run
unzip -q dist/macos/Camiel.zip -d /tmp/camiel-export-run
"/tmp/camiel-export-run/Camiel beta-1-candidate.app/Contents/MacOS/Camiel beta-1-candidate" --headless --quit-after 2
```

The current macOS build is ad-hoc signed and not notarized. Gatekeeper warnings are expected for downloaded copies.

## CI/CD

- `.github/workflows/ci.yml` runs repository quality checks.
- `.github/workflows/export.yml` builds release artifacts.
- `.github/workflows/release.yml` is manual to avoid duplicate tag-release jobs.

The workflows target Godot `4.6.3` and export template version `4.6.3.stable`.

## Release Checklist

- Update `CHANGELOG.md`.
- Run all local verification commands.
- Build release artifacts from a clean checkout.
- Smoke test at least one desktop artifact locally.
- Attach parent/teacher notes, privacy note, accessibility note, known issues, and feedback instructions.
- Tag only after the candidate build and docs are ready.
