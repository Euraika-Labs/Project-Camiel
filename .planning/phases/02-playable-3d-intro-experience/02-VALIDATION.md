---
phase: "2"
slug: "playable-3d-intro-experience"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-12"
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `02-RESEARCH.md` § Validation Architecture (23 engine-verified facts).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None for GDScript (no GUT/GdUnit4 — out of scope, unchanged from Phase 1). Python stdlib `unittest` for `tests/test_quality_gate.py` and `tests/test_ci_workflows.py`. The de facto GDScript test framework is the headless check chain: `run_headless_check.sh` (import → main scene → `verify_3d_project.gd` → every `scripts/tools/probe_*.gd`) plus `test_headless_check.sh` (self-test of the check itself). |
| **Config file** | none — unchanged from Phase 1 |
| **Quick run command** | `python3 scripts/tools/quality_gate.py --root .` |
| **Full suite command** | `bash scripts/tools/run_headless_check.sh` — invocation unchanged, content grows: `verify_3d_project.gd` retargets its Node3D assertion to `intro_level.tscn` (D-27), and the probe glob picks up **two** probes instead of one (`probe_camiel_movement.gd` + new `probe_screen_flow.gd`). |
| **Estimated runtime** | Observed ~90–150s. Watchdog ceilings are higher (`IMPORT_LIMIT=180` + `RUN_LIMIT=60` + `VERIFY_LIMIT=60` + `PROBE_LIMIT=120` **per probe** ≈ 420s worst case with 2 probes); in practice every step completes in low single-digit seconds once assets import cleanly, matching Phase 1's F2/F7. |

---

## Sampling Rate

- **After every task commit:** Run `python3 scripts/tools/quality_gate.py --root .`
- **After every plan wave:** Run `bash scripts/tools/run_headless_check.sh`
- **Before `/gsd-verify-work`:** `bash scripts/tools/run_headless_check.sh && bash scripts/tools/test_headless_check.sh` green, plus the D-30 manual playtest
- **Max feedback latency:** ~150 seconds

---

## Per-Task Verification Map

Task IDs become `02-0X-TY` once PLAN.md files exist. Rows map each in-scope requirement to a
test type and an already-runnable command; the planner attaches IDs directly.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBA | TBA | TBA | MENU-01 | — | Transition fires exactly once; guard blocks a second press | automated (headless probe) | `bash scripts/tools/run_headless_check.sh` — `probe_screen_flow.gd` title-screen case | ❌ W0 | ⬜ pending |
| TBA | TBA | TBA | MENU-02 | — | Start activates by pressed-signal only, one code path | automated (headless probe) | same file, main-menu case | ❌ W0 | ⬜ pending |
| TBA | TBA | TBA | INTRO-01 | — | N/A | automated (existing probe) | `bash scripts/tools/run_headless_check.sh` — `probe_camiel_movement.gd` | ⚠️ exists, targets `test_space.tscn` | ⬜ pending |
| TBA | TBA | TBA | INTRO-02 | — | N/A | automated (existing probe) | same | ⚠️ same retarget gap | ⬜ pending |
| TBA | TBA | TBA | INTRO-03 | — | Pickup SFX plays exactly once; collectible stops monitoring | automated (new probe) | new case: drive Camiel into `%Collectible`, assert `collected` fires once, SFX player reaches `playing == true` once, `%Collectible.monitoring == false` | ❌ W0 | ⬜ pending |
| TBA | TBA | TBA | INTRO-04 | — | Win shown via signal, not a direct cross-script call | automated (new probe) | finish-marker case: assert `finished` fires once, `%WinLayer.visible == true` | ❌ W0 | ⬜ pending |
| TBA | TBA | TBA | INTRO-05 | — | Each win button one-shot, activated through one path | automated (headless probe) | win-screen case: focus order `[%ReplayButton, %GoToMenuButton]`, synthesize `ui_accept` on each | ❌ W0 | ⬜ pending |
| TBA | TBA | TBA | INTRO-06 | — | SFX volume isolated from Music bus | automated (headless probe, **bounded retry**) + manual (D-30) | the 4 D-26 proxy assertions; `playing` **must** use `_wait_until_playing()` with a real-time timeout, never a same-frame assert, and **never** `get_playback_position()` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Two gaps the planner must explicitly close or accept

1. **INTRO-01 / INTRO-02 retarget gap.** `probe_camiel_movement.gd` proves movement, jump,
   fall-return and camera-follow against `test_space.tscn` — **not** `intro_level.tscn`. Either
   parametrize the probe to also load `intro_level.tscn`, or accept Phase 1 coverage as
   sufficient on the grounds that `intro_level.tscn` reuses the same `camiel.tscn` instance.
   Decide explicitly; do not leave it implicit.
2. **Probe-presence guard gap.** `run_headless_check.sh`'s non-vacuity guard (self-test case 12)
   fails only when the glob is **entirely empty**. With two probes, deleting *either* leaves the
   glob non-empty and the check green with a whole probe's assertions silently gone. Recommended
   fix is a by-name `REQUIRED_PROBES` allow-list (larger than this phase). **In-scope minimum:**
   add a `test_headless_check.sh` case documenting the gap as a known expectation. Do **not**
   make that case pass without implementing the allow-list — that would misrepresent the guard.

---

## Audio assertion rules (D-26) — binding on any probe touching audio

`--headless` forces `--audio-driver Dummy` on every platform (engine `--help`, VF22), so CI and
local behave identically. Per assertion:

| D-26 assertion | Safe to assert same-frame? | How |
|---|---|---|
| Bus indices resolve (`get_bus_index("Music"/"SFX") != -1`) | Yes | Assert directly (VF7) |
| BGM `playing == true` | **No** | Bounded real-time retry via `_wait_until_playing(player, 2000)` (VF9, VF22, VF23, A6) |
| Stream `loop == true` | Yes | Property on the resource, no driver involvement (VF5) |
| `set_sfx_volume()` moves SFX `volume_db` only | Yes | Bus graph, not playback state (VF8) |

**`get_playback_position()` is retracted as a liveness proxy.** VF23: frozen across dozens of
consecutive polls, advancing only in ~93ms real-wall-clock steps regardless of `--fixed-fps`, so
`> 0.0` can read false on a genuinely playing stream. A negative reading was also observed by the
orchestrator (`-0.00099773`) though not reproduced by the researcher (A6, MEDIUM). There is no
safe position-based fallback — poll `.playing` only.

**Hazard (VF23 config 2):** calling `.play()` in the same call as `add_child()` raises
`ERROR: Playback can only happen when a node is inside the scene tree` and leaves `playing`
**permanently false** — a hard usage error, not a transient. `AudioManager` must settle the
player in the tree before playing.

---

## Wave 0 Requirements

- [ ] **Regenerate the three `.ogg` files as genuine Ogg Vorbis** — they are currently **Opus**
      (`OggS OpusHead`) while their `.import` sidecars declare `oggvorbisstr` /
      `AudioStreamOggVorbis` with `valid=false`. Dormant today; `load()` returns `null` with a
      loud `ERROR:` the moment `AudioManager` touches them. Blocks every INTRO-06 assertion.
      Recipe (VF4): `ffmpeg -f lavfi -i "sine=frequency=440:duration=N" -ac 2 -threads 1 -c:a vorbis -strict -2 -qscale:a 4 out.ogg`
- [ ] **Commit `res://default_bus_layout.tres`** defining Music/SFX sending to Master, and remove
      the inert `[audio_bus_layout]` block from `project.godot` — verified inert:
      `AudioServer.get_bus_count()` returns **1** at runtime despite the file declaring Master+SFX.
      Generate via the engine's own `AudioServer.add_bus()` / `generate_bus_layout()` /
      `ResourceSaver.save()`, not hand-typed.
- [ ] **`scripts/tools/probe_screen_flow.gd`** (D-29) — blocks MENU-01, MENU-02, INTRO-05 and,
      if folded in, INTRO-03/04.
- [ ] **`verify_3d_project.gd` D-27 retarget** — new gameplay-scene check against
      `res://scenes/intro_level.tscn`. Blocks the whole suite once `run/main_scene` becomes the
      `Control`-rooted `title_screen.tscn`.
- [ ] **`test_headless_check.sh` additions** — the probe-glob partial-removal documentation case,
      landing in the same wave as `probe_screen_flow.gd`.
- [ ] Godot 4.7.2 local install — carry-over from Phase 1 (D-08), prerequisite for every command.

*Everything else — the `menu_button` component, `intro_level.tscn` geometry, the non-bus-layout
half of the `AudioManager` rebuild — is ordinary task work, verifiable incrementally.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full title → menu → play → collect → finish → replay → menu flow feels right on a real pointer/touch device, and audio is genuinely audible with a perceptible slider effect | MENU-01, MENU-02, INTRO-03, INTRO-04, INTRO-05, INTRO-06 | D-30 mandates one short human playtest, same reasoning as Phase 1's D-11: tap/click on a real device and genuine audibility cannot be verified headlessly — a Dummy driver tracks playback *state* faithfully but produces no sound to judge slider feel against | Run the built game (not headless): title → menu → intro level → collect → finish → "Nog een keer" → "Naar menu", using both pointer and keyboard at least once each; drag the SFX slider and confirm an audible change |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 150s
- [ ] Both named gaps above explicitly closed or accepted by the planner
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
