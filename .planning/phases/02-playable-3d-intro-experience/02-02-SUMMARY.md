---
phase: 02-playable-3d-intro-experience
plan: 02
subsystem: ui
tags: [godot, control, theme, procedural-icons, headless-probe]

requires:
  - phase: 02-playable-3d-intro-experience (plan 01)
    provides: rebuilt AudioManager autoload, genuine-Vorbis audio, default_bus_layout.tres — unrelated but confirms the phase's headless check baseline stayed green
provides:
  - "scenes/ui/menu_button.tscn + scripts/ui/menu_button.gd — the single reusable icon-plus-label button (D-16), used by every later screen this phase"
  - "scripts/ui/vector_icon.gd — get_icon_shapes(kind, size), a pure function drawing all six phase icons in code (D-13)"
  - "assets/theme/ui_theme.tres — the one Theme resource carrying every color/font-size/spacing token the three screens will consume"
affects: [title-screen, main-menu, win-screen, phase-4-contrast-pass]

actuals:
  tokens: 6375
  tasks: 2
  commits: 2
plan_head_before: f9769739ab1eeab24cb1a4482366890d619f2fb5

tech-stack:
  added: []
  patterns:
    - "Pure shape-descriptor function (get_icon_shapes) separated from its _draw() renderer, so headless probes assert geometry without a display"
    - "Theme type variations (DisplayLabel/HeadingLabel/ButtonLabel/SmallLabel) on the Label base type, so screens opt into a typography token via theme_type_variation instead of local overrides"
    - "Scene and resource files built via a throwaway zz_-prefixed generator script run once through the engine, then deleted before commit"

key-files:
  created:
    - assets/theme/ui_theme.tres
    - scenes/ui/menu_button.tscn
    - scripts/ui/menu_button.gd
    - scripts/ui/vector_icon.gd
    - scripts/tools/probe_menu_button.gd
  modified: []

key-decisions:
  - "Task 1 (tracer) implemented only the \"play\" icon kind, matching its own tested behavior; Task 2 (expansion) completed the remaining five kinds — this follows the plan's own split (Task 2's action literally says \"Complete get_icon_shapes ... for the remaining five kinds\") rather than building all six icons in Task 1 despite Task 1's action text describing the full inventory as reference context"
  - "Label's mouse_filter is written explicitly in the saved scene even though it equals Label's own class default (MOUSE_FILTER_IGNORE) — Godot's serializer otherwise omits properties matching the class default, which would leave only 2 of 3 inner nodes showing MOUSE_FILTER_IGNORE in the text file; the explicit line documents the tap-through contract for a future reader without changing runtime behavior"
  - "HSlider grabber/track styleboxes and the PanelContainer stylebox were registered in ui_theme.tres now, ahead of the main-menu/win-screen plans that will consume them, per the plan's explicit instruction not to leave later plans to invent local overrides"

requirements-completed: [MENU-01, MENU-02, INTRO-05]

coverage:
  - id: D1
    description: "One reusable icon-plus-label button (menu_button.tscn) activates via exactly one path (BaseButton.pressed), no second signal or input-callback override"
    requirement: "MENU-01"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_menu_button.gd#focus_and_single_emission"
        status: pass
      - kind: integration
        ref: "scripts/tools/probe_menu_button.gd#label_and_icon_binding"
        status: pass
      - kind: integration
        ref: "scripts/tools/probe_menu_button.gd#defaults"
        status: pass
      - kind: other
        ref: "grep -c '^signal ' scripts/ui/menu_button.gd == 0; grep for _input/_gui_input in scripts/ui == empty"
        status: pass
    human_judgment: false
  - id: D2
    description: "All six icon kinds (play, walk, replay, home, speaker, music_note) return real geometry from a pure, headlessly-testable function; an unrecognised kind fails soft"
    requirement: "INTRO-05"
    verification:
      - kind: unit
        ref: "scripts/tools/probe_menu_button.gd#play_icon_geometry"
        status: pass
      - kind: unit
        ref: "scripts/tools/probe_menu_button.gd#all_icon_kinds"
        status: pass
      - kind: integration
        ref: "scripts/tools/probe_menu_button.gd#live_redraw"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every color, font size, corner radius and border width the three screens need lives in one ui_theme.tres Theme resource, including the calm (non-animated) four Button states"
    verification:
      - kind: unit
        ref: "scripts/tools/probe_menu_button.gd#theme_states"
        status: pass
      - kind: other
        ref: "grep -F 'type=\"Theme\"' assets/theme/ui_theme.tres"
        status: pass
    human_judgment: false
  - id: D4
    description: "A tap anywhere on the 280x112 button reaches the root Button — inner content nodes ignore the mouse — fixing the archived Start-button defect"
    requirement: "MENU-02"
    verification:
      - kind: integration
        ref: "scripts/tools/probe_menu_button.gd#tap_through"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-09-12
status: complete
---

# Phase 2 Plan 2: Menu Button and Icon System Summary

**Single focusable icon-plus-label Button component with six procedurally-drawn icons and a centralized Theme resource, proven by an 8-case headless probe with no display.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-12 (session start)
- **Completed:** 2026-09-12T18:26:27Z
- **Tasks:** 2 completed
- **Files modified:** 8 (5 created source files + 3 engine-generated `.uid` sidecars)

## Accomplishments

- `scenes/ui/menu_button.tscn` + `scripts/ui/menu_button.gd`: the single reusable
  `Button`-rooted component every screen this phase uses (D-16). No signal of its own, no
  `_input`/`_gui_input` override — tap, click, and `ui_accept` on the focused control all
  resolve to the inherited `pressed` signal exactly once (D-14).
- `scripts/ui/vector_icon.gd`: `get_icon_shapes(kind, size)` is a pure function returning
  polygon/circle/arc/rect descriptors for all six phase icons (play, walk, replay, home,
  speaker, music_note); `_draw()` only renders what it returns. An unrecognised kind warns
  and returns nothing rather than raising.
- `assets/theme/ui_theme.tres`: one engine-generated `Theme` resource carrying the UI
  contract's colors, four font sizes as Label type variations (`DisplayLabel`,
  `HeadingLabel`, `ButtonLabel`, `SmallLabel`), the four calm Button state styleboxes
  (normal/hover/pressed/focus, plus a disabled entry for completeness), the
  `PanelContainer` panel stylebox, and `HSlider` track/grabber styleboxes for later plans
  to consume.
- `scripts/tools/probe_menu_button.gd`: 8 passing cases (`focus_and_single_emission`,
  `label_and_icon_binding`, `play_icon_geometry`, `defaults`, `all_icon_kinds`,
  `live_redraw`, `tap_through`, `theme_states`), picked up automatically by
  `run_headless_check.sh`'s `probe_*.gd` glob.

## Task Commits

Each task was committed atomically:

1. **Task 1: One focusable icon-and-label button, activated by exactly one signal, proved headlessly** - `0916c04` (feat)
2. **Task 2: The remaining five icons, the four visual states, and the tap-through guarantee** - `28ddd56` (feat)

_Note: both tasks carried `tdd="true"`; RED evidence for each is recorded below rather than
as a separate commit — task_commit_protocol calls for one commit per completed task, and the
plan's own action text only instructs a commit at the GREEN step._

## RED Evidence

**Task 1 RED** — before `scenes/ui/menu_button.tscn` existed:

```
ERROR: Cannot open file 'res://scenes/ui/menu_button.tscn'.
ERROR: Failed loading resource: res://scenes/ui/menu_button.tscn.
ERROR: Could not load res://scenes/ui/menu_button.tscn
ERROR: focus_and_single_emission: menu button scene failed to load
```

The probe failed for the intended reason (the scene not existing yet), not a parser error or
fixture crash — a valid RED.

**Task 2 RED** — before the remaining five icon kinds were implemented:

```
ERROR: all_icon_kinds: get_icon_shapes("walk", ...) returned no shapes
```

`get_icon_shapes` correctly returned an empty array (fail-soft default) for the still-missing
kinds; the new `all_icon_kinds` case caught it as intended.

## Resolved Theme Hex Values

| Token | Hex | Where |
|-------|-----|-------|
| Screen background | `#9ED1F2` | not consumed by this plan's outputs directly; registered for later screens |
| Panel/button fill | `#FFF6E8` | `Button` normal/hover/pressed styleboxes, `PanelContainer` panel |
| Accent | `#ED9E4D` | icon default color, `Button` focus stylebox border (4px) |
| Text | `#1F3A56` | `ButtonLabel`/`DisplayLabel`/`HeadingLabel`/`SmallLabel` font colors, `Button` font colors |
| Border | `#D8CBB0` | `Button`/`PanelContainer`/`HSlider` track borders (2px) |
| Destructive (reserved, unwired) | `#D9534F` | stored as `GameColors/colors/destructive` in the theme, not consumed anywhere |

## Files Created/Modified

- `assets/theme/ui_theme.tres` - shared Theme resource: colors, 4 font-size type variations, Button/PanelContainer/HSlider styleboxes
- `scenes/ui/menu_button.tscn` - `MenuButton : Button` with `Content : VBoxContainer` (mouse-ignored) → `%Icon`, `%Label`
- `scripts/ui/menu_button.gd` - exported `label_text`/`icon_kind`, `_ready()` binding, no signal or input override
- `scripts/ui/vector_icon.gd` - `get_icon_shapes()` pure function for all six icon kinds, `_draw()` renderer
- `scripts/tools/probe_menu_button.gd` - 8-case headless probe, auto-discovered by `run_headless_check.sh`

## Decisions Made

See `key-decisions` in frontmatter: the tracer/expansion split between Task 1 ("play" only)
and Task 2 (remaining five kinds), the explicit `mouse_filter` line on `%Label` for
serializer-default reasons, and registering `PanelContainer`/`HSlider` theme entries ahead of
the plans that will consume them.

## Deviations from Plan

None - plan executed exactly as written. The apparent overlap between Task 1's action text
(which fully describes all six icon constructions) and Task 2's action text (which says
"Complete ... for the remaining five kinds") was resolved by following Task 1's own
`<behavior>`/acceptance scope (only "play" is tested) and Task 2's explicit "remaining five"
wording — this is an interpretation of an already-locked plan, not a change to it.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `scenes/ui/menu_button.tscn` and `assets/theme/ui_theme.tres` are ready for the title
  screen, main menu, and win-screen plans to instantiate/consume directly.
- All four baseline checks (`run_headless_check.sh`, `test_headless_check.sh`,
  `quality_gate.py`, `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows`)
  pass on the current tree.
- No blockers for the next plan in this phase.

## Self-Check: PASSED

- `test -f assets/theme/ui_theme.tres` — FOUND
- `test -f scenes/ui/menu_button.tscn` — FOUND
- `test -f scripts/ui/menu_button.gd` — FOUND
- `test -f scripts/ui/vector_icon.gd` — FOUND
- `test -f scripts/tools/probe_menu_button.gd` — FOUND
- `git log --oneline --all --grep="02-02"` — FOUND (2 commits: `0916c04`, `28ddd56`)
- All plan-level `<verification>` commands re-run clean: `run_headless_check.sh` (Headless
  check passed, all 8 `PASS` lines + `Menu button probe passed.` present),
  `test_headless_check.sh` (13/13 self-test cases pass), `quality_gate.py` (Quality gate
  passed, exit 0).

---
*Phase: 02-playable-3d-intro-experience*
*Completed: 2026-09-12*
