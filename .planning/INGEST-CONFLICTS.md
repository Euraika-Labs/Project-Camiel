## Conflict Detection Report

### BLOCKERS (0)

None. No LOCKED-vs-LOCKED ADR contradictions (no ADRs in this ingest set), no cycles in the cross-ref graph, no UNKNOWN-classification docs, and no existing locked CONTEXT.md decisions to conflict with (MODE=new, no existing `.planning/` context).

### WARNINGS (5)

[WARNING] Accessibility report claims WCAG 2.1 AA compliance the code does not support
  Found: docs/accessibility-report.md claims all colour combinations pass WCAG AA, listing e.g. white-on-start-green and white-on-win-green at "~7.2:1"; docs/roadmap.md lists under Alpha v0.0.3 "Done": "Accessibility checks completed, WCAG 2.1 AA compliant (docs/accessibility-report.md)."
  Impact: .planning/codebase/CONCERNS.md computes the actual contrast ratios for these same colour pairs from the live GDScript/scene values and gets 1.91:1 (win green), 2.33:1 (start green), 2.76:1 (menu_button.gd green), 2.58:1 (sequence amber) — all fail the 4.5:1 AA minimum. Planning that treats accessibility/WCAG AA as a shipped, closed item will under-scope the actual remediation work, and the `Accessibility` autoload's `toggle_high_contrast()`/`_apply_contrast()` has no callers or implementers at all (CONCERNS.md), so even the one mitigating feature the report cites is inert.
  → Do not carry "WCAG 2.1 AA compliant" forward as a satisfied requirement. Route it to gsd-roadmapper as an open requirement: fix button/label colour contrast (or increase text weight/size to qualify for the 3:1 large-text threshold) and wire the Accessibility autoload before re-claiming compliance.

[WARNING] Parent Dashboard SPEC assumes progress persistence that does not exist
  Found: docs/parent-dashboard.md (SPEC) states "Camiel stores lesson progress locally on the device in `user://progress.json`" and "The game already writes progress to `user://progress.json` (via `ProgressTracker` autoload)."
  Impact: .planning/codebase/CONCERNS.md documents that `scripts/progress_tracker.gd:38` calls a nonexistent constant (`JSON.SINDY_USE_HELPER`), so the script fails to compile and the `ProgressTracker` autoload errors at every startup; separately, nothing in `scripts/` or `scenes/` ever calls `ProgressTracker.record_lesson_complete(...)`, so `user://progress.json` is never written even if the parse error were fixed. Planning a dashboard viewer or the proposed Next.js app on top of this SPEC would build a consumer for data that is never produced.
  → Route to gsd-roadmapper as a prerequisite/open requirement, sequenced before any dashboard work: fix the `JSON.stringify` call in `progress_tracker.gd`, then call `ProgressTracker.record_lesson_complete(...)` from each lesson's completion handler. Treat the JSON schema and API design in docs/parent-dashboard.md as a valid target contract (extracted to constraints.md), but not as evidence the data source exists today.

[WARNING] Web export documented as functional; export preset is broken and contradicted by other ingested docs
  Found: docs/web-export.md presents HTML5/web export as available now ("Camiel can be exported as a self-contained HTML5 game that runs in any modern desktop browser") with a full export/hosting walkthrough. This directly conflicts with two other ingested DOC-precedence sources: docs/quick-start.md lists "Web (HTML5)" as "Planned" in its Supported Platforms table, and docs/roadmap.md lists "Web export (HTML5 Godot export)" under "Next: Alpha v0.0.4 Ideas" (not yet done).
  Impact: .planning/codebase/CONCERNS.md states `export_presets.cfg` preset 4 uses `platform="HTML5"`, the Godot 3 name — Godot 4 requires `"Web"` — so the preset is "likely rejected," and no CI job ever builds or exercises it. Scheduling or documenting a web release as near-term would be planning against a non-functional export target, and the three ingested docs disagree with each other on current status (all same DOC precedence, so none can be auto-preferred).
  → Do not treat web export as available. Route "functioning Web export preset" as an open requirement (recreate the preset in the Godot 4.6 editor under the correct platform name, add a CI export job) before scheduling web hosting/release work from docs/web-export.md.

[WARNING] Build & Release guide contains stale/incorrect operational instructions
  Found: docs/build-and-release.md references `godot --headless --path . --script run_quick_test.gd` for headless testing, references repository access via `glab`/`git.euraika.net`, and gives an export-templates download URL pointing at a `godotengine/godot-export-templates` GitHub repo.
  Impact: `run_quick_test.gd` does not exist anywhere in the repository. Every other ingested doc (project-overview.md, README.md, development-log.md, etc.) and .planning/codebase/CONCERNS.md agree the repository is hosted on GitHub (`Euraika-Labs/Project-Camiel`), not `git.euraika.net`. The templates URL does not correspond to a real Godot release artifact location. Separately, this doc's Godot version guidance ("4.6 (or current LTS)") disagrees with docs/godot-setup.md ("4.6.2.stable" current) and docs/godot-update-notes.md (project moved to 4.6.4) — and CONCERNS.md independently confirms `ci.yml`/`release.yml` pin 4.6.2 while `export.yml` pins 4.6.4. Anyone following this doc literally hits a missing-file error and may install the wrong engine version.
  → Correct the script reference, git host, and template URL in docs/build-and-release.md, and pin one authoritative Godot version across docs/godot-setup.md, docs/build-and-release.md and the CI workflows (tracked separately in CONCERNS.md Tech Debt).

[WARNING] Godot engine version is inconsistent across ingested docs
  Found: docs/godot-setup.md states "Current engine: Godot 4.6.2.stable"; docs/build-and-release.md states "Godot 4 | 4.6 (or current LTS)"; docs/godot-update-notes.md documents a completed update to 4.6.4 and says "`.github/workflows/export.yml` already targets `4.6.4` — no changes needed there"; docs/quick-start.md and docs/web-export.md both instruct installing 4.6.4.
  Impact: These are all DOC-precedence sources with no way to auto-prefer one over another by content rules alone. Following docs/godot-setup.md's stated version would use a different engine than what export.yml actually runs, risking import/format mismatches (`config_version` differences noted in godot-update-notes.md).
  → Update docs/godot-setup.md to reflect the current engine version, and reconcile with the CI/export version drift already flagged in .planning/codebase/CONCERNS.md ("Godot engine version drift" under Tech Debt) before routing.

### INFO (0)

None. No ADR/SPEC precedence contradictions and no lower-precedence-vs-higher-precedence auto-resolutions applied — the only SPEC in this set (docs/parent-dashboard.md) has no competing ADR or higher-precedence source to be checked against.
