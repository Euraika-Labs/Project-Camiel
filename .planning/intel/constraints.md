# Constraints

Extracted from SPEC-classified documents. One SPEC in this ingest set: `docs/parent-dashboard.md`.

## Progress JSON Data Model
- source: docs/parent-dashboard.md
- type: schema
- content:
  ```json
  {
    "lessons": [
      {
        "lesson_id": "lesson_1",
        "stars": 3,
        "time_seconds": 142,
        "completed_at": "2026-06-05T14:32:00"
      }
    ]
  }
  ```
  Fields: `lesson_id` (string, unique lesson identifier), `stars` (int, 1-3), `time_seconds` (int), `completed_at` (string, ISO 8601 timestamp).
  Doc context: "Camiel stores lesson progress locally on the device in `user://progress.json`. The parent dashboard is a read-only viewer for this file... The game already writes progress to `user://progress.json` (via `ProgressTracker` autoload)."

## Parent Dashboard REST API
- source: docs/parent-dashboard.md
- type: api-contract
- content:
  | Method | Path | Description |
  |--------|------|-------------|
  | GET | /api/progress | Returns the raw progress.json |
  | POST | /api/progress/import | Upload a new progress.json to merge |
  | GET | /api/summary | Aggregated stats: total stars, lessons completed, total time |

## GET /api/summary Response Shape
- source: docs/parent-dashboard.md
- type: schema
- content:
  ```json
  {
    "total_lessons_completed": 5,
    "total_stars": 13,
    "total_time_seconds": 1840,
    "star_rating_breakdown": { "1_star": 1, "2_star": 2, "3_star": 2 },
    "last_session": "2026-06-05T14:38:00"
  }
  ```

## POST /api/progress/import Request
- source: docs/parent-dashboard.md
- type: protocol
- content:
  Content-Type: `multipart/form-data`; Body: `file` — the `progress.json` file exported from the game.

## Parent Dashboard Design Principles & Tech Stack
- source: docs/parent-dashboard.md
- type: nfr
- content:
  Design principles: no authentication required for LAN deployments; read-only by default (dashboard never writes back to the child's device); LocalStorage for state (no database needed, JSON file is source of truth); mobile-responsive.
  Tech stack (proposed, "Future: Next.js Parent Dashboard App" — not yet built): Next.js 16 (App Router), TypeScript, Tailwind CSS 4, Drizzle ORM + SQLite (optional, for merging multiple children's data on one machine), no external auth provider (simple passphrase screen via env var).
  Privacy note: "No child data is ever transmitted to Euraika or any third party. All progress stays on the local device."
