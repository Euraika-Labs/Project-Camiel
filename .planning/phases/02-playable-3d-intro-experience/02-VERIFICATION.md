---
phase: 02-playable-3d-intro-experience
verified: 2026-09-12T00:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-01-PLAN.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-01-SUMMARY.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-02-PLAN.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-02-SUMMARY.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-03-PLAN.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-03-SUMMARY.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-04-PLAN.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-04-SUMMARY.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-05-PLAN.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-05-SUMMARY.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-06-PLAN.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-06-SUMMARY.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-CONTEXT.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-REVIEW-FIX.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-REVIEW.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-UI-SPEC.md"
  - ".planning/phases/02-playable-3d-intro-experience/02-VALIDATION.md"
  - "default_bus_layout.tres"
  - "project.godot"
  - "scenes/collectible.tscn"
  - "scenes/finish_marker.tscn"
  - "scenes/intro_level.tscn"
  - "scenes/main_menu.tscn"
  - "scenes/title_screen.tscn"
  - "scenes/ui/menu_button.tscn"
  - "scripts/audio_manager.gd"
  - "scripts/camiel_controller.gd"
  - "scripts/collectible.gd"
  - "scripts/finish_marker.gd"
  - "scripts/intro_level.gd"
  - "scripts/main_menu.gd"
  - "scripts/title_screen.gd"
  - "scripts/tools/probe_audio_buses.gd"
  - "scripts/tools/probe_camiel_movement.gd"
  - "scripts/tools/probe_menu_button.gd"
  - "scripts/tools/probe_screen_flow.gd"
  - "scripts/tools/run_headless_check.sh"
  - "scripts/tools/test_headless_check.sh"
  - "scripts/tools/verify_3d_project.gd"
  - "scripts/ui/menu_button.gd"
  - "scripts/ui/vector_icon.gd"
covered_digest: "v1:sha256:8992f8b289286d24cf0e512e382bfc88709dcb1c70226bc490a0f31535fdd870"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 2: Playable 3D Intro Experience Verification Report

**Phase Goal:** A child can go from the title screen through the free-play 3D intro level —
moving, jumping, collecting, and reaching the goal — using tap, click, or keyboard, and see a
working win screen.
**Verified:** 2026-09-12
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Pressing Play on the title screen (tap, click, or keyboard) transitions to the main menu exactly once | ✓ VERIFIED | `scripts/title_screen.gd` fires `transition_requested` off `%PlayButton.pressed` only, with a `_transitioning` one-shot guard. `probe_screen_flow.gd#_case_title_screen` drives a real `ui_accept` InputEventAction against the focused button, asserts `transition_requested` fired exactly once and to `res://scenes/main_menu.tscn`, then re-focuses the (still-alive, pre-drain) control and re-presses, asserting the guard blocks the second fire. Independently re-run: `bash scripts/tools/run_headless_check.sh` → `Headless check passed.` |
| 2 | Pressing Start on the main menu (tap, click, or keyboard) begins the 3D intro level through one code path | ✓ VERIFIED | `scripts/main_menu.gd`'s `%StartButton.pressed` → `res://scenes/intro_level.tscn`, guarded identically. `probe_screen_flow.gd#_case_main_menu` exercises the same exactly-once + guard pattern as Truth 1, and `probe_menu_button.gd`/component-level checks confirm the button has no `_input`/`_gui_input` override (`grep`-verified no raw-input override exists in any reviewed script per `02-REVIEW.md`). |
| 3 | In the intro level, Camiel moves freely in 3D space, jumps, and can collect a 3D collectible object with pickup feedback playing exactly once | ✓ VERIFIED | `probe_camiel_movement.gd` is parametrized to run its full case set (movement, jump, camera-follow, fall-return) against `res://scenes/test_space.tscn` **and** a dedicated enclosure case against `res://scenes/intro_level.tscn` directly (const `INTRO_LEVEL_PATH`), closing the "retarget gap" `02-VALIDATION.md` flagged. Collection: `probe_screen_flow.gd#_case_collectible` teleports Camiel onto `%Collectible`, asserts `collected` fires exactly once within 120 physics frames, `monitoring` flips false, `AudioManager.is_sfx_playing()` becomes true within a bounded 2s wall-clock poll, then asserts no second `collected` after 60 more overlapping frames and that a non-player `StaticBody3D` intruder placed in the same volume triggers nothing. `grep -rn "AudioManager.play_sfx(" scripts/` (excluding `scripts/tools/`) returns exactly two call sites, both in `intro_level.gd` — the structural fix for "two independent listeners." A related race (tween-driven `reset()` re-hiding the collectible) was found in code review (WR-01), reproduced with a real failing probe case, and fixed (commit `43eb7fd`); `probe_screen_flow.gd#_case_collectible_reset_cancels_tween` now guards the regression. |
| 4 | Reaching the 3D finish marker shows the win screen with two buttons, "Nog een keer" and "Naar menu", each with an icon, activated by tap, click, or Enter on the focused button, through one code path | ✓ VERIFIED | `scenes/intro_level.tscn` declares `label_text = "Nog een keer"` / `icon_kind = "replay"` and `label_text = "Naar menu"` / `icon_kind = "home"` verbatim. `finish_marker.gd` emits `finished`; `probe_screen_flow.gd#_case_finish_marker` asserts exactly 2 signal connections (level handler + probe counter), the signal fires exactly once within 120 physics frames, `%WinLayer` becomes visible, focus moves to `%ReplayButton`, no re-fire over 60 more overlapping frames, and a non-player intruder triggers nothing. `#_case_win_buttons` drives a full replay-then-second-lap cycle (both buttons independently pressed, exactly-once each, guard blocks repeats, position/velocity/physics-processing reset asserted) — this is a genuinely exercised behavioral test, not a structural assertion. |
| 5 | Background music loops continuously and the SFX volume control has an audible effect | ✓ VERIFIED (functional loop human-confirmed per D-30) | `probe_audio_buses.gd` asserts: bus topology (Music/SFX → Master) resolves from `default_bus_layout.tres`; BGM stream is `AudioStreamOggVorbis` with `loop == true`; BGM `playing == true` via bounded wall-clock retry; `set_sfx_volume()`/`set_bgm_volume()` each move only their own bus's `volume_db`, verified bidirectionally at extremes and mid-values and through the actual `%SfxSlider`/`%BgmSlider` menu controls. Independently confirmed the three `.ogg` assets are genuine Vorbis (`OggS`/`vorbis` header, hex-dump-verified, not just the `.import` sidecar) and `AudioServer.get_bus_count()` is 3 at runtime (was 1 before this phase, meaning `get_bus_index("SFX")` was `-1`). The audible half (does it actually sound right, is the slider perceptible) was confirmed by the mandated D-30 human playtest, verbatim verdict "it works but graphics are very basic" — a functional pass with no defect or tuning request raised against audio. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scripts/audio_manager.gd` | Rebuilt autoload, corrected bus routing, single source of truth for volume | ✓ VERIFIED | Registered as `AudioManager="*res://scripts/audio_manager.gd"` in `project.godot`; exposes `play_music`, `stop_music`, `play_sfx`, `set_bgm_volume`, `set_sfx_volume`; `probe_audio_buses.gd` exercises it end-to-end |
| `default_bus_layout.tres` | AudioBusLayout with Music/SFX → Master | ✓ VERIFIED | Present, committed; `probe_audio_buses.gd#_case_bus_layout` confirms 3 buses resolve with correct sends |
| `scripts/tools/probe_audio_buses.gd` | D-26 proxies + stream loadability | ✓ VERIFIED | 10 cases run (bus layout, stream, plays, volume isolation x2, slider wiring x2, focus order) |
| `scenes/ui/menu_button.tscn` + `scripts/ui/menu_button.gd` | Reusable focusable icon+label button, no raw input override | ✓ VERIFIED | Used by title screen, main menu, and win overlay; `probe_menu_button.gd` asserts single-emission activation |
| `scripts/ui/vector_icon.gd` | Procedural icon shapes | ✓ VERIFIED | `icon_kind` values `replay`/`home` used and rendered in `intro_level.tscn`'s win buttons |
| `scenes/title_screen.tscn` / `scripts/title_screen.gd` | One-shot guarded transition | ✓ VERIFIED | `application/run/main_scene` = this scene; instantiates as `Control`; probe-confirmed exactly-once |
| `scenes/main_menu.tscn` / `scripts/main_menu.gd` | Start control + audio panel with sliders | ✓ VERIFIED | `%StartButton`, `%SfxSlider`, `%BgmSlider` present with explicit focus order |
| `scenes/intro_level.tscn` / `scripts/intro_level.gd` | Enclosed Node3D level, sole SFX caller, win overlay controller | ✓ VERIFIED | `verify_3d_project.gd` confirms Node3D root; exactly 2 `play_sfx` call sites, both here |
| `scenes/collectible.tscn` / `scripts/collectible.gd` | One-shot latch, `collected` signal, replay-safe reset | ✓ VERIFIED | WR-01 tween-cancellation race fixed and regression-guarded |
| `scenes/finish_marker.tscn` / `scripts/finish_marker.gd` | One-shot latch, `finished` signal, ungated on collectible | ✓ VERIFIED | Probe confirms reachable independent of pickup state |
| `scripts/tools/verify_3d_project.gd` | D-27 gameplay-scene Node3D retarget | ✓ VERIFIED | `_check_gameplay_scene_is_3d()` targets `res://scenes/intro_level.tscn` by name; `_check_main_scene()` no longer requires Node3D root |
| `scripts/tools/probe_screen_flow.gd` | New D-29 probe covering MENU-01/02, INTRO-03/04/05 | ✓ VERIFIED | 7 cases, all behaviorally exercised (see Truths 1-4 above) |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `scripts/title_screen.gd` | `scenes/main_menu.tscn` | `transition_requested` signal → deferred `change_scene_to_file` | ✓ WIRED | Probe-confirmed exactly once + guarded |
| `scripts/main_menu.gd` | `scenes/intro_level.tscn` | same pattern | ✓ WIRED | Probe-confirmed exactly once + guarded |
| `scripts/collectible.gd` | `scripts/intro_level.gd` | `collected` signal → `_on_collectible_collected` → `AudioManager.play_sfx` | ✓ WIRED | Signal-driven, not a direct cross-script call; exactly 2 connections (level + probe counter) |
| `scripts/finish_marker.gd` | `scripts/intro_level.gd` | `finished` signal → `_on_finish_marker_finished` → win overlay | ✓ WIRED | Same pattern, INTRO-04 explicit requirement |
| `scripts/main_menu.gd` sliders | `scripts/audio_manager.gd` | `value_changed` → `set_sfx_volume`/`set_bgm_volume` | ✓ WIRED | Bidirectional bus isolation proven by probe |
| `scenes/ui/menu_button.tscn` | `scripts/ui/vector_icon.gd` | `%Icon` child's attached script | ✓ WIRED | Icons render on all three screens, `replay`/`home` confirmed in win overlay |

### Behavioral Spot-Checks / Gate Reproduction

All four mandated gates were independently re-run by the verifier (not trusted from SUMMARY claims), on the current tree (HEAD `8041195`, clean):

| Gate | Command | Result | Status |
|---|---|---|---|
| Headless check | `bash scripts/tools/run_headless_check.sh` | `import` → `main scene` → `verifier` → 4 probes → `Headless check passed.` | ✓ PASS |
| Headless self-test | `bash scripts/tools/test_headless_check.sh` | 15/15 cases PASS, ending `Headless check self-test passed.` | ✓ PASS |
| Quality gate | `python3 scripts/tools/quality_gate.py --root .` | `Quality gate passed.` | ✓ PASS |
| Python unit tests | `python3 -m unittest tests.test_quality_gate tests.test_ci_workflows` | `Ran 14 tests in 0.009s / OK` | ✓ PASS |

Additionally, `scripts/tools/probe_screen_flow.gd` was read in full and confirmed to contain genuine, non-vacuous behavioral assertions for every "exactly once" / "one code path" claim in the roadmap's success criteria — including deliberate negative tests (non-player intruder bodies, repeated presses after guard engagement, a second lap after replay) that would fail if the underlying defect regressed. This is not a presence/wiring check alone; it is a real behavioral proof for a behavior-dependent set of truths.

### Anti-Patterns Found

Scanned all phase-authored/modified scripts (`audio_manager.gd`, `collectible.gd`, `finish_marker.gd`, `intro_level.gd`, `main_menu.gd`, `title_screen.gd`, `ui/menu_button.gd`, `ui/vector_icon.gd`, `camiel_controller.gd`, `verify_3d_project.gd`, and all four probes) for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` and "not yet implemented"/"placeholder"/"coming soon" phrasing.

**None found.** No debt markers, no stub returns, no empty handlers in the reviewed set.

The one real code-review finding (WR-01: `Collectible.reset()` not cancelling an in-flight pickup tween) was fixed in commit `43eb7fd` with a reproducing regression probe case, and the one info-level dead-code finding (IN-01) was fixed in commit `4fcf4a4`. Both are recorded and closed in `02-REVIEW.md` / `02-REVIEW-FIX.md`, and the fix report's reproduction (probe failing pre-fix, passing post-fix, verified by the fixer diffing the reverted-and-restored tree) is credible, non-vacuous evidence.

The one known, explicitly-accepted gap (`REQUIRED_PROBES` by-name allow-list absent, so removing a whole probe file leaves the check green) is documented as a self-test case (case 13) and a recorded follow-up in `02-06-SUMMARY.md` — per the phase's own scoping decision (`02-VALIDATION.md`'s "Probe-presence guard gap," in-scope minimum satisfied), this is not reported as a gap here.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| MENU-01 | 02-03 | Play transitions to main menu exactly once, any input method | ✓ SATISFIED | `probe_screen_flow.gd#_case_title_screen`; REQUIREMENTS.md marked complete |
| MENU-02 | 02-03, 02-05 | Start responds to tap/click/keyboard through one code path | ✓ SATISFIED | `probe_screen_flow.gd#_case_main_menu`; explicit focus order (Start, SFX slider, BGM slider) |
| INTRO-01 | 02-03 | Camiel moves freely in 3D with camera follow | ✓ SATISFIED | `probe_camiel_movement.gd` retargeted to `intro_level.tscn` directly |
| INTRO-02 | 02-03 | Camiel can jump | ✓ SATISFIED | Same probe, jump case included in the full case set |
| INTRO-03 | 02-04 | Collect object, pickup SFX plays exactly once | ✓ SATISFIED | `probe_screen_flow.gd#_case_collectible` + `#_case_collectible_reset_cancels_tween` |
| INTRO-04 | 02-04 | Finish marker triggers win screen via signal, not direct call | ✓ SATISFIED | `probe_screen_flow.gd#_case_finish_marker`; `grep` confirms no direct cross-script call |
| INTRO-05 | 02-02, 02-04 | Win screen: two labelled/iconned buttons, one code path | ✓ SATISFIED | `probe_screen_flow.gd#_case_win_buttons`; exact Dutch labels + icons confirmed in `.tscn` |
| INTRO-06 | 02-01, 02-05 | BGM loops continuously, SFX volume has audible effect | ✓ SATISFIED | `probe_audio_buses.gd` full case set + D-30 human playtest confirmation |

No orphaned requirements found for Phase 2 in `REQUIREMENTS.md`'s Phase 2 row group.

## Deferred Items

None outstanding for this phase's scope. MODEL-01 (primitive-shape Camiel/collectible art) is explicitly deferred to v2 per `PROJECT.md` and `REQUIREMENTS.md`'s Out of Scope table, and is not a gap — the D-30 human playtest's "graphics are very basic" remark is recorded as out-of-scope feedback in `02-06-SUMMARY.md`, consistent with the verification notes provided for this run.

## Human Verification

None required. The mandated D-30 human playtest was already performed as part of phase execution (plan 02-06) and its verbatim verdict ("it works but graphics are very basic" — a functional pass, no defect or tuning request) is recorded in `02-06-SUMMARY.md` with a clean re-run of all four gates on the exact tree played. No additional human verification items were identified by this audit.

## Gaps Summary

No gaps found. All five ROADMAP.md success criteria are backed by genuine, non-vacuous, independently-reproduced evidence: four automated gates re-run and green on the current HEAD, a hand-read probe file confirming real behavioral (not merely structural) assertions for every "exactly once"/"one code path" claim, a clean anti-pattern scan across every phase-authored script, and a documented, verbatim human playtest closing the two criteria (tap/click on a real device, genuine audibility) that are structurally unreachable headlessly. The phase's own code review found and fixed two issues (WR-01, IN-01) before this verification, both with credible before/after reproduction. The one known guard weakness (`REQUIRED_PROBES` allow-list) was explicitly scoped out by the phase's own validation strategy and is not treated as a gap here, per this run's verification notes.

---

_Verified: 2026-09-12_
_Verifier: Claude (gsd-verifier)_
