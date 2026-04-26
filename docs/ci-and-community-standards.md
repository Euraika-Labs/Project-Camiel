# CI And Community Standards

## GitHub Actions

The repository includes these workflows:

- `CI`: verifies repository hygiene, imports the Godot project, runs the Godot verification script, smoke-tests the main scene, and exports a Windows artifact.
- `CodeQL`: scans GitHub Actions workflow code with CodeQL.
- `Dependency Review`: checks dependency changes in pull requests.
- `Release`: builds Windows release artifacts and uploads them to a GitHub Release for matching tags.

## AI Quality Gate

The CI workflow includes a Project Camiel quality gate at `scripts/tools/quality_gate.py`.

It blocks common AI-slop and AI-error patterns:

- Assistant self-disclaimer text.
- Unfinished future-work markers.
- Filler copy, replace-me copy, and unsupported future promises.
- Broken local Markdown links.
- Local Markdown links that point outside the repository.
- Missing Godot `res://` resource paths in `.gd`, `.godot`, `.tscn`, `.tres`, and export config files.
- Empty tracked files.
- PNG assets under `assets/` without matching Godot `.import` metadata.
- Accidental removal of required community, security, and CI files.

The quality gate has its own unittest coverage in `tests/test_quality_gate.py`.

## CodeQL Notes

Project Camiel is primarily written in GDScript. CodeQL does not currently support GDScript as a CodeQL language.

CodeQL is configured for GitHub Actions workflow analysis. The repository is public as of 2026-04-26, so GitHub code scanning can upload CodeQL results without requiring a private-repository Code Security purchase.

If supported source languages are added later, the CodeQL setup can be expanded.

## Community Health Files

The repository includes:

- `README.md`
- `CODE_OF_CONDUCT.md`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `SUPPORT.md`
- `LICENSE`
- Issue templates.
- Pull request template.
- Dependabot configuration for GitHub Actions.

## Repository Settings

The repository has these GitHub settings configured:

- Issues enabled.
- Wiki disabled.
- Projects enabled.
- Delete branch on merge enabled.
- Dependabot alerts enabled.
- Dependabot automated security fixes enabled.
- Private vulnerability reporting enabled.
- Secret scanning enabled.
- Secret scanning push protection enabled.

## Binary Policy

Large exported builds are not committed to git.

Build outputs go to:

- GitHub Actions artifacts for CI builds.
- GitHub Release assets for published alpha builds.
