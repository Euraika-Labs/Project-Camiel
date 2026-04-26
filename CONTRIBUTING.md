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

Use Godot `4.6.2.stable`.

Open the project from the repository root, where `project.godot` lives.

## Before Opening A Pull Request

Run the verifier:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path "." --script "res://scripts/tools/verify_camiel_resources.gd"
```

Also run the main scene manually in Godot when the change affects gameplay, visuals, or input.

## Assets

- Keep Godot-ready assets under `assets/camiel/`.
- Do not commit temporary chroma-key sources, generated previews, or build outputs.
- Put exported builds in GitHub Releases, not in git.

## Pull Request Expectations

- Keep changes focused.
- Update docs when behavior or setup changes.
- Explain manual testing.
- Avoid adding complex interactions without discussing the child-facing design first.

