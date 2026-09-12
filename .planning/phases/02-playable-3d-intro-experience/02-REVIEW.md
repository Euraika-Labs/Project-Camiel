---
phase: 02-playable-3d-intro-experience
reviewed: 2026-09-12T00:00:00Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - assets/theme/ui_theme.tres
  - default_bus_layout.tres
  - project.godot
  - scenes/collectible.tscn
  - scenes/finish_marker.tscn
  - scenes/intro_level.tscn
  - scenes/main_menu.tscn
  - scenes/title_screen.tscn
  - scenes/ui/menu_button.tscn
  - scripts/audio_manager.gd
  - scripts/collectible.gd
  - scripts/finish_marker.gd
  - scripts/intro_level.gd
  - scripts/main_menu.gd
  - scripts/title_screen.gd
  - scripts/ui/menu_button.gd
  - scripts/ui/vector_icon.gd
  - scripts/tools/probe_audio_buses.gd
  - scripts/tools/probe_camiel_movement.gd
  - scripts/tools/probe_menu_button.gd
  - scripts/tools/probe_screen_flow.gd
  - scripts/tools/verify_3d_project.gd
  - scripts/tools/test_headless_check.sh
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: fixed
fixed_at: 2026-09-12T00:00:00Z
fix_report: 02-REVIEW-FIX.md
---

# Phase 2: Code Review Report

**Reviewed:** 2026-09-12
**Depth:** standard
**Files Reviewed:** 23
**Status:** fixed — see `02-REVIEW-FIX.md` for the fix commits and verification.

## Summary

This phase rebuilds the title screen, main menu, and 3D intro level fresh, exactly as
`02-CONTEXT.md` (D-13) mandates, and explicitly targets every 2D-era defect catalogued in
`CONCERNS.md`. I checked the implementation against each locked decision (D-13..D-30), each
engine-verified fact (VF1..VF23) in `02-RESEARCH.md`, and the UI contract in `02-UI-SPEC.md`,
and traced the actual runtime call graph rather than trusting the SUMMARY files' claims.

Verified directly against the source (not just the SUMMARYs' claims):

- **MENU-01/02 exactly-once:** every scene-changing handler (`title_screen.gd`,
  `main_menu.gd`, `intro_level.gd`'s `_on_go_to_menu_button_pressed`) uses `BaseButton.pressed`
  only, no `_input`/`_gui_input` override anywhere in the reviewed files, and each carries the
  one-shot `_transitioning` guard with a deferred `change_scene_to_file`. No `.tscn` in this
  phase declares a `[connection]` block for these signals (avoiding VF15's double-connect
  risk entirely — everything is wired once, in code).
- **INTRO-03 sole SFX caller:** `grep -rn "AudioManager.play_sfx(" scripts/` (excluding
  `scripts/tools/`) returns exactly two call sites, both in `scripts/intro_level.gd`
  (`_on_collectible_collected`, `_on_finish_marker_finished`). `collectible.gd` only emits
  `collected`; it never touches `AudioManager`.
  `scripts/tools/probe_screen_flow.gd`'s `#collectible` case would catch a regression here (it
  asserts `collected` fires exactly once and drains the SFX bus state before and after).
- **INTRO-04 signal-driven finish:** `finish_marker.gd` declares and genuinely emits
  `finished`; `intro_level.gd` is the only listener (`get_signal_connection_list("finished")`
  is asserted to be exactly 2 — the level's handler plus the probe's own counter — by
  `probe_screen_flow.gd`).
- **INTRO-06 bus isolation:** `AudioManager.set_sfx_volume`/`set_bgm_volume` each call
  `_apply_bus_volume` against their own resolved bus index only; `probe_audio_buses.gd` proves
  bidirectional isolation (moving one bus's `volume_db` leaves the other's untouched) in both
  directions, at extremes and mid-values, plus through the main-menu sliders.
- **Area3D collision layer sharing:** collectible, finish marker, walls, ramp, and ground all
  use Godot's default `collision_layer`/`collision_mask = 1` (VF13), so the `is_in_group
  ("player")` guard in both one-shot handlers is load-bearing, not decorative — and both
  probes plant a non-player `StaticBody3D` intruder and assert it changes nothing.
- **Replay reset:** `_on_replay_button_pressed()` hides the overlay, resumes Camiel's physics,
  calls the already-tested `teleport_to()` (zeroes velocity, snaps camera per VF21), and
  re-arms both `%Collectible` and `%FinishMarker`. `probe_screen_flow.gd#win_buttons` drives a
  full replay-then-second-lap cycle and asserts Camiel's position/velocity/physics-processing
  state, the collectible's visibility/monitoring, and a second `finished` trip — this is
  genuinely exercised, not merely asserted structurally.
- **Focus order:** title screen `[%PlayButton]`, main menu
  `[%StartButton, %SfxSlider, %BgmSlider]`, win screen `[%ReplayButton, %GoToMenuButton]` all
  match `02-UI-SPEC.md` exactly, wired via explicit `focus_neighbor_*`/`focus_next`/
  `focus_previous` NodePaths rather than spatial inference, and cross-checked against
  `probe_audio_buses.gd#menu_focus_order` and `probe_screen_flow.gd`'s per-screen cases.
- **Audio asset integrity:** all three committed `.ogg` files are genuine Vorbis (`OggS` +
  `vorbis` identification header confirmed by hex dump, not just trusting the `.import`
  sidecar), matching D-24/VF1-VF4, and `default_bus_layout.tres` matches the exact
  `AudioBusLayout` shape VF7 specifies.
- **`test_headless_check.sh` Case 13** honestly documents the probe-presence guard's known
  weakness (asserts the check *currently passes* when `probe_screen_flow.gd` alone is removed)
  rather than asserting a stronger guarantee that doesn't exist — this is exactly the kind of
  self-test the project's recurring "check passes but isn't checking" defect class demands,
  and it is not misrepresented here.

I found one real, currently-unreachable robustness gap in the collectible's replay reset (not
covered by any probe) and one line of dead code. No Critical/blocker issues.

## Warnings

### WR-01: `Collectible.reset()` does not cancel the pickup tween, so a replay during the ~0.3s pickup-feedback window can leave the collectible invisible after reset

**File:** `scripts/collectible.gd:64-80`
**Issue:** `_play_pickup_feedback()` (lines 64-68) creates a local `Tween` that is never stored
on the node:

```gdscript
func _play_pickup_feedback() -> void:
	var tween := create_tween()
	tween.tween_property(_mesh, "scale", Vector3.ONE * 1.15, 0.15)
	tween.tween_property(_mesh, "transparency", 1.0, 0.15)
	tween.tween_callback(hide)
```

`reset()` (lines 73-80) directly assigns `_mesh.scale`, `_mesh.transparency`, and calls
`show()`, but never calls `tween.kill()` on any in-flight tween:

```gdscript
func reset() -> void:
	_touched = false
	_elapsed = 0.0
	_mesh.scale = Vector3.ONE
	_mesh.transparency = 0.0
	_mesh.position.y = _rest_height
	monitoring = true
	show()
```

**Concrete failure scenario:** if `reset()` is invoked (from `intro_level.gd`'s
`_on_replay_button_pressed()`) while the 0.3s scale/fade tween from a just-collected pickup is
still running, `reset()`'s `show()` call is immediately undone when the still-running tween's
queued `tween_callback(hide)` fires afterward — the collectible ends the replayed lap
re-armed (`monitoring == true`) but permanently invisible, even though nothing else is wrong.
Under the currently committed level geometry (collectible at `(-2.5, 0.8, -1)`, finish marker
at `(-5, 0, -6)`, ~5.6m apart, walk_speed ~2.5 m/s per `02-03-SUMMARY.md`), reaching the finish
after a pickup takes over 2 seconds — far longer than the 0.3s window — so this is **not
reachable through normal play on the shipped level** and no probe exercises it
(`probe_screen_flow.gd#win_buttons` never triggers the collectible before winning). It is a
real, untested gap that would resurface immediately if a future geometry tweak (explicitly
left open as a tunable in this same codebase, e.g. after a playtest) moved the collectible and
finish marker closer together, or if a level redesign in a later phase reuses this pattern.
**Fix:** store the tween on the node and kill any prior one before starting a new one, and
kill it defensively in `reset()`:

```gdscript
var _pickup_tween: Tween

func _play_pickup_feedback() -> void:
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(_mesh, "scale", Vector3.ONE * 1.15, 0.15)
	_pickup_tween.tween_property(_mesh, "transparency", 1.0, 0.15)
	_pickup_tween.tween_callback(hide)

func reset() -> void:
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	_touched = false
	_elapsed = 0.0
	_mesh.scale = Vector3.ONE
	_mesh.transparency = 0.0
	_mesh.position.y = _rest_height
	monitoring = true
	show()
```

## Info

### IN-01: Dead assignment in the replay handler

**File:** `scripts/intro_level.gd:86`
**Issue:** `_on_replay_button_pressed()` sets `%Scrim.modulate.a = 1.0` right after hiding
`%WinLayer`. Since `%WinLayer` is invisible at that point and every future appearance of the
win overlay goes through `_on_finish_marker_finished()`, which unconditionally resets
`%Scrim.modulate.a = 0.0` before its own fade-in tween (line 61), this assignment has no
observable effect under any code path — it is always overwritten before it could ever be
seen.
**Fix:** remove the line, or if it is meant as defensive "restore to a known state," add a
one-line comment explaining that intent so a future reader does not assume it does something
observable.

---

_Reviewed: 2026-09-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
