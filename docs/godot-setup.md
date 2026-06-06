# Godot Setup

## Engine Version

Use `Godot 4.6.3.stable` with matching `4.6.3.stable` export templates.

## Main Project Files

- `project.godot`: Godot project config and autoload registration.
- `scenes/title_screen.tscn`: configured startup scene.
- `scenes/main_menu.tscn`: child-facing menu.
- `scenes/lesson_select.tscn`: five-lesson selector.
- `scenes/main.tscn`: playable intro scene.
- `scenes/camiel.tscn`: Camiel character scene.
- `scripts/camiel_controller.gd`: player movement and animation controller.
- `scripts/progress_tracker.gd`: local progress storage.

## Verification

Run the Python and Godot gates from the repository root:

```bash
python3 scripts/tools/quality_gate.py --root .
python3 -m unittest tests.test_quality_gate
godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd
godot --headless --path . --script res://scripts/tools/verify_beta1_flow.gd
godot --headless --path . --quit-after 2
```

The resource verifier checks Camiel animation resources and all core Beta 1 scenes. The flow verifier checks progress recording/reset and scene instantiation for the title, menu, lesson selector, lessons, and adult progress view.

## Export Templates

Install export templates before building release artifacts:

```bash
mkdir -p "$HOME/Library/Application Support/Godot/export_templates/4.6.3.stable"
```

Use Godot's editor template manager or download the official `Godot_v4.6.3-stable_export_templates.tpz` package and copy its `templates/` contents into that directory.

## Notes

Current macOS exports use ad-hoc signing and are not notarized. Gatekeeper warnings are expected for downloaded ZIPs until a signing and notarization workflow is added.
