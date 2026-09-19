---
phase: 03-3d-lesson-parity-progress-persistence
plan: 05
subsystem: 3d-gameplay
tags: [godot, gdscript, area3d, headless-probe, order-enforcement, persistence, lesson-table]

requires:
  - phase: 03-3d-lesson-parity-progress-persistence
    provides: "plan 03-01's ProgressTracker autoload (record_lesson_complete, STARS_PER_COMPLETION, atomic write) and its probe backup/restore hygiene"
  - phase: 03-3d-lesson-parity-progress-persistence
    provides: "plan 03-02's scripts/lesson_target.gd + scenes/lesson_target.tscn (the D-37/D-38 activation gate), scenes/lesson_room.tscn, and scripts/ui/lesson_hud.gd's set_step(current, total) -- the one place the progress-label format string exists"
  - phase: 03-3d-lesson-parity-progress-persistence
    provides: "plan 03-03's scripts/lesson_1.gd all-three-any-order orchestrator shape and probe_lesson_order.gd's _open_lesson / _touch_target / _read_progress_file / _assert_last_entry / _disk_entry_count / _assert_win_return_is_one_shot helpers"
  - phase: 03-3d-lesson-parity-progress-persistence
    provides: "plan 03-04's scripts/lesson_3.gd ordered orchestrator shape and probe_lesson_order.gd's _drive_ordered_lesson / _assert_only_active / _assert_colour_is_not_the_cue / _assert_space_key_reaches_nothing / _assert_in_play_return_is_one_shot / _touch_for_refusal / _park / _step_label_text"
provides:
  - "scripts/lesson_4.gd + scenes/lesson_4.tscn -- lesson 4: a second colour-recognition-and-counting task on yellow and green, on lesson 1's all-three-any-order rule, proved to complete from two genuinely different task orders (LESSON-04, D-43, D-36)"
  - "scripts/lesson_5.gd + scenes/lesson_5.tscn -- lesson 5: a four-step ordered sequence on lesson 3's activation pattern, whose progress label reads Stap: 4 / 4 from the one shared label form (LESSON-05, D-44, D-46 resolved)"
  - "const LESSONS complete at five entries, so the lesson-select screen, its focus cycle and both probes cover every lesson with no hardcoded lesson name anywhere (LESSON-06)"
  - "probe_lesson_order.gd's all_five_lessons_on_disk closing case: after one run drives all five lessons to real completions, every identifier the table advertises is required to be in user://progress.json (PROGRESS-02)"
  - "probe_lesson_order.gd's shared colour-and-counting driver (_colour_count_targets, _drive_touch_sequence with lesson_id and total), _assert_colour_is_the_cue, _scene_colour, _colour_separation, _target_labels; _assert_colour_is_not_the_cue strengthened with a named cue"
affects: [03-06, 04-accessibility-contrast, 08-parent-dashboard]

actuals:
  tokens: 17349
  tasks: 3
  commits: 4
  plan_head_before: f6404a7f888dce34ea2babd7c3b6d60f0ddf9b5f

tech-stack:
  added: []
  patterns:
    - "An unordered lesson proves order-independence by being DRIVEN from more than one order, not by a comment claiming any order works; lesson 4's second order interleaves a colour target into the middle of the counting task, a shape no lesson-1 case exercised"
    - "The progress label's total is a parameter end to end -- in the display, in each orchestrator and in the probe helper -- so lesson 5 reads out of four from the same one format string and no lesson can show a step number larger than its own total"
    - "A probe case states the two label strings a child literally reads (opening and closing) and the helper reconstructs the same strings from parts; the two are compared against each other BEFORE either is compared against the screen, so a self-consistent wrong total fails on the first assertion"
    - "The cue assertion is two-sided: an ordered lesson asserts colour is NOT the cue and that the named cue (shape or numeral) is the only property that varies, while a colour lesson asserts colour IS the cue and that shape and label are held uniform -- in both directions the property being taught is the only discriminator"
    - "The closing persistence case builds its expected identifier set from the lesson-select table rather than a literal list, so a sixth lesson is covered the day its row lands, and a lesson filing progress under an identifier no button can read back fails a check no per-lesson case can see"
    - "A load-modify-repack generator seeded from an already-shipped sibling scene inherits the room, spawn, character and display setup exactly (03-04's pattern, reused unchanged), so the only reviewable difference between two lessons' scene files is their targets"

key-files:
  created:
    - scripts/lesson_4.gd
    - scripts/lesson_4.gd.uid
    - scenes/lesson_4.tscn
    - scripts/lesson_5.gd
    - scripts/lesson_5.gd.uid
    - scenes/lesson_5.tscn
  modified:
    - scripts/lesson_select.gd
    - scripts/tools/probe_lesson_order.gd
    - scripts/tools/probe_lesson_select.gd
    - .planning/phases/03-3d-lesson-parity-progress-persistence/deferred-items.md

key-decisions:
  - "D-46 is resolved by parametrizing the total, and the resolution is asserted rather than described: lesson 5 declares TOTAL_TASKS := 4, passes it to the shared display's set_step(current, total), and its probe case asserts the opening label reads Stap: 0 / 4 as its very first check. A lesson reshaped down to three scored sub-tasks to fit a three-step label fails there, and a label form hardcoded to three fails there. Demonstrated: hardcoding / 3 back into scripts/ui/lesson_hud.gd passes lessons 1 through 4 and fails only lesson 5."
  - "Lesson 4 is driven from TWO genuinely different orders to real completions, not one. The plan prescribed yellow-counts-green, which is the same shape as lesson 1's own red-counts-blue run; since lesson 4 is an unordered lesson, one order proves nothing about order-independence. The second order interleaves a colour target into the MIDDLE of the counting task (green, count_3, count_1, yellow, count_2), which no lesson-1 case did -- a partly-gathered counting task has to survive another task landing on top of it."
  - "The cue assertion was made two-sided rather than copied. Lesson 4's cue IS colour, so the ordered lessons' shared-colour rule inverts: its two colour targets must differ in colour by a real distance and be IDENTICAL in shape and label, or the task quietly becomes 'touch the round one' while every completion assertion still passes. The counting objects are held uniform in colour, shape and label because their cue is quantity, and their colour is required a real distance from both of the lesson's two -- a third object in almost-yellow is exactly the trap a yellow-or-green lesson must not set."
  - "_assert_colour_is_not_the_cue was STRENGTHENED, not merely reused. It previously required only that the targets differ in something, which let a numeral lesson hand a child three different shapes and still pass -- the shape rather than the number would be what was learned. It now takes a named cue and requires the other property to be uniform. Lessons 2, 3 and 5 all pass under the stricter rule with no scene change."
  - "The lesson-1 colour-and-counting probe helpers were generalized and shared with lesson 4 rather than forked, following 03-04's precedent for the ordered driver. A regression in the all-three-any-order rule now fails both lessons' cases. This binds the PROBE only: scripts/lesson_1.gd and scripts/lesson_4.gd remain independent files with no shared base, per D-35."
  - "The five orchestrators stay five independent files. No base class, no global class name and no helper autoload was extracted from the duplication across lessons 1 and 4 or across lessons 2, 3 and 5. D-35 holds for this whole phase and MORE-02's shared lesson pattern is phase 9's scope."

requirements-completed: []

requirements-advanced:
  - id: LESSON-01
    state: "Unchanged in behaviour by this plan, but its coverage is stronger: _drive_touch_sequence now asserts the space-key trap on lesson 1's other-orders runs too, and the driver is shared with lesson 4 so a regression in the all-three-any-order rule fails both. Left UNCHECKED because plan 03-06 also carries this ID."
  - id: LESSON-02
    state: "Unchanged in behaviour, but the cue assertion it passes is now stricter (shape lessons must hold their labels uniform). Left UNCHECKED because plan 03-06 also carries this ID."
  - id: LESSON-03
    state: "Unchanged in behaviour, but the cue assertion is now stricter (numeral lessons must hold their shapes uniform). Left UNCHECKED because plan 03-06 also carries this ID."
  - id: LESSON-04
    state: "Closed in behaviour: a real, completable colour-and-counting lesson on a new pair, driven to completion from two genuinely different orders and proved not to finish on two thirds of its counting task. Left UNCHECKED because plan 03-06 also carries this ID."
  - id: LESSON-05
    state: "Closed in behaviour: a real, completable four-step sequence, proved not to finish at three steps, proved to refuse two different out-of-turn touches, and reading Stap: 4 / 4 from the one shared label form. Left UNCHECKED because plan 03-06 also carries this ID."
  - id: LESSON-06
    state: "The table is now complete at five entries, five buttons, five distinct paths all loadable as 3D nodes, focus cycling around all five. Left UNCHECKED because plan 03-06 carries this ID for its convergent pass."
  - id: PROGRESS-02
    state: "Closed for all five lessons: each records, each entry is read back off the disk with all four fields, each completion proved to APPEND, and one run now leaves all five identifiers in the file. Left UNCHECKED because plan 03-06 also carries this ID."

coverage:
  - id: D1
    description: "Lesson 4 is a real, completable lesson -- not the ten-line stub the archive shipped under this name -- driven to a real completion from two genuinely different task orders, the second interleaving a colour target into the middle of the counting task"
    requirement: LESSON-04
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_lesson_4_any_order (orders 1 and 2, each with a per-step label assertion)"
        status: pass
      - kind: unit
        ref: "acceptance greps: scripts/lesson_4.gd is 142 lines with exactly one _ready, one record call before show_win, no await, no star rule and no main-menu path"
        status: pass
    human_judgment: false
  - id: D2
    description: "Neither of lesson 4's colour targets nor a partly-gathered counting task completes the lesson on its own: both colours plus two of three counting objects, held for 120 further physics frames, leaves the label at Stap: 2 / 3 with zero completions and no new entry on disk"
    requirement: LESSON-04
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_lesson_4_any_order (the negative third run, on a fresh instance)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Colour is the cue in lesson 4 and the ONLY cue: its two colour targets are 0.805 apart in RGB, identical in shape (box) and identical in label (empty); its three counting objects are uniform in colour, shape and label, and their colour is 0.830 from yellow and 0.633 from green"
    requirement: LESSON-04
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_colour_is_the_cue"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's RED Evidence, exercises A and B -- giving the green target a different shape, and painting the counting objects the lesson's own yellow, each failed the case by name against a temporary and fully reverted scene edit"
        status: pass
    human_judgment: true
    rationale: "A permanently mis-cued lesson would be the defect the assertion forbids, so the demonstration was run against temporary edits and reverted. A human should confirm the reasoning -- that colour being the cue makes shape uniformity a requirement rather than a style choice -- not just the exit code."
  - id: D4
    description: "Lesson 4's pair is a different pair from lesson 1's: yellow is 0.671 from red and 1.163 from blue, green is 0.831 from red and 0.622 from blue, all well past the 0.35 threshold, read straight out of lesson 1's packed scene rather than restated"
    requirement: LESSON-04
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_lesson_4_any_order (the _scene_colour comparison against lesson 1)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Lesson 5 completes only when all four steps are done in its defined order, and does not complete after three; touching a step out of turn emits that target's refusal exactly once, completes nothing, leaves the label unmoved and leaves the target's own numeral intact -- proved from two different wrong first guesses (the fourth step, then the third)"
    requirement: LESSON-05
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_lesson_5_order_enforced via #_drive_ordered_lesson (negative half first, then the correct order)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Lesson 5's progress label reads Stap: 0 / 4 at the start and Stap: 4 / 4 at the finish, from the same one format string the other four lessons use with a total of 3 -- the total is a parameter, so no lesson ever shows a step number larger than its own total"
    requirement: LESSON-05
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_lesson_5_order_enforced (opening_label and closing_label stated as literals and cross-checked against the helper's reconstruction, then against the screen)"
        status: pass
      - kind: unit
        ref: "grep: 'Stap: %d / %d' appears in exactly one .gd file repo-wide (scripts/ui/lesson_hud.gd); zero non-comment lines in scripts/lesson_5.gd contain a standalone 3"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's RED Evidence, exercise B -- hardcoding / 3 back into the shared display passed lessons 1 through 4 and failed ONLY lesson 5, by name"
        status: pass
    human_judgment: true
    rationale: "Demonstrated once against a temporary, byte-identically reverted edit to the shared display. The value of the demonstration is that it shows lesson 5 is the only lesson that can detect this defect at all, which is the whole argument for not reshaping it to three steps."
  - id: D7
    description: "After every completion in lesson 5 exactly one target reports itself active -- the next in the order -- and after the last one none does; a wrong target is not merely refused, it is never live"
    requirement: LESSON-05
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_only_active, called at lesson open, after every refusal and after every completion"
        status: pass
    human_judgment: false
  - id: D8
    description: "Lesson 5's cue is the numeral and nothing else: all four targets share one colour and one shape (cylinder) and differ only in the text they display, and that shared colour is 0.624 from lesson 3's, so the two sequence lessons read as two rooms"
    requirement: LESSON-05
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_colour_is_not_the_cue with cue 'text', plus the _scene_colour comparison against lesson 3"
        status: pass
    human_judgment: false
  - id: D9
    description: "Completing lesson 4 and completing lesson 5 each write their own entry, read back off the disk with a FileAccess handle and JSON.new().parse(), asserting lesson id, three stars, a positive elapsed time and a non-empty timestamp -- and each proved to APPEND by the entry count before and after"
    requirement: PROGRESS-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_drive_touch_sequence and #_drive_ordered_lesson (_assert_last_entry plus the entries_before + N assertions)"
        status: pass
    human_judgment: false
  - id: D10
    description: "After one probe run drives all five lessons to real completions, the progress file holds an entry for every one of the five identifiers the lesson table advertises, every entry carries exactly the four required fields, and every entry's star count is three"
    requirement: PROGRESS-02
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_case_all_five_lessons_on_disk"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's RED Evidence, exercises C and D -- skipping lesson 5's case (a table row whose completion never reaches disk) and adding a fifth field to the tracker's entry each failed the closing case by name, against temporary and fully reverted edits"
        status: pass
    human_judgment: true
    rationale: "The assertion this case exists for cannot be demonstrated without temporarily creating the defect, because every per-lesson case would catch a permanent version of it first. Reverted immediately; scripts/progress_tracker.gd re-checksummed identical."
  - id: D11
    description: "Exactly five runtime scripts outside the tools directory call the tracker's record method -- one per lesson -- so no lesson can ship whose completion is never recorded, which is what the archived game shipped for its entire life"
    requirement: PROGRESS-02
    verification:
      - kind: unit
        ref: "verify command: grep -rl 'record_lesson_complete' --include='*.gd' scripts excluding scripts/tools/ and the tracker itself returns exactly 5 files (lesson_1 through lesson_5)"
        status: pass
    human_judgment: false
  - id: D12
    description: "The lesson table holds exactly five entries with five distinct identifiers, paths and labels; the screen builds five buttons; every path resolves, loads and instantiates as a 3D node; and the focus cycle runs around all five and wraps"
    requirement: LESSON-06
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_select.gd#_case_lesson_table_drives_buttons (the count assertion and the three distinctness assertions) and #_case_lesson_button_transitions"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's GREEN Evidence -- an out-of-band read of the live screen printed 5 table rows and 5 grid children with their labels and icons, rather than the count being assumed from a passing probe"
        status: pass
      - kind: manual_procedural
        ref: "this SUMMARY's RED Evidence, exercise E -- pointing the fifth table row at the fourth lesson's scene, which passes every other assertion in that file, failed the new duplicate-path assertion by name"
        status: pass
    human_judgment: true
    rationale: "The plan required the five-button screen to be confirmed in output rather than assumed, while requiring probe_lesson_select.gd's existing assertions to stay generic over the table. Confirmed with a throwaway read-only script, deleted after use."
  - id: D13
    description: "Both of each new lesson's return controls go to lesson-select, not the main menu, each through one guarded, deferred transition -- the win panel's control on the finished lesson, and the in-play control on a fresh unfinished instance"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_win_return_is_one_shot and #_assert_in_play_return_is_one_shot, both called from both new cases"
        status: pass
      - kind: unit
        ref: "grep: zero occurrences of res://scenes/main_menu.tscn in scripts/lesson_4.gd and scripts/lesson_5.gd"
        status: pass
    human_judgment: false
  - id: D14
    description: "No focusable control is alive or focused during 3D play in either new lesson, so the space key -- bound to both jump and ui_accept -- cannot end a lesson under a child's feet"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_lesson_order.gd#_assert_space_key_reaches_nothing, called from lesson 4's case through _drive_touch_sequence and from lesson 5's through _drive_ordered_lesson, before a single target is touched"
        status: pass
    human_judgment: false

duration: ~25min
completed: 2026-09-13
status: complete
---

# Phase 3 Plan 5: Lessons 4 and 5, and the Five-Identifier Assertion Summary

**The two lessons the archive advertised and never built are now real and driven to real completions — and the run that proves it ends by reading the save file back and requiring all five lesson names to be in it, which is the check nothing in the old game would ever have passed.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3 completed
- **Commits:** 4 — three task commits plus this metadata commit (measured: `git rev-list --count f6404a7..HEAD`)
- **Files:** 6 created, 4 modified

## Accomplishments

- `scripts/lesson_4.gd` + `scenes/lesson_4.tscn`: a yellow box, a green box and three purple spheres. One array of completed tasks, one comparison against one total, the tracker called before the win panel, nothing gated. `Les 4 - Geel, groen en tellen`.
- `scripts/lesson_5.gd` + `scenes/lesson_5.tscn`: four berry cylinders reading `1`, `2`, `3`, `4`, all requiring activation, order enforced by the array of target nodes being **used** to activate the next one. `TOTAL_TASKS := 4`, passed to the shared display. `Les 5 - Van 1 naar 4`.
- `const LESSONS` is **complete at five rows**. The whole diff to `scripts/lesson_select.gd` across both task commits is two added lines.
- `probe_lesson_order.gd` gained `lesson_4_any_order`, `lesson_5_order_enforced` and the closing `all_five_lessons_on_disk`, plus a two-sided cue assertion and a shared colour-and-counting driver.
- `probe_lesson_select.gd` gained the five-entry count assertion and three distinctness assertions, while still naming no lesson.

## The lesson table is complete

```gdscript
const LESSONS: Array[Dictionary] = [
	{"id": "lesson_1", "path": "res://scenes/lesson_1.tscn", "label": "Les 1", "icon": "lesson_colors"},
	{"id": "lesson_2", "path": "res://scenes/lesson_2.tscn", "label": "Les 2", "icon": "lesson_shapes"},
	{"id": "lesson_3", "path": "res://scenes/lesson_3.tscn", "label": "Les 3", "icon": "lesson_sequence"},
	{"id": "lesson_4", "path": "res://scenes/lesson_4.tscn", "label": "Les 4", "icon": "lesson_colors"},
	{"id": "lesson_5", "path": "res://scenes/lesson_5.tscn", "label": "Les 5", "icon": "lesson_sequence"},
]
```

Both rows were **appended in the same commit as their scene**, so the table never advertised a lesson that did not exist. There is no disabled button and no availability caption anywhere: that exact shape is the archived defect, where lesson 4's scene announced `Les 4 - Nu beschikbaar` above a `_ready(): pass` stub. `probe_lesson_select.gd` `load()`s and `instantiate()`s every table path asserting `Node3D`, so a premature row fails loudly rather than producing a broken button.

Lesson 4 carries lesson 1's icon and lesson 5 carries lesson 3's, because each pair shares a mechanic.

## D-46, resolved and visible

The resolution is the one plan 03-02 put in place and this plan is the first to actually exercise: **the total is a parameter.** `scripts/ui/lesson_hud.gd`'s `set_step(current, total)` holds the only copy of the progress-label format string in the repository; lessons 1 through 4 pass `3` and lesson 5 passes `4`.

- Lesson 5's **opening** label: `Stap: 0 / 4`
- Lesson 5's **closing** label: `Stap: 4 / 4`

Nothing about lesson 5's rule was reshaped to fit a label — it is four steps, scored as four, labelled as four — and there is no second format string. `grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l` returns `1`.

The probe asserts it the hard way. Each ordered case states the two strings a child literally reads as arguments, and `_drive_ordered_lesson` **first** compares them against its own reconstruction from parts, **then** against the screen:

```gdscript
if _step_label_text(0, total) != opening_label:
	_fail(case_name, "this case expects the lesson to open at %s but a total of %d reads %s -- the case and the label form disagree about this lesson's own total" % [...])
```

So a lesson quietly reshaped to three sub-tasks fails on the first assertion, not at the end where a passing win panel could absorb it. See RED Evidence exercise B: hardcoding `/ 3` back into the shared display passes lessons 1 through 4 and fails **only** lesson 5.

## What each lesson's cue is, and what is asserted NOT to carry it

This is the assertion 03-04 added (`_assert_colour_is_not_the_cue`) applied in both directions, because lesson 4 is the first lesson whose cue genuinely *is* colour.

| Lesson | The cue a child is asked to read | Asserted uniform, so it cannot be the cue |
|--------|----------------------------------|-------------------------------------------|
| 2 | **Shape** — cylinder, box, prism | one shared colour; all labels empty |
| 3 | **Numeral** — `1`, `2`, `3` | one shared colour; all cylinders |
| 4 | **Colour** — yellow vs green (pair), and **quantity** — three (count group) | both colour targets are boxes with empty labels; all three counting objects share one colour, one shape and one label |
| 5 | **Numeral** — `1`, `2`, `3`, `4` | one shared colour; all cylinders |

`_assert_colour_is_not_the_cue` was **strengthened** rather than just reused: it previously required only that the targets differ in *something*, which would have let a numeral lesson hand a child three different shapes and still pass — the shape, not the number, would have been what was learned. It now takes a named cue and requires the other property to be uniform. Lessons 2, 3 and 5 all pass under the stricter rule with no scene change.

`_assert_colour_is_the_cue` is its inverse for lesson 4. Colour separations, measured as RGB distance against a `MIN_COLOUR_SEPARATION` of 0.35:

| Pair | Separation |
|------|-----------|
| yellow `Color(0.98, 0.82, 0.18)` vs green `Color(0.2, 0.65, 0.28)` | **0.805** |
| counting purple `Color(0.55, 0.36, 0.72)` vs yellow | 0.830 |
| counting purple vs green | 0.633 |
| yellow vs lesson 1's red | 0.671 |
| yellow vs lesson 1's blue | 1.163 |
| green vs lesson 1's red | 0.831 |
| green vs lesson 1's blue | 0.622 |
| lesson 5's berry `Color(0.62, 0.24, 0.45)` vs lesson 3's blue | 0.624 |

The counting objects being purple is load-bearing, not decorative: orange (lesson 1's counting colour) is only **0.239** from this lesson's yellow, and in a lesson about telling yellow from green a third object in almost-yellow is exactly the trap the plan forbids. Lesson 1's and lesson 4's palettes are compared by reading the colours straight out of `lesson_1.tscn`'s packed scene, so the comparison cannot drift from what the scene actually declares.

## Order-independence, driven rather than claimed

**Lesson 4 is unordered**, so the requirement is that it completes from more than one genuinely different order — and both are actually driven to completion:

| Order | Touches | Labels after each |
|-------|---------|-------------------|
| 1 | yellow → count_1 → count_2 → count_3 → green | `1 / 3`, `1 / 3`, `1 / 3`, `2 / 3`, `3 / 3` |
| 2 | green → count_3 → count_1 → **yellow** → count_2 | `1 / 3`, `1 / 3`, `1 / 3`, `2 / 3`, `3 / 3` |
| 3 (negative) | yellow, green, count_1, count_2, then 120 idle physics frames | stays `2 / 3`, **0 completions**, no new entry on disk |

Order 2 is the one no lesson-1 case exercised: the counting objects are gathered out of their declared index order **and** a colour target lands in the middle of the counting task. A lesson that reset or forgot a partly-gathered count would complete order 1 and fail order 2. Order 3 is the plan's negative — two thirds of a counting task is not two thirds of a task, it is no task at all.

**Lesson 5 is ordered** (D-37/D-38), so the second form applies — two different wrong-first touches, each proved to refuse and complete nothing, before the correct order is ever driven:

| Order 1 (wrong) | Order 2 (wrong) | Order 3 (correct) |
|-----------------|-----------------|-------------------|
| fourth step first → refused once, 0 completions, label still `Stap: 0 / 4`, numeral still `4` | third step first → refused once, 0 completions, label unmoved, numeral still `3` | `1` → `2` → `3` → `4`, labels `1 / 4`, `2 / 4`, `3 / 4`, `4 / 4`, one completion |

The wrong guesses (`[3, 2]`) are deliberately different from lesson 2's (`[1, 2]`) and lesson 3's (`[2, 1]`), so one shared bug in the shared activation gate cannot hide behind one shared wrong touch. `_assert_only_active` runs at lesson open, after every refusal and after every completion: the wrong target is not merely refused after the fact, it is **never live**.

## Target spacing

03-03 recorded that two 0.55-radius target areas overlap below **1.1 m** apart, and that a 0.35-radius character capsule reaches into a 0.55 area from **0.9 m**. Both new lessons sit well past both thresholds.

| Lesson | Positions (x, y, z) | Minimum pairwise distance |
|--------|---------------------|---------------------------|
| 4 | yellow `(-3.8, 0.5, -3.2)`, green `(3.8, 0.5, -3.2)`, count_1 `(-2.0, 0.5, 1.4)`, count_2 `(0.0, 0.5, 2.0)`, count_3 `(2.0, 0.5, 1.4)` | **2.088 m** (count_1–count_2 and count_2–count_3; every other pair is 4.0 m or more) |
| 5 | `1` at `(-3.6, 0.5, 2.4)`, `2` at `(2.8, 0.5, 3.0)`, `3` at `(-1.2, 0.5, -1.0)`, `4` at `(3.4, 0.5, -3.6)` | **4.162 m** (`1`–`3`; the rest run 5.28 m to 9.22 m) |

Lesson 4's 2.088 m is **1.90×** the area-overlap threshold and **2.32×** the capsule-reach threshold; lesson 5's 4.162 m is **3.78×** and **4.62×**. Every touch is unambiguously one target.

Neither layout is a straight line. Lesson 4's three counting objects form a shallow triangle (cross product −2.4, where zero would be collinear) rather than the row lesson 1 used; lesson 5's four steps turn the other way at step 3 than at step 2 (cross products −23.2 then +28.8), so the path zig-zags rather than being a line or a simple loop a child could walk without reading the numbers. Every target is at least **2.5 m** from the spawn point (lesson 4) and **3.18 m** (lesson 5), and at least **4.69 m** / **2.97 m** from the probe's parking spot `(5, 0.1, 5)`, so no lesson starts with the character already inside an area and no park-then-touch is a body that never left.

**One deliberate departure from the plan's text:** Task 1 step B says to group the counting objects "about a metre apart". A metre is *below* the 1.1 m area-overlap threshold, so one teleport could complete two counting objects at once and the per-step label assertions would be untestable rather than merely flaky. They are 2.088 m apart instead — still one recognisable group in one part of the room, still further apart than lesson 1's own 1.4 m. Recorded as deviation 1.

## Task Commits

1. **Task 1 (tracer): Lesson 4 tells yellow from green and counts to three in any order** — `3944df7` (feat)
2. **Task 2: Lesson 5 walks 1 to 4 in order and its sign reads Stap: 4 / 4** — `e7c1c41` (feat)
3. **Task 3: Five lessons, five buttons, five identifiers on the disk** — `70a6a78` (test)

## RED Evidence

**Task 1 — RED (lesson 4 does not exist).** The `lesson_4_any_order` case was written first, along with the probe generalization it needs, and `bash scripts/tools/run_headless_check.sh` run against it. Lessons 1, 2 and 3 still passed on the refactored helpers, and the new case failed for the only reason it should:

```
PASS lesson_1_count_first
PASS lesson_1_other_orders
PASS lesson_1_guards
PASS lesson_2_order_enforced
PASS lesson_3_order_enforced
ERROR: lesson_4_any_order: res://scenes/lesson_4.tscn does not exist
   GDScript backtrace (most recent call first):
       [0] _fail (res://scripts/tools/probe_lesson_order.gd:122)
       [1] _open_lesson (res://scripts/tools/probe_lesson_order.gd:222)
       [2] _case_lesson_4_any_order (res://scripts/tools/probe_lesson_order.gd:1503)
```

**Task 1 — exercise A: shape allowed to become the cue.** `GreenTarget`'s `shape_kind` was temporarily changed from `box` to `sphere`, so a child could answer "which is the green one" by picking the round one without ever looking at a colour. Every completion assertion in the file would still have passed:

```
ERROR: lesson_4_any_order: YellowTarget is a box and GreenTarget is a sphere -- this
lesson's cue is colour, so its two colour targets must be the same shape or the child
can answer by shape without ever looking at the colour
```

**Task 1 — exercise B: the counting objects painted the lesson's own yellow.**

```
ERROR: lesson_4_any_order: the counting objects are (0.98, 0.82, 0.18, 1.0) and
YellowTarget is (0.98, 0.82, 0.18, 1.0), only 0.000 apart -- at least 0.35 wanted,
because a third object in one of the lesson's two colours is the trap this lesson
must not set
```

`scenes/lesson_4.tscn` was regenerated from its generator after each exercise and re-verified: 3 counting objects at `Color(0.55, 0.36, 0.72, 1)`, 2 boxes, 5 targets, 0 `requires_activation = true`.

**Task 2 — RED (lesson 5 does not exist).**

```
CHECK FAILED: probe probe_lesson_order.gd: Godot exited with status 1
ERROR: lesson_5_order_enforced: res://scenes/lesson_5.tscn does not exist, so its
palette cannot be compared against
```

**Task 2 — exercise A: lesson 5 reshaped to a total of three.** `TOTAL_TASKS` was temporarily set to `3` in `scripts/lesson_5.gd`, which is exactly the reconciliation D-44 forbids. The case's own declared total is independent of the lesson's, so it fired on the first assertion:

```
ERROR: lesson_5_order_enforced: the progress label reads Stap: 0 / 3 at the start of
the lesson, Stap: 0 / 4 wanted
```

**Task 2 — exercise B: the D-46 defect itself, reintroduced.** The shared display's `set_step` was temporarily rewritten to `"Stap: %d / 3" % current` — a label form hardcoded to three, the alternative D-46 explicitly asked the planner to choose against. **Lessons 1 through 4 all passed. Only lesson 5 failed:**

```
PASS lesson_1_count_first
PASS lesson_1_other_orders
PASS lesson_1_guards
PASS lesson_2_order_enforced
PASS lesson_3_order_enforced
PASS lesson_4_any_order
ERROR: lesson_5_order_enforced: the progress label reads Stap: 0 / 3 at the start of
the lesson, Stap: 0 / 4 wanted
```

That is the whole argument for not reshaping lesson 5 to three steps, in one run: lesson 5 is the only lesson in the game that can detect this class of defect at all. `scripts/ui/lesson_hud.gd` was restored to `421a8e31cc94fe545ca9ebd8cd51c7de311498b88b89e524a435e7f1be13f13b` and `scripts/lesson_5.gd` to `2b604c5c9b8d1851c85f1090417c7eeebb2ad317a738532943f690388864525e`, both byte-identical to their pre-exercise values; `git diff -- scripts/ui/lesson_hud.gd` is empty.

**Task 3 — exercise C: a lesson in the table whose completion never reaches disk.** `_case_lesson_5_order_enforced()` was temporarily removed from the probe's run order, reproducing a lesson the screen offers but nothing ever records — the archived defect exactly. No per-lesson case can see this, because each only checks its own entry:

```
ERROR: all_five_lessons_on_disk: after every lesson was driven to a real completion the
progress file holds no entry for ["lesson_5"] -- that lesson's completion is never
recorded, which is exactly what the archived game shipped for its entire life
```

**Task 3 — exercise D: the tracker slipping a fifth field into a child's save file.** A `"rubric_bonus": 1` field was temporarily added to `scripts/progress_tracker.gd`'s entry:

```
ERROR: all_five_lessons_on_disk: entry 0 carries 5 fields (["completed_at", "lesson_id",
"rubric_bonus", "stars", "time_seconds"]), exactly 4 wanted -- lesson_id, stars,
time_seconds and completed_at
```

`scripts/progress_tracker.gd` was restored to `1b22af588a32ac14e7bf265cb912fd3cdeef395882c8188678220410b0142793`, byte-identical.

**Task 3 — exercise E: a fifth table row pointed at a lesson that already has a button.** `lesson_5`'s path was temporarily changed to `res://scenes/lesson_4.tscn`. The table still held five entries, five distinct identifiers and five distinct labels; the button was still built, its label and icon still matched its entry, and its path still loaded and instantiated as a 3D node — every pre-existing assertion in that file passed:

```
ERROR: lesson_table_drives_buttons: two table entries point at
res://scenes/lesson_4.tscn; one of the buttons opens the wrong lesson
```

`scripts/lesson_select.gd` was restored to `722f393e271051c410d2597a2b681ed3aeff6fdc1a7ea83e88bf11cd94bf2183`, byte-identical.

## GREEN Evidence

Every probe success line observed in one run:

```
PASS lesson_1_count_first
PASS lesson_1_other_orders
PASS lesson_1_guards
PASS lesson_2_order_enforced
PASS lesson_3_order_enforced
PASS lesson_4_any_order
PASS lesson_5_order_enforced
[probe_lesson_order] all_five_lessons_on_disk 8 entries on disk covering all 5 identifiers: ["lesson_1", "lesson_2", "lesson_3", "lesson_4", "lesson_5"]
PASS all_five_lessons_on_disk
Lesson order probe passed.
Lesson select probe passed.
Lesson kit probe passed.
Progress persistence probe passed.
Screen flow probe passed.
Menu button probe passed.
Camiel movement probe passed.
Audio bus probe passed.
```

**The five identifiers read off the disk** are the `all_five_lessons_on_disk` line above: `lesson_1`, `lesson_2`, `lesson_3`, `lesson_4`, `lesson_5`, across **8 entries** (three lesson-1 completions, one each for lessons 2, 3 and 5, two for lesson 4 — one per driven order). Every entry was required to carry exactly four fields and a star count of three. The expected set is built from `const LESSONS` rather than a literal list in the probe, so a sixth lesson in a later phase is covered by this assertion the day its row lands.

**The two new lessons' JSON entries, read back off the disk:**

```
[probe_lesson_order] lesson_4_any_order last progress entry: {
	"completed_at": "2026-09-13T01:40:06",
	"lesson_id": "lesson_4",
	"stars": 3.0,
	"time_seconds": 0.009
}
[probe_lesson_order] lesson_5_order_enforced last progress entry: {
	"completed_at": "2026-09-13T01:40:07",
	"lesson_id": "lesson_5",
	"stars": 3.0,
	"time_seconds": 0.037
}
```

Each is read with a `FileAccess` handle and `JSON.new().parse()` — never `JSON.parse_string()`, whose engine `ERROR:` line would fail the headless check even on a correct path. `stars` prints as `3.0` only because the probe re-parses the file before printing and Godot's JSON module returns every number as float on parse; the on-disk bytes hold plain JSON integers. Lesson 4's case asserted `entries_before + 1` after its first completion and `entries_before + 2` after its second; lesson 5's asserted `+1`. Appends, not overwrites.

**The cue assertions, printed from the running scenes:**

```
[probe_lesson_order] lesson_2_order_enforced cue shape, shapes ["cylinder", "box", "prism"], texts ["", "", ""], one shared colour (0.9294, 0.6196, 0.302, 1.0)
[probe_lesson_order] lesson_3_order_enforced cue text, shapes ["cylinder", "cylinder", "cylinder"], texts ["1", "2", "3"], one shared colour (0.13, 0.35, 0.82, 1.0)
[probe_lesson_order] lesson_4_any_order cue colour, pair (0.98, 0.82, 0.18, 1.0) / (0.2, 0.65, 0.28, 1.0) separated by 0.805, 3 counting objects all sphere (0.55, 0.36, 0.72, 1.0) labelled ""
[probe_lesson_order] lesson_5_order_enforced colour (0.62, 0.24, 0.45, 1.0) is 0.624 from the other sequence lesson's (0.13, 0.35, 0.82, 1.0)
[probe_lesson_order] lesson_5_order_enforced cue text, shapes ["cylinder", "cylinder", "cylinder", "cylinder"], texts ["1", "2", "3", "4"], one shared colour (0.62, 0.24, 0.45, 1.0)
```

**The lesson-select screen, read out of band rather than assumed.** A throwaway read-only script opened the live screen and printed what it actually built — after Task 1:

```
[confirm] LESSONS table rows: 4
[confirm] %LessonGrid children: 4 -> ["lesson_1(label=Les 1, icon=lesson_colors)", "lesson_2(label=Les 2, icon=lesson_shapes)", "lesson_3(label=Les 3, icon=lesson_sequence)", "lesson_4(label=Les 4, icon=lesson_colors)"]
```

and after Task 2:

```
[confirm] LESSONS table rows: 5
[confirm] %LessonGrid children: 5 -> ["lesson_1(label=Les 1, icon=lesson_colors)", "lesson_2(label=Les 2, icon=lesson_shapes)", "lesson_3(label=Les 3, icon=lesson_sequence)", "lesson_4(label=Les 4, icon=lesson_colors)", "lesson_5(label=Les 5, icon=lesson_sequence)"]
```

`probe_lesson_select.gd` needed **no change at all** for either new lesson — it gained full coverage of both purely from the two appended table rows. Task 3's edits to that file add the five-entry count and the distinctness assertions, which are about the table as a whole rather than about any lesson.

**Measured frame counts** (fixed 60fps headless): teleport-to-refusal was 2 physics frames for every out-of-turn touch in lesson 5, matching lessons 2 and 3, and well inside the 120-frame ceiling every shipped probe uses.

## Exactly five record call sites

```
$ grep -rl 'record_lesson_complete' --include='*.gd' scripts | grep -v -e '^scripts/tools/' -e '^scripts/progress_tracker\.gd$'
scripts/lesson_1.gd
scripts/lesson_2.gd
scripts/lesson_3.gd
scripts/lesson_4.gd
scripts/lesson_5.gd
```

Five lessons, five call sites, one per lesson. The archived count was **zero**, while `docs/` claimed otherwise. This is now a `<verify>` command in the plan rather than a note, so a sixth lesson that forgets to record, or something other than a lesson that starts recording, fails the gate.

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
[setup] copying working tree to /var/folders/05/.../tmp.UUPujQjmuV
PASS case 1: fresh copy with no .godot cache passes
PASS case 2: planted parse error fails
PASS case 3: planted runtime script error fails
PASS case 4: planted scene with missing ext_resource fails
PASS case 5: C# file rejected
PASS case 6: raw key-state polling rejected
PASS case 7: wrong base renderer rejected
PASS case 8: wrong engine version rejected
PASS case 9: engine stall reported
PASS case 10: missing engine binary exits 2
PASS case 11: invalid limit override exits 2
PASS case 12: zero behaviour probes fails
PASS case 13: removing one named probe (probe_screen_flow.gd) while others remain still passes -- known gap in the probe-presence guard
PASS case 14: inert inline audio bus configuration (no layout resource) fails, naming the audio probe
PASS case 15: generic ERROR during import fails
Headless check self-test passed.
EXIT=0

$ python3 scripts/tools/quality_gate.py --root .
Quality gate passed.
EXIT=0

$ python3 -m unittest tests.test_quality_gate tests.test_ci_workflows
..............
----------------------------------------------------------------------
Ran 14 tests in 0.012s

OK
EXIT=0
```

## Files Created/Modified

- `scripts/lesson_4.gd` — `_on_task_completed` (the nested counting rule), `_mark_task`, `_on_hud_back_requested`, `_apply_lesson_complete`; `transition_requested` and `lesson_completed` signals; title `Les 4 - Geel, groen en tellen`; 142 lines
- `scenes/lesson_4.tscn` — `Lesson4 : Node3D` with the shared `LessonRoom`, `PlayerSpawn` and `Camiel` at `(0, 0.1, 4.5)`, `%Hud`, `%YellowTarget` / `%GreenTarget` (both `box`, nothing gated) and `%CountGroup` holding three purple `sphere`s
- `scripts/lesson_5.gd` — `_sequence` (the order, four targets), `_on_task_completed` (append, advance, activate or finish), `_on_hud_back_requested`, `_apply_lesson_complete`; `const TOTAL_TASKS := 4`; title `Les 5 - Van 1 naar 4`; 152 lines
- `scenes/lesson_5.tscn` — `Lesson5 : Node3D` with `%Step1Target` … `%Step4Target` (all `cylinder`, all berry, `display_text` `1` … `4`, all `requires_activation = true`)
- `scripts/lesson_select.gd` — two appended table rows; nothing else in the file changed
- `scripts/tools/probe_lesson_order.gd` — `_colour_count_targets`, `_target_labels`, `_scene_colour`, `_colour_separation`, `_assert_colour_is_the_cue`, `const MIN_COLOUR_SEPARATION`, `const EXPECTED_LESSON_COUNT`, the three new cases, and the total threaded through `_step_label_text`, `_drive_touch_sequence` and `_drive_ordered_lesson`
- `scripts/tools/probe_lesson_select.gd` — `const EXPECTED_LESSON_COUNT` and the count plus three distinctness assertions

### Files touched outside the plan's declared lists

One, named as required:

- **`.planning/phases/03-3d-lesson-parity-progress-persistence/deferred-items.md`** — a paragraph appended to the existing Jolt item recording that it did **not** recur (see Issues Encountered). No item was removed, softened or closed.

`scripts/lesson_target.gd`, `scenes/lesson_target.tscn`, `scenes/lesson_room.tscn`, `scenes/ui/lesson_hud.tscn`, `scripts/ui/lesson_hud.gd`, `scripts/lesson_1.gd`, `scripts/lesson_2.gd`, `scripts/lesson_3.gd` and `scripts/progress_tracker.gd` are all **unchanged** — reused, not forked (D-45). `git diff f6404a7..HEAD --stat` touches nine tracked files, all of them in this plan's declared lists.

Both generators were throwaway `zz_*` scripts, deleted after use and never staged; `git ls-files '*zz_*'` is empty. Each seeded its scene by instantiating an already-shipped sibling (`lesson_1.tscn` for lesson 4, `lesson_3.tscn` for lesson 5), swapping the root script, stripping the sibling's own targets and adding new ones — which is why the new scenes carry byte-identical room, spawn, character and display setup and differ only in their targets. Neither sibling scene was modified (`git status --short scenes/lesson_1.tscn scenes/lesson_3.tscn` empty after both generator runs).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug in the plan's own geometry] The counting objects are 2.088 m apart, not "about a metre"**

- **Found during:** Task 1, laying out the scene against 03-03's recorded thresholds
- **Issue:** Task 1 step B says to group the three counting objects "about a metre apart". 03-03 measured that two 0.55-radius target areas **overlap** below 1.1 m, so one teleport can complete two targets at once. At a metre the case's per-step label assertions (`1 / 3`, `1 / 3`, `2 / 3`) would not be testable — not flaky, untestable — because the second and third counting objects could register from one touch.
- **Fix:** 2.088 m between neighbouring counting objects (1.90× the overlap threshold, 2.32× the capsule-reach threshold), arranged as a shallow triangle rather than lesson 1's row. Still one recognisable group in one part of the room; still further apart than lesson 1's own 1.4 m.
- **Files modified:** `scenes/lesson_4.tscn`
- **Verification:** every touch in both driven orders registered exactly one completion; the label held at `1 / 3` across the first two counting objects in both orders
- **Committed in:** `3944df7`

**2. [Rule 2 — Missing critical verification] The plan's lesson 4 order was the same shape as one lesson 1 already drove**

- **Found during:** Task 1, reading the plan's step D against its own instruction
- **Issue:** step D says to "drive a different order from the ones lesson 1's cases used" and then prescribes yellow → three counting objects → green, which is exactly the shape of lesson 1's `other_orders` run 1 (red → three counting objects → blue). For an **unordered** lesson, one order proves nothing about order-independence — that is the requirement's whole content.
- **Fix:** the prescribed order is driven **and** a second, genuinely different one: green → count_3 → count_1 → yellow → count_2, which gathers the counting objects out of their declared index order and interleaves a colour target into the middle of the counting task. A lesson that reset or forgot a partly-gathered count passes order 1 and fails order 2.
- **Files modified:** `scripts/tools/probe_lesson_order.gd`
- **Verification:** both orders complete exactly once with the correct label after every step; the progress file grows by exactly 2 across the two
- **Committed in:** `3944df7`

**3. [Rule 2 — Missing critical functionality] The cue assertion was one-sided and too weak in both directions**

- **Found during:** Task 1, applying 03-04's `_assert_colour_is_not_the_cue` to a lesson whose cue genuinely *is* colour
- **Issue:** two gaps. First, the existing helper required only that an ordered lesson's targets differ in *something* — so a numeral lesson could hand a child three different shapes and still pass, and the shape rather than the number would be what was learned. Second, nothing at all covered a colour lesson: lesson 4 could have shipped with a box and a sphere, turning "which one is green" into "which one is round", and every completion assertion would still have passed.
- **Fix:** `_assert_colour_is_not_the_cue` now takes a named cue and requires the *other* property to be uniform (shape lessons hold labels uniform, numeral lessons hold shapes uniform). `_assert_colour_is_the_cue` is its inverse for lesson 4: the pair must differ in colour by at least `MIN_COLOUR_SEPARATION` and be identical in shape and label, the counting objects must be uniform in all three, and their colour must be a real distance from both of the lesson's two.
- **Files modified:** `scripts/tools/probe_lesson_order.gd`
- **Verification:** lessons 2, 3 and 5 pass under the stricter rule with no scene change; RED exercises A and B above show both halves of the new assertion failing by name
- **Committed in:** `3944df7`

**4. [Rule 2 — Missing critical verification] Lesson 4's pair was never proved to be a different pair from lesson 1's**

- **Found during:** Task 1, against the plan's `<behavior>` line "clearly different colours from each other **and from lesson 1's pair**"
- **Issue:** the plan states it as behaviour and specifies no assertion for it. A second colour lesson in the first one's two colours would teach a child nothing they had not already been asked, and nothing would have failed.
- **Fix:** `_scene_colour` reads the declared colours straight out of `lesson_1.tscn`'s packed scene (no instantiation, no second 3D room in the case), and lesson 4's case requires each of its own two to be at least `MIN_COLOUR_SEPARATION` from each of lesson 1's. The same helper gives lesson 5 the equivalent check against lesson 3's blue, so the two sequence lessons read as two rooms.
- **Files modified:** `scripts/tools/probe_lesson_order.gd`
- **Verification:** all four lesson-1 comparisons run 0.622–1.163; lesson 5 vs lesson 3 is 0.624
- **Committed in:** `3944df7` (lesson 4), `e7c1c41` (lesson 5)

**5. [Rule 2 — Missing critical verification] The closing case could not see a lesson filing progress under an identifier no button reads back**

- **Found during:** Task 3, writing the case against Pitfall 3's warning
- **Issue:** the plan asks the closing case to assert the file *contains* all five identifiers. That catches a lesson that never records, but not a lesson that records under the **wrong** identifier while the table offers the right one — its own per-lesson case would still pass if the two agreed with each other, and a child's history would be filed where no dashboard can ever find it.
- **Fix:** the case also requires every identifier *found in the file* to be one the table offers, so an unknown identifier fails as loudly as a missing one.
- **Files modified:** `scripts/tools/probe_lesson_order.gd`
- **Verification:** the case passes on the real five; RED exercise C shows the missing-identifier half failing by name
- **Committed in:** `70a6a78`

### Adjusted, Not Fixed

**6. [Plan step wording] The `all_five_lessons_on_disk` success line is a literal, unlike its siblings**

Task 3's acceptance criterion requires `grep -Fq 'PASS all_five_lessons_on_disk' scripts/tools/probe_lesson_order.gd` to succeed. Every other case in that file prints `"PASS %s" % case_name`, so the contiguous string never appears in the source and the criterion would have been vacuous. This one case prints the literal instead, with a comment saying why: a success line the whole phase's gate is checked for should be findable by searching the file for it, not only by running the process. Runtime output is unchanged.

**7. [Structural] The lesson-1 colour-and-counting probe helpers are shared with lesson 4, not copied**

`_lesson_1_targets` became `_colour_count_targets(case_name, lesson, first_name, second_name)` and `_drive_touch_sequence` gained `lesson_id` and `total` parameters, so lesson 1's three cases and lesson 4's case run through one driver. This follows 03-04's precedent for `_drive_ordered_lesson` and is the opposite of D-35's constraint, which binds the **orchestrators**: `scripts/lesson_1.gd` and `scripts/lesson_4.gd` remain independent files with no shared base. Sharing the probe driver means a regression in the all-three-any-order rule fails *both* lessons' cases instead of one. Lessons 1, 2 and 3 were re-run green on the refactored helpers before lesson 4's scene existed — that run is the Task 1 RED output above, where the first five `PASS` lines are the pre-existing coverage surviving the refactor.

`_drive_touch_sequence` also picked up `_assert_space_key_reaches_nothing`, which the plan specifies for lesson 4; lesson 1's other-orders case now carries it too, which is strictly more coverage than it had.

### Process Deviations

**8. [Executor error, self-corrected] A blanket `git checkout --` discarded uncommitted work, which was fully re-applied**

While restoring `scripts/tools/probe_lesson_order.gd` after Task 3's RED exercise C, `git checkout -- <file>` was used instead of reversing the temporary edit in place. `HEAD` was Task 2 at that moment, so the restore also discarded Task 3's uncommitted additions (the two constants, the `_initialize` registration and the whole `_case_all_five_lessons_on_disk` function). They were re-applied immediately and the file re-checksummed to `7868622f08e418c1229d66a2b8662d734ff6841fca57db735d5ee88962ea7793` — **byte-identical** to its pre-exercise state — and re-run green before anything was committed. No work was lost and nothing shipped from the damaged state. The lesson is the one the executor's own guidance states: reverse a temporary edit the same way it was made, and never use a blanket working-tree restore on a file that holds uncommitted work.

**9. [Branch policy] Commits landed on `main` under the pre-existing config override**

`HEAD` was on `main` when this executor started and `.planning/config.json` already carried `git.allow_default_branch_commits: true` (written by plan 03-03, and gitignored, so it is a local setting rather than a repository change). This executor did **not** modify that config. No commit was pushed, no tag created, no workflow run triggered, and git credential configuration was not touched.

---

**Total deviations:** 9 — one geometry correction, four added verifications closing real gaps, one acceptance-criterion literalism, one documented structural choice, one self-corrected executor error, one pre-existing process override. **Impact:** all four added verifications strengthen the suite; the geometry correction is what makes lesson 4's per-step assertions testable at all; none changed the behaviour either `<behavior>` block describes.

## Known Stubs

None. Both lessons are real, completable lessons driven end to end by a probe — lesson 4 from two different orders, lesson 5 through its full four-step sequence — and neither scene contains a target without a working completion rule. The lesson table is complete at five rows and every row's scene exists, loads and instantiates as a 3D node, asserted per entry.

## Threat Flags

None. No new network endpoint, auth path, file access pattern or schema change was introduced. The save file's schema is unchanged and is now asserted to be exactly the four fields plan 03-01 defined, which narrows the surface rather than widening it.

## Issues Encountered

**The Jolt warning from 03-04 did not recur — 0 occurrences in 6 consecutive runs.** `deferred-items.md` logs an intermittent `WARNING: Jolt Physics job system exceeded the maximum number of jobs` seen once in six runs during plan 03-04, with the plausible cause recorded as pressure from the probe instantiating eight full 3D rooms in one process. That probe now instantiates **thirteen** (lessons 4 and 5 add five more instances between them), which should have made an instance-count-driven warning more frequent. It appeared zero times across six consecutive runs, every one of which ended `Lesson order probe passed.`:

```
run 1: jolt_warnings=0 passed=1
run 2: jolt_warnings=0 passed=1
run 3: jolt_warnings=0 passed=1
run 4: jolt_warnings=0 passed=1
run 5: jolt_warnings=0 passed=1
run 6: jolt_warnings=0 passed=1
total Jolt warnings across 6 runs: 0
```

The item stays logged rather than closed — six clean runs do not disprove an intermittent warning — but it is now recorded as **not scaling with the number of rooms**, which argues against room count being the cause. **Nothing was loosened to accommodate it:** `run_headless_check.sh`'s log scan still matches `SCRIPT ERROR`, `Parse Error` and `ERROR:` exactly as before, no watchdog limit was raised, and no probe was changed. If it does become frequent, the recorded fix stands: free each lesson instance decisively rather than relying on `queue_free()` plus two process frames.

**One assertion in this plan's own work briefly broke a pre-existing invariant, and was fixed at the root.** Lesson 5's header comment originally quoted the shared progress-label format string to explain the D-46 resolution, which made `grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l` return `2`. The invariant does not distinguish a comment from code, and it should not — a probe that quotes the display's format string is exactly the defect 03-04 fixed. The comment was rewritten to describe the form rather than reproduce it, and now says so explicitly so the next person does not reintroduce it. The count is back to `1`.

Both implementation tasks otherwise passed on the first probe run after their scenes were generated; neither generator needed a fix.

## User Setup Required

None — no external service configuration, no package install of any kind, and no third-party asset. Every mesh, material and label in both new scenes is an engine primitive built by code already in the repository.

## Next Phase Readiness

- **For plan 03-06 (the convergent pass):** all five lessons exist, all five are driven to real completions in one probe run, all five record, and all five identifiers land on disk. `LESSON-01`..`LESSON-05`, `LESSON-06` and `PROGRESS-02` are closed in behaviour and left **unchecked** in `REQUIREMENTS.md` per the shared-ID rule, because 03-06 carries them too.
- **Reusable surface this plan adds:** `_colour_count_targets`, `_drive_touch_sequence(…, lesson_id, total)`, `_target_labels`, `_scene_colour`, `_colour_separation`, `_assert_colour_is_the_cue`, `_assert_colour_is_not_the_cue(…, cue)`, `_case_all_five_lessons_on_disk`, and `EXPECTED_LESSON_COUNT` in both probes. A sixth lesson in a later phase needs: its scene and script, one appended table row, one case, and `EXPECTED_LESSON_COUNT` bumped in two places — the closing persistence assertion covers it automatically because it reads the table.
- **The two `EXPECTED_LESSON_COUNT` constants are deliberately duplicated**, one per probe, rather than shared. Each probe is a standalone `--script` entrypoint and neither imports the other; a lesson added without updating both fails loudly in whichever was missed, which is the desired behaviour.
- **Carried forward unchanged:** the `REQUIRED_PROBES` named-probe allow-list gap is still deliberately absent and remains out of Phase 3 scope per `03-VALIDATION.md`. With eight probes now in the glob, deleting any single one still leaves the check green with that probe's whole coverage silently gone — `test_headless_check.sh` case 13 asserts this known gap explicitly rather than hiding it. Tracked in `STATE.md`'s Pending Todos and in `deferred-items.md`.
- **`project.godot` was not touched** by this plan (`git diff f6404a7..HEAD -- project.godot` is empty), so the `config/name` / `OS.get_user_data_dir()` cross-phase hazard is unchanged. Phase 4's CI-02 version-string work can still silently orphan every child's `progress.json`; the risk is now larger in kind, because the file holds five lessons' history rather than three.
- **Manual verification still outstanding** (`03-RESEARCH.md`'s Manual-Only table): progress surviving a real process exit and relaunch; whether a refusal reads as gentle rather than as a failure to a real three-year-old; and, new with this plan, whether a three-year-old actually distinguishes this yellow from this green on a real screen. 0.805 in RGB distance is a machine's answer to that question, not a child's — the colours were chosen from the room's existing palette and are far apart numerically, but only a person watching a child can confirm the lesson teaches what it means to.

## Self-Check: PASSED

- `scripts/lesson_4.gd` — FOUND
- `scripts/lesson_4.gd.uid` — FOUND
- `scenes/lesson_4.tscn` — FOUND
- `scripts/lesson_5.gd` — FOUND
- `scripts/lesson_5.gd.uid` — FOUND
- `scenes/lesson_5.tscn` — FOUND
- Commit `3944df7` — FOUND in `git log --oneline --all`
- Commit `e7c1c41` — FOUND in `git log --oneline --all`
- Commit `70a6a78` — FOUND in `git log --oneline --all`
- All acceptance criteria from Tasks 1, 2 and 3 re-verified with the plan's exact `grep`/`test`/`awk` commands — all PASS
- `git diff f6404a7..HEAD -- scripts/lesson_select.gd` shows two added table rows and nothing else — verified
- `grep -rl 'Stap: %d / %d' --include='*.gd' scripts | wc -l` returns `1` — verified
- `grep -rl 'record_lesson_complete' --include='*.gd' scripts` outside tools and the tracker returns exactly 5 files — verified
- `git ls-files '*zz_*'` empty — verified
- `git diff f6404a7..HEAD -- scripts/lesson_target.gd scenes/lesson_target.tscn scenes/lesson_room.tscn scenes/ui/lesson_hud.tscn scripts/ui/lesson_hud.gd scripts/lesson_1.gd scripts/lesson_2.gd scripts/lesson_3.gd scripts/progress_tracker.gd project.godot` empty — verified (reused, not forked)
- `bash scripts/tools/run_headless_check.sh` — PASSED (exit 0)
- `bash scripts/tools/test_headless_check.sh` — PASSED (exit 0, all 15 cases)
- `python3 scripts/tools/quality_gate.py --root .` — PASSED
- `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` — PASSED (14 tests, OK)

---
*Phase: 03-3d-lesson-parity-progress-persistence*
*Completed: 2026-09-13*
