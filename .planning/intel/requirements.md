# Requirements

No PRD-classified documents were present in this ingest set (`CLASSIFICATIONS_DIR` contained 0 docs of `type: PRD`).

Nothing to extract. `docs/parent-dashboard.md` was classified `SPEC` (technical contract, not a requirements document) and is extracted to `constraints.md` instead.

Note for downstream `gsd-roadmapper`: several capabilities are documented as if shipped but are contradicted by `.planning/codebase/CONCERNS.md` / `ARCHITECTURE.md` (WCAG AA compliance, progress persistence, web export). These are surfaced as WARNINGs in `INGEST-CONFLICTS.md` with a recommendation to track them as open requirements — they are not written here because this file is strictly a PRD-sourced extraction and no PRD exists in this ingest set.
