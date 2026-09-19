# CI And Community Standards

## GitHub Actions

The repository includes these workflows:

- `CI`: verifies repository hygiene, imports the Godot project, runs the Godot verifier and behavioral probes plus failure-injection self-tests, and exports Windows, Linux, macOS and Web artifacts.
- `CodeQL`: scans GitHub Actions workflow code with CodeQL.
- `Dependency Review`: checks dependency changes in pull requests.
- `Release`: reuses the complete CI chain and uploads all four platform packages to a GitHub Release for matching tags.

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

The observed PR checks also include `Analyze (python)` from CodeQL - Code Quality. This does not analyze GDScript gameplay.

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

Repository settings are mutable GitHub configuration, not enforced by this document. Read them with `gh api repos/Euraika-Labs/Project-Camiel` before relying on a particular hosting or merge setting.

## Main Branch Protection

The `main` branch is protected.

Required checks (observed 19 September 2026):

- `Repository hygiene`
- `Verify Godot project`
- `Export Windows build`
- `Analyze GitHub Actions`

Protection rules:

- Pull request required before merging.
- The current required approving-review count is zero.
- Last-pusher approval is not currently required.
- Stale approvals are dismissed when new commits are pushed.
- Branch must be up to date before merge.
- Conversation resolution required before merge.
- Linear history required.
- Signed commits required.
- Administrator enforcement is currently disabled.
- Force pushes disabled.
- Branch deletion disabled.

## Binary Policy

Large exported builds are not committed to git.

Build outputs go to:

- GitHub Actions artifacts for CI builds.
- GitHub Release assets for published alpha builds.

`Export Windows build` is the stable required status name. The actual reusable export job is `export-builds / Export windows build`; the stable gate depends on successful completion of the four-platform export workflow and fails for failed, skipped or cancelled exports. See [build evidence](build-and-release.md).
