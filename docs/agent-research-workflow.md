# Agent Research Workflow

This workflow guides agents who research, plan, or revise Project Camiel. Use it before changing roadmap scope, child-facing design, privacy behavior, accessibility policy, platform support, or release criteria.

## Goals

- Turn broad questions into researched decisions.
- Keep child safety, privacy, accessibility, and playability ahead of feature volume.
- Separate evidence, assumptions, and implementation choices.
- Leave enough notes for the next agent to continue without restarting discovery.

## Trigger Conditions

Run this workflow when work touches any of these areas:

- New lessons, learning goals, scoring, or feedback loops.
- Audio, localization, accessibility, or non-reader support.
- Parent/teacher progress views or stored child data.
- Web, Android, iOS, desktop export, signing, or store policy.
- Public releases, beta testing, or feedback collection.

## Research Loop

1. **Frame the question.** Write one decision sentence, such as "Should Alpha v0.0.7 support mobile web?" Add the milestone, affected files, and user impact.
2. **Route agents.** Assign only the roles needed from the role matrix below.
3. **Collect sources.** Prefer primary sources: official Godot docs, app-store policies, privacy regulators, accessibility standards, and repo files. Use dated notes for anything likely to change.
4. **Extract constraints.** Convert source findings into concrete requirements, risks, and acceptance checks.
5. **Synthesize.** Produce one recommendation, rejected alternatives, confidence level, and open risks.
6. **Patch the plan.** Update `docs/roadmap.md`, relevant feature docs, or release docs. Keep changes milestone-scoped.
7. **Verify.** Run `python3 scripts/tools/quality_gate.py --root .` after documentation edits. Run Godot verification when resource paths, scenes, or exports change.

## Agent Role Matrix

| Role | Use When | Outputs |
|------|----------|---------|
| Product researcher | Milestone scope, play loop, child-facing value | User story, success metric, rejected scope |
| Learning researcher | Lesson design or educational progression | Learning objective, task sequence, adult note |
| Safety and privacy researcher | Child data, feedback forms, accounts, analytics | Data inventory, legal/policy constraints, risk controls |
| Accessibility researcher | UI, audio, input, contrast, motion, non-reader support | Accessibility checks, assistive alternatives, gaps |
| Platform researcher | Godot export, desktop, web, Android, iOS, signing | Supported target matrix, build risks, source links |
| Engineering researcher | Architecture, tests, resource layout, maintainability | File impact map, implementation risks, verification commands |
| Playtest researcher | Beta readiness or lesson validation | Observation script, findings summary, milestone changes |
| Roadmap integrator | Any milestone change | Roadmap patch, decision log entry, follow-up issues |

## Routing Rules

- If a feature stores child data, always include Safety and privacy researcher.
- If a feature changes interaction, input, audio, or visuals, include Accessibility researcher.
- If a feature affects exported builds, include Platform researcher.
- If a feature adds or changes lessons, include Learning researcher and Playtest researcher.
- If research changes milestone scope, include Roadmap integrator.

## Evidence Standards

- Primary sources outrank blog posts, forum posts, and model memory.
- Repo evidence must include exact paths, such as `project.godot` or `scenes/lesson_2.tscn`.
- Unverified claims must be labeled as assumptions and converted into research questions.
- Legal and store-policy guidance must be checked against current official sources before release decisions.
- Avoid adding features solely because a source says they are common; keep every feature tied to Camiel's age range and learning goals.

## Research Packet Template

Create a packet in `docs/research/YYYY-MM-DD-topic.md` for major decisions.

```markdown
# Research Packet: Topic

## Decision
One sentence describing the decision this packet supports.

## Context
- Milestone:
- Affected files:
- User impact:

## Sources
| Source | Date Checked | Relevant Finding |
|--------|--------------|------------------|

## Constraints
- Requirement:
- Risk:
- Acceptance check:

## Recommendation
Recommendation, confidence level, and reason.

## Rejected Alternatives
| Alternative | Reason |
|-------------|--------|

## Roadmap Impact
- Milestone:
- Change:
- Verification:
```

## Decision Log

For small decisions, add a short entry to the relevant feature doc instead of creating a packet. Include:

- Date checked.
- Decision owner or agent role.
- Source links.
- Accepted recommendation.
- Verification command.

## Beta 1 Research Cadence

- **Alpha v0.0.4:** audit current partially landed features and confirm what is player-visible.
- **Alpha v0.0.5:** research lesson progression and playtest structure.
- **Alpha v0.0.6:** research non-reader audio, WCAG 2.2 implications, and reduced-motion needs.
- **Alpha v0.0.7:** research Godot export constraints and platform policy.
- **Alpha v0.0.8:** research child data minimization and parent progress views.
- **Alpha v0.0.9:** synthesize playtest findings into Beta 1 readiness criteria.
- **Beta 1:** summarize external feedback and define the next beta only from evidence.

## Guardrails

- No ads, in-app purchases, third-party trackers, cloud sync, or child accounts before Beta 1.
- No time pressure, failure punishment, or complex menus for children.
- No public store submission until privacy, accessibility, platform, and adult-facing documentation have been reviewed.
- Keep every milestone shippable on its own; do not hide essential work in later cleanup.
