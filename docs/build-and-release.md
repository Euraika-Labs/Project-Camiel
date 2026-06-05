# Build & Release Guide — Camiel

> **Author:** Euraika development team  
> **Last updated:** 2026-06-05

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Build](#local-development-build)
3. [Local Release Build](#local-release-build)
4. [CI/CD Pipeline (GitHub Actions)](#cicd-pipeline-github-actions)
5. [Export Presets Reference](#export-presets-reference)
6. [Version Numbering](#version-numbering)
7. [Creating a Release](#creating-a-release)
8. [Post-Release Checklist](#post-release-checklist)

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Godot 4 | 4.6 (or current LTS) | Game engine |
| Git | any recent | Source control |
| `glab` or `git` | latest | Repository access on git.euraika.net |
| `gh` CLI (optional) | latest | GitHub release management |

### Installing Godot 4

Download from [godotengine.org](https://godotengine.org).

```bash
# macOS (Intel/Apple Silicon)
brew install godot

# Or download the binary directly
curl -LO https://github.com/godotengine/godot/releases/download/4.6-stable/Godot_v4.6-stable.zip
unzip Godot_v4.6-stable.zip
chmod +x Godot_v4.6
```

### Installing Export Templates

Export templates are required for building release binaries:

```bash
# In Godot editor: Editor → Manage Export Templates → Download
# Or via CLI (replace 4.6 with your Godot version)
curl -LO https://github.com/godotengine/godot-export-templates/releases/download/4.6-stable/Godot_v4.6-stable-export_templates.tpz
```

---

## Local Development Build

### Editor Play

```bash
cd Project-Camiel
godot --path .
# Opens the Godot editor. Press F5 to run the main scene.
```

### Headless Play (test without window)

```bash
godot --headless --path . --script run_quick_test.gd
```

---

## Local Release Build

### Using the Godot Editor

1. Open the project in Godot.
2. Go to **Project → Export**.
3. Select **Windows Desktop** preset.
4. Click **Export Project**.
5. Save to `builds/alpha-vX.Y.Z/windows/Camiel-alpha-vX.Y.Z.exe`.

### Using the Command Line

```bash
# Full headless export
godot --headless --path . --export-release "Windows Desktop" builds/alpha-v0.0.3/windows/Camiel-alpha-v0.0.3.exe

# Verify the file was created
ls -lh builds/alpha-v0.0.3/windows/
```

### Using the Python Extract Script (for CI)

```bash
python3 scripts/ui/extract_templates.py /tmp/templates.tpz "4.6/stable"
```

---

## CI/CD Pipeline (GitHub Actions)

The automated pipeline is defined in `.github/workflows/export.yml`.

### Pipeline Stages

```
Push to main ──→ quality-gate ──→ export-windows ──→ [artefact uploaded]
                                       │
                                       └── release (on tags v*)
                                                          │
                                                          └── [GitHub Release created]

Tag v* ──→ quality-gate ──→ export-windows ──→ package ──→ [artefact uploaded]
                                             │
                                             └── Create Release
```


### Quality Gate Step

Before any export, the pipeline runs the Godot quality gate script:

```yaml
- name: Quality Gate
  run: godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd
```

This script verifies:
- No build artefacts (`.exe`, `.pck`, `.zip`) are committed to the repo.
- `project.godot` is present at the repo root.
- `config_version` is set in `project.godot`.
- No unfinished task markers (e.g. X-TODO, X-FIXME, placeholder copy) in source files.
- All Godot resource paths referenced in `.gd` and `.tscn` files exist on disk.

If the quality gate fails, the pipeline stops — no artefact is exported.

### Export Step

The Windows export runs headlessly using the `gobject/godot-action` GitHub Action:

```yaml
- uses: gobject/godot-action@v3
  with:
    godot-version: 4.6.2

- name: Export Windows
  run: |
    mkdir -p builds/$GITHUB_REF_NAME/windows
    godot --headless --path . --export-release "Windows Desktop" \
      builds/$GITHUB_REF_NAME/windows/Camiel.exe
```

The output path uses `$GITHUB_REF_NAME` so branch builds and tag builds are isolated:
- Push to `main` → `builds/refs/heads/main/windows/Camiel.exe`
- Tag `v0.0.3` → `builds/tags/v0.0.3/windows/Camiel.exe`

### Artifact Upload

After a successful export, the artefacts are uploaded as GitHub Actions artifacts:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: camiel-windows-$GITHUB_REF_NAME
    path: builds/$GITHUB_REF_NAME/windows/
```

Artifacts are retained for 30 days (default). They can be downloaded from the GitHub Actions run summary.

### Release Creation on Tags

When a semver tag (`v*`) is pushed, the pipeline creates a GitHub Release:

```yaml
- name: Create Release
  if: startsWith(github.ref, refs/tags/)
  uses: softprops/action-gh-release@v1
  with:
    files: builds/$GITHUB_REF_NAME/windows/*
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The release:
- Is named after the tag (e.g. `v0.0.3`).
- Includes the packaged `.zip` of the Windows executable.
- Is marked as a draft until manually published (or change `draft: false`).

### Running the Pipeline Locally (act)

You can simulate GitHub Actions locally with [nektos/act](https://github.com/nektos/act):

```bash
# Install act
brew install act

# Run the quality gate job
act -j quality-gate

# Run the full pipeline (requires Docker)
act -P ubuntu-latest=catthehacker/ubuntu:latest
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GODOT_VERSION` | `4.6` | Godot version to use |
| `EXPORT_PRESET` | `Windows Desktop` | Which preset to export |
| `TEMPLATES_VERSION` | `4.6/stable` | Export templates version |

---

## Export Presets Reference

The `export_presets.cfg` file at the repo root defines all export targets.

### Current Presets

| Preset | Platform | Output | Encryption |
|--------|---------|--------|-----------|
| `Windows Desktop` | Windows x86_64 | `builds/.../Camiel-alpha-vX.Y.Z.exe` | Not encrypted |

### Adding a New Preset

1. Open the project in Godot.
2. Go to **Project → Export**.
3. Click **Add...** and select your target platform.
4. Configure the preset (output path, custom features, etc.).
5. The preset is saved to `export_presets.cfg` — commit this file.

### Browser Export (Future)

When adding HTML5/Web export:

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

**Note:** Web export requires a web server that supports SharedArrayBuffer
(COOP/COEP headers). See [Godot docs on Web export](https://docs.godotengine.org).

---

## Version Numbering

Camiel uses **Semantic Versioning** (SemVer): `MAJOR.MINOR.PATCH`

| Increment | When | Example |
|-----------|------|---------|
| `PATCH` | Bug fixes, no new features | `0.0.1` → `0.0.2` |
| `MINOR` | New features, backward-compatible | `0.0.2` → `0.1.0` |
| `MAJOR` | Breaking changes | `1.0.0` → `2.0.0` |

**Alpha versions** are pre-releases: `0.0.1-alpha.1`, `0.0.2-alpha.1`.

The version string is stored in:
- `project.godot` → `config/name`
- `export_presets.cfg` → `application/file_version`
- `scenes/main_menu.tscn` → `$UI/VersionLabel` text

---

## Creating a Release

### 1. Update the Changelog

See `CHANGELOG.md` for the format. Add a new entry for the release version.

### 2. Tag the Release

```bash
git checkout develop
git pull origin develop

# Merge develop into main for a release
git checkout main
git merge develop --no-ff -m "Merge develop for v0.0.3"

# Tag the release
git tag -a v0.0.3 -m "v0.0.3: Alpha release — Lessons, accessibility, CI"
git push origin main --tags
```

### 3. GitHub Actions自动化

Pushing the tag triggers the full pipeline:
- Quality gate runs.
- Windows export is built.
- If on `main` or a `v*` tag, code signing runs (if `WINDOWS_SIGNING_CERT_B64` is set).
- A GitHub Release is created using `CHANGELOG.md` as the body.

### 4. Manual Artefact Upload (if CI fails)

```bash
# Export locally
godot --headless --path . --export-release "Windows Desktop" builds/Camiel-alpha-v0.0.3.exe

# Upload to the GitHub Release
gh release upload v0.0.3 builds/Camiel-alpha-v0.0.3.exe --clobber
```

---

## Post-Release Checklist

- [ ] `CHANGELOG.md` updated with all changes since last release
- [ ] `docs/roadmap.md` marked current version as done
- [ ] Git tag pushed to `origin main`
- [ ] GitHub Release created and artefacts attached
- [ ] Export presets `export_path` updated to next version
- [ ] `project.godot` `config/name` updated to next version
- [ ] `scenes/main_menu.tscn` version label updated
- [ ] Announced in relevant channels (internal, partner, community)

---

*Maintained by: Euraika development team*  
*Last reviewed: 2026-06-05*
