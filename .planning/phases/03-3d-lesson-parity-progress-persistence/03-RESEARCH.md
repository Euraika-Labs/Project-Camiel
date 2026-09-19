---
phase: "3"
slug: "3d-lesson-parity-progress-persistence"
status: complete
researched: 2026-09-12
engine: "Godot 4.7.2.stable.official.ed1daf0bf (verified, see Verified Facts)"
---

# Phase 3: 3D Lesson Parity & Progress Persistence — Research

**Researched:** 2026-09-12
**Domain:** Godot 4.7 `user://` JSON persistence, headless order-enforcement proofs for
`Area3D` targets, and a data-driven lesson-select screen, built on the D-13..D-30 patterns
Phase 1/2 already proved.
**Confidence:** HIGH on everything backed by a fresh engine run this session (see Verified
Facts); MEDIUM/LOW items are flagged explicitly and listed in Assumptions and Risks.

**Method note:** All persistence facts (user_data_dir, `DirAccess.rename_absolute`, JSON
write/read, corrupt-file behaviour, config/name-change orphaning) were reproduced this session
against a throwaway `mktemp -d` scratch project, run through the installed
`/Applications/Godot.app/Contents/MacOS/Godot` (4.7.2.stable), under `--headless`. Nothing under
`scenes/`, `scripts/`, `assets/`, or `project.godot` in this repository was touched by any test.
Facts about existing repo code (probe patterns, `focus_neighbor_*` usage, collision defaults,
`teleport_to`) are cited from files `Read` this session, with path and line evidence.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

D-31..D-46 (full text in `03-CONTEXT.md`; summarized):

- **D-31:** Lesson-select is its own scene, `scenes/lesson_select.tscn`, reached from a "Lessen"
  button on `main_menu.tscn` using the D-14/D-15 one-shot-guarded, deferred transition. Not a
  `CanvasLayer` overlay.
- **D-32:** Five `menu_button.tscn` instances in a `GridContainer`, with explicit
  `focus_neighbor_*` wiring.
- **D-33:** `lesson_id` → scene mapping is a typed const array of `{id, path, label}`
  dictionaries inside `scripts/lesson_select.gd` — no autoload, no `class_name`.
- **D-34:** Each lesson's "Terug" returns to lesson-select, not the main menu.
- **D-35:** No shared `LessonBase` this phase. Five independent orchestrators,
  `scripts/lesson_1.gd`..`scripts/lesson_5.gd`.
- **D-36:** Lesson 1 tracks all three tasks in one `Array[String]` and checks `size() == 3`
  after every completion — order-independent, ALL THREE required.
- **D-37:** For L2/L3, wrong order is structurally impossible: only the currently expected
  target is touchable, others gently reject. No "checking an expected index while leaving every
  target live."
- **D-38:** Ordered targets expose `activate()`/`deactivate()`, emit `task_completed` only when
  active and touched, and emit a separate past-tense `rejected` signal for the refusal path.
- **D-39:** Writes are atomic: `user://progress.json.tmp` then rename over
  `user://progress.json`.
- **D-40:** Schema is an append-log array plus a top-level `"version"` field.
- **D-41:** `stars` is a flat, deterministic `3` per completion.
- **D-42:** "No error" for writes is proved by a probe that re-reads `user://progress.json`
  from disk after a real completion and asserts all four fields.
- **D-43:** Lesson 4 is a second colour-recognition-and-counting task, reusing L1's
  all-three-any-order logic.
- **D-44:** Lesson 5 is a four-step sequence task extending L3's activate/deactivate pattern.
- **D-45:** One generic `@export`-parametrized target script reused across L1/L2/L4
  (colour/order configurable); the sequence-target pattern across L3/L5. No
  one-script-per-shape.
- **D-46:** All five lessons share a three-sub-task shape for the `"Stap: N / 3"` label form;
  L5's four-step sequence must be reconciled explicitly (see Q6/Pitfall 8 below for the
  recommended resolution).

### Claude's Discretion

- Exact lesson geometry, target placement, colours and counts within each lesson's stated rule.
- Dutch strings for new content, tone from archived ones ("Goed zo!", "Goed zo, Camiel
  wandelt!"). Existing UI strings are fixed by `02-UI-SPEC.md`.
- Node/signal naming within `CONVENTIONS.md`.
- How the phase splits into plans and their wave grouping.
- Whether `ProgressTracker` is a rebuilt autoload or a plain script, provided the public surface
  is callable from every lesson and D-39/D-42 hold.

### Deferred Ideas (OUT OF SCOPE)

- `MODEL-01` — Camiel's real 3D model. Phase 03.1.
- `MORE-02` — shared `LessonBase` abstraction. Phase 9.
- WCAG AA contrast / high-contrast toggle — Phase 4.
- Dutch voice-over — Phase 5. Touch/analog controls — Phase 6. Web export — Phase 7.

**Cross-phase hazard carried forward and confirmed this session (see VF3):** `user://` resolves
against `config/name`. Phase 4's CI-02 version-string work will change `OS.get_user_data_dir()`
and silently orphan every child's `progress.json`. Not this phase's requirement to fix.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LESSON-01 | L1 finishes regardless of task order | Q4/D-36 — reusable target script tracks `Array[String]`, checks `size()==3` |
| LESSON-02 | L2 only completes circle→square→triangle in order | Q2/Q4/D-37/D-38 — activate/deactivate + `rejected` signal, headless probe pattern |
| LESSON-03 | L3 only completes in defined order | Same pattern as LESSON-02, reusing the sequence-target shape (D-44 extends it) |
| LESSON-04 | Real, completable 3D task (second colour+count) | D-43 — reuses L1's logic directly (Q4) |
| LESSON-05 | Real, completable 3D task (four-step sequence) | D-44 — reuses L3's activate/deactivate shape (Q2/Q4), label reconciliation in Pitfall 8 |
| LESSON-06 | Lesson-select screen reachable from main menu | Q3 — `GridContainer` + explicit `focus_neighbor_*`, D-33's data table |
| PROGRESS-01 | Progress tracker initializes without script error | Q1/Pitfall 1 — `JSON.new().parse()` not `JSON.parse_string()`, first-run/corrupt-file handling verified this session |
| PROGRESS-02 | Completion writes `lesson_id`/`stars`/`time_seconds`/`completed_at` to `user://progress.json` | Q1 — verified atomic write/read cycle, D-42's re-read-from-disk probe pattern |

</phase_requirements>

---

## Verified Facts

All commands run this session via `mktemp -d` scratch projects against
`/Applications/Godot.app/Contents/MacOS/Godot` (4.7.2.stable), `--headless`. Raw output is
verbatim below each command.

| ID | Fact | Command | Observed output |
|----|------|---------|------------------|
| PF1 | **`OS.get_user_data_dir()` on this machine resolves under the config/name-derived path, exactly matching `CONCERNS.md`'s prediction** (`app_userdata/Camiel alpha-v0.0.3`). No `use_custom_user_dir` is set in the repo's `project.godot` (confirmed by `Read` this session), so this is the live path. | `project.godot` with `config/name="Camiel alpha-v0.0.3"`; `--headless --script res://probe.gd` printing `OS.get_user_data_dir()` | `USER_DATA_DIR=/Users/bert/Library/Application Support/Godot/app_userdata/Camiel alpha-v0.0.3` |
| PF2 | **`DirAccess.rename_absolute()` succeeds (`OK`/`0`) both for a fresh rename (no existing target) and for renaming over an already-existing target file**, and the target's contents are fully replaced (not merged/appended). This directly validates D-39's atomic tmp-then-rename pattern. | `DirAccess.rename_absolute(globalize_path("user://progress.json.tmp"), globalize_path("user://progress.json"))`, called twice — once with no `progress.json` present, once with a prior `progress.json` present | `RENAME_NO_TARGET_ERR=0 (OK=true)` / `FINAL_EXISTS_AFTER_RENAME=true` / `RENAME_OVER_EXISTING_ERR=0 (OK=true)` / re-read after the second rename: `PARSED_AFTER_OVERWRITE_RENAME_ENTRY_COUNT=2` (both the original and the newly-appended entry present, proving the rename replaced the file with the tmp file's full content, not a partial/merged write) |
| PF3 | **`JSON.stringify(data, "\t")` is the correct call signature** — no `JSON.SINDY_USE_HELPER` constant exists (confirmed absent; the archived code's exact defect). Signature is `JSON.stringify(data: Variant, indent: String = "", sort_keys: bool = true, full_precision: bool = false) -> String`. | `JSON.stringify({"entries": [...]}, "\t")` | `JSON_TEXT_SAMPLE={` / `	"entries": [` / `		{` / `			"completed_at": "` — clean, indented, no error |
| PF4 | **First-run (no file) is silent — no engine `ERROR:` line.** `FileAccess.file_exists()` returns `false`; `FileAccess.open(path, FileAccess.READ)` on a missing file returns a null `FileAccess` object with **no printed `ERROR:` line**, and `FileAccess.get_open_error()` reports `7` (`ERR_FILE_NOT_FOUND`). | `FileAccess.file_exists("user://does_not_exist.json")`, then `FileAccess.open(...)`, then `FileAccess.get_open_error()` | `MISSING_FILE_EXISTS=false` / `OPEN_MISSING_FOR_READ_RESULT=<Object#null> open_error=7` — no `ERROR:` line accompanies this |
| PF5 | **Corrupt/truncated JSON via the static `JSON.parse_string()` DOES print an engine `ERROR:` line to stderr, even though it also returns `null` cleanly to the caller.** This is load-bearing: `run_headless_check.sh` greps every log for `ERROR:` and fails the whole check on a match — so a progress tracker written with `JSON.parse_string()` would make the headless check go red the instant a probe exercises the corrupt-file-recovery path, even though the *game* recovers correctly. | `JSON.parse_string("{\"version\": 1, \"entries\": [ { \"lesson_id\": \"x\", ")` (deliberately truncated) | `ERROR: Parse JSON failed. Error at line 0: Expected key` / `   at: parse_string (core/io/json.cpp:629)` / `CORRUPT_PARSE_RESULT=<null> (is null=true)` |
| PF6 | **The instance method `JSON.new().parse(text)` returns an `Error` code silently — no `ERROR:` line is printed** — making it the correct call for a fail-soft recovery path that must not trip the log-scan. `get_error_line()`/`get_error_message()` are available for optional diagnostics without triggering the print. | `var json := JSON.new(); var err := json.parse(corrupt_text)` on the same truncated string as PF5 | `JSON.parse() ERROR=43 (OK=false) error_line=0 error_message=Expected key` — **no accompanying `ERROR:` engine print**, unlike PF5's static call on identical input |
| PF7 | **All of PF1-PF6 hold identically under `--headless`** (every command above was run with `--headless`; D-42's probe can safely re-read the file from disk in the same headless invocation that wrote it). | Same scratch runs, all invoked as `"$GODOT" --headless --path "$SCRATCH" --script res://probe.gd --quit-after 30` | Exit code 0 for the whole run; all prints above present; no stall |
| PF8 | **Changing `config/name` changes `OS.get_user_data_dir()` to a different directory, and a `progress.json` written under the old name is invisible under the new name** — confirming the cross-phase hazard CONTEXT.md flags for Phase 4's CI-02 work is real, not theoretical. | Wrote `progress.json` under `config/name="Camiel alpha-v0.0.3"`, then re-launched the same scratch project directory with only `config/name` changed to `"Camiel"` and re-checked | `USER_DATA_DIR_NEW_NAME=/Users/bert/Library/Application Support/Godot/app_userdata/Camiel` (vs. PF1's `.../Camiel alpha-v0.0.3`) / `OLD_PROGRESS_FILE_VISIBLE_UNDER_NEW_NAME=false` |
| PF9 | **`focus_neighbor_right` (and by extension `_left`/`_top`/`_bottom`) is already proven working, in this exact codebase, on a `Button`-rooted node** — `scripts/tools/probe_screen_flow.gd`'s `_case_win_buttons()` reads `replay_button.focus_neighbor_right` as a `NodePath` and resolves it with `replay_button.get_node(neighbor_path)` to assert it points at `%GoToMenuButton`. This is the exact pattern D-32 needs for the `GridContainer`, already exercised by the current green test suite — not a fresh engine claim, a `Read`-and-cited fact from this repo. | `Read scripts/tools/probe_screen_flow.gd:523-529` | `var neighbor_path: NodePath = replay_button.focus_neighbor_right` ... `if replay_button.get_node(neighbor_path) != go_to_menu_button:` |
| PF10 | **`menu_button.gd`'s `@export` surface is exactly `label_text: String` and `icon_kind: String`**, both settable per-instance at scene-instantiation time with no scene changes required to reuse `menu_button.tscn` five times with distinct content. | `Read scripts/ui/menu_button.gd:11-21` | `@export var label_text: String = "":` (setter updates `%Label.text`) and `@export var icon_kind: String = "play":` (setter updates `%Icon.icon_kind`) |
| PF11 | **`vector_icon.gd` dispatches shapes through a single `match` statement in `get_icon_shapes(kind, target_size)`**, a pure function with no node-state dependency; current valid kinds are `"play"`, `"walk"`, `"replay"`, `"home"`, `"speaker"`, `"music_note"`. An unrecognised kind `push_warning`s and returns `[]` (fails soft, not hard) — adding a new lesson icon kind is a new `match` arm plus one new `_<kind>_shapes()` function, zero changes to the dispatch mechanism. | `Read scripts/ui/vector_icon.gd:38-55` | `match kind: "play": return _play_shapes(...) ... _: push_warning(...); return []` |
| PF12 | **`Area3D`/`CharacterBody3D` default `collision_layer`/`collision_mask` are both `1`**, so the ground and any other default-layer body also fires `body_entered` on every lesson target — the `is_in_group("player")` guard (already the pattern in `collectible.gd`/`finish_marker.gd`) remains a functional requirement for every new lesson target, not layer/mask configuration. Carried over verified fact, not re-tested this session (Phase 2's VF13 already proved it against this same engine/project). | Cited from `02-RESEARCH.md` VF13 | `player collision_layer/mask: 1 / 1` / `area collision_layer/mask: 1 / 1`; ground also triggered `body_entered` in that test |

---

## Assumptions and Risks

| # | Claim | Confidence | Impact if wrong | How an executor would detect it |
|---|-------|-----------|------------------|----------------------------------|
| A1 | **Physics-frame timing for `body_entered` after a `teleport_to()` call is bounded by a real, already-proven pattern (`while count == 0 and frames_waited < 120: await physics_frame`), not independently re-measured for lesson targets this session.** `probe_screen_flow.gd`'s finish-marker and collectible cases both use this exact 120-frame (2s at 60fps) ceiling and pass in the current green suite. | HIGH that the *pattern* transfers (same `Area3D`/`CharacterBody3D` mechanics, same engine), not independently re-verified for a five-target sequence in this session | Low — if a specific ordered-sequence probe needs more headroom (e.g. teleporting across a larger level), the fix is raising the loop's frame ceiling, not redesigning the pattern | A probe that times out at 120 frames without firing `task_completed`/`rejected` is the detection signal; raise the ceiling, don't add `await get_tree().create_timer()` real-time waits |
| A2 | **The recommended D-46 label reconciliation (parametrize the total in `"Stap: %d / %d"` rather than hardcoding `/ 3`) is this research's recommendation, not a locked decision** — D-46 explicitly requires the planner to resolve this and record the choice. | N/A — explicitly flagged as needing planner sign-off, not a research gap | If the planner instead hardcodes `/ 3` and special-cases L5's label string, the visible text still reads correctly; the risk is only that "one shared form" becomes "one shared form plus one exception," a documentation/consistency cost, not a functional one | See Pitfall 8 below |
| A3 | **Icon content for five new lesson-select buttons is left unspecified in detail** (Claude's Discretion covers exact geometry) — this research gives the *mechanism* (new `match` arms in `vector_icon.gd`), not final pictogram designs. | N/A — explicitly deferred to discretion | None; intentionally open | — |
| A4 | **`Time.get_datetime_string_from_system()` for `completed_at` is carried over from the archived schema's convention, not independently re-verified for format stability in 4.7.2 this session** — a plausible but untested assumption that its output format is unchanged from what the archive assumed. | MEDIUM | Low — the field is a free-form string per D-40's schema; even a format change would not break parsing, only the human-readable date form the parent dashboard (Phase 8) will need to parse. | Print one sample value during Wave 0 and confirm it round-trips through `JSON.stringify`/`parse` unchanged (trivial; do it inline in the first progress-tracker probe) |
| A5 | **Collision-layer segregation for lesson targets is not needed** — the existing group-check-only pattern (PF12) is treated as sufficient, matching Phase 2's structural fix rather than introducing new layers. This is a design recommendation, not a re-verified fact for lesson geometry specifically (lesson scenes do not exist yet to test against). | HIGH (same defaults, same engine, same guard pattern that already ships and passes) | Low — if a lesson's geometry turns out to need layer segregation for some other reason (e.g. one target's `Area3D` overlapping another target's `Area3D`, not the ground), that is an additive, local fix scoped to that one scene, not a research gap | A probe asserting `rejected`/`task_completed` fires on the wrong target's overlap would surface this immediately |

---

## Research Questions — Implementation Guidance

### Q1 — `user://` persistence (highest risk, now verified)

**Working `ProgressTracker` shape**, using PF1-PF8's exact verified calls:

```gdscript
# scripts/progress_tracker.gd (plain script or autoload — either satisfies D-46's discretion)
extends Node

const PROGRESS_PATH := "user://progress.json"
const PROGRESS_TMP_PATH := "user://progress.json.tmp"
const SCHEMA_VERSION := 1

signal progress_saved

var _entries: Array[Dictionary] = []


func _ready() -> void:
	_entries = _load_entries()


## D-40/D-41: stars is always 3; time_seconds/completed_at are real values the
## calling lesson computed. D-39: atomic tmp-then-rename write (PF2).
func record_lesson_complete(lesson_id: String, time_seconds: float) -> void:
	var entry := {
		"lesson_id": lesson_id,
		"stars": 3,
		"time_seconds": time_seconds,
		"completed_at": Time.get_datetime_string_from_system(),
	}
	_entries.append(entry)
	_write_entries()
	progress_saved.emit()


func _load_entries() -> Array[Dictionary]:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return []  # PF4: silent, no ERROR: line — this is the expected first run.

	var f := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if f == null:
		push_warning("[ProgressTracker] Could not open %s: %s" % [PROGRESS_PATH, error_string(FileAccess.get_open_error())])
		return []

	var text := f.get_as_text()
	f.close()

	# PF5/PF6: JSON.new().parse() — NEVER the static JSON.parse_string() — a
	# corrupt/truncated file must recover silently, without an engine
	# ERROR: line, or PROGRESS-01's "no error" contract fails the moment a
	# probe exercises this path even though the recovery itself is correct.
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("[ProgressTracker] Corrupt progress file, starting fresh: %s (line %d)" % [json.get_error_message(), json.get_error_line()])
		return []

	var data: Variant = json.get_data()
	if not (data is Dictionary) or not data.has("entries") or not (data["entries"] is Array):
		push_warning("[ProgressTracker] Unexpected progress file shape, starting fresh.")
		return []

	var typed: Array[Dictionary] = []
	for item: Variant in data["entries"]:
		if item is Dictionary:
			typed.append(item)
	return typed


func _write_entries() -> void:
	var data := {"version": SCHEMA_VERSION, "entries": _entries}
	var json_text := JSON.stringify(data, "\t")  # PF3 — the correct signature.

	var tmp := FileAccess.open(PROGRESS_TMP_PATH, FileAccess.WRITE)
	if tmp == null:
		push_warning("[ProgressTracker] Could not open tmp file for write.")
		return
	tmp.store_string(json_text)
	tmp.close()

	# D-39: atomic rename over any existing target (PF2 confirms both the
	# fresh-rename and overwrite-existing-target cases return OK).
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(PROGRESS_TMP_PATH),
		ProjectSettings.globalize_path(PROGRESS_PATH)
	)
	if err != OK:
		push_warning("[ProgressTracker] Atomic rename failed: %s" % error_string(err))
```

**D-42's re-read-from-disk probe** (the correct shape — never assert only on `progress_saved`):

```gdscript
# In a new probe, after driving a real lesson to completion:
var f := FileAccess.open("user://progress.json", FileAccess.READ)
if f == null:
	_fail(case_name, "user://progress.json was not created after lesson completion")
	return
var json := JSON.new()
if json.parse(f.get_as_text()) != OK:
	f.close()
	_fail(case_name, "user://progress.json is not valid JSON after a real completion")
	return
f.close()
var data: Dictionary = json.get_data()
var last: Dictionary = data["entries"][-1]
if last["lesson_id"] != "lesson_1" or last["stars"] != 3 or not (last["time_seconds"] is float or last["time_seconds"] is int) or String(last["completed_at"]).is_empty():
	_fail(case_name, "progress entry missing/incorrect fields: %s" % last)
	return
```

**Cross-phase hazard, confirmed (PF8):** do not add any fix for this in Phase 3 — the phase's
own scope is "record for the first time," and CONTEXT.md already scopes the `config/name` fix
to Phase 4. Just don't let a Phase 3 task accidentally touch `config/name` while wiring
anything.

---

### Q2 — Headless proof of order enforcement (D-37, D-38)

**The reusable teleport-and-settle pattern**, already proven in `probe_screen_flow.gd`'s
finish-marker and collectible cases (`Read scripts/tools/probe_screen_flow.gd:206-213`,
`354-362`):

```gdscript
camiel.teleport_to(target.global_position)
var frames_waited := 0
while _signal_count == 0 and frames_waited < 120:
	await physics_frame
	frames_waited += 1
if _signal_count != 1:
	_fail(case_name, "...")
```

**Driving a full ordered sequence and proving the negative (the case shape D-37/D-38 need):**

```gdscript
func _case_lesson_2_order() -> void:
	# ... instantiate lesson_2.tscn, get %CircleTarget/%SquareTarget/%TriangleTarget, camiel ...
	var rejected_count := 0
	square.rejected.connect(func(): rejected_count += 1)

	# Wrong order first: touch square before circle. Must reject, not complete.
	camiel.teleport_to(square.global_position)
	var waited := 0
	while rejected_count == 0 and waited < 120:
		await physics_frame
		waited += 1
	if rejected_count != 1:
		_fail(case_name, "touching square out of order did not emit rejected exactly once")
		return
	if completed_count != 0:
		_fail(case_name, "touching square out of order completed a task; order is not enforced")
		return

	# Now the correct order. circle -> activates square -> square -> activates triangle -> triangle.
	camiel.teleport_to(circle.global_position)
	# ... wait for task_completed("circle"), assert orchestrator called square.activate() ...
	camiel.teleport_to(square.global_position)
	# ... wait for task_completed("square") — square was rejected once already but never
	#     latched _touched, so it is still touchable now that it's active (D-38's design) ...
```

**Observing `rejected` the same way `finished`/`collected` are proven exactly-once** (connection
count + emission count, `Read scripts/tools/probe_screen_flow.gd:201-204`):

```gdscript
var connections := square_target.get_signal_connection_list("rejected")
if connections.size() != 1:  # only the probe's own counter, since the orchestrator listens to
	_fail(case_name, "...")  # task_completed, not rejected, per D-38's stated split
```

---

### Q3 — Lesson-select screen (D-31..D-34)

**`focus_neighbor_*` wiring for a `GridContainer` of five buttons** (2 rows: 3 + 2, or
5-in-a-row — geometry is discretion). Set explicitly in `lesson_select.gd`'s `_ready()`, per
D-32's rejection of default tree-order traversal, using the exact property PF9 already proves
works in this codebase:

```gdscript
func _wire_focus_order(buttons: Array[Button]) -> void:
	for i in buttons.size():
		var next := buttons[(i + 1) % buttons.size()]
		var prev := buttons[(i - 1 + buttons.size()) % buttons.size()]
		buttons[i].focus_neighbor_right = buttons[i].get_path_to(next)
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(next)
		buttons[i].focus_neighbor_left = buttons[i].get_path_to(prev)
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(prev)
```

A probe asserts traversal the same way `_case_win_buttons()` already does (PF9): read
`button.focus_neighbor_right`, `get_node()` it, assert identity with the expected next button —
repeat around the full cycle.

**`menu_button.tscn` needs zero scene changes to be instanced five times** (PF10) — set
`label_text` and `icon_kind` per instance from `lesson_select.gd`'s D-33 data table:

```gdscript
# scripts/lesson_select.gd
const LESSONS := [
	{"id": "lesson_1", "path": "res://scenes/lesson_1.tscn", "label": "Les 1", "icon": "lesson_colors"},
	{"id": "lesson_2", "path": "res://scenes/lesson_2.tscn", "label": "Les 2", "icon": "lesson_shapes"},
	{"id": "lesson_3", "path": "res://scenes/lesson_3.tscn", "label": "Les 3", "icon": "lesson_sequence"},
	{"id": "lesson_4", "path": "res://scenes/lesson_4.tscn", "label": "Les 4", "icon": "lesson_colors"},
	{"id": "lesson_5", "path": "res://scenes/lesson_5.tscn", "label": "Les 5", "icon": "lesson_sequence"},
]
```

**New icon kinds** (PF11: adding one is a new `match` arm + one new `_<kind>_shapes()`
function, zero dispatch-mechanism changes). Recommended minimal set, thematically tied to each
lesson's mechanic rather than a literal "1".."5" (exact geometry is discretion):
`"lesson_colors"` (two colour dots, for L1/L4's colour-recognition tasks), `"lesson_shapes"`
(small circle+square+triangle outline, for L2), `"lesson_sequence"` (three ascending dots or an
arrow, for L3/L5). Three new kinds cover all five lessons since L1/L4 share a mechanic and
L3/L5 share a mechanic.

---

### Q4 — Lesson scene structure (D-45)

**`collectible.gd` gives**: a one-shot latch (`_touched`), a player-group guard, a `.call_deferred()`
wrapper around the reaction (required — Area3D forbids toggling `monitoring` synchronously
inside its own `body_entered` callback), and a `reset()` for replay. It does **not** give:
per-instance identity (`task_id`), an inactive/active gate, or a `rejected` signal — those are
D-45's new surface.

**Recommended `scripts/lesson_target.gd`** (reused across L1/L2/L4 directly; L3/L5 reuse the
same script with `requires_activation = true`, satisfying D-45's "sequence-target pattern"
without a second script):

```gdscript
# scripts/lesson_target.gd
extends Area3D

signal task_completed(task_id: String)
signal rejected

@export var task_id: String = ""
@export var target_color: Color = Color.WHITE  # visual only; drives the mesh material
@export var requires_activation: bool = false  # true for L2/L3/L4-ordered/L5 targets
@export var order_number: int = 0  # display-only label; NEVER read for gating logic (D-37)

@onready var _mesh: MeshInstance3D = $Mesh

var _touched := false
var _active := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_active = not requires_activation
	if _mesh.mesh is PrimitiveMesh and _mesh.get_surface_override_material(0) == null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = target_color
		mat.emission_enabled = true
		mat.emission = target_color
		_mesh.set_surface_override_material(0, mat)


func activate() -> void:
	_active = true


func deactivate() -> void:
	_active = false


func _on_body_entered(body: Node3D) -> void:
	if _touched:
		return
	if not body.is_in_group("player"):
		return
	if requires_activation and not _active:
		rejected.emit()
		return
	_apply_touch.call_deferred()


func _apply_touch() -> void:
	_touched = true
	if requires_activation:
		_active = false
	task_completed.emit(task_id)


func reset() -> void:
	_touched = false
	_active = not requires_activation
```

This is D-37's structural fix in code: the orchestrator drives `activate()`/`deactivate()`
explicitly after each `task_completed`, and a target that is not active **cannot** complete —
there is no `_expected_order` counter for the orchestrator to declare and forget to read (the
archived `lesson_2.gd` defect).

**Collision layers:** none needed (PF12, A5) — the group-check guard already required for the
ground/floor overlap is sufficient and matches the shipped, tested Phase 2 pattern. Do not add
layer/mask configuration unless a specific lesson's geometry demonstrates a need a probe
catches.

**`intro_level.gd`'s completion → overlay pattern, mapped to a lesson:**

```gdscript
# scripts/lesson_1.gd (D-35: independent orchestrator, no shared base)
extends Node3D

signal transition_requested(target_path: String)
signal lesson_completed(lesson_id: String, time_seconds: float)

const LESSON_SELECT_PATH := "res://scenes/lesson_select.tscn"

var _completed_tasks: Array[String] = []
var _start_time_msec := 0
var _transitioning := false


func _ready() -> void:
	_start_time_msec = Time.get_ticks_msec()
	%RedTarget.task_completed.connect(_on_task_completed)
	%BlueTarget.task_completed.connect(_on_task_completed)
	%CountTarget.task_completed.connect(_on_task_completed)
	%BackButton.pressed.connect(_on_back_button_pressed)  # D-34: returns to lesson-select


func _on_task_completed(task_id: String) -> void:
	if not _completed_tasks.has(task_id):
		_completed_tasks.append(task_id)
	%ProgressLabel.text = "Stap: %d / 3" % _completed_tasks.size()  # D-36: order-independent
	if _completed_tasks.size() == 3:
		_apply_lesson_complete()


func _apply_lesson_complete() -> void:
	var time_seconds := (Time.get_ticks_msec() - _start_time_msec) / 1000.0
	ProgressTracker.record_lesson_complete("lesson_1", time_seconds)  # PROGRESS-02, before overlay
	lesson_completed.emit("lesson_1", time_seconds)
	%WinLayer.visible = true
	%BackButton2.grab_focus()  # win-overlay's own "Terug naar lessen" control


func _on_back_button_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_requested.emit(LESSON_SELECT_PATH)
	get_tree().change_scene_to_file.call_deferred(LESSON_SELECT_PATH)
```

Recording progress **before** showing the overlay (not after, not on a timer) means D-42's
re-read-from-disk probe can assert the file the instant `%WinLayer.visible` flips true, with no
race against an `await get_tree().create_timer(...)` delay — directly avoiding the archived
"scene transitions after `await` timers" fragility class (`CONVENTIONS.md`/`CONCERNS.md`).

---

### Q5 — Extending the verification chain

**New probes** (auto-discovered by the existing `probe_*.gd` glob in `run_headless_check.sh` —
zero changes needed to that script itself, confirmed by `Read` this session,
`run_headless_check.sh:212-224`):

- `scripts/tools/probe_lesson_select.gd` — focus-order traversal (Q3), five distinct
  `label_text`/`icon_kind` values, "Lessen" button on the main menu reaches it (LESSON-06).
- `scripts/tools/probe_lesson_order.gd` — L2/L3/L5's order enforcement + the negative
  out-of-order case per ordered lesson (Q2), and L1/L4's any-order completion (D-36).
- `scripts/tools/probe_progress_persistence.gd` — D-42's re-read-from-disk assertion after a
  real completion, first-run (no file, PF4), and corrupt-file recovery (PF5/PF6) — this probe
  should plant a deliberately truncated `user://progress.json` before launch (a `--script`
  probe can write one to its own sandboxed `user://` in `_initialize()` before exercising the
  tracker) and assert the tracker starts clean with no `ERROR:` line.

**`test_headless_check.sh`:** the `REQUIRED_PROBES` allow-list gap documented in
`02-RESEARCH.md`'s Q6 is still deliberately absent, and a follow-up is recorded in `STATE.md` —
per the research brief's explicit instruction, this document does not propose implementing it.
The one new self-test case genuinely warranted by this phase's content: a planted
`config/name`-changed `project.godot` proving `probe_progress_persistence.gd` still passes
(because it only exercises the *mechanism*, not a specific directory) — optional, not a Wave 0
blocker.

---

## Pitfalls

Each ties to a documented 2D defect from `03-CONTEXT.md`'s `<specifics>` section.

### Pitfall 1 — `JSON.parse_string()` on a corrupt file trips the headless log-scan even when the code recovers correctly (NEW finding, blocks PROGRESS-01)
**What goes wrong:** the static `JSON.parse_string()` prints an engine `ERROR: Parse JSON
failed...` line to stderr on invalid input (PF5), and `run_headless_check.sh` fails the whole
check on any `ERROR:` match in a probe log. A `ProgressTracker` written the archive's way
(`JSON.parse_string(json_str)`, checking only for `null`) would functionally recover from a
corrupt file but still fail CI the moment a probe exercises that path.
**Why it happens:** the static convenience method conflates "return null" with "log an error,"
whereas the instance method separates them.
**Structural fix:** use `JSON.new()` + `.parse(text)`, check the returned `Error` code, use
`.get_data()` only on `OK` (PF6 — confirmed silent). See Q1's `_load_entries()`.
**Warning signs:** a probe log showing `ERROR: Parse JSON failed` while the printed test result
still says "PASS" — the check would fail before that PASS line is ever reached, so in practice:
`run_headless_check.sh` going red on the progress-persistence probe with no other visible cause.

### Pitfall 2 — `JSON.SINDY_USE_HELPER` doesn't exist (`CONCERNS.md`: parse error at every startup)
**What goes wrong (archived):** `progress_tracker.gd:38` called
`JSON.stringify(data, JSON.SINDY_USE_HELPER)` — a nonexistent constant — so the script failed to
compile and the registered autoload errored at every startup (PROGRESS-01's exact negative).
**Structural fix:** `JSON.stringify(data, "\t")` (PF3 — verified signature, no such constant
exists in 4.7.2).
**Warning signs:** any script referencing an ALL-CAPS `JSON.*` member not in
`https://docs.godotengine.org/en/stable/classes/class_json.html`'s constant list — grep for
`JSON\.[A-Z_]+` outside `JSON.stringify`/`.parse`/`.parse_string` calls.

### Pitfall 3 — Nothing ever calls `record_lesson_complete(...)` (`CONCERNS.md`: progress never written)
**What goes wrong (archived):** the autoload existed and compiled (once Pitfall 2 was fixed),
but no lesson orchestrator ever called it — `docs/parent-dashboard.md` claimed the game already
wrote progress, which was false.
**Structural fix:** every lesson's `_apply_lesson_complete()`-equivalent calls
`ProgressTracker.record_lesson_complete(...)` **before** showing the win overlay (Q4) — not
gated behind an `await` timer, so D-42's probe has no race to lose.
**Warning signs:** grep for `record_lesson_complete(` outside the five lesson scripts; zero
hits outside them (or fewer than five call sites, one per lesson) is the regression.

### Pitfall 4 — `_expected_order` declared and never read (`CONCERNS.md`/`lesson_2.gd`: any order completed)
**What goes wrong (archived):** the array existed, was never consulted; every target was always
touchable regardless of the child's actual order.
**Structural fix:** D-37/D-38's `activate()`/`deactivate()` gate on the **target itself**
(Q4's `lesson_target.gd`), not a counter the orchestrator promises to check. A target that is
`not _active` structurally cannot emit `task_completed` — it can only emit `rejected`.
**Warning signs:** the negative-case probe (Q2) is the direct regression test — if it stops
failing loudly when a target is touched out of order, the fix has regressed.

### Pitfall 5 — Cross-script private-method calls and lost label text (`CONCERNS.md`/`sequence_target.gd`)
**What goes wrong (archived):** `lesson_3.gd` called `target_2._set_inactive()` (a private
method, cross-script) and the error-flash path overwrote the target's own label with
`str(order_number)`, permanently losing the original text after the first wrong touch.
**Structural fix:** `activate()`/`deactivate()`/`reset()` are **public** methods on
`lesson_target.gd` (Q4) — no orchestrator ever touches a private (`_`-prefixed) member on
another script. Because `rejected` is a signal, not an in-place mutation, there is no shared
mutable label state to corrupt; any error-flash visual feedback should be implemented as a
tween on the mesh material, not a label-text overwrite.
**Warning signs:** grep for `._[a-z]` cross-script calls in any new lesson script.

### Pitfall 6 — 10-line stubs advertised as available (`CONCERNS.md`: `lesson_4.gd`/`lesson_5.gd`)
**What goes wrong (archived):** `_ready(): pass` stubs whose scenes said "Nu beschikbaar."
**Structural fix:** D-43/D-44 give both lessons a concrete, real rule (second colour+count;
four-step sequence) — LESSON-04/05 are explicit requirements this phase must satisfy with
working completion logic, reusing L1's/L3's mechanisms respectively (Q4). No stub may ship.
**Warning signs:** `quality_gate.py`'s forbidden-phrase scan does **not** catch "Placeholder"
text (documented gap in `CONCERNS.md`) — this must be caught by the lesson-order probe actually
driving each lesson to completion, not by the quality gate.

### Pitfall 7 — Lessons 2-5 unreachable (`CONCERNS.md`: main menu only ever linked lesson_1)
**What goes wrong (archived):** no scene/script referenced `lesson_2..5.tscn`.
**Structural fix:** D-33's typed const array in `lesson_select.gd` is the single source of
truth for every lesson's path, consumed by both the button-instancing loop and (implicitly) a
probe that can iterate the same array to confirm every path resolves and loads
(`ResourceLoader.exists()` + `load()` per entry).
**Warning signs:** a probe that hardcodes only "lesson_1" and never iterates the table would
reproduce exactly this blind spot in test form — iterate `LESSONS`, not a literal list.

### Pitfall 8 — D-46's three-sub-task label form vs. L5's four-step sequence (open reconciliation, flagged by CONTEXT.md itself)
**What goes wrong if unresolved:** hardcoding `"Stap: %d / 3"` into a shared helper and reusing
it verbatim for L5 produces a visibly wrong "Stap: 4 / 3" the moment the fourth step completes.
**Recommended resolution (this research's recommendation — CONTEXT.md requires the planner to
record the choice explicitly, not silently pick one):** keep one shared label **format**,
parametrize the total: `"Stap: %d / %d" % [current, total]`, where `total` is a per-lesson
constant (`3` for L1-L4, `4` for L5). This honors D-46's "one progress-label form covers every
lesson" literally (same template string, same call site shape in every orchestrator) while
staying correct for L5. The alternative — treating L5's four steps as three scored sub-tasks by
merging two into one "stage" — would misrepresent LESSON-05's actual four-step sequence rule to
the child and to any probe asserting step count, and is not recommended.
**Warning signs:** any lesson-5 probe asserting `%ProgressLabel.text == "Stap: 4 / 3"` (wrong on
its face) instead of `"Stap: 4 / 4"`.

---

## Recommended Task Decomposition

Worktree isolation flags for real parallelism, following the same file-overlap discipline
`02-RESEARCH.md` established.

**Strictly ordered (Wave 0 — nothing else can be probed without these):**
1. **`scripts/lesson_target.gd`** (Q4) — the shared reusable target script every lesson depends
   on. New file, no scene dependency yet.
2. **`scripts/progress_tracker.gd`** (Q1) — new file (or autoload registration in
   `project.godot`), no lesson dependency. Can build in parallel with task 1 (disjoint files).
3. **`scenes/lesson_select.tscn` + `scripts/lesson_select.gd`** (Q3, D-31..D-34) — depends on
   `menu_button.tscn` (existing, read-only) but not on tasks 1/2. Genuinely parallel with 1/2.

**Five genuinely independent lesson builds after Wave 0 (distinct scene+script pairs, real parallelism):**
- **L1** (`scenes/lesson_1.tscn`, `scripts/lesson_1.gd`) — depends on `lesson_target.gd` +
  `progress_tracker.gd` (read-only deps on Wave 0 output), not on L2-L5's files.
- **L2** (`scenes/lesson_2.tscn`, `scripts/lesson_2.gd`) — same dependency shape, uses
  `lesson_target.gd`'s `requires_activation = true` path.
- **L3** (`scenes/lesson_3.tscn`, `scripts/lesson_3.gd`) — same shape as L2.
- **L4** (`scenes/lesson_4.tscn`, `scripts/lesson_4.gd`) — reuses L1's completion logic
  directly (D-43); genuinely independent files from L1 itself, so still a parallel wave slot,
  not a dependency on L1's plan landing first (only on `lesson_target.gd`).
- **L5** (`scenes/lesson_5.tscn`, `scripts/lesson_5.gd`) — reuses L3's shape (D-44) with 4
  targets instead of 3; same independence argument as L4.

**File-level overlap warning:** `scenes/main_menu.tscn`/`scripts/main_menu.gd` are touched by
the lesson-select wave (adding the "Lessen" button) — if `main_menu.gd` is mid-edit by another
concurrent phase-3 task, sequence the lesson-select task after it, or fold the one-line button
addition into the same task that builds `lesson_select.tscn`.

**Convergent, strictly after all five lessons + lesson-select + progress-tracker land:**
- **Verification-chain plan:** `probe_lesson_select.gd`, `probe_lesson_order.gd`,
  `probe_progress_persistence.gd` (Q5) — each probe instantiates scenes from every prior wave,
  so this is necessarily last. Bundling all three new probes in one plan keeps "verification
  chain" coherent, matching Phase 2's own precedent.

---

## Validation Architecture

### Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Still none for GDScript — the headless check chain remains the de facto framework: `run_headless_check.sh` (import → main scene → `verify_3d_project.gd` → every `probe_*.gd`) + `test_headless_check.sh` self-test. Python stdlib `unittest` for `tests/test_quality_gate.py`, unchanged. |
| Config file | none |
| Quick run command | `python3 scripts/tools/quality_gate.py --root .` |
| Full suite command | `bash scripts/tools/run_headless_check.sh` (unchanged invocation; probe glob grows from 2 probes to 5) |
| Runtime | Same watchdog ceilings as Phase 2 (`IMPORT_LIMIT=180s`, `RUN_LIMIT=60s`, `VERIFY_LIMIT=60s`, `PROBE_LIMIT=120s` per probe); observed real runtime stays low-single-digit-seconds per probe once assets import cleanly (Phase 1/2 precedent) — no new asset-import-heavy work this phase (no new audio/textures), so no material runtime growth expected beyond 3 more probe invocations at ~120s ceiling each (worst case), a few seconds in practice. |

### Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LESSON-01 | L1 completes regardless of task order | automated (headless probe) | `bash scripts/tools/run_headless_check.sh` (`probe_lesson_order.gd`'s L1 any-order case) | ❌ Wave 0 — probe doesn't exist |
| LESSON-02 | L2 only completes circle→square→triangle in order | automated (headless probe, incl. negative case) | same file, L2 case (Q2 shape) | ❌ Wave 0 |
| LESSON-03 | L3 only completes in defined order | automated (headless probe, incl. negative case) | same file, L3 case | ❌ Wave 0 |
| LESSON-04 | Real, completable second colour+count task | automated (headless probe) | same file, L4 case (reuses L1's assertion shape) | ❌ Wave 0 |
| LESSON-05 | Real, completable four-step sequence | automated (headless probe, incl. negative case) | same file, L5 case (reuses L3's assertion shape, `total=4` per Pitfall 8) | ❌ Wave 0 |
| LESSON-06 | Lesson-select reachable, all 5 by tap/click/keyboard | automated (headless probe) | `probe_lesson_select.gd` — focus-order traversal + each button's `transition_requested` (Q1's pattern from `02-RESEARCH.md`) | ❌ Wave 0 |
| PROGRESS-01 | Tracker initializes without script error | automated (headless probe + log-scan) | `run_headless_check.sh`'s own `ERROR:`/`SCRIPT ERROR:`/`Parse Error:` grep across every log, plus `probe_progress_persistence.gd`'s first-run/corrupt-file cases (PF4-PF6) | ❌ Wave 0 |
| PROGRESS-02 | Completion writes all 4 fields to `user://progress.json` | automated (headless probe, re-reads disk per D-42) | `probe_progress_persistence.gd`'s post-completion re-read case (Q1) | ❌ Wave 0 |

### Sampling Rate

- **After every task commit:** `python3 scripts/tools/quality_gate.py --root .`
- **After every plan wave:** `bash scripts/tools/run_headless_check.sh`
- **Before `/gsd-verify-work`:** `bash scripts/tools/run_headless_check.sh && bash scripts/tools/test_headless_check.sh` green, plus one short human playtest (all 5 lessons reachable and completable, progress visibly persists across a relaunch — the one thing headless probes cannot observe: a real second process launch reading back the first process's write)
- **Max feedback latency:** ~150-200s (full-suite observed ceiling, 5 probes instead of 2)

### Wave 0 Requirements

- [ ] `scripts/lesson_target.gd` (Q4) — blocks every lesson build.
- [ ] `scripts/progress_tracker.gd` (Q1) — blocks every lesson's completion handler and both
      PROGRESS probes.
- [ ] `scenes/lesson_select.tscn` + `scripts/lesson_select.gd` (Q3) — blocks LESSON-06's probe
      and the "Lessen" button wiring on `main_menu.tscn`.
- [ ] Godot 4.7.2 local install — unchanged carry-over prerequisite.

*Everything else (the five lesson scenes' exact geometry, icon content, Dutch strings) is
ordinary plan/task work, verified incrementally per lesson as each lands.*

### Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| Progress genuinely persists across a real app relaunch (not just within one headless process) | PROGRESS-02 | A `--headless --script` probe writes and reads within the same process; it cannot prove the OS-level file survives a full process exit and a fresh launch reading `user://` fresh, though PF1-PF8 make this very low-risk given the mechanism is plain `FileAccess` on a real path | Launch the built game, complete one lesson, quit fully, relaunch, and (informally, e.g. via a debug print or the eventual Phase 8 dashboard) confirm the entry is still present |
| All 5 lessons feel completable and fair to a real child, tap/click/keyboard | LESSON-01..06 | Feel and pacing cannot be judged headlessly (Dummy driver, no real display) | Play through lesson-select → each of the 5 lessons → confirm completion, using both pointer and keyboard at least once | <!-- quality-gate: allow forbidden-phrase -->

---

## Sources

### Primary (HIGH confidence)
- This session's `mktemp -d` scratch-project runs against the installed Godot 4.7.2.stable
  binary (PF1-PF8) — persistence, JSON, and atomic-rename behavior.
- `Read` of this repo's own shipped, tested code this session: `scripts/tools/probe_screen_flow.gd`,
  `scripts/ui/menu_button.gd`, `scripts/ui/vector_icon.gd`, `scripts/collectible.gd`,
  `scripts/finish_marker.gd`, `scripts/intro_level.gd`, `scripts/camiel_controller.gd`,
  `scripts/tools/verify_3d_project.gd`, `scripts/tools/run_headless_check.sh`, `project.godot`.
- `01-ENGINE-FACTS.md` (F1-F11) and `02-RESEARCH.md` (VF1-VF23) — carried-over engine facts
  re-cited where directly relevant (collision defaults, `--headless`/`--fixed-fps` requirements,
  `Area3D` deferred-toggle rule).

### Secondary (MEDIUM confidence)
- Archived 2D scripts (`git show archive/2d-alpha-v0.0.3:...`) — used only for the documented
  defect mechanisms and Dutch string tone, never as a porting source (D-13).

### Tertiary (LOW confidence)
- Icon content/geometry recommendations (Pitfall/Q3) — Claude's Discretion per CONTEXT.md, not
  independently verified against any external source.

## Metadata

**Confidence breakdown:**
- Persistence (Q1): HIGH — every load-bearing call verified against the real engine this session.
- Order enforcement (Q2): HIGH for the mechanism (reuses an already-shipped, tested pattern);
  MEDIUM for exact per-lesson probe timing not independently re-measured (A1).
- Lesson-select (Q3): HIGH — every claim is a direct `Read` of already-shipped, tested code.
- Lesson target script (Q4): HIGH for the mechanism (directly derived from `collectible.gd`'s
  proven shape plus D-37/D-38's explicit requirements); LOW/discretion for exact geometry.
- D-46 reconciliation (Pitfall 8): a recommendation, not a verified fact — flagged for planner
  sign-off per CONTEXT.md's own instruction.

**Research date:** 2026-09-12
**Valid until:** 30 days (stable engine, no external dependency churn expected)




