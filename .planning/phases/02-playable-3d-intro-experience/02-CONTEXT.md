# Phase 2: Playable 3D Intro Experience - Context

**Gathered:** 2026-09-12
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous batch-table proposals, accepted per area)

<domain>
## Phase Boundary

A child goes from the title screen, through the main menu, into the free-play 3D intro
level — moving, jumping, collecting one object, reaching the finish — and sees a working
win screen, using tap, click, or keyboard throughout. Background music loops and the SFX
volume control has a distinct, audible effect.

Requirements in scope: MENU-01, MENU-02, INTRO-01, INTRO-02, INTRO-03, INTRO-04, INTRO-05, INTRO-06.

**In scope:** title screen, main menu, the 3D intro level (one collectible, one finish
marker), the win screen with its two Dutch buttons, the audio bus architecture and the
`AudioManager` autoload, and the headless probes that prove all of it.

**Out of scope:** the five lessons and progress persistence (Phase 3), WCAG contrast and
the high-contrast toggle (Phase 4), spoken Dutch voice-over (Phase 5), analog/multi-touch
controls (Phase 6), Web export (Phase 7). Camiel stays a primitive-shape capsule —
MODEL-01 remains deferred.

</domain>

<decisions>
## Implementation Decisions

Numbering continues from Phase 1 (which ended at D-12).

### UI Reuse & Input Architecture

- **D-13:** Rebuild the title screen, main menu, and win screen **fresh**. Take only the
  Dutch strings and layout intent from `archive/2d-alpha-v0.0.3`; do not port the scripts.
  Every archived UI script carries a defect documented in `.planning/codebase/CONCERNS.md`
  — the title screen changed scene twice, `StartButton` had no `pressed` connection, and
  the `About` button was dead. Porting them imports the bugs the requirements exist to
  eliminate. — **Reversibility:** cheap — the archive tag keeps the old scenes available.
- **D-14:** Tap, click, and keyboard collapse into one code path via **`BaseButton.pressed`
  only**. Keyboard activation comes from focus plus the engine's built-in `ui_accept`,
  which already emits `pressed`. **No script changes scenes from `_input` or `_gui_input`.**
  This is the direct fix for MENU-01/MENU-02: the 2D double-fire came from handling both
  `_input` *and* the button signal, and Enter always loaded `main.tscn` regardless of which
  button had focus.
- **D-15:** Every scene-changing handler carries a **one-shot `_transitioning` guard**
  (`if _transitioning: return`) and performs the change deferred. MENU-01 demands "exactly
  once"; the guard makes that structural rather than incidental.
- **D-16:** Rebuild **`scenes/ui/menu_button.tscn`** (+ `scripts/ui/menu_button.gd`) as the
  single focusable icon-plus-label button, used by both menus and the win screen. INTRO-05
  requires an icon on each win button, and `CONVENTIONS.md` places reusable UI scenes in
  `scenes/ui/`.

### 3D Intro Level & Collectible

- **D-17:** `scenes/intro_level.tscn` is **fully enclosed** — walls on all sides, one low
  ramp to jump onto. A three-year-old's first level should not punish wandering. D-06's
  soft fall-return stays built and probe-tested from Phase 1; the intro level simply does
  not exercise it.
- **D-18:** The collectible is a **floating, slowly rotating primitive** (sphere with an
  emissive material) carrying an `Area3D` trigger. This matches primitive-shape Camiel
  while MODEL-01 is deferred; the archived 2D collectible art stays unported.
- **D-19:** **Exactly one collectible** in the intro level. INTRO-03 says "a 3D collectible
  object", singular, and one pickup keeps the "sound plays exactly once per pickup"
  assertion unambiguous to probe.
- **D-20:** The finish marker is an **`Area3D` that emits a `finished` signal**; the level
  listens for it and shows the win screen. This satisfies INTRO-04's requirement for a
  single signal-driven path rather than a direct cross-script call.
- **D-21:** The finish marker is **not gated** on collecting the object. Free play, no dead
  ends — the child can reach the goal whether or not they picked anything up.

### Audio Architecture

- **D-22:** **Three audio buses: Master, Music, SFX** (Music and SFX both routed to
  Master). BGM plays on Music, effects on SFX. This fixes a real defect in the archived
  `scripts/audio_manager.gd:37`, which set `_bgm_player.bus = SFX_BUS` — commented "BGM
  routed through SFX so it respects sfx volume". With that routing INTRO-06 is
  unsatisfiable as written, because one slider moves both.
- **D-23:** Rebuild the **`AudioManager` autoload** while keeping the archived public
  surface — `play_music`, `stop_music`, `play_sfx`, `set_bgm_volume`, `set_sfx_volume` — so
  Phase 3's lessons call the same API. Fix the bus routing (D-22) and the linear-vs-dB
  confusion in the original, which named a field `_bgm_volume_db` and then commented it
  `linear 0-1`. Autoload naming follows `CONVENTIONS.md` (PascalCase, registered in
  `project.godot`).
- **D-24:** "Loops continuously" is guaranteed by setting **`loop = true` on the imported
  `.ogg` stream resource**, plus a probe assertion that the player is still playing after
  several seconds. The kept audio files are `assets/audio/bgm_ambient.ogg`,
  `sfx_collect.ogg`, and `sfx_finish.ogg`.
- **D-25:** The **SFX volume control is an `HSlider` on the main menu**, so it is reachable
  — INTRO-06 requires it to have an audible effect.
- **D-26:** Headless CI cannot hear anything, so the probe asserts a **testable proxy** for
  audibility: correct bus indices resolve, the BGM player reports `playing == true` after
  N seconds, its stream reports `loop == true`, and `set_sfx_volume()` changes the SFX
  bus's `volume_db` **without** changing Music's. That last assertion is the one that would
  have caught the original routing bug.

### Screen Flow & Headless Verification

- **D-27:** **Retarget the Node3D assertion.** Phase 1's `scripts/tools/verify_3d_project.gd`
  asserts the *main scene's* root is a `Node3D` — a tracer-era proxy for "this project is
  genuinely 3D". Phase 2's entry point is a `Control`-rooted title screen, which would fail
  that check. Change the assertion to target the **gameplay** scene root
  (`intro_level.tscn` is a `Node3D`) and let `run/main_scene` be the title screen.
  Explicitly rejected: wrapping the title UI in a `Node3D` shell purely to keep the check
  literal. That makes the check pass without checking anything real, which is the exact
  failure mode Phase 1's code review already caught once (the probe glob matched zero files
  and the suite still reported green). — **Reversibility:** cheap, but the assertion must
  stay meaningful.
- **D-28:** Scene flow is `title_screen.tscn` → `main_menu.tscn` → `intro_level.tscn`. The
  **win screen is a `CanvasLayer` overlay inside the intro level**, not a separate scene, so
  "Nog een keer" restarts without a scene round-trip and "reaching the finish shows the win
  screen" has one unambiguous meaning. The win buttons are "Nog een keer" (replay) and
  "Naar menu", each with an icon.
- **D-29:** Add **`scripts/tools/probe_screen_flow.gd`**, which instantiates each screen,
  emits `pressed` on the focused button, and asserts the transition or signal fired
  **exactly once**. It is picked up automatically by the `probe_*.gd` glob in
  `run_headless_check.sh`, and Phase 1's self-test case 12 now guarantees a missing probe
  fails the check rather than passing vacuously.
- **D-30:** Phase 2 closes with **one short human playtest** (title → menu → play → collect
  → finish → replay → menu), for the same reason as D-11: tap and click on a real pointer
  device, and genuine audibility, cannot be verified headlessly.

### Claude's Discretion

- Exact intro-level geometry: floor dimensions, ramp height and placement, wall height,
  lighting setup, and where the collectible and finish marker sit — within D-17's enclosed
  shape.
- Visual styling of the three screens: fonts, colours, button sizes, spacing. Note that
  WCAG AA contrast and the high-contrast toggle are Phase 4, so do not over-invest here,
  but do not paint into a corner either.
- Which icons the win-screen buttons carry, and how they are sourced or drawn given the
  2D art is unported.
- Collectible rotation speed, emissive intensity, and pickup feedback timing.
- Slider range and default value for the SFX control, and whether a BGM slider appears
  alongside it (`set_bgm_volume` exists in the API either way).
- Node and signal naming within `CONVENTIONS.md` (past-tense `snake_case` signals,
  `_on_<source>_<signal>` handlers, two blank lines between top-level functions, no
  `class_name`).
- How many plans the phase splits into and their wave grouping.

</decisions>

<code_context>
## Existing Code Insights

**Built in Phase 1 and available to reuse:**
- `scripts/camiel_controller.gd` — `CharacterBody3D` capsule with a `SpringArm3D` chase
  camera. `steering_mode` defaults to `TURN_AND_WALK` following the D-11 human playtest;
  `CAMERA_RELATIVE` remains selectable. Movement uses InputMap actions (D-07), never raw
  key polling, so Phase 6 touch controls can map onto the same actions.
- `scenes/camiel.tscn` — the instanceable player.
- `scenes/test_space.tscn` — the Phase 1 Node3D test space; `intro_level.tscn` follows its
  structure (WorldEnvironment / Sun / Ground + CollisionShape3D + Mesh).
- `assets/materials/ground.tres`.
- `scripts/tools/run_headless_check.sh` — the one-command check: import → main scene →
  every `scripts/tools/probe_*.gd` → verifier, each watchdog-bounded, logs scanned for
  `SCRIPT ERROR|Parse Error|ERROR:`. Fails when the probe glob matches nothing.
- `scripts/tools/test_headless_check.sh` — 13-case self-test of the check itself.
- `scripts/tools/verify_3d_project.gd` — enforces the pinned baseline (engine version,
  renderer, physics engine, Node3D root, every `.gd`/`.tscn` loads). D-27 retargets its
  main-scene assertion.
- `scripts/tools/probe_camiel_movement.gd` — the pattern `probe_screen_flow.gd` follows:
  drives real InputMap actions headlessly and asserts observable behaviour.

**Pinned engine baseline (from `01-ENGINE-FACTS.md`):** Godot 4.7.2, `config_version=5`,
`gl_compatibility` renderer on base/`.mobile`/`.web`, `physics/3d/physics_engine` =
`"Jolt Physics"` (with the space — `JoltPhysics3D` is wrong and silently falls back).

**Recoverable from `archive/2d-alpha-v0.0.3`** (reference only, per D-13): `scenes/title_screen.tscn`,
`scenes/main_menu.tscn`, `scenes/ui/menu_button.tscn`, `scenes/ui/progress_bar.tscn`,
`scenes/collectible.tscn`, `scenes/finish_marker.tscn`, and the scripts
`title_screen.gd`, `main_menu.gd`, `game_hud.gd`, `hud.gd`, `intro_scene.gd`,
`collectible.gd`, `finish_marker.gd`, `audio_manager.gd`, `accessibility.gd`,
`progress_tracker.gd`. Dutch strings worth carrying forward include "Goed zo!" and
"Goed zo, Camiel wandelt!".

**Documented 2D-era defects this phase must not reproduce** (`.planning/codebase/CONCERNS.md`):
- Title screen changed scene **twice** — `_input` handled `ui_accept` and the focused
  `PlayButton` also emitted `pressed`. → D-14, D-15.
- `main_menu.tscn` connected only `LessonButton.pressed`; `StartButton` had no connection,
  so only Enter worked — and Enter always loaded `main.tscn` regardless of focus. Touch and
  mouse-only children could not start the level. → D-14.
- "Collect sound plays twice or not at all." → D-19, D-26.
- `GameHUD` connected to `get_tree().group_added`, a signal that does not exist in Godot 4.
- BGM routed through the SFX bus. → D-22.
- Raw `Input.is_key_pressed(KEY_*)` across four scripts, with the key set duplicated. →
  already fixed by D-07's InputMap actions.

**Conventions** (`.planning/codebase/CONVENTIONS.md`): scripts named after the scene they
drive; reusable UI in `scenes/ui/` with scripts in `scripts/ui/`; signals past-tense
`snake_case` with typed arguments; handlers `_on_<source>_<signal>`; autoloads PascalCase in
`project.godot`; no `class_name` anywhere; two blank lines between top-level functions.

</code_context>

<specifics>
## Specific Ideas

- The win screen's two buttons are labelled exactly **"Nog een keer"** (replay) and
  **"Naar menu"**, each with an icon, per INTRO-05.
- The requirements' unusual precision — "exactly once", "one code path", "signal-driven
  rather than a direct cross-script call", "plays exactly once per pickup" — is not
  stylistic. Each phrase maps to a specific defect recorded in `CONCERNS.md`. Plans should
  treat each as an assertion to prove, not a description to satisfy loosely.
- Phase 1's code review found the verification chain could pass vacuously when the probe
  glob matched zero files. New probes must be accompanied by the reasoning that they
  actually assert something, and any new non-vacuity risk gets its own self-test case in
  `test_headless_check.sh`.

</specifics>

<deferred>
## Deferred Ideas

- **MODEL-01** — replacing primitive-shape Camiel with real 3D art. The 2D drawings stay
  retrievable from the archive tag. Not this phase.
- Progress persistence and the five lessons — Phase 3 (the archived `progress_tracker.gd`
  is the reference).
- WCAG AA contrast and the high-contrast toggle — Phase 4. The archived `accessibility.gd`
  used group lookups into private methods; `CONCERNS.md` recommends a `contrast_changed`
  signal instead.
- Analog and multi-touch controls — Phase 6. The archived `mobile_controller.gd` ignored a
  second finger once `_touch_id` was set, so the child could not move and jump at once.
- Dutch voice-over — Phase 5.
- Web export — Phase 7.

</deferred>
