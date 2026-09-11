# Phase 1: 3D Foundation & Archive - Research

**Researched:** 2026-09-11
**Domain:** Godot 4.7.2 / GDScript — 2D-to-3D project migration, git archival, headless CI verification
**Confidence:** MEDIUM (engine mechanics are well documented; several exact literal values could not be confirmed against a running Godot install because Godot is not installed on this machine — see Environment Availability and Assumptions Log)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Build the 3D game with Godot and GDScript only; no C# anywhere, because C# projects cannot be exported to the Web (Phase 7). — **Reversibility:** one-way.
- **D-02:** Pin Godot **4.7.2** (`4.7.2-stable`, released 2026-08-18). Godot 4.6.4 does not exist. In this phase, set 4.7.2 in `project.godot`, the local install, and every CI step this phase touches (`ci.yml`, and `release.yml` where it runs the resource verifier). Aligning `export.yml`, release notes, and the version string source stays in Phase 4. — **Reversibility:** costly.
- **D-03:** Godot issue 122707 reports headless runs stalling on 4.7.1 (closed as archived/not planned, not fixed). The headless check in this phase must use a timeout. If 4.7.2 stalls in headless runs, stop and raise it with the user before changing the version pin.
- **D-04:** Use the **Compatibility** renderer on every platform (desktop, Web, low-end devices), so there is one look and one visual test pass. Remove Forward Plus from `project.godot`. — **Reversibility:** costly.
- **D-05:** Third-person camera **behind Camiel** that follows him and turns along behind him. The child never controls the camera directly (no mouse-look, no camera keys).
- **D-06:** Camiel **can fall** off the edge of a level. After a fall he reappears at the last safe spot with a soft sound. No penalty, no failure screen, no lost progress. The Phase 1 test space has at least one edge, so this rule is built and tested here.
- **D-07:** Movement input in this phase is keyboard only: arrow keys and WASD to move, Space to jump. Define these as InputMap actions in `project.godot` (no raw `Input.is_key_pressed` polling), so touch controls in Phase 6 can map onto the same actions.
- **D-08:** The user approved installing Godot 4.7.2 on this Mac (official macOS build from `godotengine/godot-builds` release `4.7.2-stable`). Godot is not installed today.
- **D-09:** One project check, runnable locally before every commit and in CI: (1) import the project headless; (2) run the main scene headless with a timeout, capturing stdout/stderr; (3) fail on any `SCRIPT ERROR`, `Parse Error`, or `ERROR:` line; (4) run a `--script` verifier that loads every `.gd` and loads+instantiates every `.tscn`, calling `quit(1)` on any failure. Runtime script errors do not change Godot's exit code on their own, which is why the log scan is required.
- **D-10:** In this phase the check replaces the 2D-specific CI steps: `scripts/tools/verify_camiel_resources.gd` (`ci.yml` line 110, `release.yml` line 72) and the `--quit-after 2` smoke test (`ci.yml` line 115). CI stays green after the 2D content is removed. Broader pipeline work (Linux tar path, duplicate release race, single version source) remains Phase 4.
- **D-11:** Phase 1 closes only after a short manual playtest by the user (~5 min): walk in all directions, jump, fall off an edge and return, judge the camera. The steering model is confirmed or switched based on this playtest.
- **D-12:** Create the archive tag before removing anything. The removal task needs an explicit user confirmation checkpoint (FOUND-02); do not remove 2D content without it. — **Reversibility:** costly.

### Claude's Discretion

- **Steering model:** start with camera-relative movement (up/W moves away from the camera) and a camera that lazily swings back behind Camiel. If the playtest (D-11) shows this confuses young children, switch to turn-and-walk controls (left/right turns Camiel, up walks forward) with the camera fixed behind him.
- **What stays from 2D:**
  - Keep `assets/audio/bgm_ambient.ogg`, `assets/audio/sfx_collect.ogg`, `assets/audio/sfx_finish.ogg` and their `.import` files.
  - Remove all other 2D scenes, scripts, and art, including `assets/camiel/`, `assets/dogs/`, `assets/dogs_side/`, `assets/collectibles/`, and the 2D tool scripts.
  - The 2D Camiel drawings stay retrievable from the archive tag for the later MODEL-01 decision.
  - Keep repository tooling: `scripts/tools/quality_gate.py` and `tests/test_quality_gate.py`.
- **Archive tag name:** `archive/2d-alpha-v0.0.3`.
- **Physics engine:** `project.godot` has no physics setting. Pick Jolt or Godot Physics for 3D, set it explicitly in `project.godot`, and record the choice in the plan.
- **Script and folder names** for the check (e.g. a shell wrapper plus a GDScript verifier under `scripts/tools/`) and for the 3D baseline folders, within `.planning/codebase/CONVENTIONS.md`.
- **Camera tuning:** distance, height, swing speed, and collision handling.

### Deferred Ideas (OUT OF SCOPE)

- Test the Web export on a real iPad early, before Phase 7 (single-threaded export, Web Audio sample mode). iOS Safari is the largest Godot Web risk (Godot issue 116750). To be scheduled when planning the Phase 7 approach or as an inserted spike.
- The win screen decision (two big buttons, "Nog een keer" and "Naar menu") is recorded in `.planning/PROJECT.md` Key Decisions and applies to Phase 2.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-01 | Archive the pre-pivot 2D game under a dedicated git tag before any 2D runtime content is removed | See "Archive & Git Tagging" pattern below; current repo state (tags, HEAD, clean tree) verified this session |
| FOUND-02 | Remove 2D gameplay scenes/scripts/assets once the archive tag exists and the user has confirmed removal | See "Runtime State Inventory" — exact 2D files enumerated from this session's repo listing; `[VERIFIED]` list of what breaks on removal |
| FOUND-03 | Decide and consistently set the renderer (Forward Plus vs Compatibility) — **already decided: Compatibility (D-04)** | See "Renderer" implementation notes — exact `project.godot` keys |
| FOUND-04 | `Node3D`-based scene/script/asset folder structure baseline on Godot 4.7.2 | See "Recommended Project Structure" and "config/features" notes |
| FOUND-05 | Primitive-shape Camiel (capsule) moves freely in 3D test space with a following camera | See "CharacterBody3D + SpringArm3D" pattern, "Don't Hand-Roll" (physics/camera), Code Examples |
| FOUND-06 | Local headless run surfaces GDScript parse/runtime errors before commit | See "Headless Verification" — exact CLI flags confirmed against official docs, `--quit-after` import caveat, issue 122707 stall risk and mitigation |
</phase_requirements>

## Summary

Phase 1 is a migration + baseline phase, not a features phase: retag and remove the 2D game, flip two project-wide settings (engine version, renderer), stand up a minimal `Node3D` scene with a capsule `CharacterBody3D` and a `SpringArm3D`-based follow camera, and replace the 2D-era CI verification steps with a headless check that actually fails on script errors (unlike the current `--quit-after 2` smoke test, which exits 0 regardless of script errors — confirmed by reading `.github/workflows/ci.yml` this session).

All headline decisions (engine version, renderer, camera model, input scheme, archive tag name, what 2D content survives) are already locked in `01-CONTEXT.md`; this research focuses on the Godot 4.7.2 mechanics needed to implement them correctly: the exact `project.godot` keys for renderer and physics engine, the documented headless CLI flags and their known rough edges (an import-on-`--quit-after-1` bug and the 122707 stall issue), the standard `SpringArm3D` third-person camera pattern, and the concrete list of files/paths in *this* repository that FOUND-02's removal step must touch.

**Primary recommendation:** Do the archive tag and removal exactly as sequenced in D-12 (tag → confirm → remove), set `rendering/renderer/rendering_method="gl_compatibility"` and `physics/3d/physics_engine="JoltPhysics3D"` explicitly in `project.godot`, build the follow camera as `CharacterBody3D → (movement-relative rig) → SpringArm3D → Camera3D` with the spring arm's default shape used for wall-collision, and implement the headless check as a shell wrapper that runs the editor-import step, then the main scene with `--quit-after` and a hard OS-level `timeout`, greps stdout+stderr for `SCRIPT ERROR|Parse Error|ERROR:`, and finally runs a `--script` GDScript verifier (same `extends SceneTree` / `push_error` / `quit(1)` shape as the current `verify_camiel_resources.gd`) that loads and instantiates every `.tscn` under `res://scenes/`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 2D game archival (git tag) | Version control / repo tooling | — | Git-level operation, outside the Godot runtime entirely |
| 2D content removal | Filesystem / repo tooling | Godot project settings | Files deleted on disk; `project.godot` (`run/main_scene`, `[autoload]`) must be updated in the same pass or the project fails to boot |
| Renderer selection | Godot project settings | — | `project.godot` `[rendering]` section is the single source of truth; affects every scene at runtime, not a per-scene concern |
| Physics engine selection | Godot project settings | — | `project.godot` `[physics]` section; engine-level, not per-node |
| 3D folder/scene baseline | Godot scene tree (`Node3D`) | Filesystem (`scenes/`, `scripts/`, `assets/`) | The scene tree is the runtime structure; the folder layout is the on-disk mirror the CONVENTIONS.md naming rules already assume |
| Camiel movement | GDScript on `CharacterBody3D` (physics tier) | InputMap (project settings) | Physics-driven movement belongs on the character body's `_physics_process`; input mapping is declarative config, not code |
| Camera follow | GDScript/node config on a camera rig (`SpringArm3D`) | — | Godot's built-in node handles collision-aware follow; no custom camera-tier code needed for the base case |
| Fall-and-reappear (D-06) | GDScript on a boundary trigger (`Area3D`) + Camiel controller | Audio playback | Detection is a trigger-tier concern; the reset and sound are consequences applied to the character controller |
| Headless verification | CI/local tooling (shell + `--script` GDScript) | Godot CLI (`--headless`) | Verification is a repo-tooling concern layered over the engine's CLI, mirroring the existing `scripts/tools/` pattern |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.7.2-stable | Game engine, GDScript runtime, editor, CLI/headless tooling | Locked by D-02; `[VERIFIED: github.com/godotengine/godot-builds/releases/tag/4.7.2-stable]` release exists, published 2026-08-18, 57 bug fixes across 39 contributors `[CITED: godotengine.org/article/maintenance-release-godot-4-7-2/]` |
| GDScript | (bundled with 4.7.2) | All product and tooling scripts | Locked by D-01 (no C#, Web export requirement) |
| Jolt Physics (`JoltPhysics3D`) | bundled engine module, no separate install | 3D rigid body / character physics | `[CITED: docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html]` — built into Godot core since 4.4 as a module (not an addon); Godot 4.6+ uses it as the default for **new** projects. This project's `project.godot` has no `[physics]` section yet (`[VERIFIED: project.godot:1-56]` — full file read this session, no `physics/3d/physics_engine` key present), so nothing currently overrides the engine default; the phase should still set the key **explicitly** per the Claude's-Discretion instruction, not rely on the implicit default. |

No third-party packages (npm/pip/cargo-style dependencies) are installed by this phase — Godot is a single engine binary, not a package-manager dependency. The Package Legitimacy Gate is therefore not applicable; see the dedicated note below.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `SpringArm3D` (built-in node) | bundled | Collision-aware camera arm | Standard node for any third-person follow camera; avoids hand-rolling camera-vs-wall raycasts |
| `CharacterBody3D` (built-in node) | bundled | Player physics body with `move_and_slide()` | Standard node for kinematic player movement in Godot 4 |
| `Area3D` (built-in node) | bundled | Fall-boundary / "off the edge" trigger for D-06 | Standard node for trigger volumes; no physics response needed, only a signal |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Jolt Physics (`JoltPhysics3D`) | Godot Physics (`GodotPhysics3D`) | Godot Physics is the older, fully-stable built-in; Jolt is faster and multi-core friendly but documented as still experimental and "may change in future releases," and "lacks some features of Godot Physics so isn't a full drop-in replacement" `[CITED: docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html]`. For a simple capsule walking on a flat-ish test space with one edge, either works; Jolt is recommended because it is already the new-project default direction in 4.6+ and this project has no legacy 3D physics behavior to preserve. |
| `--quit-after` + log-grep for the main-scene smoke test | A dedicated GUT/GdUnit4 test suite | Out of scope for Phase 1 (no test framework is installed in this repo yet); D-09 explicitly specifies the lighter log-scan + verifier-script approach, which matches the existing `verify_camiel_resources.gd` pattern this repo already uses. |
| Camera-relative movement + lazy-follow camera | Turn-and-walk controls with a camera rigidly fixed behind Camiel | Both are already scoped in CONTEXT.md — camera-relative is the starting point (Claude's Discretion), turn-and-walk is the documented fallback if the D-11 playtest shows the first is confusing for a 3-year-old. |

**Installation:**
```bash
# No package manager install. Godot itself is a downloaded binary (D-08):
# macOS official build from godotengine/godot-builds, tag 4.7.2-stable.
# Typical post-install path on this Mac (per CONTEXT.md "Specifics"):
#   /Applications/Godot.app/Contents/MacOS/Godot
```

**Version verification:** `godot --version` is not runnable in this research session — **Godot is not installed on this machine** (`which godot` returned nothing this session; `[VERIFIED: command run this session — 'godot not found']`). The release itself was confirmed to exist via the GitHub releases page `[VERIFIED: github.com/godotengine/godot-builds/releases/tag/4.7.2-stable]`. Verifying the actual installed binary reports `4.7.2.stable` is a task for the plan (D-08's install step), not something this research could confirm.

## Package Legitimacy Audit

Not applicable. This phase installs no npm/pip/cargo packages — only the Godot 4.7.2 engine binary (a direct download of an official release artifact, not a package-registry dependency) and uses only Godot's own built-in nodes/modules (`CharacterBody3D`, `SpringArm3D`, `Area3D`, Jolt Physics). No `package-legitimacy check` run was needed or possible against an ecosystem registry (npm/PyPI/crates) because none of those ecosystems are involved in this phase.

**Packages removed due to [SLOP] verdict:** none (n/a)
**Packages flagged as suspicious [SUS]:** none (n/a)

## Architecture Patterns

### System Architecture Diagram

```
 ┌─────────────────────────────────────────────────────────────────┐
 │ Git repository (version control tier)                             │
 │                                                                     │
 │  HEAD (19ebc6b) ──tag──▶ archive/2d-alpha-v0.0.3 [FOUND-01]        │
 │       │                                                             │
 │       │ (after user confirms removal — checkpoint)                 │
 │       ▼                                                             │
 │  2D scenes/scripts/art deleted from working tree [FOUND-02]        │
 │  audio assets + quality_gate.py + test_quality_gate.py kept        │
 └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ Godot project settings tier (project.godot)                       │
 │                                                                     │
 │  [application] config/features = ("4.7", ...)         [FOUND-04]   │
 │  [application] run/main_scene  = res://scenes/.../test_space.tscn  │
 │  [rendering]   renderer/rendering_method = "gl_compatibility" [F-03]│
 │  [physics]     physics/3d/physics_engine = "JoltPhysics3D"         │
 │  [input]       move_forward/back/left/right, jump (InputMap) [D-07]│
 │  [autoload]    2D-era AudioManager/Accessibility/ProgressTracker   │
 │                removed or replaced                                  │
 └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ Runtime scene tree (Node3D baseline)                       [FOUND-05]
 │                                                                     │
 │   TestSpace (Node3D)                                               │
 │    ├── Floor (StaticBody3D + CollisionShape3D)  — has an edge      │
 │    ├── FallBoundary (Area3D) ──body_entered──▶ reset Camiel  [D-06]│
 │    ├── Camiel (CharacterBody3D, CapsuleMesh + CapsuleShape3D)      │
 │    │      ├── _physics_process(): reads InputMap actions,          │
 │    │      │     applies move_and_slide()                            │
 │    │      └── (child) CameraRig (Node3D, yaw-follows Camiel)       │
 │    │             └── SpringArm3D (length, collision shape)         │
 │    │                    └── Camera3D               [D-05, no mouse-look]
 │    └── DirectionalLight3D / WorldEnvironment (visibility baseline)  │
 └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ Headless verification tier (local + CI)                    [FOUND-06]
 │                                                                     │
 │  1. godot --headless --editor --path . --quit   (import)           │
 │  2. timeout N godot --headless --path . --quit-after M             │
 │       stdout+stderr ──grep──▶ SCRIPT ERROR|Parse Error|ERROR:      │
 │       any match ──▶ fail                                            │
 │  3. godot --headless --path . --script res://scripts/tools/<verify>.gd
 │       loads+instantiates every scenes/**/*.tscn, quit(1) on fail   │
 └─────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

The repo already follows the conventions in `.planning/codebase/CONVENTIONS.md` (snake_case files, scenes mirrored by scripts, tool scripts under `scripts/tools/`). Extend it rather than inventing a parallel structure:

```
scenes/
├── camiel.tscn              # CharacterBody3D root (capsule), replaces the deleted 2D camiel.tscn
├── test_space.tscn          # Node3D root — Phase 1's "small 3D test space" (FOUND-05); becomes obsolete once Phase 2 builds the real intro level
└── ui/                      # untouched by Phase 1 (2D UI scenes here are removed per FOUND-02 discretion list; keep the folder only if a 3D scene needs it)

scripts/
├── camiel_controller.gd     # CharacterBody3D movement (_physics_process, InputMap reads)
├── camera_rig.gd            # optional — only needed if yaw-follow logic can't be done with pure node config
└── tools/
    ├── quality_gate.py      # kept unchanged (Claude's Discretion)
    ├── run_headless_check.sh    # new: shell wrapper (import + timeout + grep), naming at Claude's discretion
    └── verify_3d_project.gd     # new: --script verifier, verb_noun.gd naming per CONVENTIONS.md, extends SceneTree

assets/
└── audio/                   # bgm_ambient.ogg, sfx_collect.ogg, sfx_finish.ogg + .import (kept, Claude's Discretion)
```

Exact folder/file names for the 3D baseline and the check scripts are explicitly left to Claude's discretion in CONTEXT.md; the structure above follows the existing naming conventions (`verb_noun.gd` for tool scripts, scene/script name pairing) rather than prescribing new ones.

### Pattern 1: CharacterBody3D + SpringArm3D third-person follow camera

**What:** A `SpringArm3D` node positioned as a child of a yaw-only rig attached to (or above) the player, with a `Camera3D` as its only child. The spring arm automatically shortens if the camera would clip through geometry — no manual raycasting needed.

**When to use:** Any third-person camera that must avoid clipping through walls/floors without hand-rolled collision code. Matches D-05 (camera behind Camiel, child never controls it directly).

**Example (official docs pattern, adapted — mouse-look lines removed per D-05 "no mouse-look"):**
```gdscript
# Source: https://docs.godotengine.org/en/stable/tutorials/3d/spring_arm.html
# Node hierarchy under Camiel (CharacterBody3D):
#   CameraPivot (Node3D)          <- rotated to follow Camiel's facing/movement direction
#     └── SpringArm3D             <- spring_length = 3 (approx), shape left <empty> to use
#            └── Camera3D            the camera's own frustum for auto collision shortening

# Movement-tier script on Camiel; camera-tier code stays separate:
@onready var _camera_pivot: Node3D = %CameraPivot

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# ... apply to velocity, move_and_slide() ...
	if direction.length() > 0.01:
		# lazily swing the camera pivot's yaw to follow movement direction (D-05: no direct control)
		var target_yaw := atan2(-direction.x, -direction.z)
		_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, target_yaw, delta * 3.0)
```

### Pattern 2: Headless "fail loudly" verifier script

**What:** A `--script`-run GDScript extending `SceneTree`, loading every relevant resource, calling `push_error()` + `quit(1)` on any failure, `print()` + `quit(0)` on success.

**When to use:** Exactly D-09/FOUND-06's requirement. This repository already has one working example to generalize from.

**Example (existing repo pattern, generalized for the 3D baseline — verified by reading the file this session):**
```gdscript
# Source: this repo, scripts/tools/verify_camiel_resources.gd (read in full this session)
# The 2D verifier's shape — extends SceneTree, EXPECTED-style checks, push_error + quit(1) + return,
# print + quit(0) at the end — is the pattern to reuse for the new project-wide verifier.
extends SceneTree

func _initialize() -> void:
	var dir := DirAccess.open("res://scenes")
	if dir == null:
		push_error("Could not open res://scenes")
		quit(1)
		return
	# ... walk scenes/**/*.tscn, load() each, instantiate(), queue_free() ...
	# any load() or instantiate() failure -> push_error(...) ; quit(1) ; return
	print("3D project scenes verified.")
	quit(0)
```

### Anti-Patterns to Avoid

- **Raw `Input.is_key_pressed(KEY_*)` polling:** the 2D codebase does this in `camiel_controller.gd`, `intro_scene.gd`, `finish_marker.gd`, `main_menu.gd` (documented in `.planning/codebase/CONCERNS.md`, confirmed this session). D-07 explicitly requires InputMap actions instead — don't repeat this in the 3D controller.
- **Trusting `--quit-after` exit code for correctness:** the current CI smoke test (`--quit-after 2`) exits 0 even when autoloads fail to parse (this is the exact bug behind D-09/D-10 replacing it) `[VERIFIED: .github/workflows/ci.yml — "Smoke test main scene" step, confirmed by reading the file this session]`.
- **Manual camera-vs-wall raycasting:** `SpringArm3D` already does this; hand-rolling it duplicates a solved problem (see Don't Hand-Roll).
- **Renaming/removing 2D content without updating `[autoload]` in `project.godot`:** the three 2D-era autoloads (`AudioManager`, `Accessibility`, `ProgressTracker`) point at scripts that FOUND-02 deletes; leaving the `[autoload]` entries in place after deletion makes the project fail to boot even headless (see Runtime State Inventory).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Camera-vs-geometry collision for the follow camera | Manual raycast from character to desired camera position, clamp distance | `SpringArm3D` (built-in) | Auto-shortens on collision; documented, zero-maintenance solution `[CITED: docs.godotengine.org/en/stable/tutorials/3d/spring_arm.html]` |
| Kinematic character movement + collision response | Custom AABB/capsule-vs-world sweep code | `CharacterBody3D.move_and_slide()` | Built-in, handles slopes/steps/sliding; this is the standard Godot 4 pattern for player controllers |
| "Did Camiel walk off the test space" detection | Per-frame Y-position threshold check in the controller script | `Area3D` trigger volume below/around the platform edge, `body_entered` signal | Matches the existing repo's established one-shot-trigger pattern (`_on_body_entered` + `is_in_group` + latch, documented in CONVENTIONS.md) rather than inventing a new detection mechanism |
| Detecting GDScript parse/runtime errors in CI | Parsing Godot's exit code alone | Godot's own log output (stdout+stderr) grepped for `SCRIPT ERROR`/`Parse Error`/`ERROR:`, combined with a `--script` loader that explicitly `quit(1)`s | D-09 documents that Godot's exit code does not reflect runtime script errors on its own — this is a known, confirmed engine limitation, not a guess to route around with custom exit-code logic |

**Key insight:** Godot 4's built-in 3D nodes (`CharacterBody3D`, `SpringArm3D`, `Area3D`) already solve every mechanical problem this phase needs (movement, camera collision, trigger detection). The only genuinely custom code this phase needs is the InputMap-driven movement script, the camera's lazy-yaw-follow behavior (a design choice, not a solved-elsewhere problem), and the headless verifier script (which follows an existing in-repo pattern rather than a library).

## Runtime State Inventory

**Trigger:** This phase removes the entire pre-pivot 2D game (FOUND-02) after archiving it (FOUND-01). This is exactly the rename/refactor/migration case requiring an explicit runtime-state audit.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None found. `[VERIFIED: project.godot:1-56, read in full this session]` — no `config/use_custom_user_dir` or other setting that would make the 2D game write to a shared/external datastore. The 2D `progress_tracker.gd` autoload never actually wrote progress (`[VERIFIED: .planning/codebase/CONCERNS.md — "The game never records progress" finding]`), so `user://progress.json` under `Camiel alpha-v0.0.3`'s app-data folder, if it exists on this machine from prior manual play, contains at most stale/no data — not a migration concern for this phase. | None — nothing to migrate. |
| Live service config | None. This is a local, offline single-player game with no external service integrations (no n8n, no Datadog, no Cloudflare Tunnel, no cloud config referenced anywhere in `project.godot`, `.github/workflows/*.yml`, or `docs/*`). | None. |
| OS-registered state | None found for the *2D game itself*. Godot's own installation (D-08) will register in `/Applications/Godot.app` — that is an addition this phase makes, not a rename to clean up. No Task Scheduler / launchd / pm2 entries reference this project (`[VERIFIED: no such files found in the repo; this is a game project, not a service]`). | None for 2D removal. New: document the Godot install path once installed (D-08). |
| Secrets/env vars | None. No `.env`, SOPS keys, or CI secret names reference "2D" or any name that changes in this phase. `GH_TOKEN`/`github.token` in `release.yml` is unrelated to the pivot. | None. |
| Build artifacts / installed packages | `export_presets.cfg` export paths point at `builds/alpha-v0.0.3/...` (`[VERIFIED: export_presets.cfg, read in full this session]`) — these are **not** committed build outputs (`builds/` is gitignored, confirmed via `.gitignore` read this session), so there is nothing on disk to clean up from prior exports in this repo checkout. The `export_presets.cfg` file itself must still parse after 2D removal (per CONTEXT.md canonical refs) but its content is explicitly out of scope for Phase 1 (Phase 4/7 own it). `scripts/tools/__pycache__/quality_gate.cpython-314.pyc` is a stale Python bytecode cache (gitignored via `__pycache__/`), unrelated to the 2D/3D pivot and safe to ignore. | None required by FOUND-02; note `export_presets.cfg` must remain parseable (no action, just don't break it). |

**Files/settings FOUND-02 removal must touch (enumerated this session, `[VERIFIED: repository listing + project.godot read this session]`):**

- **Delete:** `scenes/blue_target.tscn`, `camiel.tscn`, `collectible.tscn`, `count_challenge.tscn`, `finish_marker.tscn`, `lesson_1.tscn`…`lesson_5.tscn`, `main.tscn`, `main_menu.tscn`, `red_block.tscn`, `sequence_target.tscn`, `shape_target.tscn`, `title_screen.tscn`, and everything under `scenes/ui/` (per CONTEXT.md discretion — 2D UI); all of `scripts/*.gd` except the tool scripts kept below; `assets/camiel/`, `assets/dogs/`, `assets/dogs_side/`, `assets/collectibles/`.
- **Keep:** `assets/audio/bgm_ambient.ogg`, `sfx_collect.ogg`, `sfx_finish.ogg` + their `.import` siblings (`[VERIFIED: assets/audio/ directory listing this session — all three .ogg and matching .ogg.import files present]`); `scripts/tools/quality_gate.py`, `tests/test_quality_gate.py`.
- **Must edit, not just delete-around:** `project.godot` — `run/main_scene` currently points at `res://scenes/title_screen.tscn` (deleted) and must point at the new 3D test scene; `[autoload]` currently registers `AudioManager`, `Accessibility`, `ProgressTracker` (all deleted under the "remove all other 2D scenes/scripts" rule) — these entries must be removed or the project will error at every startup, including headless (this directly threatens FOUND-06's "no script errors" check).
- **Must remain parseable but is Phase 4/7 scope, not edited here beyond "don't break":** `export_presets.cfg`, `.github/workflows/export.yml`.
- **CI files this phase does touch (per D-02/D-10):** `.github/workflows/ci.yml` (Godot version bump to 4.7.2, replace the resource-verifier + smoke-test steps), `.github/workflows/release.yml` (Godot version bump, replace the resource-verifier step it also runs).

## Common Pitfalls

### Pitfall 1: Headless exit code does not reflect script errors

**What goes wrong:** A CI/local check that only inspects Godot's process exit code passes even when autoloads fail to parse or scripts throw runtime errors.
**Why it happens:** Godot's `--quit-after N` smoke test exits 0 regardless of script errors that occurred during those N frames — this is the exact, already-observed behavior of this repo's current CI step, which passes green despite a confirmed parse error in `progress_tracker.gd` (`JSON.SINDY_USE_HELPER` is not a real constant) `[VERIFIED: .planning/codebase/CONCERNS.md "Known Bugs" — Parse error finding, cross-referenced against .github/workflows/ci.yml read this session]`.
**How to avoid:** D-09's design — grep stdout+stderr for `SCRIPT ERROR|Parse Error|ERROR:` in addition to checking the exit code, and use a `--script` verifier that explicitly `quit(1)`s on failure rather than relying on the engine's own natural exit code.
**Warning signs:** A CI step that only checks `$?` after a headless run with no log inspection.

### Pitfall 2: Headless mode can stall indefinitely on 4.7.1 (issue 122707)

**What goes wrong:** A headless run with any scene loaded as the main scene can stall ~25-55 seconds in with the main thread still "active" (busy-wait, not a clean hang), making a naive CI step time out unpredictably or hang the runner.
**Why it happens:** Confirmed open-source issue against Godot 4.7.1 on Windows and Linux; root cause not identified by the reporter, closed by maintainers as "not planned" rather than fixed `[VERIFIED: github.com/godotengine/godot/issues/122707 — fetched and read this session; status "closed as not planned"]`. Whether 4.7.2 (a maintenance release with 57 bug fixes) resolves this specific issue was **not confirmed** — the 4.7.2 release notes reviewed this session did not mention issue 122707 by number `[ASSUMED: absence of a changelog mention is not proof the issue is fixed or unfixed — D-03's stop-and-raise-with-user instruction is the correct response, not an assumption that 4.7.2 is safe]`.
**How to avoid:** Per D-03, wrap every headless invocation in an OS-level `timeout` (not just `--quit-after`, which only bounds frame count, not wall-clock hangs). The issue reporter found two mitigations worth carrying into the plan: (1) a custom `--script` that does not load any `.tscn` runs indefinitely without stalling, and (2) `--disable-render-loop` avoids the stall in their repro `[CITED: github.com/godotengine/godot/issues/122707]`. Since D-09's verifier script *does* need to load `.tscn` files, the `timeout` wrapper is the primary defense; `--disable-render-loop` is a candidate flag to add to the headless commands if a stall is observed.
**Warning signs:** A headless CI step that hangs past its expected duration rather than failing fast.

### Pitfall 3: `--quit`/`--quit-after 1` can skip resource import on first run

**What goes wrong:** In some Godot 4 versions, running headless with `--quit` or `--quit-after 1` immediately after a fresh checkout (no `.godot/` cache yet) fails to fully import resources, while `--quit-after 2` (or a separate `--editor --quit` import pass first) works.
**Why it happens:** Documented, reproduced community issue `[CITED: github.com/godotengine/godot/issues/77508]`; a related issue (`#83449`) reports exit code 1 on first headless import even with no visible errors.
**How to avoid:** Follow D-09's ordering exactly — a dedicated import pass (`--headless --editor --path . --quit`) *before* the main-scene run, matching what `ci.yml`'s existing "Import project" step already does `[VERIFIED: .github/workflows/ci.yml, read this session]`. Don't collapse the import and verification passes into a single invocation.
**Warning signs:** Resources failing to load only on a clean checkout / clean CI runner, but working locally where `.godot/` is already cached.

### Pitfall 4: Editing `project.godot` by hand risks silent corruption

**What goes wrong:** `project.godot`'s own header warns it is "best edited using the editor UI" (`[VERIFIED: project.godot:1-3]`) — hand-editing the `[rendering]`/`[physics]`/`[input]` sections risks subtly wrong types (e.g. a string where the format expects a typed literal) that the editor would normally catch.
**Why it happens:** The file format allows arbitrary text edits with no validation until Godot next loads it.
**How to avoid:** Prefer setting the renderer/physics engine through the actual Godot editor's Project Settings dialog once installed (D-08), then verify the resulting `project.godot` diff, rather than hand-typing the `[rendering]`/`[physics]` sections from research alone. If hand-editing is unavoidable before the editor is available, the FOUND-06 headless check (which does an editor-mode import pass) will catch a malformed file.
**Warning signs:** The headless "Import project" step failing right after a manual `project.godot` edit.

## Code Examples

### InputMap actions in `project.godot` (D-07)

```ini
# Source pattern: this repo's existing [input] section format, read this session
# (project.godot:23-38 — ui_focus_next/prev and mobile_jump already use this InputEventKey shape).
# New entries needed for D-07 (exact physical_keycode values must be captured from the editor,
# not hand-typed — see Pitfall 4). Structural shape shown; literal keycode integers are [ASSUMED]
# placeholders only, not verified against a running editor:
[input]

move_forward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":4194320,"keycode":0, ...), Object(InputEventKey,"physical_keycode":87, ...)]
}
# ...move_back / move_left / move_right (arrows + WASD) and "jump" (Space) follow the same shape.
```

**Note on this example:** the two existing actions (`ui_focus_next`, `ui_focus_prev`) and their exact `physical_keycode` integers (4194326, 4194325) were read directly from `project.godot` this session and are `[VERIFIED: project.godot:25-38]`. The new movement/jump action keycodes above are structural placeholders, not verified values — the plan should generate these through the Godot editor's Input Map UI (which writes the correct `InputEventKey` object literal) rather than hand-authoring the integers.

### Git archive tag (FOUND-01)

```bash
# Source: standard git tagging; the existing tag in this repo (alpha-v0.0.1) is lightweight
# ([VERIFIED: `git for-each-ref refs/tags` run this session — objecttype "commit", i.e. lightweight]).
# An annotated tag is recommended for the archive marker since it carries a message and date:
git tag -a archive/2d-alpha-v0.0.3 -m "Archive: pre-pivot 2D game state before 3D rebuild (FOUND-01)"
git push origin archive/2d-alpha-v0.0.3   # if/when pushing is part of the plan
```

Current repo state confirmed this session: `HEAD` is `19ebc6b` on branch `docs/codebase-map`, working tree clean, only existing tag is `alpha-v0.0.1` `[VERIFIED: git log -1, git status --short, git for-each-ref, run this session]`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `config/features=PackedStringArray("4.6", "Forward Plus")`, Godot Physics implicit default | `config/features` reflecting `4.7` + explicit `rendering/renderer/rendering_method` and `physics/3d/physics_engine` keys | This phase (D-02, D-04, discretion) | Every future 3D visual/physics decision inherits these two settings; Phase 4/7 build on top rather than re-deciding |
| `Input.is_key_pressed(KEY_*)` raw polling (documented in this repo's 2D code) | `Input.get_vector()` / `Input.is_action_pressed()` against InputMap actions | This phase (D-07) | Enables Phase 6's touch controls to map onto the same actions without touching the movement script |
| Godot Physics as the only 3D physics engine (pre-4.4) | Jolt Physics built into the engine core, default for new projects since 4.6 | Godot 4.4 (Jolt added as a module) → 4.6 (became new-project default) `[CITED: gamefromscratch.com/godot-4-4-gets-native-jolt-physics-support/; docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html]` | This project predates the 3D pivot entirely (was 2D, no physics engine setting existed) — there is no legacy 3D physics behavior to preserve, so adopting Jolt has no migration cost here |
| CI smoke test (`--quit-after 2`, exit-code-only) | Log-scanning + `--script` verifier (D-09) | This phase | Directly fixes the confirmed gap where the current CI passes despite a real parse error in the 2D codebase |

**Deprecated/outdated:**
- `"HTML5"` as a Godot export platform identifier is the Godot 3 name; Godot 4 calls it `"Web"` — noted in `.planning/codebase/CONCERNS.md` as a likely-broken preset in this repo's `export_presets.cfg`. Not this phase's concern (WEB-01, Phase 7) but relevant context: the Web export work later in this project inherits whatever renderer this phase locks in (D-04 already anticipates this by choosing Compatibility on every platform).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The literal `project.godot` values `physics/3d/physics_engine="JoltPhysics3D"` / `"GodotPhysics3D"` / `"DEFAULT"` are the exact enum strings Godot writes/reads (synthesized from WebSearch results, not confirmed by opening a running editor's generated file) | Standard Stack, Code Examples | Low — if the literal string differs, the headless import/verify step (FOUND-06) will surface a project-settings parse problem immediately, and the fix is a one-line correction once Godot is installed (D-08) |
| A2 | `config/features` for a Compatibility-renderer project writes the literal string `"Compatibility"` (matching this repo's existing `"Forward Plus"` pattern) rather than `"GL Compatibility"` (an internal engine string seen in some WebSearch results) | Architecture Patterns (System Diagram) | Low — this is a cosmetic project-metadata string with no functional effect; the actual renderer behavior is controlled by `rendering/renderer/rendering_method`, which was confirmed via search across multiple independent sources |
| A3 | Godot 4.7.2 does or does not still exhibit the headless stall from issue 122707 (the issue was filed against 4.7.1; its closure as "not planned" and the 4.7.2 changelog reviewed this session neither confirm nor deny a fix) | Common Pitfalls (Pitfall 2), User Constraints D-03 | Medium — this is exactly why D-03 requires a timeout-wrapped headless check and a "stop and ask the user" trigger rather than assuming safety; the plan must not skip the timeout wrapper on the assumption 4.7.2 is fixed |
| A4 | The macOS post-install binary path is `/Applications/Godot.app/Contents/MacOS/Godot` (carried from CONTEXT.md "Specifics," not independently re-verified this session since Godot is not installed) | Standard Stack (Installation) | Low — standard macOS `.app` bundle convention; easy to confirm once D-08's install step runs |

**If this table is empty:** N/A — see entries above.

## Open Questions

1. **Does Godot 4.7.2 fix the headless stall (issue 122707)?**
   - What we know: filed and reproduced against 4.7.1; closed by maintainers as "not planned" (not "fixed"); the 4.7.2 changelog reviewed this session lists 57 bug fixes but did not surface a reference to this issue number.
   - What's unclear: whether any of those 57 fixes incidentally resolve the underlying busy-wait, or whether it's still present.
   - Recommendation: D-03 already covers this — build the headless check with a hard `timeout` from the start (don't add it reactively), and if a stall is observed during Phase 1 execution, stop and raise it with the user per D-03 rather than silently increasing the timeout or downgrading the engine version.

2. **Exact `InputEventKey` literals for the new movement/jump InputMap actions.**
   - What we know: the structural shape (from this repo's existing `ui_focus_next`/`ui_focus_prev`/`mobile_jump` entries, read this session) and which physical keys are required (arrows, WASD, Space — D-07).
   - What's unclear: the precise `physical_keycode` integers Godot's editor would generate for each key on this machine/keyboard layout.
   - Recommendation: generate these through the Godot editor's Input Map UI once Godot is installed, rather than hand-typing keycode integers — this avoids Pitfall 4 (silent `project.godot` corruption).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Godot Engine 4.7.2 (local) | Running/testing the project, all of FOUND-04/05/06, D-09's local headless check | ✗ | — | D-08: user has approved installing the official macOS build from `godotengine/godot-builds` release `4.7.2-stable`; this is a plan task, not a blocker research could resolve |
| `git` | FOUND-01 (archive tag), FOUND-02 (removal commit) | ✓ | (repo is an active git working tree; tags/log/status commands ran successfully this session) | — |
| GitHub Actions runner (`ubuntu-latest`) with Godot download step | D-10 (CI replacement of 2D-specific steps) | ✓ (existing `.github/workflows/ci.yml` pattern already downloads Godot per-job) | Currently pins 4.6.2 in this repo; must be bumped to 4.7.2 per D-02 | — |

**Missing dependencies with no fallback:**
- Godot 4.7.2 itself is not installed locally. There is no fallback for FOUND-05/FOUND-06 verification without it — D-08's install step must happen before those success criteria can be checked locally. (CI can still verify headlessly once `ci.yml` is updated, independent of the local install.)

**Missing dependencies with fallback:**
- None beyond the above — the local Godot install has no substitute for this project (it's the engine, not a swappable library).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None for GDScript (no GUT/GdUnit4 installed — confirmed absent from `scripts/`, `addons/` is not present in the repo listing this session). Python side: stdlib `unittest`, used by `tests/test_quality_gate.py`, run via `python3 -m unittest tests.test_quality_gate` in CI `[VERIFIED: .github/workflows/ci.yml, read this session]`. |
| Config file | none for GDScript — see Wave 0 |
| Quick run command | `timeout 60 /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/<verify>.gd` (exact script name at Claude's discretion) |
| Full suite command | Local headless check (import + timed main-scene run + log grep + verifier script) — this **is** the full suite for Phase 1; there is no separate GDScript unit-test layer yet |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-01 | Archive tag exists at the correct commit before removal | smoke (git) | `git tag -l archive/2d-alpha-v0.0.3 && git rev-parse archive/2d-alpha-v0.0.3` | ✅ Wave 0 (plain git, no new file needed) |
| FOUND-02 | No dangling `res://` references after removal; kept files intact | automated (existing tool) | `python3 scripts/tools/quality_gate.py --root .` | ✅ (tool already exists, `[VERIFIED: scripts/tools/quality_gate.py]`) |
| FOUND-03 | Renderer set consistently, Forward Plus removed | automated (grep) | `grep -q 'renderer/rendering_method="gl_compatibility"' project.godot && ! grep -q 'Forward Plus' project.godot` | ✅ Wave 0 (shell one-liner, no new file needed) |
| FOUND-04 | `Node3D` baseline exists, engine pinned to 4.7.2 | automated (headless import) | `godot --headless --editor --path . --quit` (exit 0, no import errors in log) | ❌ Wave 0 — needs Godot installed (D-08) |
| FOUND-05 | Capsule Camiel moves freely, camera follows | manual-only (playtest, D-11) | N/A — this requirement is explicitly closed by a human playtest per D-11, not an automated assertion of "feels right for a 3-year-old" | manual-only, justified: movement *feel* for a target user this young is not meaningfully automatable; D-11 already mandates the human check |
| FOUND-06 | Headless run surfaces parse/runtime errors | automated (new script) | `scripts/tools/run_headless_check.sh` (or equivalent name) — import pass, timed main-scene run with log grep, `--script` verifier | ❌ Wave 0 — new file, this is the deliverable itself |

### Sampling Rate

- **Per task commit:** `python3 scripts/tools/quality_gate.py --root .` (fast, no Godot needed) + the new headless check once Godot is installed locally
- **Per wave merge:** Full headless check (import + timed run + verifier script)
- **Phase gate:** Full headless check green, plus D-11's manual playtest, before the phase is considered done

### Wave 0 Gaps

- [ ] `scripts/tools/run_headless_check.sh` (or equivalent shell wrapper name) — covers FOUND-06's import + timeout + log-grep steps
- [ ] `scripts/tools/verify_3d_project.gd` (or equivalent name, `verb_noun.gd` per CONVENTIONS.md) — covers FOUND-06's `--script` loader/instantiator, generalizing the pattern already in `verify_camiel_resources.gd`
- [ ] Godot 4.7.2 local install (D-08) — blocks running any of the above until done
- [ ] No GDScript unit-test framework install needed for Phase 1 — D-09's log-scan + verifier approach is the explicitly specified validation mechanism; introducing GUT/GdUnit4 is out of scope here

## Security Domain

This is a local, offline, single-player, single-device children's game with no network calls, no authentication, and no user-supplied data beyond keyboard input read directly by the engine. `security_enforcement` is not explicitly disabled in project config (no `.planning/config.json` exists in this repo — confirmed this session), so per the default-enabled rule this section is included, with an honest assessment that almost nothing in the OWASP ASVS applies to a Phase 1 scope this narrow.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | No accounts, no auth in this game at all |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | Single local user, no roles |
| V5 Input Validation | Marginal | Keyboard input is read through Godot's InputMap/`Input` singleton, not parsed as untrusted text; no validation library needed. Becomes relevant later (Phase 3, `progress.json` parsing) but not in Phase 1. |
| V6 Cryptography | No | No secrets, no stored credentials, nothing encrypted in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Malformed/oversized `.tscn`/`.gd` files causing the headless verifier to hang or crash rather than fail cleanly | Denial of Service (local, low severity) | The `timeout`-wrapped headless check (D-09) already bounds worst-case runtime; no additional mitigation needed at this phase's scope |
| Supply-chain risk from the Godot binary itself | Tampering | D-08 specifies downloading the **official** `godotengine/godot-builds` release artifact by tag, not a third-party mirror — this is already the correct mitigation, just worth stating explicitly since Godot is being freshly installed in this phase |

Given the scope (a local capsule moving in a test box, no network, no persistence in this phase), there is no meaningful additional threat surface introduced by Phase 1's work beyond what's already covered by D-08's "official build" instruction.

## Sources

### Primary (HIGH confidence)
None fetched at HIGH confidence this session (no Context7 MCP tool was available in this environment — attempted and unavailable). All engine-behavior claims are MEDIUM (official docs via WebFetch/WebSearch) or LOW (WebSearch synthesis without a direct docs fetch); see per-claim tags throughout.

### Secondary (MEDIUM confidence — official docs, fetched or search-confirmed this session)
- https://docs.godotengine.org/en/stable/tutorials/3d/spring_arm.html — SpringArm3D third-person camera pattern (fetched)
- https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html — Jolt Physics project setting (fetched)
- https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html — `--headless`, `--quit-after`, `--script`, `--check-only`, `--path` flag definitions (fetched)
- https://github.com/godotengine/godot/issues/122707 — headless stall issue, status and workarounds (fetched)
- https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable — 4.7.2 release existence (search-confirmed)
- https://godotengine.org/article/maintenance-release-godot-4-7-2/ — 4.7.2 release notes summary (search-confirmed)

### Tertiary (LOW confidence — WebSearch synthesis only, flagged in Assumptions Log)
- `physics/3d/physics_engine` literal enum values (`DEFAULT`/`GodotPhysics3D`/`JoltPhysics3D`) — synthesized across several secondary blog/community sources, not confirmed via a direct primary-doc fetch or a running editor
- `config/features` string for the Compatibility renderer (`"Compatibility"` vs `"GL Compatibility"`) — conflicting signals between this repo's own existing pattern and general WebSearch results

### In-repo (verified by reading this session)
- `project.godot` (full file)
- `scripts/tools/verify_camiel_resources.gd` (full file)
- `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `export_presets.cfg` (full files, via Bash cat)
- `.planning/codebase/CONVENTIONS.md`, `.planning/codebase/CONCERNS.md` (full files)
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/01-3d-foundation-archive/01-CONTEXT.md` (full files)
- Repository file listing (`scenes/`, `scripts/`, `assets/`) and git state (`git tag`, `git log`, `git status`, `git for-each-ref`)

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — engine version and core node choices are well documented; a couple of literal `project.godot` string values are unconfirmed against a running install (Godot not installed on this machine)
- Architecture: HIGH — `SpringArm3D`/`CharacterBody3D`/`Area3D` patterns are official, stable Godot 4 docs, and the repo-specific structure is grounded in files read this session
- Pitfalls: HIGH — all four pitfalls are grounded in either this repo's own confirmed CI behavior or a fetched/read GitHub issue, not speculation

**Research date:** 2026-09-11
**Valid until:** 30 days (stable engine release; re-check if Godot 4.7.3+ ships before planning executes, and re-check issue 122707's status once Godot 4.7.2 is actually installed and can be tested directly)
