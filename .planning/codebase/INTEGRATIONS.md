# External Integrations

**Analysis Date:** 2026-09-11

## APIs & External Services

**Runtime (game binary):**
- None. No GDScript file in `scripts/` uses `HTTPRequest`, `HTTPClient`, `WebSocketPeer`, `JavaScriptBridge`, or any other networking API. The game is fully offline by design: `docs/parent-dashboard.md` says no child data leaves the device.
- Keep it this way. This is a children's product (ages 3+), and adding any network call is a privacy and product decision, not just an implementation detail.

**Engine / platform APIs used (local only):**
- `DisplayServer.is_touchscreen_available()` - Detects touch devices to show mobile controls (`scripts/mobile_controller.gd:19`)
- `AudioServer.get_bus_index()` - Resolves the `Master`/`SFX` buses (`scripts/audio_manager.gd`)
- `Time.get_datetime_string_from_system()` - Timestamps lesson completion (`scripts/progress_tracker.gd:16`)
- `ResourceLoader` / `ResourceSaver` - Loads assets and generates resources (`scripts/audio_manager.gd`, `scripts/tools/build_camiel_resources.gd`)

**Build/CI external services:**
- GitHub Releases (godotengine/godot) - Downloads the Godot Linux headless binary and export templates in every export job
  - URL pattern: `https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_STATUS}/Godot_v${GODOT_VERSION}-${GODOT_STATUS}_linux.x86_64.zip` and `..._export_templates.tpz`
  - Client: `curl --fail --retry 5`
  - Auth: none (public)
  - Files: `.github/workflows/ci.yml`, `.github/workflows/export.yml`, `.github/workflows/release.yml`
- GitHub REST API (via `gh api`) - Checks repo visibility and Code Security status before running CodeQL
  - Auth: `GH_TOKEN: ${{ github.token }}`
  - File: `.github/workflows/codeql.yml`
- GitHub CodeQL / code scanning - Scans workflow YAML only, since GDScript is unsupported (`.github/workflows/codeql.yml`, `.github/codeql/codeql-config.yml`)
- GitHub Dependency Review - Fails PRs on high-severity dependency changes (`.github/workflows/dependency-review.yml`)
- Dependabot - Weekly GitHub Actions version bumps (`.github/dependabot.yml`)
- GitHub Wiki - Product context, safety principles, and character bible, linked from `README.md` (`https://github.com/Euraika-Labs/Project-Camiel/wiki`)

**Documented but not implemented:**
- Authenticode code signing (DigiCert timestamp server `http://timestamp.digicert.com`; SignPath.io, SSL.com, and Sectigo as certificate options). `docs/code-signing.md` describes it, but no workflow has a signing step.
- `gobject/godot-action@v3` appears in `docs/build-and-release.md` and `docs/web-export.md`. The real workflows download Godot with `curl` instead. Follow the workflows, not those docs.
- A Next.js 16 parent dashboard (with optional Drizzle + SQLite) is a future design in `docs/parent-dashboard.md`. No code exists.
- itch.io and GitHub Pages hosting for the web build are covered in `docs/web-export.md`. No deploy automation exists.
- `git.euraika.net` (GitLab) is named as a repo access route in `docs/build-and-release.md`. No GitLab CI config exists.

## Data Storage

**Databases:**
- None.

**File Storage:**
- Local filesystem only, through Godot's `user://` sandbox:
  - `user://progress.json` - Lesson progress records (`lesson_id`, `stars`, `time_seconds`, `completed_at`), written by the `ProgressTracker` autoload (`scripts/progress_tracker.gd`) with `FileAccess` + `JSON`
  - Resolved per OS under `.../Godot/app_userdata/Camiel alpha-v0.0.3/` because `config/name` in `project.godot` sets the folder name. Renaming the project or bumping its version orphans existing progress files.
  - Known defect: `_save_progress` calls `JSON.stringify(data, JSON.SINDY_USE_HELPER)`. That constant doesn't exist in Godot's `JSON` class, so saving will error at parse or run time. Use `JSON.stringify(data, "\t")` instead. `_load_progress` also does not check `JSON.parse_string` for a non-Dictionary or `null` result.
- Accessibility settings are not persisted. `scripts/accessibility.gd` holds them in memory only; a comment says `ConfigFile` could be used.
- Read-only game assets are packed into the PCK (`res://assets/...`), embedded in the binary (`binary_format/embed_pck=true`).

**Caching:**
- None beyond Godot's editor import cache (`.godot/`, gitignored).

## Authentication & Identity

**Auth Provider:**
- None. The game has no accounts, login, or user identity.
  - `docs/parent-dashboard.md` suggests a future passphrase screen set by env var for the dashboard. It is not implemented.

**Signing identities (release):**
- Android keystore: `android/keystore/publish=""` and `android/keystore/debug=""` are empty in `export_presets.cfg` (preset 3). Supply these through the local editor settings or CI secrets, and never commit them.
- Windows/macOS code signing: `codesign/enable=false` in every desktop preset.

## Monitoring & Observability

**Error Tracking:**
- None. There is no crash reporting or analytics SDK, which is deliberate given the child-privacy stance.

**Logs:**
- Godot console output only: `print(...)` (for example `[Accessibility] High-contrast mode ON` in `scripts/accessibility.gd`), `push_warning(...)` (for example `[AudioManager] BGM not found:` in `scripts/audio_manager.gd`), and `push_error(...)` plus `quit(1)` in the headless tools (`scripts/tools/verify_camiel_resources.gd`).
- CI annotations: `quality_gate.py` prints GitHub `::error file=...::` lines (`format_github_error`). The workflows print `::error::` and `::notice::` lines.

## CI/CD & Deployment

**Hosting:**
- GitHub repository `Euraika-Labs/Project-Camiel` (public).
- Binaries are published as GitHub Release assets and GitHub Actions artifacts. They are never committed: `builds/` is gitignored and CI rejects tracked files over 95 MB.

**CI Pipeline (GitHub Actions, all `ubuntu-latest`):**
- `.github/workflows/ci.yml` (push/PR to `main`, manual) - Godot 4.6.2
  1. `repository-hygiene`: `python3 -m unittest tests.test_quality_gate`, `python3 scripts/tools/quality_gate.py --root .`, a tracked-file size check (95 MB), a conflict-marker grep
  2. `verify-godot`: headless import, `verify_camiel_resources.gd`, `--quit-after 2` smoke test
  3. `export-windows`: export `Windows Desktop`, then upload an artifact named `Camiel-alpha-v0.0.1-windows` (the version is hardcoded and stale), kept 14 days
- `.github/workflows/export.yml` (push to `main`, tags `v*`, any PR, manual) - Godot 4.6.4
  - `quality` → `export-windows`, `export-linux`, `export-macos` (artifacts kept 30 days) → `release` (tags only, `softprops/action-gh-release@v2` with `secrets.GITHUB_TOKEN`)
  - Risk: `tar -czf "dist/linux/Camiel-linux.tar.gz" Camiel.x86_64` runs from the repo root, but the binary is at `dist/linux/Camiel.x86_64`, so the Linux packaging step will fail.
  - Risk: the macOS export runs on Linux with codesign disabled. The result is an unsigned, unnotarized `.zip`.
- `.github/workflows/release.yml` (tags `alpha-v*` and `v*`, manual with a `tag` input) - Godot 4.6.2
  - Verifies the project, exports Windows, then `gh release create` (notes from `ALPHA_V0_0_1_NOTES.md`) and `gh release upload --clobber`
  - Overlap: a `v*` tag triggers both `release.yml` and `export.yml`'s `release` job, and both write to the same GitHub Release.
- `.github/workflows/codeql.yml` (push/PR to `main`, weekly cron `21 3 * * 1`, manual) - Actions-language CodeQL
- `.github/workflows/dependency-review.yml` (PR to `main`) - `fail-on-severity: high`
- Required checks on `main` (from `docs/ci-and-community-standards.md`): `Repository hygiene`, `Verify Godot project`, `Export Windows build`, `Analyze GitHub Actions`.

## Environment Configuration

**Required env vars:**
- Runtime: none.
- CI (defined inline, non-secret): `GODOT_VERSION`, `GODOT_STATUS`, `GODOT_TEMPLATE_VERSION`, `GODOT_BIN`, `REF_SLUG`, `REF_CLEAN`.
- CI (provided by GitHub): `github.token` / `secrets.GITHUB_TOKEN` (used as `GH_TOKEN`/`GITHUB_TOKEN`). Workflow `permissions` are scoped: `contents: read` by default, `contents: write` for release jobs, `security-events: write` for CodeQL.
- Documented only, not referenced by any workflow: `AUTHENTICODE_CERT_B64`, `AUTHENTICODE_CERT_PATH`, `AUTHENTICODE_PASSWORD` (`docs/code-signing.md`); `WINDOWS_SIGNING_CERT_B64`, `EXPORT_PRESET`, `TEMPLATES_VERSION` (`docs/build-and-release.md`).

**Secrets location:**
- GitHub Actions secrets. Only the built-in `GITHUB_TOKEN` is used today.
- No `.env`, certificate, or keystore files are in the repository. Secret scanning and push protection are on at the repo level (`docs/ci-and-community-standards.md`).
- `.gitignore` does not list `*.pfx`, `*.p12`, `*.pem`, or `*.keystore`, although `docs/code-signing.md` and the Android preset comments recommend it. Add these patterns before any signing work.

## Webhooks & Callbacks

**Incoming:**
- None (no server component).

**Outgoing:**
- None from the game.
- From CI only: artifact uploads and GitHub Release publishing through the GitHub API.

---

*Integration audit: 2026-09-11*
