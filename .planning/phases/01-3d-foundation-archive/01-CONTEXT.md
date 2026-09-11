# Phase 1: 3D Foundation & Archive - Context

**Gathered:** 2026-09-11
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase retires the 2D game and lays the 3D foundation. It delivers:

1. The pre-pivot 2D game archived under a git tag (FOUND-01).
2. The 2D gameplay scenes, scripts, and art removed from the runtime project after the user confirms the removal (FOUND-02).
3. The renderer decided and set in project settings (FOUND-03).
4. A `Node3D`-based folder baseline on the pinned engine version (FOUND-04).
5. A primitive-shape Camiel (capsule) moving freely in a small 3D test space with a camera behind Camiel (FOUND-05).
6. A local headless check that surfaces GDScript parse and runtime script errors (FOUND-06).

Not in this phase: title screen, main menu, collectibles, finish marker, and win screen (Phase 2); lessons and progress saving (Phase 3); contrast, high-contrast toggle, full CI/release pipeline hardening, and docs rewrite (Phase 4); touch controls (Phase 6); Web export (Phase 7).

</domain>

<decisions>
## Implementation Decisions

### Engine & Version
- **D-01:** Build the 3D game with Godot and GDScript only; no C# anywhere, because C# projects cannot be exported to the Web (Phase 7). The choice follows an engine comparison on 2026-09-11 against Unity 6, Unreal 5, and web-native Three.js/Babylon.js. — **Reversibility:** one-way — switching engines later means rewriting every scene, script, and CI workflow.
- **D-02:** Pin Godot **4.7.2** (`4.7.2-stable`, released 2026-08-18). Godot 4.6.4 does not exist (verified against the GitHub API); `ci.yml` currently uses 4.6.2 and `export.yml` the nonexistent 4.6.4. In this phase, set 4.7.2 in `project.godot`, the local install, and every CI step this phase touches (`ci.yml`, and `release.yml` where it runs the resource verifier). Aligning `export.yml`, release notes, and the version string source stays in Phase 4 (CI-01, CI-02). — **Reversibility:** costly — scene/resource formats and CI download steps are tied to the engine version.
- **D-03:** Godot issue 122707 reports headless runs stalling on 4.7.1 (closed as archived, not fixed). The headless check in this phase must use a timeout. If 4.7.2 stalls in headless runs, stop and raise it with the user before changing the version pin.

### Renderer
- **D-04:** Use the **Compatibility** renderer on every platform (desktop, Web, low-end devices), so there is one look and one visual test pass. Remove Forward Plus from `project.godot`. — **Reversibility:** costly — switching later changes lighting and material behaviour in every 3D scene and doubles visual QA.

### Camera & Controls
- **D-05:** Third-person camera **behind Camiel** that follows him and turns along behind him. The child never controls the camera directly (no mouse-look, no camera keys).
- **D-06:** Camiel **can fall** off the edge of a level. After a fall he reappears at the last safe spot with a soft sound. No penalty, no failure screen, no lost progress. The Phase 1 test space has at least one edge, so this rule is built and tested here.
- **D-07:** Movement input in this phase is keyboard only: arrow keys and WASD to move, Space to jump. Define these as InputMap actions in `project.godot` (no raw `Input.is_key_pressed` polling, a known 2D-era problem), so touch controls in Phase 6 can map onto the same actions.

### Proving "no errors"
- **D-08:** The user approved installing Godot 4.7.2 on this Mac (official macOS build from the `godotengine/godot-builds` release `4.7.2-stable`). Godot is not installed today.
- **D-09:** One project check, runnable locally before every commit and in CI:
  1. Import the project headless.
  2. Run the main scene headless with a timeout, capturing stdout and stderr.
  3. Fail on any `SCRIPT ERROR`, `Parse Error`, or `ERROR:` line.
  4. Run a `--script` verifier that loads every `.gd` and loads and instantiates every `.tscn`, calling `quit(1)` on any failure.

  Runtime script errors do not change Godot's exit code on their own, which is why the log scan is required.
- **D-10:** In this phase the check replaces the 2D-specific CI steps: `scripts/tools/verify_camiel_resources.gd` (`ci.yml` line 110, `release.yml` line 72) and the `--quit-after 2` smoke test (`ci.yml` line 115). CI stays green after the 2D content is removed. The broader pipeline work (Linux tar path, duplicate release race, single version source) remains Phase 4.
- **D-11:** Phase 1 closes only after a short manual playtest by the user (about 5 minutes): walk in all directions, jump, fall off an edge and return, and judge the camera behaviour. The steering model (see Claude's Discretion) is confirmed or switched based on this playtest.

### Archive & Removal (carried from locked project decisions)
- **D-12:** Create the archive tag before removing anything. The removal task needs an explicit user confirmation checkpoint (FOUND-02); do not remove 2D content without it. — **Reversibility:** costly — the 2D content remains recoverable from the tag, but restoring it later conflicts with the new 3D project structure.

### Claude's Discretion
- **Steering model:** start with camera-relative movement (up/W moves away from the camera) and a camera that lazily swings back behind Camiel. If the playtest (D-11) shows this confuses young children, switch to turn-and-walk controls (left/right turns Camiel, up walks forward) with the camera fixed behind him.
- **What stays from 2D** (area not discussed):
  - Keep the dimension-independent audio files `assets/audio/bgm_ambient.ogg`, `assets/audio/sfx_collect.ogg`, `assets/audio/sfx_finish.ogg` and their `.import` files.
  - Remove all other 2D scenes, scripts, and art, including `assets/camiel/`, `assets/dogs/`, `assets/dogs_side/`, `assets/collectibles/`, and the 2D tool scripts.
  - The 2D Camiel drawings stay retrievable from the archive tag for the later MODEL-01 decision.
  - Keep the repository tooling: `scripts/tools/quality_gate.py` and `tests/test_quality_gate.py`.
- **Archive tag name:** `archive/2d-alpha-v0.0.3`.
- **Physics engine:** `project.godot` has no physics setting. Pick Jolt or Godot Physics for 3D, set it explicitly in `project.godot`, and record the choice in the plan.
- **Script and folder names** for the check (for example a shell wrapper plus a GDScript verifier under `scripts/tools/`) and for the 3D baseline folders, within the conventions in `.planning/codebase/CONVENTIONS.md`.
- **Camera tuning:** distance, height, swing speed, and collision handling.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and decisions
- `.planning/ROADMAP.md` §Phase 1: 3D Foundation & Archive — goal and success criteria
- `.planning/REQUIREMENTS.md` — FOUND-01 through FOUND-06 (this phase); CI-01 through CI-05 (Phase 4 boundary)
- `.planning/PROJECT.md` — Key Decisions (pivot, full replacement, primitive shapes, Godot + GDScript, 4.7.2, Compatibility renderer) and Constraints

### Current project state to change
- `project.godot` — `config/features` (4.6, Forward Plus), `run/main_scene` (points at the 2D `scenes/title_screen.tscn`), `[autoload]` (three 2D-era scripts that will be missing after removal), `[input]`
- `.github/workflows/ci.yml` — Godot 4.6.2 download steps, resource verifier (line 110), smoke test (line 115)
- `.github/workflows/release.yml` — resource verifier step (line 72)
- `.github/workflows/export.yml` — pins the nonexistent 4.6.4; its last five runs failed at startup (Phase 4 owns the fix)
- `export_presets.cfg` — presets and `builds/alpha-v0.0.3/` export paths that reference the 2D build
- `.gitignore` — ignores `*.import` although Godot import files must be committed; new 3D assets will hit this
- `scripts/tools/quality_gate.py` — fails CI on missing `res://` paths, PNGs under `assets/` without `.import`, forbidden phrases, and broken Markdown links; any removal must leave no dangling `res://` references

### 2D reference (archive and remove; consult for intent only)
- `.planning/codebase/ARCHITECTURE.md` — what the 2D scenes, autoloads, and signals did
- `.planning/codebase/STRUCTURE.md` — full list of 2D directories and files
- `.planning/codebase/CONCERNS.md` — CI fragility (smoke test passes on script errors), `.import` gitignore conflict, Godot version drift, hardcoded key polling
- `.planning/codebase/CONVENTIONS.md` — GDScript style to keep: tabs, static typing, snake_case, file header comments, fail-soft runtime code, tool scripts that `quit(1)`

### External
- Godot docs, Exporting for the Web (Compatibility renderer and GDScript-only constraints): https://github.com/godotengine/godot-docs/blob/master/tutorials/export/exporting_for_web.rst
- Godot issue 122707 (headless stall report on 4.7.1): https://github.com/godotengine/godot/issues/122707
- Godot 4.7.2 release: https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `assets/audio/bgm_ambient.ogg`, `assets/audio/sfx_collect.ogg`, `assets/audio/sfx_finish.ogg`: kept for the 3D game; Phase 2 wires them up.
- `scripts/tools/quality_gate.py` and `tests/test_quality_gate.py`: repository tooling that stays unchanged.
- `.github/workflows/ci.yml`: the Godot download, template install, and job layout can be reused with the version changed to 4.7.2 and the 2D steps swapped for the new check.
- `scripts/tools/verify_camiel_resources.gd`: its `extends SceneTree` + `push_error` + `quit(1)` shape is the pattern for the new verifier, even though the script itself is removed.

### Established Patterns
- GDScript conventions in `.planning/codebase/CONVENTIONS.md` apply to all new 3D scripts.
- Autoload singletons are registered in `project.godot` under `[autoload]` with PascalCase names. After removal, the three 2D-era entries (`AudioManager`, `Accessibility`, `ProgressTracker`) point at deleted scripts and would error at startup, so they must be removed or replaced in this phase.
- The quality gate checks every `res://` string in `.gd`, `.tscn`, `.tres`, `.godot`, and `.cfg` files, so a partial removal fails CI.

### Integration Points
- `project.godot` `run/main_scene` must point at the new 3D test scene.
- `export_presets.cfg` must still parse after removal; its content is otherwise Phase 4 and Phase 7 work.
- The CI check from D-09/D-10 becomes the base that Phase 4 extends (CI-03).

</code_context>

<specifics>
## Specific Ideas

- The audience is children around age 3, so movement should feel slow and forgiving. The fall-return is gentle: soft sound, no penalty.
- Camiel is a capsule in this phase; lesson props later use boxes and spheres. The real model is v2 (MODEL-01).
- The macOS headless binary path after install is typically `/Applications/Godot.app/Contents/MacOS/Godot`.
- The playtest (D-11) is the moment the user judges whether free 3D movement with a camera behind Camiel works for a young child.

</specifics>

<deferred>
## Deferred Ideas

- Test the Web export on a real iPad early, before Phase 7 (single-threaded export, Web Audio sample mode). iOS Safari is the largest Godot Web risk (Godot issue 116750, a page crash when audio plays). To be scheduled when planning the Phase 7 approach or as an inserted spike.
- The win screen decision (two big buttons, "Nog een keer" and "Naar menu") is recorded in `.planning/PROJECT.md` Key Decisions and applies to Phase 2.

</deferred>

---

*Phase: 01-3d-foundation-archive*
*Context gathered: 2026-09-11*
