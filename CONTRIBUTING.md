# Contributing

Thanks for helping with Project Camiel.

## Project Direction

Project Camiel is aimed at children from around 3 years old. Contributions should be:

- Simple.
- Friendly.
- Low pressure.
- Visually clear.
- Educational where possible.

## Development Setup

Use Godot `4.7.2.stable`.

Open the project from the repository root, where `project.godot` lives.

## Before Opening A Pull Request

Run the project check before every commit. It imports the project, runs the main scene with a timeout, fails on script errors, verifies every script and scene, and runs behaviour probes:

```bash
bash scripts/tools/run_headless_check.sh
```

Set `GODOT=/path/to/Godot` when Godot is not at `/Applications/Godot.app` or on `PATH`. On Windows, run this command from Git Bash.

Also run the main scene manually in Godot when the change affects gameplay, visuals, or input.

## Assets

- Keep Godot-ready assets under `assets/` and commit their `.import` files.
- Do not commit temporary chroma-key sources, generated previews, or build outputs.
- Put exported builds in GitHub Releases, not in git.

## Pull Request Expectations

- Keep changes focused.
- Update docs when behavior or setup changes.
- Explain manual testing.
- Avoid adding complex interactions without discussing the child-facing design first.

