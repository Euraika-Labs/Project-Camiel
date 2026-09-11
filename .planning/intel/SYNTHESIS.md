# Synthesis Summary

Ingest mode: `new` (no existing PROJECT.md, REQUIREMENTS.md, ROADMAP.md, or phase CONTEXT.md found).

## Doc Counts

- Total classified docs: 15
- By type: DOC = 14, SPEC = 1, ADR = 0, PRD = 0, UNKNOWN = 0
- Confidence: high = 12, medium = 3, low = 0

## Decisions (decisions.md)

- ADRs found: 0
- Locked decisions: 0
- File is empty by design — no ADR-type documents in this ingest set.

## Requirements (requirements.md)

- PRDs found: 0
- Requirements extracted: 0
- File is empty by design — no PRD-type documents in this ingest set. `docs/parent-dashboard.md` was classified SPEC and extracted to constraints.md instead.

## Constraints (constraints.md)

- Source: docs/parent-dashboard.md (SPEC, medium confidence)
- Entries: 5 — schema x2 (Progress JSON Data Model, GET /api/summary response shape), api-contract x1 (REST API endpoint table), protocol x1 (POST /api/progress/import request), nfr x1 (design principles + proposed Next.js tech stack)
- Caution: this SPEC's premise ("the game already writes progress to user://progress.json") is contradicted by code — see WARNING below and INGEST-CONFLICTS.md.

## Context (context.md)

- 14 DOC-type sources synthesized into 14 topic sections: Project Overview & Status, Target Audience & Design Principles, Gameplay & Controls, Learning Objectives, Accessibility, Assets & Animations, Godot Engine/Setup/Version History, Development History, Build & Release Process, CI/CD & Community Standards, Code Signing, Web Export, Quick-Start/Installation, Roadmap.
- Each topic section carries source attribution per doc; sections with doc-vs-code mismatches carry an inline NOTE pointing to the relevant INGEST-CONFLICTS.md entry.

## Conflicts

- Blockers: 0
- Competing variants: 0
- Auto-resolved (info): 0
- Warnings: 5 — all are doc-claims-shipped-feature-but-code-does-not-support-it findings, cross-checked against `.planning/codebase/CONCERNS.md` and `ARCHITECTURE.md`:
  1. Accessibility report / roadmap claim WCAG 2.1 AA compliance; actual computed contrast ratios fail (1.91-2.76:1 vs 4.5:1 required), and the Accessibility autoload is never wired up.
  2. Parent Dashboard SPEC assumes `user://progress.json` is already being written; `ProgressTracker` fails to compile (invalid JSON constant) and is never called from any lesson.
  3. Web export documented as functional in docs/web-export.md, contradicted by docs/quick-start.md and docs/roadmap.md (both say "Planned"), and the Web export preset uses the wrong Godot-4 platform name and has never been CI-built.
  4. Build & Release guide contains stale/incorrect instructions: nonexistent `run_quick_test.gd`, wrong git host (`git.euraika.net` vs actual GitHub), broken export-templates URL.
  5. Godot engine version is inconsistent across docs/godot-setup.md (4.6.2), docs/build-and-release.md (4.6), and docs/godot-update-notes.md/quick-start.md/web-export.md (4.6.4).

Full detail for every entry: `.planning/INGEST-CONFLICTS.md`

## Pointers

- Decisions: `.planning/intel/decisions.md`
- Requirements: `.planning/intel/requirements.md`
- Constraints: `.planning/intel/constraints.md`
- Context: `.planning/intel/context.md`
- Conflicts report: `.planning/INGEST-CONFLICTS.md`

No blockers — this ingest set is safe to route to `gsd-roadmapper`, which should treat the 5 WARNING findings as open requirements/prerequisites (not satisfied capabilities) when drafting REQUIREMENTS.md and ROADMAP.md.
