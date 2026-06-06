# Project Camiel

[![CI](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/ci.yml/badge.svg)](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/ci.yml)
[![CodeQL](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/codeql.yml/badge.svg)](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/codeql.yml)

**Project Camiel** is a child-friendly educational game built with Godot 4, starring Camiel — a friendly Bernese Mountain Dog. Designed for children aged 3+.

## Features

### Alpha v0.0.1 — Core Game
- Playable intro scene with Camiel as a `CharacterBody2D`
- Idle, walk, run, jump, sit, and sleep animations
- Child-friendly level with color blocks
- Simple controls: arrows/WASD to move, Space/W/Up to jump

### Alpha v0.0.2 — Game Feel
- Main menu with large, accessible Start button
- Collectible stars with pickup feedback and HUD counter
- Finish marker with Dutch encouragement ("Goed zo!")
- Audio manager with BGM and SFX support

### Alpha v0.0.3 — Learning
- Three educational micro-tasks:
  - **Touch the red block** — color recognition
  - **Find blue** — visual discrimination
  - **Count 1, 2, 3** — number sense
- Lesson system with Dutch progress tracking ("Taken: N/3")
- Parent/teacher notes in `docs/parent-teacher-notes.md`
- Accessibility report and improvement notes

### Beta 1 Candidate — Trusted Testing
- Five-lesson learning pack with local progress tracking
- Adult-facing local progress view and reset control
- Mobile touch overlay for the intro scene
- Mute, reduced-motion, and high-contrast controls for adult setup

## Controls

| Action | Keys |
|--------|------|
| Walk | Left / Right arrows or A / D |
| Run | Hold Shift |
| Jump | Space, W, or Up arrow |
| Sit | S or Down arrow |
| Sleep | X |

## Quick Start

1. Install [Godot 4.6.3](https://godotengine.org)
2. Open the project: `File > Open Project > select project.godot`
3. Press Play (F5)

For first-time setup, see [docs/quick-start.md](docs/quick-start.md).

## Documentation

| Doc | What it covers |
|-----|---------------|
| `docs/roadmap.md` | Project roadmap and release history |
| `docs/parent-teacher-notes.md` | How parents/teachers use the game |
| `docs/accessibility-report.md` | WCAG 2.1 AA audit and compliance |
| `docs/build-and-release.md` | CI/CD pipeline and export process |
| `docs/quick-start.md` | 5-minute setup guide |

## Building

```bash
# Run quality gate
python3 scripts/tools/quality_gate.py --root .

# Run Godot verification
godot --headless --path . --script res://scripts/tools/verify_camiel_resources.gd
godot --headless --path . --script res://scripts/tools/verify_beta1_flow.gd

# Export macOS build
godot --headless --path . --export-release "macOS" dist/macos/Camiel.zip
```

The GitHub Wiki contains the broader product context, safety principles, character bible, and long-term architecture notes:

https://github.com/Euraika-Labs/Project-Camiel/wiki

## Community And Security

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). All contributors must follow the community code of conduct.

## License

MIT / GPL — see [LICENSE](LICENSE).
