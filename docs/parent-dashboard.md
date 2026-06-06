# Parent Progress View

The Beta 1 candidate uses a local adult progress screen instead of a network dashboard. It is available from **Voor volwassenen** on the main menu.

## Privacy Model

- No accounts.
- No cloud sync.
- No ads or analytics.
- No child names or personal details.
- No network API is enabled by default.
- Progress stays on the local device.

## Stored Data

Progress is saved by `ProgressTracker` to `user://progress.json`.

```json
{
	"lessons": {
		"lesson_1": {
			"lesson_id": "lesson_1",
			"stars": 3,
			"last_time_seconds": 42,
			"best_time_seconds": 38,
			"completed_at": "2026-06-06T10:30:00"
		}
	}
}
```

## Adult Screen

The adult screen shows:

- Completed lesson count.
- Total stars.
- Per-lesson completion summary.
- Mute, reduced-motion, and high-contrast controls.
- Local progress reset.

## Manual File Locations

Godot stores `user://` data inside the app user-data folder:

- **Windows:** `%APPDATA%\Godot\app_userdata\Camiel beta-1-candidate\progress.json`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/Camiel beta-1-candidate/progress.json`
- **Linux:** `~/.local/share/godot/app_userdata/Camiel beta-1-candidate/progress.json`

## Deferred Dashboard Work

A browser-based or LAN progress dashboard is deferred until after Beta 1. If added later, it must include authentication, a data minimization review, and a clear adult-only workflow before any network endpoint is enabled.
