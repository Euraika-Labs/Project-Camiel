# Phase 1: 3D Foundation & Archive - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-11
**Phase:** 01-3d-foundation-archive
**Areas discussed:** Project direction (during the superseded 2D phase 1), Engine choice, Renderer choice, Camera & controls, Proving "no errors"

---

## Project direction (superseded 2D Phase 1: Playable Intro Path)

The discussion started on the original 2D phase 1. The user selected Win screen & replay, About button, and Proving "no errors", and added: "the game should be also in 3D".

### Where should the 3D game go?

| Option | Description | Selected |
|--------|-------------|----------|
| Separate later milestone (Recommended) | Stabilize 2D and ship v0.0.4 features first; 3D as its own milestone | |
| New phase in this milestone | Add a 3D phase later in the roadmap; phase 1 stays 2D | |
| Switch to 3D now | 2D stabilization partly wasted, roadmap rebuilt, phase 1 paused | ✓ |

### Win screen after reaching the flag (kept for Phase 2)

| Option | Description | Selected |
|--------|-------------|----------|
| Two big buttons (Recommended) | "Nog een keer" and "Naar menu" with icons; tap, click, or Enter | ✓ |
| Replay only | One big tappable replay button | |
| Automatically to the menu | Show the result, return to the menu after a few seconds | |

### What kind of 3D?

| Option | Description | Selected |
|--------|-------------|----------|
| 3D look, side-scroll play (Recommended) | 3D visuals, movement locked to left/right and jump | |
| Full 3D world | Free movement in all directions with a following camera | ✓ |
| 2.5D: 3D world, 2D Camiel | 3D environment with the existing sprite as a billboard | |

### What happens to the 2D game?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep systems, rebuild visuals (Recommended) | Keep menus, audio, progress, CI; rebuild character and levels | |
| Fully replace | New 3D game from scratch; 2D code as reference only | ✓ |
| Keep both side by side | 2D stays playable next to the 3D build | |

### Source of the 3D Camiel model

| Option | Description | Selected |
|--------|-------------|----------|
| Simple shapes first | Gameplay with primitives; real model later | ✓ |
| Generate from existing art | AI image-to-3D from the 2D drawings | |
| Made or commissioned | Modelled in Blender by the user or an artist | |

### How to rework the plan

| Option | Description | Selected |
|--------|-------------|----------|
| Short 3D spike first (Recommended) | Small working test, then rebuild the roadmap | |
| Rebuild the roadmap now | Rework the phases immediately | ✓ |
| New milestone for 3D | Close this milestone and start a new one | |

**Notes:** The roadmap was rebuilt (commit `84e572b`) and the discussion restarted on the new Phase 1. For the new phase, the user selected Renderer choice, Camera & controls, and Proving "no errors", and asked: "is godot the correct engine?"

---

## Engine choice

### First question

| Option | Description | Selected |
|--------|-------------|----------|
| Stay with Godot 4.6.4 (Recommended) | Free and open source; CI and workflows stay usable | |
| Switch to Unity 6 | Richest 3D ecosystem; closed source, CI rebuilt | |
| Web-native (Three.js/Babylon.js) | Browser first; desktop needs a wrapper | |
| Research comparison first | Research agent compares current licenses and export quality | ✓ |

**Notes:** The research compared Godot, Unity 6, Unreal 5, and web-native. It recommended Godot 4.x with GDScript and the Compatibility renderer. It also found that Godot 4.6.4 does not exist; the orchestrator verified this against the GitHub API (4.6.3 and 4.7.2 exist).

### Decision after research

| Option | Description | Selected |
|--------|-------------|----------|
| Godot + GDScript (Recommended) | Lowest switching cost; MIT, no telemetry; iPad Web risk | ✓ |
| Web-native (Three.js/Babylon.js) | Only if the browser becomes the main platform | |
| Unity 6 | Richer 3D; telemetry audit, C# rewrite, CI licensing | |

### Version pin

| Option | Description | Selected |
|--------|-------------|----------|
| 4.7.2 (Recommended) | Newest stable; rebuild makes the jump cheap; check issue 122707 | ✓ |
| 4.6.3 | Latest 4.6 patch; upgrade later during the milestone | |

---

## Renderer choice

| Option | Description | Selected |
|--------|-------------|----------|
| Compatibility everywhere (Recommended) | One look on desktop, Web, and low-end tablets | ✓ |
| Forward+ desktop, Compatibility Web | Nicer desktop lighting; two looks to test | |
| Forward+ only for now | Best desktop graphics; forced switch at Phase 7 | |

---

## Camera & controls

### Camera

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed follow camera (Recommended) | High 3/4 view that never rotates | |
| Camera behind Camiel | Third-person, turns along behind Camiel | ✓ |
| Child rotates the camera | Mouse or extra keys control the camera | |

### Steering

| Option | Description | Selected |
|--------|-------------|----------|
| Camera swings along (Recommended) | Camera-relative movement; camera re-centres behind Camiel | |
| Turn and walk | Left/right turns, up walks forward | |
| You decide | Claude chooses based on a first test | ✓ |

### Level edges and falling

| Option | Description | Selected |
|--------|-------------|----------|
| Visible fence, no falling (Recommended) | Fences or hedges; Camiel cannot fall | |
| Invisible walls | Camiel stops at an invisible edge | |
| Gentle return after a fall | Camiel falls, reappears at the last safe spot with a soft sound | ✓ |

---

## Proving "no errors"

| Option | Description | Selected |
|--------|-------------|----------|
| Local + CI + short playtest (Recommended) | Local Godot install, one check script shared with CI, 5-minute playtest | ✓ |
| Local + CI, no playtest | Automated checks only | |
| CI only | No local install; every check runs in GitHub Actions | |

---

## Claude's Discretion

- Steering model: camera-relative movement with a lazily re-centring camera, confirmed or switched after the playtest.
- What stays from 2D (area not selected): keep the three audio files; remove all other 2D scenes, scripts, and art; drawings stay in the archive tag.
- Archive tag name: `archive/2d-alpha-v0.0.3`.
- Physics engine choice (Jolt or Godot Physics), script and folder names, camera tuning.

## Deferred Ideas

- Early Web export test on a real iPad before Phase 7 (iOS Safari is the largest Godot Web risk).
- Not discussed after the pivot: About button (the new Phase 2 menu requirements do not include one) and button text language (all child-facing text stays Dutch by project convention).
