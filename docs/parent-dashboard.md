# Parent Dashboard

A lightweight progress-viewing tool for parents and teachers to see how children are progressing through Camiel lessons — without needing to be in front of the game itself.

---

## Overview

Camiel stores lesson progress locally on the device in `user://progress.json`. The parent dashboard is a read-only viewer for this file. It is intentionally simple: no accounts, no cloud sync, no internet required.

**Why it matters:**
- Parents can review progress at a glance during dinner or at the weekend
- Teachers can check class progress before or after a session
- No sensitive child data leaves the device (privacy by design)
- Works entirely offline

---

## Simplest Approach: JSON File Viewer

The game already writes progress to `user://progress.json` (via `ProgressTracker` autoload). A parent or teacher can:

1. Connect the device to a computer
2. Navigate to the game's user data folder:
   - **Windows:** `%APPDATA%\Godot\app_userdata\Camiel alpha-v0.0.3\progress.json`
   - **macOS:** `~/Library/Application Support/Godot/app_userdata/Camiel alpha-v0.0.3/progress.json`
   - **Linux:** `~/.local/share/godot/app_userdata/Camiel alpha-v0.0.3/progress.json`
   - **Android:** Use a file manager app (such as ZArchiver or Files by Google) to browse to `Android/data/org.godotengine.camiel/files/`
3. Open `progress.json` in any text editor

---

## Progress JSON Data Model

```json
{
  "lessons": [
    {
      "lesson_id": "lesson_1",
      "stars": 3,
      "time_seconds": 142,
      "completed_at": "2026-06-05T14:32:00"
    },
    {
      "lesson_id": "lesson_2",
      "stars": 2,
      "time_seconds": 208,
      "completed_at": "2026-06-05T14:38:00"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `lesson_id` | string | Unique lesson identifier (e.g. `lesson_1`, `lesson_2`) |
| `stars` | int | Stars earned: 1–3 |
| `time_seconds` | int | Time taken to complete the lesson |
| `completed_at` | string | ISO 8601 timestamp of completion |

---

## Future: Next.js Parent Dashboard App

A lightweight Next.js app can be built to render the JSON file as a visual dashboard.

### Architecture

```
parent-dashboard/
├── app/
│   ├── page.tsx           # Upload + display progress
│   └── layout.tsx         # App shell
├── components/
│   └── ProgressTable.tsx  # Lesson table with stars + time
├── lib/
│   └── parse.ts           # Parse and validate progress.json
└── package.json
```

### API Endpoint Design

If the dashboard is served as a network app (e.g. running on the same home network as the child's device):

| Method | Path | Description |
|--------|------|-------------|
| `GET /api/progress` | Returns the raw progress.json |  |
| `POST /api/progress/import` | Upload a new progress.json to merge |  |
| `GET /api/summary` | Aggregated stats: total stars, lessons completed, total time |  |

### `GET /api/summary` Response Shape

```json
{
  "total_lessons_completed": 5,
  "total_stars": 13,
  "total_time_seconds": 1840,
  "star_rating_breakdown": { "1_star": 1, "2_star": 2, "3_star": 2 },
  "last_session": "2026-06-05T14:38:00"
}
```

### `POST /api/progress/import` Request

- Content-Type: `multipart/form-data`
- Body: `file` — the `progress.json` file exported from the game

### Design Principles

- **No authentication required** for LAN deployments — parents are in control of their own network
- **Read-only by default** — the dashboard never writes back to the child's device
- **LocalStorage for state** — no database needed; the JSON file is the source of truth
- **Mobile-responsive** — parent may view on a phone or tablet

### Tech Stack

- **Next.js 16** (App Router)
- **TypeScript**
- **Tailwind CSS 4**
- **Drizzle ORM + SQLite** (optional, for merging multiple children's data on one machine)
- **No external auth provider** — simple passphrase screen (configurable via env var) is sufficient

---

## Privacy Note

No child data is ever transmitted to Euraika or any third party. All progress stays on the local device. The parent dashboard is a purely local tool.