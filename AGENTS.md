# Repository Guidelines

## Project Structure & Module Organization

Project Camiel is a Godot 4.6 game. `project.godot` is the root config, with the main scene set to `res://scenes/title_screen.tscn`. Runtime GDScript lives in `scripts/`, scene files in `scenes/`, reusable UI in `scripts/ui/` and `scenes/ui/`, and repository tooling in `scripts/tools/`. Python tests for tooling are in `tests/`. Game assets are under `assets/camiel/` and `assets/audio/`; longer project notes live in `docs/`.

## Build, Test, and Development Commands

- `godot --path .`: open the project in the Godot editor; press F5 to run the main scene.
- `godot --headless --path . --script "res://scripts/tools/verify_camiel_resources.gd"`: validate required scenes, resources, animations, and Camiel scene wiring.
- `python3 scripts/tools/quality_gate.py --root .`: run repository hygiene checks for local Markdown links, `res://` paths, empty files, and blocked draft markers.
- `python3 -m unittest tests.test_quality_gate`: run the Python unit tests for the quality gate.
- `godot --headless --path . --export-release "Windows Desktop" builds/local/Camiel.exe`: create a local Windows export. Keep `builds/` out of git.

Use Godot 4.6.x and match the version pinned in `.github/workflows/ci.yml` when validating CI-sensitive changes.

## Coding Style & Naming Conventions

Follow `.editorconfig`: UTF-8, LF endings, final newline, and trimmed trailing whitespace. Use tabs for GDScript indentation, matching existing files, and 4 spaces for Python. Prefer `snake_case` for GDScript files, functions, variables, signals, and node names used from code. Use typed `@export` and `@onready` variables where they improve clarity. Keep gameplay copy short, friendly, and age-appropriate for children around 3+.

## Testing Guidelines

For tooling changes, add or update `unittest` coverage in `tests/test_quality_gate.py`. For gameplay, UI, asset, or input changes, run the Godot verifier and manually play the affected scene in the editor. Also run the repository quality gate before opening a PR, especially after editing Markdown, `.gd`, `.tscn`, `.tres`, or asset paths.

## Commit & Pull Request Guidelines

Recent history uses concise conventional commits such as `feat: ...`, `fix: ...`, `fix(qg): ...`, and `ci(deps): ...`. Keep the subject imperative and focused. Pull requests should follow `.github/PULL_REQUEST_TEMPLATE.md`: include a short summary, confirm the child-friendly checklist, document exact test commands or manual checks, update docs when behavior or setup changes, and avoid committing large binaries.

## Security & Configuration Tips

Do not commit secrets, exported builds, or temporary generated files. Keep release binaries in GitHub Actions artifacts or GitHub Releases. When adding resources, ensure every checked-in Godot path resolves from `res://`.
