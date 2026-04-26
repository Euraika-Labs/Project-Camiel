# CI And Community Standards

## GitHub Actions

The repository includes these workflows:

- `CI`: verifies repository hygiene, imports the Godot project, runs the Godot verification script, smoke-tests the main scene, and exports a Windows artifact.
- `CodeQL`: scans GitHub Actions workflow code with CodeQL.
- `Dependency Review`: checks dependency changes in pull requests.
- `Release`: builds Windows release artifacts and uploads them to a GitHub Release for matching tags.

## CodeQL Notes

Project Camiel is primarily written in GDScript. CodeQL does not currently support GDScript as a CodeQL language.

CodeQL is still configured for GitHub Actions workflow analysis. If supported languages are added later, the CodeQL setup can be expanded.

The GitHub repository is currently private. GitHub requires GitHub Code Security or Advanced Security before code scanning results can be uploaded for private repositories. The workflow detects that condition and leaves a notice instead of failing the whole pipeline when code scanning is not available.

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

Secret scanning and push protection are not available on the current private repository plan unless GitHub Secret Protection is enabled for the organization.

## Binary Policy

Large exported builds are not committed to git.

Build outputs go to:

- GitHub Actions artifacts for CI builds.
- GitHub Release assets for published alpha builds.
