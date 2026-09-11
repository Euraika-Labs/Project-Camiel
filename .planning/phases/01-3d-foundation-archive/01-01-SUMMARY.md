---
phase: 01-3d-foundation-archive
plan: 01
subsystem: infra
tags: [git, godot, project-settings, archival]

# Dependency graph
requires: []
provides:
  - Annotated, pushed archive tag `archive/2d-alpha-v0.0.3` holding the complete pre-pivot 2D game
  - Runtime project (`project.godot`, `scenes/`, `scripts/`, `assets/`) with all 2D gameplay content removed
  - `project.godot` with no main scene, no autoloads, and no touch-jump input action left over from 2D
affects: [01-02, 01-03, 01-04, 01-05]

# Actuals (#2632)
actuals:
  tokens: 67793
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Archive-before-delete: create and verify an annotated git tag containing the full pre-removal tree before any destructive `git rm`"
    - "Deletion-only project.godot edits: remove only the exact lines tied to deleted content, leave every other byte untouched"

key-files:
  created:
    - .planning/phases/01-3d-foundation-archive/01-01-SUMMARY.md
  modified:
    - project.godot

key-decisions:
  - "User selected remove-and-push-tag at the Task 2 checkpoint: push the archive tag to origin, then remove the 2D content"
  - "Tag target confirmed as origin/main (754b99d41eab83dd86a8ae44f5dc25619bbf9ced), an ancestor of HEAD with identical 2D paths, so no local planning commits were published by the tag push"
  - "Auth gate resolved by switching the active `gh` account to anubissbe (admin+push on Euraika-Labs/Project-Camiel) and pushing the tag with a one-shot `git -c credential.helper='!gh auth git-credential'` override, without touching the user's osxkeychain credential helper or its cached token"

patterns-established:
  - "Pattern: sensitive git-ref pushes on a repo with a stale cached credential helper use a one-shot `-c credential.helper` override scoped to the single command, never a config-wide or keychain rewrite"

requirements-completed: [FOUND-01, FOUND-02]

coverage:
  - id: D1
    description: "Annotated archive tag archive/2d-alpha-v0.0.3 created at origin/main (754b99d), proven to contain every 2D file tracked at HEAD, and pushed to origin"
    requirement: "FOUND-01"
    verification:
      - kind: other
        ref: "git cat-file -t archive/2d-alpha-v0.0.3 && git merge-base --is-ancestor archive/2d-alpha-v0.0.3 HEAD"
        status: pass
      - kind: other
        ref: "git ls-remote --tags origin refs/tags/archive/2d-alpha-v0.0.3"
        status: pass
    human_judgment: false
  - id: D2
    description: "2D gameplay scenes, scripts, and art removed from the runtime project only after the user's recorded remove-and-push-tag checkpoint answer"
    requirement: "FOUND-02"
    verification:
      - kind: other
        ref: "git ls-files scenes scripts assets == exactly the 8 kept paths (assets/audio/* + scripts/tools/quality_gate.py)"
        status: pass
    human_judgment: false
  - id: D3
    description: "project.godot no longer references deleted content (main scene, autoloads, touch-jump action removed) and repository tooling still passes"
    requirement: "FOUND-02"
    verification:
      - kind: other
        ref: "python3 scripts/tools/quality_gate.py --root ."
        status: pass
      - kind: unit
        ref: "tests.test_quality_gate (python3 -m unittest)"
        status: pass
    human_judgment: false

# Metrics
duration: multi-session (3 executor runs across 2 checkpoints)
completed: 2026-09-11
status: complete
---

# Phase 01 Plan 01: Archive and Remove Pre-Pivot 2D Game Summary

**Pushed the annotated `archive/2d-alpha-v0.0.3` tag to origin (target `754b99d`), then removed all 248 tracked 2D files and unregistered them from `project.godot`, leaving only audio assets and the quality-gate tool.**

## Performance

- **Duration:** multi-session (Task 1 + checkpoint in an earlier run, Task 2 decision resolved in a second run that hit an auth gate on the tag push, Task 3 completed in this run)
- **Started:** 2026-09-11 (Phase 01 execution start, per STATE.md)
- **Completed:** 2026-09-11T11:47:54Z
- **Tasks:** 3 (plus 1 prep deviation)
- **Files modified:** 249 (`project.godot` edited; 248 tracked files deleted)

## Accomplishments

- Created and verified the annotated tag `archive/2d-alpha-v0.0.3` at `754b99d41eab83dd86a8ae44f5dc25619bbf9ced` (= `origin/main`), proven to hold the complete pre-removal 2D tree (23 scenes, all `.gd`/`.gd.uid` scripts, 191 art files) before anything was deleted
- Pushed the archive tag to `origin` per the user's `remove-and-push-tag` decision, confirmed present on GitHub via `git ls-remote`
- Removed all 2D gameplay content: `scenes/` (23 files), `scripts/ui/`, every remaining `.gd`/`.gd.uid` under `scripts/` (including the two 2D tool scripts and their `.uid` files), `assets/camiel/`, `assets/dogs/`, `assets/dogs_side/`, `assets/collectibles/`
- Edited `project.godot` with a deletion-only diff: removed `run/main_scene`, the entire `[autoload]` section (`AudioManager`, `Accessibility`, `ProgressTracker`), and the `mobile_jump` touch-jump input action, while leaving `config/name`, `config/features`, `ui_focus_next`/`ui_focus_prev`, `[display]`, `[audio]`, and `[audio_bus_layout]` byte-identical
- Confirmed the runtime project and repository tooling both pass after removal: `python3 scripts/tools/quality_gate.py --root .` and `python3 -m unittest tests.test_quality_gate` both exit 0

## Task Commits

Each task was committed atomically across three executor sessions:

1. **Prep (deviation, Rule 3): Ignore GSD runtime state, sync STATE.md** - `4867824` (chore)
2. **Task 1: Create the annotated archive tag** - *(git ref only — annotated tag object, no working-tree commit)*
3. **Task 2: User confirms removal** - *(checkpoint:decision — no commit; answer recorded as `remove-and-push-tag`)*
4. **Task 3: Push tag, remove 2D content, edit project.godot** - `06841d7` (chore)

**Plan metadata:** commit for this SUMMARY (see below)

## Files Created/Modified

- `project.godot` - Removed `run/main_scene`, the `[autoload]` section, and the `mobile_jump` input action (11 lines deleted, 0 added)
- 248 tracked files under `scenes/`, `scripts/`, `assets/camiel/`, `assets/dogs/`, `assets/dogs_side/`, `assets/collectibles/` - deleted (recoverable from `archive/2d-alpha-v0.0.3`)
- `.planning/phases/01-3d-foundation-archive/01-01-SUMMARY.md` - this file

## Decisions Made

- User answered the Task 2 checkpoint with `remove-and-push-tag`: push the archive tag to origin first, then remove the 2D content
- Tag target chosen as `origin/main` (`754b99d`), not local `HEAD`, because it is an ancestor of `HEAD` with an identical 2D tree — the push therefore uploads no local planning commits
- Auth gate on the tag push (origin returned 403 under the previously-active read-only `bert-colemont_tme` GitHub account) resolved by switching the active `gh` account to `anubissbe` (which has `push`/`admin` on the repo) and pushing with a one-shot `git -c credential.helper='!gh auth git-credential'` override, rather than rewriting the user's `osxkeychain` credential helper or its cached token

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] GSD runtime state files untracked/uncommitted before Task 1 (prior session)**
- **Found during:** Prep, before Task 1 (an earlier executor session)
- **Issue:** `.planning/config.json` and `.planning/state.json` (GSD tool runtime state, not plan artifacts) were untracked and STATE.md needed syncing before the archive task could start cleanly
- **Fix:** Added `.gitignore` entries for GSD runtime state, synced `.planning/STATE.md`
- **Files modified:** `.gitignore`, `.planning/STATE.md`, `.planning/config.json`
- **Verification:** `git status --porcelain` clean before Task 1's pre-check ran
- **Committed in:** `4867824`

**2. [Auth gate, not a deviation] Tag push 403 under stale active GitHub account**
- **Found during:** Task 3, step 1 (an earlier executor session)
- **Issue:** `git push origin refs/tags/archive/2d-alpha-v0.0.3` returned 403 because the locally cached `osxkeychain` credential and the then-active `gh` account (`bert-colemont_tme`) were read-only on `Euraika-Labs/Project-Camiel`
- **Resolution:** Orchestrator switched the active `gh` account to `anubissbe` (confirmed `push`/`admin` scope) between sessions; this session verified the switch via `gh auth git-credential get`, then pushed with a one-shot `-c credential.helper='!gh auth git-credential'` override (never modifying `credential.helper` in git config or touching the keychain, per explicit user constraint)
- **Verification:** `git ls-remote --tags origin refs/tags/archive/2d-alpha-v0.0.3` returned the tag object id after the push
- **Documented as:** authentication gate (normal flow), not a deviation — see Authentication Gates below

---

**Total deviations:** 1 auto-fixed (1 blocking — GSD runtime-state prep). The tag-push 403 was an authentication gate, handled per the auth-gate protocol, not a deviation.
**Impact on plan:** No scope creep. The prep fix was necessary housekeeping before the plan's own Task 1 could run; the auth gate was resolved without touching prohibited credential storage.

## Authentication Gates

- **Task:** Task 3, step 1 (push the archive tag)
- **What was needed:** GitHub push access to `Euraika-Labs/Project-Camiel` for the tag ref
- **What Claude did:** Detected the 403, verified the active `gh` account lacked push access, and (after the orchestrator switched accounts) verified the new active account (`anubissbe`) via `gh auth git-credential get` before retrying
- **Outcome:** Push succeeded via a one-shot credential-helper override scoped to the single `git push` invocation; no changes made to `credential.helper` config or the keychain

## Issues Encountered

None beyond the documented auth gate, which resolved cleanly on retry.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The runtime project has no 2D gameplay content left; `project.godot` references nothing deleted; `python3 scripts/tools/quality_gate.py --root .` and `python3 -m unittest tests.test_quality_gate` both pass
- **Known and accepted intermediate state (per plan objective):** the project currently has no main scene, and the CI "Verify Godot project" job still calls the now-deleted `verify_camiel_resources.gd`. Plan 01-03 creates the 3D main scene and its replacement check; Plan 01-05 replaces the CI steps (D-10). This is expected, not a defect of this plan.
- Archive tag `archive/2d-alpha-v0.0.3` is durable on `origin` for the later MODEL-01 decision on the 2D Camiel drawings

---
*Phase: 01-3d-foundation-archive*
*Completed: 2026-09-11*
