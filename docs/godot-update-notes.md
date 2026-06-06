# Godot 4.6.3 Update Notes

Project Camiel currently targets `Godot 4.6.3.stable`.

## What Changed

- CI workflows and local build docs now use Godot `4.6.3`.
- `project.godot` uses `config_version=5`, which is the format expected by Godot 4.6.3.
- Export templates are installed under `4.6.3.stable`.
- Desktop export presets are configured for Beta 1 candidate outputs.
- macOS export requires `rendering/textures/vram_compression/import_etc2_astc=true`.

## Why 4.6.3

Local verification found Godot 4.6.3 available as the stable engine release and matching export templates. Do not move workflows to a newer patch number until the official Godot release and matching export templates are available.

## Required Local Setup

Install the editor and matching export templates:

```bash
godot --version
godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd
godot --headless --path . --script res://scripts/tools/verify_beta1_flow.gd
```

## Compatibility

Existing scenes and scripts load under Godot 4.6.3. The release compiler is stricter than editor play for some inferred variable types, so use the export command as part of final verification.

## Rollback

Rollback should only be used if 4.6.3 introduces a blocking issue:

1. Reinstall the previous Godot editor and export templates.
2. Revert workflow and documentation version strings.
3. Re-run the resource verifier, Beta 1 flow verifier, startup smoke test, and export.
