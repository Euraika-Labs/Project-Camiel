# Contributing

Thanks for helping with Project Camiel.

## Project Direction

Project Camiel is aimed at children from around 3 years old. Contributions should be simple, friendly, low pressure, visually clear, and educational where possible.

## Development Setup

Use Godot `4.6.3.stable` with matching export templates. Open the project from the repository root, where `project.godot` lives.

## Before Opening A Pull Request

Run the local gates:

```bash
python3 scripts/tools/quality_gate.py --root .
python3 -m unittest tests.test_quality_gate
godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd
godot --headless --path . --script res://scripts/tools/verify_beta1_flow.gd
```

Also run the main scene manually in Godot when the change affects gameplay, visuals, input, or audio.

## Assets

- Keep Godot-ready assets under `assets/`.
- Do not commit temporary chroma-key sources, generated previews, or local build outputs.
- Put exported builds in GitHub Releases or `dist/` for local verification, not in git.

## Pull Request Expectations

- Keep changes focused.
- Update docs when behavior or setup changes.
- Explain manual testing and any platform not tested.
- Avoid complex child-facing interactions without design review.
