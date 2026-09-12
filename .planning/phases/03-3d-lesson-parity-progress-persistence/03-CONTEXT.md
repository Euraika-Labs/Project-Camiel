# Phase 3: 3D Lesson Parity & Progress Persistence - Context

**Gathered:** 2026-09-12
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous batch-table proposals, all four areas accepted)

<domain>
## Phase Boundary

A lesson-select screen reachable from the main menu offers Lessons 1-5 by tap, click or
keyboard (LESSON-06); five real, completable 3D lessons are rebuilt fresh onto the D-13..D-30
patterns, each honouring its own completion rule (L1 all-three-any-order, L2
circle→square→triangle, L3 defined sequence, L4/L5 newly designed); and every completion
durably records `lesson_id`, `stars`, `time_seconds`, `completed_at` to `user://progress.json`
with no startup or write error (PROGRESS-01, PROGRESS-02).

Requirements in scope: LESSON-01..LESSON-06, PROGRESS-01, PROGRESS-02.

**Out of scope:** Camiel's real 3D art — phase **03.1** owns `MODEL-01`; primitives stay.
WCAG contrast and the high-contrast toggle — phase 4. Spoken Dutch voice-over — phase 5.
Touch/analog controls — phase 6. Lessons are built keyboard/tap/click-first on the existing
InputMap and `BaseButton` patterns only.

**This phase is not a port.** The archived 2D lesson layer was substantially non-functional:
lessons 2-5 were unreachable, `lesson_4.gd`/`lesson_5.gd` were 10-line stubs, and the progress
tracker never once wrote a file. Four of the five lessons and the entire persistence layer are
being built for the first time.

</domain>

<decisions>
## Implementation Decisions

Numbering continues from phase 2 (which ended at D-30).

### Lesson-select screen & navigation

- **D-31:** Lesson-select is its own scene, `scenes/lesson_select.tscn`, reached from a
  "Lessen" button on `main_menu.tscn` using the same one-shot-guarded, deferred transition as
  D-14/D-15. Not a `CanvasLayer` overlay — the win screen's overlay pattern (D-28) exists to
  avoid a scene round-trip on replay, which does not apply here.
- **D-32:** The five lesson buttons are `menu_button.tscn` instances (D-16) in a
  `GridContainer`, with **explicit `focus_neighbor_*` wiring** rather than relying on
  default tree-order traversal. Phase 2 established explicit focus order because the probes
  are written against it.
- **D-33:** The `lesson_id` → scene mapping is a typed const array of `{id, path, label}`
  dictionaries inside `scripts/lesson_select.gd` — script-owned data, no autoload, no
  `class_name` (per `CONVENTIONS.md`). A `.tres` Resource list was rejected as introducing a
  resource type this phase does not need; phase 9's MORE-01 can revisit it.
- **D-34:** Each lesson's "Terug" control returns to **lesson-select**, not the main menu, so
  browsing context is not lost. This deliberately differs from the archived
  `_on_back_button_pressed` target.

### Lesson rules & the shared pattern

- **D-35:** **No shared `LessonBase` this phase.** Five independent orchestrators,
  `scripts/lesson_1.gd` .. `scripts/lesson_5.gd`. MORE-02's shared-lesson-pattern requirement
  is explicitly phase 9 scope; introducing the abstraction now would be speculative.
- **D-36:** Lesson 1 tracks all three tasks in one `Array[String]` and checks `size() == 3`
  after every completion. This is the direct fix for the archived `lesson_manager.gd` defect,
  whose completion check tested only `red_block` + `blue_target` — finishing the count task
  first permanently soft-locked the lesson. **LESSON-01's "regardless of which of its three
  tasks is completed first" means ALL THREE, order-independent — not "any one is enough".**
- **D-37:** For the ordered lessons (L2, L3), wrong order is made **structurally impossible**:
  only the currently expected target is touchable, others gently reject. Checking an expected
  index in the orchestrator while leaving every target live is explicitly rejected — that is
  the exact shape of the archived `lesson_2.gd` defect, where `_expected_order` was declared
  and never read, so any order completed the lesson.
- **D-38:** Ordered targets expose `activate()` / `deactivate()`, emit `task_completed` only
  when active **and** touched, and emit a separate past-tense `rejected` signal for the gentle
  refusal path. The `rejected` signal exists so a probe can prove the negative — that a
  wrong-order touch did nothing — rather than only asserting eventual completion.

### Progress persistence

- **D-39:** Writes are atomic: serialise to `user://progress.json.tmp`, then rename over
  `user://progress.json`. This is `CONCERNS.md`'s own stated fix for "one corrupt write loses
  all history". Direct overwrite is rejected despite matching the archived simplicity.
- **D-40:** The schema stays an **append-log array** plus a top-level `"version"` field.
  PROGRESS-02 says each completion "writes a matching entry", which the append-log satisfies
  literally; a per-lesson best-only dictionary would be more useful long-term but conflicts
  with the requirement's wording. `version` is added so a future migration is possible.
- **D-41:** `stars` is a **flat, deterministic 3** per completion. No scoring rubric exists
  anywhere in LESSON-01..05 or PROGRESS-01..02, and deriving stars from completion time
  against a par time would invent a tunable nobody asked for. Revisit only if a requirement
  later defines a rubric.
- **D-42:** "Writes ... with no error" is proved by a probe that **re-reads
  `user://progress.json` from disk** after a real lesson completion and asserts all four
  fields are present and correct. Asserting only that a `progress_saved` signal fired is
  rejected — it would pass while the file was never written, which is precisely what happened
  in the 2D code.

### Lessons 4 and 5

- **D-43:** Lesson 4 is a **second colour-recognition and counting task** (new colour pair plus
  counting), reusing L1's all-three-any-order completion logic directly. Lowest
  implementation risk, and it exercises the D-36 fix a second time.
- **D-44:** Lesson 5 is a **four-step sequence task** extending the L3 activate/deactivate
  pattern — reusing the one archived mechanism that actually enforced order correctly.
- **D-45:** One generic `@export`-parametrized target script is reused across L1/L2/L4
  (colour/order configurable), and the sequence-target pattern across L3/L5. Bespoke
  one-script-per-shape granularity, as the archive had, is rejected.
- **D-46:** All five lessons share a **three-sub-task shape**, so one progress-label form
  (`"Stap: N / 3"`) covers every lesson. Note D-44 describes a four-step sequence: reconcile
  by treating the sequence as three scored sub-tasks, or adjust the label form — the planner
  must resolve this explicitly and record which it chose.

### Claude's Discretion

- Exact lesson geometry, target placement, colours and counts within each lesson's stated rule.
- The Dutch strings for new content, taking tone from the archived ones ("Goed zo!",
  "Goed zo, Camiel wandelt!"). Existing UI strings are fixed by `02-UI-SPEC.md`.
- Node and signal naming within `CONVENTIONS.md` (past-tense `snake_case` signals,
  `_on_<source>_<signal>` handlers, two blank lines between top-level functions, no
  `class_name`).
- How the phase splits into plans and their wave grouping.
- Whether `ProgressTracker` is a rebuilt autoload or a plain script, provided the public
  surface is callable from every lesson and the D-39/D-42 guarantees hold.

</decisions>

<code_context>
## Existing Code Insights

**Built in phases 1-2 and available to reuse:**
- `scenes/ui/menu_button.tscn` + `scripts/ui/menu_button.gd` — the focusable icon-and-label
  button with exactly one activation path. `scripts/ui/vector_icon.gd` draws six icons
  procedurally; new lessons may need new icon kinds.
- `assets/theme/ui_theme.tres` — all design tokens.
- `scripts/audio_manager.gd` — autoload with `play_music`, `stop_music`, `play_sfx`,
  `set_bgm_volume`, `set_sfx_volume`, on a real three-bus layout (Master/Music/SFX).
- `scenes/intro_level.tscn` + `scripts/intro_level.gd` — the pattern for a 3D level with
  `Area3D` triggers, a signal-driven completion path, and a `CanvasLayer` win overlay.
- `scenes/collectible.tscn`, `scenes/finish_marker.tscn` — `Area3D` trigger precedents,
  including the collision-layer guard against non-player bodies and the deferred
  `monitoring` toggle.
- `scripts/tools/probe_screen_flow.gd` — the probe pattern for driving UI and 3D triggers
  headlessly: synthesised `ui_accept`, signal-connection counts, repeated-press guards,
  negative intruder cases.
- `scripts/tools/run_headless_check.sh` — one-command check; auto-discovers
  `scripts/tools/probe_*.gd`. `test_headless_check.sh` is its 15-case self-test.

**Engine facts that bind lesson and probe code** (from `01-ENGINE-FACTS.md` and phase 2):
- Autoloads are NOT resolvable as bare global identifiers from a `--script` SceneTree
  entrypoint — use `root.get_node_or_null()`.
- Never call `.play()` in the same call as `add_child()`; settle the node in the tree first.
- Never assert `playing` in the same frame as `.play()`; use a bounded real-time retry. Never
  use `get_playback_position()` as a liveness proxy.
- `Area3D` forbids toggling `monitoring` synchronously inside its own `body_entered` callback.
- `CanvasLayer` has no `modulate` property in 4.7.2.
- Godot 4.7.2, `gl_compatibility` renderer, `physics/3d/physics_engine = "Jolt Physics"`.

**Archived 2D lesson code** (`archive/2d-alpha-v0.0.3`) — reference for Dutch strings and
lesson rules only; **do not port the scripts** (D-13's precedent): `lesson_manager.gd`,
`lesson_2.gd`..`lesson_5.gd`, `progress_tracker.gd`, `sequence_target.gd`, `shape_target.gd`,
`count_challenge.gd`.

</code_context>

<specifics>
## Specific Ideas

**The documented 2D defects this phase's requirements are written against** — each requirement
phrase is an assertion to prove, not prose to satisfy loosely:

- `lesson_manager.gd` (L1): completion tested only `red_block` + `blue_target`; finishing the
  count task first permanently soft-locked the lesson. → D-36
- `lesson_2.gd` (L2): `_expected_order` declared and never read — any order completed. → D-37
- `sequence_target.gd` (L3): gated order correctly via `activate()`/`_set_inactive()`, but
  called the private `_set_inactive()` cross-script, and its error flash overwrote the
  target's label with `str(order_number)`, losing the original text. → D-38
- `lesson_4.gd` / `lesson_5.gd`: 10-line stubs (`_ready(): pass`) whose scenes falsely
  advertised "Les 4 - Nu beschikbaar". → D-43, D-44
- Lessons 2-5 were **unreachable** — the main menu only ever linked `lesson_1.tscn`. → D-31
- `progress_tracker.gd`: `JSON.stringify(data, JSON.SINDY_USE_HELPER)` references a
  nonexistent constant, so the autoload failed to compile at every startup. → D-42
- `progress_tracker.gd`: **nothing ever called `record_lesson_complete(...)`** — progress was
  never written, while the docs claimed it was. → D-42
- `progress_tracker.gd`: no schema version, unbounded append-log, no atomic write. → D-39, D-40

**Headless order-enforcement cannot literally click shapes.** Prove it the way
`probe_screen_flow.gd` proves the collectible and finish marker: teleport Camiel onto each
`Area3D` target in sequence, plus **at least one deliberately out-of-order case per ordered
lesson** to prove the negative. Skipping the negative case reproduces the
check-that-passes-without-checking pattern this phase exists to eliminate.

**Both L4 and L5 must yield real values for `stars` and `time_seconds`.** PROGRESS-02 requires
them for every completion. Content design must not defer this to the persistence layer, which
has no data to compute them from.

</specifics>

<deferred>
## Deferred Ideas

- **`MODEL-01`** — Camiel's real 3D model and animations. Now phase **03.1**, immediately after
  this phase. Its art-source decision (AI-generated from the archived 2D drawings vs.
  commissioned) is still open.
- **`MORE-02`** — the shared lesson pattern / `LessonBase` abstraction. Phase 9. D-35
  deliberately does not pre-empt it.
- WCAG AA contrast and the high-contrast toggle — phase 4. The archived `accessibility.gd`
  used group lookups into private methods; `CONCERNS.md` recommends a `contrast_changed`
  signal instead.
- Dutch voice-over — phase 5. Touch/analog controls — phase 6. Web export — phase 7.
  Parent dashboard — phase 8, and it reads the `progress.json` this phase creates, so the
  D-40 schema choice constrains it.

**Cross-phase hazard to carry forward:** `user://` resolves against `project.godot`'s
`config/name` / custom-user-dir settings (unresolved tech debt in `CONCERNS.md`). This phase
writes real save data there for the first time. Phase 4's CI-02 version-string work could
silently orphan every child's `progress.json`. Not this phase's requirement to fix, but the
risk begins here.

</deferred>
