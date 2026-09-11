# Phase 1: 3D Foundation & Archive - Pattern Map

**Mapped:** 2026-09-11
**Files analyzed:** 9 (new/modified)
**Analogs found:** 7 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `project.godot` (edit: version, renderer, physics, autoload, main_scene, input) | config | request-response (engine boot config) | `project.godot` (current file, in place) | exact (edit-in-place) |
| `scenes/test_space.tscn` (new) | scene/component | event-driven (scene tree init) | `scenes/main.tscn` (2D root scene, being removed — consult via archive tag for intent only) | role-match |
| `scripts/camiel_controller.gd` (new, 3D rewrite) | controller (character/physics) | event-driven (`_physics_process` per-frame) | `scripts/camiel_controller.gd` (current 2D version, in place — to be rewritten, not deleted-and-recreated) | exact (rewrite-in-place) |
| `scripts/camera_rig.gd` (new, optional) | controller (camera) | event-driven (`_physics_process`/`_process` per-frame) | none in repo (no camera-follow script exists in 2D codebase — 2D used a static/fixed camera) | no analog — use RESEARCH.md Pattern 1 (SpringArm3D) |
| `scripts/tools/run_headless_check.sh` (new) | utility (CI/local check, shell wrapper) | batch (sequential CLI invocations, log-scan) | `.github/workflows/ci.yml` steps "Import project" / "Verify resources" / "Smoke test main scene" (lines ~103-116) — same sequence, currently inlined in YAML rather than a standalone script | role-match (pattern exists, not yet extracted to a script) |
| `scripts/tools/verify_3d_project.gd` (new) | utility (headless `--script` verifier) | batch (load+instantiate every scene, fail-hard) | `scripts/tools/verify_camiel_resources.gd` | exact |
| `.github/workflows/ci.yml` (edit: version bump, replace 2D verify/smoke steps) | config (CI pipeline) | batch | `.github/workflows/ci.yml` (current file, in place) | exact (edit-in-place) |
| `.github/workflows/release.yml` (edit: version bump, replace verify step) | config (CI pipeline) | batch | `.github/workflows/release.yml` (current file, in place) | exact (edit-in-place) |
| `scripts/tools/quality_gate.py` / `tests/test_quality_gate.py` | utility / test | batch | unchanged — kept as-is per CONTEXT.md discretion | n/a (no change) |

## Pattern Assignments

### `scripts/tools/verify_3d_project.gd` (utility, batch fail-hard verifier)

**Analog:** `scripts/tools/verify_camiel_resources.gd` (git-tracked, full file read this session)

**Full pattern shape to copy (this file's entire structure is the template):**
```gdscript
extends SceneTree

func _initialize() -> void:
	var frames: SpriteFrames = load("res://assets/camiel/camiel_sprite_frames.tres")
	if frames == null:
		push_error("Missing camiel_sprite_frames.tres")
		quit(1)
		return
	# ... per-item checks with early push_error + quit(1) + return ...

	for scene_path in ["res://scenes/camiel.tscn", "res://scenes/main.tscn"]:
		if load(scene_path) == null:
			push_error("Could not load scene: %s" % scene_path)
			quit(1)
			return

	var camiel_scene: PackedScene = load("res://scenes/camiel.tscn")
	var camiel := camiel_scene.instantiate()
	if camiel.get_script() == null:
		push_error("Camiel scene has no controller script attached.")
		quit(1)
		return
	camiel.queue_free()

	print("Camiel Godot resources verified.")
	quit(0)
```

**What to change for the 3D verifier:**
- Replace the hardcoded 2-scene list (`camiel.tscn`, `main.tscn`) with a directory walk of `res://scenes/**/*.tscn` (per RESEARCH.md Pattern 2) — use `DirAccess.open("res://scenes")` and recurse, `push_error` + `quit(1)` + `return` if the directory can't be opened.
- For each discovered `.tscn`: `load()` it, `instantiate()` it, check the result isn't null, then `queue_free()`. Any failure follows the exact push_error/quit(1)/return shape above.
- Keep the CharacterBody root type check pattern (was `CharacterBody2D`, becomes `CharacterBody3D` for `camiel.tscn`) and the "has a controller script attached" check.
- Naming: `verb_noun.gd` under `scripts/tools/` per CONVENTIONS.md (e.g. `verify_3d_project.gd`).
- Final success line: `print("3D project scenes verified.")` then `quit(0)`, matching the analog's final two lines exactly.

---

### `scripts/tools/run_headless_check.sh` (utility, batch shell wrapper)

**Analog:** `.github/workflows/ci.yml` steps "Import project" (headless editor import), "Verify resources" (`--script` verifier), "Smoke test main scene" (`--quit-after`) — these three steps, read in full this session, are the sequence to extract into a standalone script.

**Import + verify + smoke sequence to copy (currently inlined in CI YAML, lines ~103-116):**
```bash
"$GODOT_BIN" --headless --editor --path . --quit
"$GODOT_BIN" --headless --path . --script "res://scripts/tools/verify_camiel_resources.gd"
"$GODOT_BIN" --headless --path . --quit-after 2
```

**What to change for the new wrapper (per D-09/D-10/D-03):**
- Wrap every invocation in an OS-level `timeout N` (not just `--quit-after`, which only bounds frame count — see RESEARCH.md Pitfall 2 / issue 122707).
- After the main-scene run, capture stdout+stderr to a temp file and `grep -E 'SCRIPT ERROR|Parse Error|ERROR:'` — any match fails the script (`exit 1`). This replaces the old exit-code-only "Smoke test main scene" step, which is the confirmed-broken step in CONCERNS.md.
- Call `verify_3d_project.gd` (not `verify_camiel_resources.gd`) as the final step.
- Resolve `GODOT_BIN` the same way `ci.yml` does (env var / `$RUNNER_TEMP` in CI, `/Applications/Godot.app/Contents/MacOS/Godot` locally per CONTEXT.md Specifics) — accept it as an argument or env var so the script works both locally and in CI.
- Follow Python-tooling error style analog (`scripts/tools/quality_gate.py`) only for its "report as data, return nonzero exit" philosophy — the wrapper itself is bash, so keep it POSIX-shell simple, `set -euo pipefail` at the top matching the inline style already used in `ci.yml`'s Python heredoc step ("Check tracked file sizes").

---

### `project.godot` (config, edit-in-place)

**Analog:** the file itself, current state (git-tracked, full file read this session).

**Sections to edit, with current values as the base pattern:**
```ini
[application]
config/name="Camiel alpha-v0.0.3"
run/main_scene="res://scenes/title_screen.tscn"      # -> res://scenes/test_space.tscn
config/features=PackedStringArray("4.6", "Forward Plus")   # -> ("4.7", "Compatibility") — see RESEARCH.md Assumption A2 on exact literal

[autoload]
AudioManager="res://scripts/audio_manager.gd"          # remove or replace — script deleted in FOUND-02
Accessibility="res://scripts/accessibility.gd"         # remove or replace
ProgressTracker="res://scripts/progress_tracker.gd"    # remove or replace

[input]
ui_focus_next={ "deadzone": 0.5, "events": [Object(InputEventKey, ..., "physical_keycode":4194326, ...)] }
ui_focus_prev={ ... "physical_keycode":4194325 ... }
mobile_jump={ "deadzone": 0.5, "events": [] }
```

**New sections to add (no existing analog in this file — follow RESEARCH.md Code Examples exactly, generate via editor per Pitfall 4, don't hand-type keycodes):**
```ini
[rendering]
renderer/rendering_method="gl_compatibility"

[physics]
physics/3d/physics_engine="JoltPhysics3D"
```
`move_forward` / `move_back` / `move_left` / `move_right` / `jump` InputMap actions follow the same `{ "deadzone": ..., "events": [Object(InputEventKey, ...)] }` shape as `ui_focus_next` above (D-07) — generate the literal `physical_keycode` integers through the Godot editor's Input Map UI, not by hand.

---

### `.github/workflows/ci.yml` / `.github/workflows/release.yml` (config, edit-in-place)

**Analog:** the files themselves, current state (both git-tracked, read in full this session).

**Version env block to bump (ci.yml lines ~18-21, release.yml lines ~16-19):**
```yaml
env:
  GODOT_VERSION: 4.6.2
  GODOT_STATUS: stable
  GODOT_TEMPLATE_VERSION: 4.6.2.stable
  GODOT_BIN: Godot_v4.6.2-stable_linux.x86_64
```
→ bump all four values to `4.7.2` / `4.7.2.stable` / `Godot_v4.7.2-stable_linux.x86_64` per D-02.

**ci.yml steps to replace (verify-godot job, lines ~103-116):**
```yaml
      - name: Import project
        run: "$RUNNER_TEMP/godot/${GODOT_BIN}" --headless --editor --path . --quit
      - name: Verify resources
        run: "$RUNNER_TEMP/godot/${GODOT_BIN}" --headless --path . --script "res://scripts/tools/verify_camiel_resources.gd"
      - name: Smoke test main scene
        run: "$RUNNER_TEMP/godot/${GODOT_BIN}" --headless --path . --quit-after 2
```
→ replace with a single step invoking `scripts/tools/run_headless_check.sh` (D-10), keeping the "Download Godot" step above it unchanged in shape (only version bumped).

**release.yml step to replace ("Verify project", ~line 60):**
```bash
"$RUNNER_TEMP/godot/${GODOT_BIN}" --headless --editor --path . --quit
"$RUNNER_TEMP/godot/${GODOT_BIN}" --headless --path . --script "res://scripts/tools/verify_camiel_resources.gd"
```
→ same replacement: call `scripts/tools/run_headless_check.sh`.

---

### `scripts/camiel_controller.gd` (controller, rewrite-in-place, CharacterBody2D → CharacterBody3D)

**Analog:** the current file itself (git-tracked, first 60+ lines read this session) — reuse its **shape**, not its 2D physics.

**Patterns to keep from the analog:**
- `@export var` tunables block at top (`walk_speed`, `jump_velocity`, `gravity`, etc.) — same convention, new 3D-appropriate names/values.
- `@onready var` node references below exports.
- `_ready()` calling `add_to_group("player")`.
- `_physics_process(delta)` as the single per-frame entry point, ending in `move_and_slide()`.
- Header comment block per CONVENTIONS.md (`# camiel_controller.gd` + purpose).

**Pattern to explicitly NOT keep (anti-pattern, per D-07 / RESEARCH.md Anti-Patterns):**
```gdscript
func _read_direction() -> int:
	var direction := 0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
```
Replace raw `Input.is_key_pressed(KEY_*)` polling with `Input.get_vector("move_left", "move_right", "move_forward", "move_back")` against the new InputMap actions (D-07), per RESEARCH.md Pattern 1.

**New pattern (no in-repo analog — camera-relative movement + SpringArm3D):** see RESEARCH.md "Pattern 1: CharacterBody3D + SpringArm3D third-person follow camera" for the full code example; that section is the primary source for `scripts/camiel_controller.gd`'s movement/camera-yaw logic and for the new `scripts/camera_rig.gd` (if split out).

---

## Shared Patterns

### Fail-hard tool-script pattern (headless verification)
**Source:** `scripts/tools/verify_camiel_resources.gd` (full file)
**Apply to:** `scripts/tools/verify_3d_project.gd`
```gdscript
if <check fails>:
	push_error("<message>")
	quit(1)
	return
# ...
print("<success message>")
quit(0)
```

### Fail-soft runtime pattern (game code)
**Source:** `.planning/codebase/CONVENTIONS.md` §Error Handling (cites `scripts/audio_manager.gd`)
**Apply to:** `scripts/camiel_controller.gd`, any new fall-boundary/camera scripts
```gdscript
func play_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM not found: ", path)
		return
```
Use guard-clause early returns and `push_warning` with a `[ClassTag]` prefix for recoverable runtime problems; never crash. Applies to the new fall-and-reappear (D-06) handler on the Camiel controller.

### One-shot trigger pattern (Area3D boundary)
**Source:** `.planning/codebase/CONVENTIONS.md` §Error Handling, generalized from `scripts/red_block.gd` / `scripts/finish_marker.gd` (2D `Area2D` pattern; no 3D `Area3D` analog exists yet in this repo — apply the same shape to the new fall-boundary)
**Apply to:** the new `FallBoundary` (`Area3D`) trigger for D-06
```gdscript
func _on_body_entered(body: Node3D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	_touched = true
	_apply_reset()
```
(Swap `Node2D`→`Node3D`; D-06 has no "touched" latch requirement per se since it can re-trigger every fall, so drop the boolean latch unless repeat-triggering during the reset animation needs debouncing.)

### CI step sequencing (import → verify → smoke)
**Source:** `.github/workflows/ci.yml` (verify-godot job, current 3-step sequence) and `.github/workflows/release.yml` ("Verify project" step)
**Apply to:** `scripts/tools/run_headless_check.sh`, and the edited `ci.yml`/`release.yml` steps that call it
Keep the exact ordering: headless editor import first (Pitfall 3 — resource import on a clean checkout), then the timed main-scene log-scan, then the `--script` verifier — do not collapse or reorder these three passes.

### GDScript naming/style conventions
**Source:** `.planning/codebase/CONVENTIONS.md` (full file)
**Apply to:** all new/edited `.gd` files
- Tabs for indentation, two blank lines between top-level functions, static typing everywhere (`:=` inference for literals, explicit `: Type` for node refs).
- Header comment block: `# file_name.gd` + one-to-three line purpose summary.
- `snake_case` functions/variables, `_leading_underscore` for private state and unused params, `UPPER_SNAKE_CASE` consts.
- Tool scripts under `scripts/tools/` named `verb_noun.gd`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `scripts/camera_rig.gd` (optional split-out) | controller (camera) | event-driven | No camera-follow script exists in the 2D codebase (2D used a static fixed camera, no follow logic). Use RESEARCH.md "Pattern 1: CharacterBody3D + SpringArm3D third-person follow camera" as the primary source instead of an in-repo analog. |
| `scenes/test_space.tscn` (Node3D root, floor + FallBoundary + lighting) | scene | event-driven | No 3D scene exists in this repo yet. Follow RESEARCH.md's System Architecture Diagram scene-tree layout (`TestSpace (Node3D)` → `Floor (StaticBody3D)`, `FallBoundary (Area3D)`, `Camiel (CharacterBody3D)`, `DirectionalLight3D`/`WorldEnvironment`) rather than an in-repo 2D scene, which only offers the general "root scene wires up children in `_ready`" convention from CONVENTIONS.md. |

## Metadata

**Analog search scope:** `scripts/`, `scripts/tools/`, `scenes/`, `.github/workflows/`, `project.godot`, `.planning/codebase/CONVENTIONS.md`
**Files scanned:** `scripts/tools/verify_camiel_resources.gd`, `scripts/camiel_controller.gd`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `project.godot`, `.planning/codebase/CONVENTIONS.md` (all confirmed git-tracked via `git ls-files`)
**Pattern extraction date:** 2026-09-11
