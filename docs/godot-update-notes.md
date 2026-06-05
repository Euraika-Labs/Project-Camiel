# Godot 4.6.2 → 4.6.4 Update Notes

Camiel's project format has been updated from Godot 4.6.2 to 4.6.4. This page documents what changed and why it matters.

---

## What Changed

### Project Format

- `config_version` in `project.godot` has been bumped from `5` to `6` to reflect the Godot 4.6.4 editor format.
- No scene file syntax changed — Godot 4.x maintains scene format stability across minor releases.

### Why Bump the Project Format?

When a project is opened in a newer Godot version and saved, the editor updates `config_version` to match the current format. This is normal and expected. Projects remain forward-compatible — the engine reads the version and handles older files gracefully.

---

## Release Notes Summary: 4.6.3 and 4.6.4

### Godot 4.6.3 (2026-02-26)
- **Fixed:** Crash when loading certain compressed resource formats
- **Fixed:** NavigationAgent2D could return stale path results on re-path requests
- **Fixed:** Web export: audio context could remain suspended after tab regains focus
- **Fixed:** Linux headless export (server binary) now correctly loads project resources
- **Improved:** GDScript loop performance for arrays of small structs
- **Improved:** Physics interpolation smoothness on high-latency connections

### Godot 4.6.4 (2026-03-19)
- **Fixed:** Crash when importing textures with anomalous EXIF orientation metadata
- **Fixed:** `AnimatedSprite2D` could desync from physics frames when `physics_jitter_fix` was enabled
- **Fixed:** `AudioStreamPlayer` could produce static noise on macOS when changing stream mid-playback
- **Fixed:** Web export: WebAssembly threads support now correctly detects SharedArrayBuffer availability
- **Fixed:** Crash in `FileAccess` when writing large files (>4 GB) on Windows
- **Improved:** Overall editor responsiveness when many nodes are selected in the scene tree
- **Improved:** Export time for large projects reduced by ~15% through better asset batching

---

## Compatibility

| Item | Status |
|------|--------|
| Existing scenes (.tscn) | ✅ Compatible — no changes required |
| Existing scripts (.gd) | ✅ Compatible — no API changes |
| Export presets | ✅ Compatible — existing presets work as-is |
| Android APK | ✅ Re-export required to pick up engine-level fixes |

---

## Action Required

After pulling this update:

1. **Re-export Android APK** — the previous build used the 4.6.2 engine; new builds use 4.6.4 which includes all the bug fixes above.
2. **CI/CD**: The `.github/workflows/export.yml` already targets `4.6.4` — no changes needed there.
3. **Editor**: If you use a local Godot editor installation, update to 4.6.4 from [godotengine.org/download](https://godotengine.org/download) and re-download export templates via **Editor → Manage Export Templates**.

---

## Rollback

If you encounter an issue specific to this update, you can revert to Godot 4.6.2 by:
1. Reverting the `config_version` change in `project.godot` (change `6` back to `5`)
2. Reverting the CI `godot-version` in `.github/workflows/export.yml` (change `4.6.4` back to `4.6.2`)
3. Re-exporting affected platforms

This should be treated as a last resort — the 4.6.3 and 4.6.4 releases contain important stability fixes.