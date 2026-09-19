---
phase: 03-3d-lesson-parity-progress-persistence
plan: 04
subsystem: 3d-gameplay
tags: [godot, gdscript, area3d, headless-probe, order-enforcement, persistence]

requires:
  - phase: 03-3d-lesson-parity-progress-persistence
    provides: "plan 03-01's ProgressTracker autoload (record_lesson_complete, atomic write) and its probe backup/restore hygiene"
  - phase: 03-3d-lesson-parity-progress-persistence
    provides: "plan 03-02's scripts/lesson_target.gd + scenes/lesson_target.tscn (the D-37/D-38 activation gate, activate/deactivate/is_active, the rejected signal), scenes/lesson_room.tscn, scripts/ui/lesson_hud.gd + scenes/ui/lesson_hud.tscn"
  - phase: 03-3d-lesson-parity-progress-persistence
    provides: "plan 03-03's const LESSONS table in scripts/lesson_select.gd, scripts/lesson_1.gd's orchestrator shape, and probe_lesson_order.gd's _open_lesson / _touch_target / _read_progress_file / _assert_last_entry / _disk_entry_count / _assert_win_return_is_one_shot / backup-restore helpers"
provides:
  - "scripts/lesson_2.gd + scenes/lesson_2.tscn — lesson 2: circle, square, triangle enforced structurally by an array of the target nodes that is used to activate, with no identifier comparison anywhere (LESSON-02, D-37, D-38)"
  - "scripts/lesson_3.gd + scenes/lesson_3.tscn — lesson 3: the same shape over three numbered targets, and the shape plan 03-05's four-step lesson 5 reuses (LESSON-03, D-44)"
  - "two appended rows in const LESSONS, so the lesson-select screen, its focus cycle and its probe cover both new lessons with no edit to either probe's own lesson-select coverage"
  - "probe_lesson_order.gd's ordered-lesson case shape: _drive_ordered_lesson, _assert_only_active, _assert_colour_is_not_the_cue, _assert_space_key_reaches_nothing, _assert_in_play_return_is_one_shot, _touch_for_refusal, _park, _step_label_text"
affects: [03-05, 03-06, 08-parent-dashboard]

actuals:
  tokens: 10979
  tasks: 2
  commits: 3
  plan_head_before: 982e8fc3077795400093280844ea1a3393e0dc40

tech-stack:
  added: []
  patterns:
    - "An ordered rule is enforced by an array of the target NODES that is read to activate the next one, never by comparing an arriving identifier: the orchestrator has no branch on which task arrived, so there is no declared-and-never-read order to forget (D-37)"
    - "A negative probe case leads with the wrong order and asserts a refusal plus zero completions plus an unmoved label BEFORE it ever drives the correct order; a correct-order-only case would have passed on the archived defect"
    - "Asserting `exactly one target reports itself active` after every completion turns 'the wrong target was refused' into 'the wrong target was never live', which is the stronger claim D-37 actually makes"
    - "A probe reconstructs a label from its parts rather than reusing the display's own format string, so the format string survives in exactly one .gd file and the probe can still catch the display changing it"
    - "One shared probe helper drives both ordered lessons, so a regression in the shared activation gate fails both cases; the lessons' own orchestrators stay separate files (D-35)"
    - "A load-modify-repack generator seeded from an already-shipped sibling scene (instantiate lesson_1.tscn, swap the script, strip its own targets, add new ones, pack, save) inherits the room, spawn, character and display setup exactly, so the only reviewable difference between two lessons' scene files is their targets"

key-files:
  created:
    - scripts/lesson_2.gd
    - scripts/lesson_2.gd.uid
    - scenes/lesson_2.tscn
    - scripts/lesson_3.gd
    - scripts/lesson_3.gd.uid
    - scenes/lesson_3.tscn
  modified:
    - scripts/lesson_select.gd
    - scripts/tools/probe_lesson_order.gd

key-decisions:
  - "The lesson table grew by APPEND to exactly three rows, and only for scenes that exist on disk. No row for lesson 4 or 5, no disabled button, no not-yet-available caption: that exact shape is the archived defect, where lesson 4's scene advertised availability above a _ready(): pass stub. probe_lesson_select.gd load()s and instantiate()s every table path asserting Node3D, so a premature row fails loudly rather than producing a broken button."
  - "Lessons 2 and 3 are ordered lessons (D-37/D-38), so 'completes from more than one order' is answered the way the plan's must-have truths require: each lesson is driven from THREE distinct orders in one case -- two different wrong-first touches, each proved to refuse and complete nothing, and then the correct order proved to complete. For lesson 2 that is square-first and triangle-first; for lesson 3, third-first and second-first, deliberately different from lesson 2's so the two lessons are not exercised by the same wrong guess."
  - "Both orchestrators are byte-for-byte the same shape over different targets, and the duplication is deliberate and recorded rather than removed. D-35 keeps the five orchestrators independent this phase and MORE-02's shared lesson pattern is explicitly phase 9's scope. No base script, no global class name and no helper autoload was extracted."
  - "The refusal signal is deliberately NOT connected in either orchestrator. The target's own scale dip is the whole of a child's feedback (D-38, calm prohibition), and leaving the signal with exactly one listener is what makes the probe's connection-count assertions (2 on every completion, 1 on every refusal) meaningful rather than decorative."
  - "A new probe assertion beyond the plan: every target in an ordered lesson shares ONE colour and the targets are nonetheless distinguishable by shape or numeral. Without it, 'lesson 2 is a shape lesson' and 'lesson 3 is a counting lesson' were only true by inspection of the generator; both lessons would have collapsed into 'touch the orange one' if a later edit recoloured a target, and nothing would have failed."

requirements-completed: []

requirements-advanced:
  - id: LESSON-02
    state: "Closed in behaviour and proved from three distinct task orders including two negatives, but left UNCHECKED in REQUIREMENTS.md because plan 03-06 also carries this ID (its convergent pass re-asserts all five lessons)."
  - id: LESSON-03
    state: "Closed in behaviour, with the numeral-intact regression test for the archived error-flash defect, but left UNCHECKED because plan 03-06 also carries this ID."
  - id: LESSON-06
    state: "The table now holds three of five lessons. It cannot be true while two lessons are unbuilt, so it stays unchecked; plans 03-05 and 03-06 carry it."
  - id: PROGRESS-02
    state: "Closed for real lesson-2 and lesson-3 completions, each read back off the disk with all four fields and each proved to APPEND (entry count before/after). Left unchecked because plans 03-05 and 03-06 carry it for lessons 4 and 5."

coverage:
  - id: D1
    description: "Lesson 2 completes only on circle, square, triangle, and the wrong order is proved to do nothing: the square and then the triangle are each touched before their turn, each refuses exactly once, completes nothing, and leaves the progress label at Stap: 0 / 3"
    requirement: LESSON-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_lesson_2_order_enforced (negative half, driven before the correct order)"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's RED Evidence, 'the gate removed on purpose' -- the square's activation requirement was temporarily dropped and the case failed on the refusal assertion by name"
        status: pass
    human_judgment: true
    rationale: "The gate-removal demonstration was run once interactively against a temporary, fully-reverted scene edit rather than baked in, because a permanently ungated target would itself be the defect this assertion forbids. A human should confirm the reasoning, not just the exit code."
  - id: D2
    description: "A shape refused once is still completable when its turn arrives: the square lesson 2 completes at step 2 is the very target that refused at step 0, and its refusal counter is still exactly 1 at the end of the run"
    requirement: LESSON-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_drive_ordered_lesson (post-run refusal-count assertion)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Lesson 3 completes only on its defined order, with the same structural gate and the same negative proof from a different wrong guess (third target first, then second)"
    requirement: LESSON-03
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_lesson_3_order_enforced"
        status: pass
    human_judgment: false
  - id: D4
    description: "A refused target's own displayed text is unchanged -- lesson 3's Step3Target still reads 3 after refusing, which is a direct regression test for the archived sequence_target.gd error flash that overwrote a target's label with str(order_number) and lost the text permanently"
    requirement: LESSON-03
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_drive_ordered_lesson (per-refusal text assertion, plus a whole-run re-assertion at the end)"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's RED Evidence, 'the archived label-overwrite defect reintroduced' -- both lessons' assertions failed by name, and 03-02's probe_lesson_kit.gd caught it too"
        status: pass
    human_judgment: true
    rationale: "Demonstrated once against a temporary, byte-identically reverted edit to scripts/lesson_target.gd. A permanent overwrite would be the defect itself."
  - id: D5
    description: "No expected-order value and no identifier comparison exists in either orchestrator -- the order lives in an array of the target nodes and that array is used to activate, which is the one thing the archived lesson failed to do"
    requirement: LESSON-02
    verification:
      - kind: unit
        ref: "grep acceptance criteria on both files: zero non-comment lines matching 'expected' (case-insensitive), zero matching 'task_id ==' or 'task_id !=', zero matching 'rejected', and _sequence[_step].activate() present"
        status: pass
    human_judgment: false
  - id: D6
    description: "After every completion exactly one target reports itself active -- the next in the order -- and after the last one none does; the wrong target is not merely refused, it is never live"
    requirement: LESSON-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_only_active, called at lesson open, after every refusal and after every completion in both cases"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's RED Evidence -- with the square's gate removed this assertion fired first, by name, before the refusal assertion was even reached"
        status: pass
    human_judgment: true
    rationale: "Same temporary-and-reverted demonstration as D1."
  - id: D7
    description: "Completing lesson 2 and completing lesson 3 each write their own entry to user://progress.json, read back off the disk with a FileAccess handle and JSON.new().parse(), asserting lesson id, three stars, a positive elapsed time and a non-empty timestamp -- and each proved to APPEND by the entry count before and after"
    requirement: PROGRESS-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_drive_ordered_lesson (_assert_last_entry plus the entries_before + 1 assertion), called from both cases"
        status: pass
    human_judgment: false
  - id: D8
    description: "No private member of the target or display script is read or called from either orchestrator; activation, deactivation and the active state are reached only through their public surface"
    requirement: LESSON-03
    verification:
      - kind: unit
        ref: "grep: zero non-comment lines matching '\\._[a-z]' in scripts/lesson_2.gd and scripts/lesson_3.gd"
        status: pass
    human_judgment: false
  - id: D9
    description: "Both of each lesson's return controls go to lesson-select, not the main menu, each through one guarded, deferred transition -- the win panel's control on the finished lesson, and the in-play control on a fresh unfinished instance"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_win_return_is_one_shot (win panel) and #_assert_in_play_return_is_one_shot (in-play, fresh instance), both called from both cases"
        status: pass
      - kind: unit
        ref: "grep: zero occurrences of res://scenes/main_menu.tscn in scripts/lesson_2.gd and scripts/lesson_3.gd"
        status: pass
    human_judgment: false
  - id: D10
    description: "No focusable control is alive or focused during 3D play in either lesson, so the space key -- bound to both jump and ui_accept -- cannot end a lesson under a child's feet; asserted as the consequence (no focus owner, three accept presses changing nothing) rather than as a setting"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_space_key_reaches_nothing, called from both cases before a single target is touched"
        status: pass
    human_judgment: false
  - id: D11
    description: "Both new lessons are in the one table the screen and its probe read, so a third and a second button, their labels, icons, focus cycle, transitions and scene-loadability are all covered with no edit to probe_lesson_select.gd"
    requirement: LESSON-06
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_select.gd#_case_lesson_table_drives_buttons and #_case_lesson_button_transitions (both iterate the table and name no lesson)"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's GREEN Evidence -- an out-of-band read of the live screen printed 3 table rows and 3 grid children with their labels and icons, rather than the count being assumed from a passing probe"
        status: pass
    human_judgment: true
    rationale: "The plan required the two- and three-button screen to be confirmed in output rather than assumed, while requiring probe_lesson_select.gd itself to need no change. Confirmed with a throwaway read-only script, deleted after use."
  - id: D12
    description: "Colour is never the cue in an ordered lesson: all three targets share one colour, and they are told apart by shape (lesson 2) or by numeral (lesson 3)"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_colour_is_not_the_cue, called from both cases"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-13
status: complete
---

# Phase 3 Plan 4: Lessons 2 and 3, Order Enforced Structurally Summary

**A child who steps on the square before the circle feels it shrink away from them and nothing else happens at all — and the proof of that is two negatives driven before either lesson's correct order is ever touched, because a correct-order-only test would have passed on the archived code this phase exists to replace.**

## Performance

- **Duration:** ~50 min
- **Tasks:** 2 completed
- **Commits:** 3 — two task commits plus this metadata commit (measured: `git rev-list --count 982e8fc..HEAD`, which includes the metadata commit, so `actuals.commits` is 3 rather than the 2 task commits listed below)
- **Files:** 6 created, 2 modified

## Accomplishments

- `scripts/lesson_2.gd` and `scripts/lesson_3.gd`: the order is an `@onready var _sequence: Array[Area3D]` holding the target nodes themselves, and it is **used** — `_sequence[_step].activate()` in the ready callback for the first turn and again on every advance. There is no comparison of an arriving identifier anywhere in either file, deliberately: a comparison is exactly what the archived `lesson_2.gd` declared and never read, and leaving one in would invite the next reader to mistake it for the mechanism.
- `scenes/lesson_2.tscn`: a cylinder, a box and a prism in one accent orange, all three requiring activation — including the circle, which the orchestrator activates in its own ready callback so all three targets are uniform and the advance has exactly one code path.
- `scenes/lesson_3.tscn`: three cylinders showing `1`, `2` and `3` in one strong blue, so the numeral is the cue and the hue never is.
- `const LESSONS` grew by two appended rows to exactly three. Nothing else in `scripts/lesson_select.gd` changed — the whole diff for both tasks is two added lines.
- `scripts/tools/probe_lesson_order.gd` gained the ordered-lesson case shape: `_drive_ordered_lesson` leads with the negative half, then walks the correct order asserting the exact label and the single live target after every step, then reads the disk, then drives both return controls.

## The lesson table holds exactly three rows

```gdscript
const LESSONS: Array[Dictionary] = [
	{"id": "lesson_1", "path": "res://scenes/lesson_1.tscn", "label": "Les 1", "icon": "lesson_colors"},
	{"id": "lesson_2", "path": "res://scenes/lesson_2.tscn", "label": "Les 2", "icon": "lesson_shapes"},
	{"id": "lesson_3", "path": "res://scenes/lesson_3.tscn", "label": "Les 3", "icon": "lesson_sequence"},
]
```

`lesson_4.tscn` and `lesson_5.tscn` do not exist, so a row for them would be a promise the screen cannot keep. No disabled button and no "not yet available" caption was written either — that is precisely the archived shape, where lesson 4's scene advertised availability above a `_ready(): pass` stub. Plan 03-05 appends its two rows with its two scenes. `grep -c 'lesson_4\|lesson_5' scripts/lesson_select.gd` returns zero.

## Order-independence: how it is answered for two ordered lessons

The phase's headline defect is a lesson that soft-locks or cannot be finished from a legitimate order. Lessons 2 and 3 have a **genuinely required** sequence (D-37/D-38), so the second half of that requirement applies: the wrong-order touch is proved to refuse and complete nothing, and the correct order is proved still to complete. Both are driven, per lesson, in one case:

| Lesson | Order 1 (wrong) | Order 2 (wrong) | Order 3 (correct) |
|--------|-----------------|-----------------|-------------------|
| 2 | square first → refused once, 0 completions, label still `Stap: 0 / 3` | triangle first → refused once, 0 completions, label still `Stap: 0 / 3` | circle → square → triangle, labels `1 / 3`, `2 / 3`, `3 / 3`, one completion |
| 3 | third target first → refused once, 0 completions, label unmoved, numeral still `3` | second target first → refused once, 0 completions, label unmoved, numeral still `2` | `1` → `2` → `3`, labels `1 / 3`, `2 / 3`, `3 / 3`, one completion |

The wrong guesses differ between the two lessons on purpose, so one shared bug cannot be hidden by one shared wrong touch. And the square lesson 2 completes at step 2 is **the same target that refused at step 0** — proof that a child's wrong first guess consumed nothing. Its refusal counter is re-asserted as exactly 1 after the whole run.

The stronger claim is also asserted: `_assert_only_active` runs at lesson open, after every refusal and after every completion, and requires that exactly one target reports itself active (and after the last completion, none). A wrong target is not merely refused after the fact — it is never live.

## Task Commits

1. **Task 1 (tracer): Lesson 2 refuses a shape out of turn and completes only circle, square, triangle** — `5a0a79d` (feat)
2. **Task 2: Lesson 3 walks 1, 2, 3 and refuses anything out of turn** — `57168f2` (feat)

## RED Evidence

**Task 1 — RED (lesson 2 does not exist).** The `lesson_2_order_enforced` case was written first and `bash scripts/tools/run_headless_check.sh` run against it:

```
PASS lesson_1_guards
ERROR: lesson_2_order_enforced: res://scenes/lesson_2.tscn does not exist
   GDScript backtrace (most recent call first):
       [0] _fail (res://scripts/tools/probe_lesson_order.gd:97)
       [1] _open_lesson (res://scripts/tools/probe_lesson_order.gd:197)
       [2] _drive_ordered_lesson (res://scripts/tools/probe_lesson_order.gd:620)
       [3] _case_lesson_2_order_enforced (res://scripts/tools/probe_lesson_order.gd:1201)
```

**Task 1 — the gate removed on purpose (two sub-runs).** `requires_activation = true` was temporarily deleted from `SquareTarget` in `scenes/lesson_2.tscn`, reproducing an ungated target. The **live-target** assertion fired first, before the refusal assertion was even reached:

```
CHECK FAILED: probe probe_lesson_order.gd: Godot exited with status 1
ERROR: lesson_2_order_enforced: SquareTarget reports itself active while the only live
target should be CircleTarget -- exactly one target is live at a time (D-37)
   GDScript backtrace (most recent call first):
       [0] _fail (res://scripts/tools/probe_lesson_order.gd:97)
       [1] _assert_only_active (res://scripts/tools/probe_lesson_order.gd:554)
```

To prove the **refusal** assertion itself bites rather than relying on the earlier guard, the two `_assert_only_active(case_name, targets, 0)` calls were temporarily short-circuited and the check re-run with the gate still removed:

```
CHECK FAILED: probe probe_lesson_order.gd: Godot exited with status 1
ERROR: lesson_2_order_enforced: touching SquareTarget before its turn refused 0 times
within 120 physics frames, exactly 1 wanted -- a wrong-order touch that is never refused
is the archived defect
```

Both files were restored immediately. `scripts/tools/probe_lesson_order.gd` re-checksummed to `3cc571cafee551802078b64d2949f7e76900ff2f5f0c9da82c5a0a31284cd1d5` and `scenes/lesson_2.tscn` to `9bf9457591e891b02a6810d9dadcee5f8d8cee92bf40eef39dc657bf283869e5`, both identical to the pre-exercise values; `grep -c 'RED-EXERCISE'` returns zero in both and `grep -c 'requires_activation = true' scenes/lesson_2.tscn` returns 3.

**Task 2 — RED (lesson 3 does not exist).**

```
CHECK FAILED: probe probe_lesson_order.gd: Godot exited with status 1
ERROR: lesson_3_order_enforced: res://scenes/lesson_3.tscn does not exist
```

**Task 2 — the archived label-overwrite defect reintroduced.** `_play_rejection_feedback()` in `scripts/lesson_target.gd` was temporarily given `_label.text = task_id`, reproducing the archived `sequence_target.gd` error flash that replaced a target's label with `str(order_number)`. Three independent assertions caught it. 03-02's own kit probe first:

```
ERROR: activation_gate_refuses_then_allows: target1's label reads t1 after rejection,
expected 1 -- rejection must never touch the label
```

then lesson 2's:

```
ERROR: lesson_2_order_enforced: refusing SquareTarget changed its own displayed text
from  to square -- the archived sequence target destroyed its own label on an error flash
```

and, with the lesson 2 case temporarily skipped so lesson 3's could be reached, lesson 3's numeral assertion — the one written specifically for this recorded defect:

```
ERROR: lesson_3_order_enforced: refusing Step3Target changed its own displayed text
from 3 to step_3 -- the archived sequence target destroyed its own label on an error flash
```

`scripts/lesson_target.gd` was restored to `0e53159ef4648956d24cb9376fb8f9365ea301c00076da3c0efe56e428712677` and `scripts/tools/probe_lesson_order.gd` to `58e483c3c8b102966c7a59b0a3e71f1542700e5dd8cf86af7de4a65fda436e1f`, both byte-identical to the pre-exercise values. `git diff -- scripts/lesson_target.gd` is empty: the shared target script is unchanged by this plan.

## GREEN Evidence

```
PASS lesson_1_count_first
PASS lesson_1_other_orders
PASS lesson_1_guards
[probe_lesson_order] lesson_2_order_enforced shapes ["cylinder", "box", "prism"], texts ["", "", ""], one shared colour (0.9294, 0.6196, 0.302, 1.0)
[probe_lesson_order] lesson_2_order_enforced out-of-turn refusal on SquareTarget: 2 frames
[probe_lesson_order] lesson_2_order_enforced out-of-turn refusal on TriangleTarget: 2 frames
[probe_lesson_order] lesson_2_order_enforced last progress entry: {
	"completed_at": "2026-09-13T01:14:40",
	"lesson_id": "lesson_2",
	"stars": 3.0,
	"time_seconds": 0.041
}
PASS lesson_2_order_enforced
[probe_lesson_order] lesson_3_order_enforced shapes ["cylinder", "cylinder", "cylinder"], texts ["1", "2", "3"], one shared colour (0.13, 0.35, 0.82, 1.0)
[probe_lesson_order] lesson_3_order_enforced out-of-turn refusal on Step3Target: 2 frames
[probe_lesson_order] lesson_3_order_enforced out-of-turn refusal on Step2Target: 2 frames
[probe_lesson_order] lesson_3_order_enforced last progress entry: {
	"completed_at": "2026-09-13T01:14:40",
	"lesson_id": "lesson_3",
	"stars": 3.0,
	"time_seconds": 0.027
}
PASS lesson_3_order_enforced
Lesson order probe passed.

PASS main_menu_opens_lesson_select
PASS lesson_table_drives_buttons
PASS lesson_button_transitions
Lesson select probe passed.
```

**The two JSON entries read back off the disk** are the blocks above. Each is read with a `FileAccess` handle and `JSON.new().parse()` — never `JSON.parse_string()`, whose engine `ERROR:` line would fail the headless check even on a correct path. `lesson_id` is `lesson_2` / `lesson_3`, `stars` is 3, `time_seconds` is positive, `completed_at` is a non-empty timestamp. `stars` prints as `3.0` only because the probe re-parses the file before printing and Godot's JSON module returns every number as float on parse; the on-disk bytes hold plain JSON integers. Each case asserted the disk entry **count** before and after its completion and required exactly `+1`, so an append is proved rather than an overwrite.

**The lesson-select screen, read out of band rather than assumed.** The plan required the growing screen to be confirmed in output while `probe_lesson_select.gd` itself needed no edit. A throwaway read-only script opened the live screen and printed what it actually built — after Task 1:

```
[confirm] LESSONS table rows: 2
[confirm] %LessonGrid children: 2 -> ["lesson_1(label=Les 1, icon=lesson_colors)", "lesson_2(label=Les 2, icon=lesson_shapes)"]
```

and after Task 2:

```
[confirm] LESSONS table rows: 3
[confirm] %LessonGrid children: 3 -> ["lesson_1(label=Les 1, icon=lesson_colors)", "lesson_2(label=Les 2, icon=lesson_shapes)", "lesson_3(label=Les 3, icon=lesson_sequence)"]
```

`probe_lesson_select.gd` is unchanged by this plan (`git diff` shows no change to it at all); it gained coverage of both new lessons purely from the two appended table rows.

**Measured frame counts** (fixed 60fps headless): teleport-to-refusal was 2 physics frames for every out-of-turn touch in both lessons, and teleport-to-completion 3 or fewer — well inside the 120-frame ceiling the shipped probes use. 03-02 measured 3 frames for a refusal on a bare target in the kit probe; 2 here, inside a real lesson.

## Target spacing

03-03 recorded that two 0.55-radius target areas overlap below 1.1 m apart, so one teleport can complete two targets at once and make per-step assertions untestable rather than merely flaky. A 0.35-radius character capsule also reaches into a 0.55 area from 0.9 m. Both lessons have only three targets in the shared 12 m room, so they are spaced far past both thresholds:

| Lesson | Positions (x, y, z) | Minimum pairwise distance |
|--------|---------------------|---------------------------|
| 2 | circle `(-3.2, 0.5, -1.0)`, square `(3.4, 0.5, -3.0)`, triangle `(0.9, 0.5, 1.6)` | **4.85 m** (circle–triangle; circle–square 6.90 m, square–triangle 5.24 m) |
| 3 | `1` at `(-2.8, 0.5, 1.8)`, `2` at `(2.6, 0.5, 0.2)`, `3` at `(-0.6, 0.5, -3.4)` | **4.82 m** (2–3; 1–2 5.63 m, 1–3 5.65 m) |

4.82 m is 4.4× the area-overlap threshold and 5.4× the capsule-reach threshold, so each touch is unambiguously one target. Both layouts are also deliberately **not** a straight line — the cross product of the two edge vectors is 25.36 for lesson 2 and −24.56 for lesson 3, where zero would mean collinear — so the order is something a child follows by shape or numeral rather than a direction they walk. Every target is at least 3.04 m from the spawn point and at least 5.33 m from the probe's parking spot `(5, 0.1, 5)`, so no lesson starts with the character already inside an area and no park-then-touch is a body that never left.

## For plan 03-05: the shape lesson 5 reuses

Lesson 5 is a **four-step** sequence (D-44) extending this pattern. Reuse `scripts/lesson_3.gd` verbatim with exactly these differences:

1. `const LESSON_ID := "lesson_5"` and **`const TOTAL_TASKS := 4`**.
2. `_sequence` holds **four** target nodes in order. Nothing else changes: `_step >= _sequence.size()` already covers four, and `_sequence[_step].activate()` is unchanged.
3. **The total is 4, not 3.** `%Hud.set_step(_completed_tasks.size(), TOTAL_TASKS)` already parametrizes it — `scripts/ui/lesson_hud.gd`'s `set_step(current, total)` is the one place `"Stap: %d / %d"` exists, so passing 4 produces `Stap: 1 / 4` … `Stap: 4 / 4` with no second format string and no exception. Do **not** hardcode a 3 anywhere, and do not copy the format string into the probe.
4. In the probe, `ORDERED_TOTAL` and `_step_label_text()` are hardcoded to 3 and will need the total passed in (or a second constant) for lesson 5's case. `_drive_ordered_lesson` is otherwise total-agnostic: it derives every label from the step index and asserts `targets.size()` steps.
5. Keep the duplication. D-35 holds for all five orchestrators this phase; do not extract a base from lessons 2, 3 and 5.

`scripts/lesson_2.gd` is the shape for lesson 4's ordered half if 03-05 needs one, but D-43 makes lesson 4 a second **all-three-any-order** lesson, so `scripts/lesson_1.gd` is the right model there, not this plan's.

Both generators for this plan were throwaway `zz_*` scripts, deleted after use and never staged; `git ls-files '*zz_*'` is empty. The generator seeded each scene by instantiating `scenes/lesson_1.tscn`, swapping the root script, stripping lesson 1's own targets and adding new ones — which is why `scenes/lesson_2.tscn` and `scenes/lesson_3.tscn` carry byte-identical room, spawn, character and display setup and differ only in their targets. Note that re-running such a generator rewrites its sibling scene with fresh random `unique_id` values; `scenes/lesson_2.tscn` was restored with `git checkout -- scenes/lesson_2.tscn` after Task 2's generator pass so Task 2's diff stayed confined to lesson 3.

## Four baselines

```
$ bash scripts/tools/run_headless_check.sh
[step] import
[step] main scene
[step] verifier
[step] probe probe_audio_buses.gd
[step] probe probe_camiel_movement.gd
[step] probe probe_lesson_kit.gd
[step] probe probe_lesson_order.gd
[step] probe probe_lesson_select.gd
[step] probe probe_menu_button.gd
[step] probe probe_progress_persistence.gd
[step] probe probe_screen_flow.gd
Headless check passed.
EXIT=0

$ bash scripts/tools/test_headless_check.sh
... all 15 cases PASS ...
PASS case 14: inert inline audio bus configuration (no layout resource) fails, naming the audio probe
PASS case 15: generic ERROR during import fails
Headless check self-test passed.
EXIT=0

$ python3 scripts/tools/quality_gate.py --root .
Quality gate passed.
EXIT=0

$ python3 -m unittest tests.test_quality_gate tests.test_ci_workflows
Ran 14 tests in 0.017s
OK
EXIT=0
```

`"Stap: %d / %d"` still exists in exactly one `.gd` file repo-wide (`scripts/ui/lesson_hud.gd`); `grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l` returns `1`. Both new lessons call the shared display's `set_step` and hold no format string of their own — see deviation 1 for the one place this nearly broke.

## Files Created/Modified

- `scripts/lesson_2.gd` — `_sequence` (the order), `_on_task_completed` (append, advance, activate or finish), `_on_hud_back_requested`, `_apply_lesson_complete`; `transition_requested` and `lesson_completed` signals; title `Les 2 - Vormen op volgorde`
- `scenes/lesson_2.tscn` — `Lesson2 : Node3D`, the shared `LessonRoom`, `PlayerSpawn` and `Camiel` at `(0, 0.1, 4.5)`, `%Hud`, and `%CircleTarget` / `%SquareTarget` / `%TriangleTarget` (`cylinder` / `box` / `prism`, all accent orange, all `requires_activation = true`)
- `scripts/lesson_3.gd` — the same shape; title `Les 3 - Van 1 naar 3`
- `scenes/lesson_3.tscn` — `Lesson3 : Node3D` with `%Step1Target` / `%Step2Target` / `%Step3Target` (all `cylinder`, all strong blue, `display_text` `1` / `2` / `3`, all `requires_activation = true`)
- `scripts/lesson_select.gd` — two appended table rows; nothing else in the file changed
- `scripts/tools/probe_lesson_order.gd` — `_step_label_text`, `_ordered_targets`, `_watch_ordered_targets`, `_park`, `_touch_for_refusal`, `_rejections`, `_on_target_rejected_counted`, `_assert_only_active`, `_assert_colour_is_not_the_cue`, `_assert_space_key_reaches_nothing`, `_drive_ordered_lesson`, `_assert_in_play_return_is_one_shot`, and the two cases

`scripts/lesson_target.gd`, `scenes/lesson_target.tscn`, `scenes/lesson_room.tscn`, `scripts/ui/lesson_hud.gd`, `scenes/ui/lesson_hud.tscn` and `scripts/lesson_1.gd` are all **unchanged** — reused, not forked (D-45). `git diff 982e8fc..HEAD --stat` touches eight files, all of them in this plan's declared lists; no file outside them was modified, and no pre-existing probe needed a change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing critical verification] The probe copied the shared display's progress-label format string**

- **Found during:** Task 1, checking acceptance criteria before committing
- **Issue:** `_drive_ordered_lesson` built its wanted label with `"Stap: %d / %d" % [i + 1, ORDERED_TOTAL]`. That made `grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l` return `2`, breaking the D-46 invariant that the format string lives in exactly one file. Worse than the count: a probe that copies the display's format string silently agrees with the display about any change to it, so the string could be edited in both places and nothing would fail.
- **Fix:** added `_step_label_text(current)`, which reconstructs the label from its parts (`"Stap: " + str(current) + " / " + str(ORDERED_TOTAL)`). The probe now derives the label independently, so a change to the display's format is a failure rather than a shared assumption.
- **Files modified:** `scripts/tools/probe_lesson_order.gd`
- **Verification:** `grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l` returns `1`; full check green
- **Committed in:** `5a0a79d`

**2. [Rule 2 — Missing critical functionality] Nothing proved colour was not the cue in either ordered lesson**

- **Found during:** Task 1, reviewing the generated scene
- **Issue:** the plan requires all three of lesson 2's shapes to share one colour, "because this is a shape lesson and colour must not be the cue", and lesson 3 to share one blue so the numeral is the cue. Both were true in the generator and asserted nowhere. A later edit recolouring one target would turn either lesson into "touch the orange one" and every existing assertion would still pass. Godot also omits a property equal to its script default when packing, so `CircleTarget`'s `shape_kind = "cylinder"` is **not** written into `scenes/lesson_2.tscn` at all — the circle being a cylinder was, before this fix, verifiable only by knowing `lesson_target.gd`'s default.
- **Fix:** `_assert_colour_is_not_the_cue` asserts one shared colour across the whole lesson and that the targets remain distinguishable by shape or numeral, and prints the live shape kinds and texts. The GREEN output above now shows `["cylinder", "box", "prism"]` read off the running scene, which is where the circle's implicit cylinder is actually confirmed.
- **Files modified:** `scripts/tools/probe_lesson_order.gd`
- **Verification:** both cases print their shapes, texts and shared colour; full check green
- **Committed in:** `5a0a79d`

**3. [Rule 2 — Missing critical verification] The plan's probe steps did not carry the space-key trap or the in-play return control into the new lessons**

- **Found during:** Task 1, against 03-03's recorded deviations 2 and 3
- **Issue:** plan 03-03 found both of these genuinely broken or unproven and added them to lesson 1's cases. The plan for 03-04 specifies only the win panel's return control and says nothing about focus during play, so lessons 2 and 3 would have shipped with the same two gaps 03-03 had just closed. `scripts/ui/menu_button.gd:30` forces `focus_mode = Control.FOCUS_ALL` in its own `_ready()`, and `jump` and `ui_accept` both bind the space key, so the trap is one careless line away in any lesson.
- **Fix:** `_assert_space_key_reaches_nothing` (no focus owner during play, in-play control `FOCUS_NONE`, three accept presses changing nothing) and `_assert_in_play_return_is_one_shot` (a fresh unfinished instance, one guarded transition to lesson-select, second activation blocked) are both called from both new cases.
- **Files modified:** `scripts/tools/probe_lesson_order.gd`
- **Verification:** both cases green; both new lessons carry the assertion, not just lesson 1
- **Committed in:** `5a0a79d` (lesson 2), `57168f2` (lesson 3)

### Adjusted, Not Fixed

**4. [Plan step wording] The gate-removal exercise failed on the live-target assertion before it reached the refusal assertion**

Task 1's action step says to remove the square's activation requirement and "watch the case fail on the refusal assertion". It failed one assertion earlier, on `_assert_only_active` — an ungated target reports itself active from its own ready callback, which the case checks before it touches anything. That is the stronger and earlier detection, but it is not the assertion the plan asked to see bite, so the exercise was run a second time with the two `_assert_only_active` calls temporarily short-circuited, and the refusal assertion was observed failing by name. Both runs are quoted in RED Evidence above; neither left a trace.

**5. [Structural] One shared probe helper drives both ordered lessons, rather than two hand-written cases**

Task 2's action step says to add lesson 3's case "on the same shape as lesson 2's". It is literally the same code: `_drive_ordered_lesson` is shared and the two cases differ only in the six values they pass (scene path, lesson id, target names, which targets to touch out of turn, and the numerals each displays). This is deliberate and is the opposite of D-35's constraint, which binds the **orchestrators** — `scripts/lesson_2.gd` and `scripts/lesson_3.gd` remain independent files with no shared base. Sharing the probe helper means a regression in the shared activation gate fails *both* cases instead of one, which is strictly better coverage; the RED evidence for the label-overwrite defect shows exactly that happening.

### Process Deviation

**6. [Branch policy] Commits landed on `main` under the pre-existing config override**

`HEAD` was on `main` when this executor started and `.planning/config.json` already carried `git.allow_default_branch_commits: true` (written by plan 03-03, and gitignored so it is a local setting rather than a repository change). This executor did not modify that config. No commit was pushed, no tag created, no workflow run triggered, and git credential configuration was not touched.

---

**Total deviations:** 6 — three added verifications closing real gaps, one plan-step literalism adjustment, one documented structural choice, one pre-existing process override. **Impact:** all three of the added verifications strengthen the suite; none changed the behaviour either `<behavior>` block describes.

## Known Stubs

None. Both lessons are real, completable lessons driven end to end by a probe, and neither scene contains a target without a working completion rule. The lesson table deliberately holds three rows rather than five, which is the opposite of a stub: the two unbuilt lessons are not advertised anywhere a child can see, and `probe_lesson_select.gd`'s per-entry load-and-instantiate assertion makes advertising them before they exist a hard failure.

## Issues Encountered

**One intermittent engine warning, reported rather than hidden.** One run of `probe_lesson_order.gd` printed:

```
WARNING: Jolt Physics job system exceeded the maximum number of jobs. This should not
happen. Please report this. Waiting for jobs to become available...
     at: CreateJob (modules/jolt_physics/spaces/jolt_job_system.cpp:123)
```

It did not reproduce in five subsequent runs (three with both new lessons, two with the probe reverted to its Task-1 state), so it is not caused by lesson 3 specifically and not deterministic. It is a `WARNING:`, which `run_headless_check.sh`'s log scan does not match by design — the scan looks for `SCRIPT ERROR`, `Parse Error` and `ERROR:` — and Jolt self-recovers by waiting for a job slot. Logged to `deferred-items.md` rather than chased: it is engine scheduling noise under a probe that now instantiates eight full 3D rooms in one process, not a behaviour this plan owns. If it becomes frequent, the fix is to `free()` each lesson instance decisively instead of relying on `queue_free()` plus two process frames, not to loosen the log scan.

Both implementation tasks otherwise passed on the first probe run after their scenes were generated; neither generator needed a fix.

## User Setup Required

None — no external service configuration, no package install of any kind, and no third-party asset. Every mesh and material in both scenes is an engine primitive built by code already in the repository.

## Next Phase Readiness

- **For plan 03-05:** the four-step orchestrator shape and its `TOTAL_TASKS := 4` requirement are spelled out in "For plan 03-05" above, including the two probe constants (`ORDERED_TOTAL`, `_step_label_text`) that are hardcoded to 3 and will need the total threaded through for lesson 5's case.
- **Reusable surface this plan adds:** `_drive_ordered_lesson`, `_assert_only_active`, `_assert_colour_is_not_the_cue`, `_assert_space_key_reaches_nothing`, `_assert_in_play_return_is_one_shot`, `_touch_for_refusal`, `_park`, `_ordered_targets`, `_watch_ordered_targets`, `_rejections`, `_step_label_text`. Lesson 5's case should be four lines of arguments, not a new case body.
- **Append the table row in the same commit as the scene.** Both probes then cover the new lesson automatically; `probe_lesson_select.gd` needed no edit for either of this plan's two lessons.
- **Carried forward unchanged:** the `REQUIRED_PROBES` named-probe allow-list gap is still deliberately absent and remains out of Phase 3 scope per `03-VALIDATION.md`. `project.godot` was not touched by this plan (`git diff 982e8fc..HEAD -- project.godot` is empty), so the `config/name` / `OS.get_user_data_dir()` cross-phase hazard is unchanged.
- **Manual verification still outstanding** (`03-RESEARCH.md`'s Manual-Only table): progress surviving a real process exit and relaunch, and whether a refusal reads as gentle rather than as a failure to a real three-year-old. The scale dip is the only feedback a wrong touch produces and nothing else changes on screen, which is what the calm prohibition asks for, but only a person watching a child can confirm it lands that way.

## Self-Check: PASSED

- `scripts/lesson_2.gd` — FOUND
- `scripts/lesson_2.gd.uid` — FOUND
- `scenes/lesson_2.tscn` — FOUND
- `scripts/lesson_3.gd` — FOUND
- `scripts/lesson_3.gd.uid` — FOUND
- `scenes/lesson_3.tscn` — FOUND
- Commit `5a0a79d` — FOUND in `git log --oneline --all`
- Commit `57168f2` — FOUND in `git log --oneline --all`
- All acceptance criteria from Tasks 1 and 2 re-verified with the plan's exact `grep`/`test`/`awk` commands — all PASS
- `git diff -- scripts/lesson_select.gd` across both commits shows two added table rows and nothing else — verified
- `grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l` returns `1` — verified
- `git ls-files '*zz_*'` empty — verified
- `git diff -- scripts/lesson_target.gd scripts/lesson_1.gd scripts/tools/probe_lesson_select.gd` empty across both commits — verified (reused, not forked)
- `bash scripts/tools/run_headless_check.sh` — PASSED (exit 0)
- `bash scripts/tools/test_headless_check.sh` — PASSED (exit 0, all 15 cases)
- `python3 scripts/tools/quality_gate.py --root .` — PASSED
- `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` — PASSED (14 tests, OK)

---
*Phase: 03-3d-lesson-parity-progress-persistence*
*Completed: 2026-09-13*
