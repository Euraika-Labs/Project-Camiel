# Build And Release

## Export Templates

Godot export templates were installed for:

`4.6.2.stable`

Installed template directory:

`%APPDATA%\Godot\export_templates\4.6.2.stable`

The Windows release template used by the build:

`windows_release_x86_64.exe`

## Export Preset

The Windows export preset is stored in:

`export_presets.cfg`

Preset name:

`Windows Desktop`

Export target:

`builds/alpha-v0.0.1/windows/Camiel-alpha-v0.0.1.exe`

The build embeds the `.pck` into the `.exe`.

## Build Command

Example command:

```powershell
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe"
& $godot --headless --path "." --export-release "Windows Desktop" "builds/alpha-v0.0.1/windows/Camiel-alpha-v0.0.1.exe"
```

## Local Build Output

Local build files:

- `builds/alpha-v0.0.1/windows/Camiel-alpha-v0.0.1.exe`
- `builds/alpha-v0.0.1/windows/Camiel-alpha-v0.0.1-windows.zip`

The `builds/` folder is ignored by git because exported binaries are large.

## GitHub Release

Release tag:

`alpha-v0.0.1`

Release URL:

https://github.com/Euraika-Labs/Project-Camiel/releases/tag/alpha-v0.0.1

Uploaded release assets:

- `Camiel-alpha-v0.0.1.exe`
- `Camiel-alpha-v0.0.1-windows.zip`

## Why Builds Are Not In Git

GitHub blocks normal git pushes for files over 100 MB.

The alpha `.exe` and `.zip` are larger than that, so they are published as GitHub Release assets instead of being committed to the repository.

## Current Caveat

The Windows build is not code-signed. Windows may show a first-run warning.
