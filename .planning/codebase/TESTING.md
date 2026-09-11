# Testing Patterns

**Analysis Date:** 2026-09-11

Project Camiel has no GDScript unit test framework. Verification has three layers:

1. **Python unittest** for the repository quality gate (`tests/test_quality_gate.py`).
2. **Repository quality gate** run over the whole tree (`scripts/tools/quality_gate.py`).
3. **Headless Godot checks**: project import, a resource/scene verifier script (`scripts/tools/verify_camiel_resources.gd`), and a main-scene smoke run.

Gameplay behaviour is checked by manually running scenes in the Godot editor. `CONTRIBUTING.md` and `.github/PULL_REQUEST_TEMPLATE.md` require this.

## Test Framework

**Runner:**
- Python `unittest` (stdlib) for tooling tests. No pytest, no `requirements.txt`, no third-party packages.
- Godot `4.6.2.stable` headless for engine-level checks (`GODOT_VERSION: 4.6.2`, `GODOT_STATUS: stable` in `.github/workflows/ci.yml`).
- Config: none. There is no `pytest.ini`, `pyproject.toml`, or GDScript test addon; `addons/` does not exist, so no GUT or gdUnit4.

**Assertion Library:**
- `unittest.TestCase` assertions (`assertIn`, `assertEqual`) for Python.
- GDScript verifier: explicit `if` checks that call `push_error(...)` then `quit(1)`. It does not use `assert()`, which is stripped from release builds and does not set an exit code.

**Run Commands (local, from the repository root):**
```bash
python3 -m unittest tests.test_quality_gate          # Quality gate unit tests (4 tests)
python3 -m unittest tests.test_quality_gate -v       # Verbose
python3 scripts/tools/quality_gate.py --root .       # Full repository quality gate

# Godot checks: set GODOT to your Godot 4.6.2 binary, for example
#   macOS:   GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
#   Linux:   GODOT="./Godot_v4.6.2-stable_linux.x86_64"
"$GODOT" --headless --editor --path . --quit                                         # Import project (build .godot cache)
"$GODOT" --headless --path . --script "res://scripts/tools/verify_camiel_resources.gd" # Verify resources and scenes
"$GODOT" --headless --path . --quit-after 2                                          # Smoke test main scene
```

Windows (the command documented in `CONTRIBUTING.md` and `docs/godot-setup.md`):
```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path "." --script "res://scripts/tools/verify_camiel_resources.gd"
```

Notes:
- Run the import step before the verifier on a fresh clone. `.godot/` is gitignored, and without an import cache `load()` of PNG textures fails.
- Watch mode: not available.
- Coverage: not available (no `coverage.py` or GDScript coverage tooling).
- Rebuilding animation resources is a generator, not a test: `"$GODOT" --headless --path . --script "res://scripts/tools/build_camiel_resources.gd"`. It overwrites `assets/camiel/camiel_sprite_frames.tres`, `scenes/camiel.tscn`, and `scenes/main.tscn`, which wipes hand edits to those scenes. Don't run it casually.

## CI Execution

**`.github/workflows/ci.yml`** (on push to `main`, PRs to `main`, and `workflow_dispatch`; `ubuntu-latest`; concurrency cancels in-progress runs per ref):

| Job | Needs | Steps |
|-----|-------|-------|
| `Repository hygiene` | - | `python3 -m unittest tests.test_quality_gate`, then `python3 scripts/tools/quality_gate.py --root .`, then an inline Python check that no tracked file exceeds 95 MiB, then `git grep` for conflict markers (excluding `.godot`, `tmp`, `builds`) |
| `Verify Godot project` | hygiene | Download the Godot 4.6.2 Linux zip, then `--headless --editor --path . --quit` (import), then `--headless --path . --script "res://scripts/tools/verify_camiel_resources.gd"`, then `--headless --path . --quit-after 2` (smoke) |
| `Export Windows build` | verify | Install export templates, import, `--export-release "Windows Desktop"`, upload artifact (14-day retention) |

**`.github/workflows/export.yml`**: a `quality` job runs only `python3 scripts/tools/quality_gate.py --root .`, and the platform export jobs run after it (`needs: quality`). It does not run the unittest suite or the Godot verifier.

**`.github/workflows/release.yml`**: a "Verify project" step runs `verify_camiel_resources.gd` headless before building release artifacts.

**`.github/workflows/codeql.yml`**: analyses GitHub Actions workflow code only. CodeQL has no GDScript support (`docs/ci-and-community-standards.md`).

**Required checks on `main`** (branch protection, per `docs/ci-and-community-standards.md`): `Repository hygiene`, `Verify Godot project`, `Export Windows build`, `Analyze GitHub Actions`.

## Test File Organization

**Location:**
- Python tests: top-level `tests/`, kept separate from the code they test.
- Godot verification: `scripts/tools/verify_camiel_resources.gd`, a `SceneTree` script run through `--script`, not a test directory.
- `tests/` has no `__init__.py`. `python3 -m unittest tests.test_quality_gate` works because Python 3 treats it as a namespace package. Run commands from the repository root.

**Naming:**
- Python: `tests/test_<module>.py`, one `<Module>Tests(unittest.TestCase)` class, and methods named `test_<blocks|accepts>_<condition>`.
- Godot checks: `scripts/tools/verify_<subject>.gd`.

**Structure:**
```
tests/
└── test_quality_gate.py            # unittest for scripts/tools/quality_gate.py
scripts/tools/
├── quality_gate.py                 # system under test (also run directly in CI)
├── verify_camiel_resources.gd      # headless Godot verifier (CI + release)
└── build_camiel_resources.gd       # generator, not a test
```

## Test Structure

**Python suite organization** (`tests/test_quality_gate.py`):
```python
REPO_ROOT = Path(__file__).resolve().parents[1]
QUALITY_GATE_PATH = REPO_ROOT / "scripts" / "tools" / "quality_gate.py"

# Load the script by path; scripts/tools is not an importable package.
spec = importlib.util.spec_from_file_location("quality_gate", QUALITY_GATE_PATH)
quality_gate = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(quality_gate)


class QualityGateTests(unittest.TestCase):
    def run_gate(self, files):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            for relative_path, content in files.items():
                path = root / relative_path
                path.parent.mkdir(parents=True, exist_ok=True)
                if isinstance(content, bytes):
                    path.write_bytes(content)
                else:
                    path.write_text(content, encoding="utf-8")
            return quality_gate.run_checks(root, [Path(name) for name in files])

    def assert_has_code(self, findings, code):
        self.assertIn(code, {finding.code for finding in findings})

    def test_blocks_broken_local_markdown_links(self):
        findings = self.run_gate({"docs/README.md": "<markdown linking to a missing missing-setup.md>"})
        self.assert_has_code(findings, "broken-markdown-link")
```

**Godot verifier structure** (`scripts/tools/verify_camiel_resources.gd`):
```gdscript
extends SceneTree

const EXPECTED := {
	"idle_right": 4,
	"walk_right": 6,
	# ... one entry per animation with its expected frame count
}

func _initialize() -> void:
	var frames: SpriteFrames = load("res://assets/camiel/camiel_sprite_frames.tres")
	if frames == null:
		push_error("Missing camiel_sprite_frames.tres")
		quit(1)
		return

	for animation_name: String in EXPECTED.keys():
		if not frames.has_animation(animation_name):
			push_error("Missing animation: %s" % animation_name)
			quit(1)
			return

	var camiel_scene: PackedScene = load("res://scenes/camiel.tscn")
	var camiel := camiel_scene.instantiate()
	if not camiel is CharacterBody2D:
		push_error("Camiel scene root is not a CharacterBody2D.")
		quit(1)
		return
	camiel.queue_free()

	print("Camiel Godot resources verified.")
	quit(0)
```

**Patterns:**
- **Setup:** Python tests build a throwaway repository in `TemporaryDirectory()` from a `{relative_path: content}` dict, inside a `run_gate` helper. There are no `setUp` or `tearDown` methods; the context manager does the cleanup.
- **Scoped scan:** pass an explicit file list to `run_checks(root, files)`. This skips `check_required_files`, which only runs on a full scan (`files is None`), so fixtures don't need all the community files.
- **Markdown links in docs:** the gate's link regex also matches links inside fenced code blocks, so never write a literal relative Markdown link to a non-existent file in any `.md` file, `.planning/` included.
- **Assertion:** check for the presence of a finding `code` string (`forbidden-phrase`, `broken-markdown-link`, `missing-godot-resource`, `unsafe-markdown-link`, `empty-file`, `missing-godot-import`, `missing-required-file`) rather than exact messages. Pair every "blocks" test with the clean-project test `test_accepts_clean_child_friendly_project_files`, which asserts `assertEqual([], findings)`.
- **Godot:** fail fast. Each check is `push_error`, `quit(1)`, `return`. Free instantiated scenes with `queue_free()`. Print one success line and `quit(0)` at the end.

## Mocking

**Framework:** None. No `unittest.mock` and no GDScript doubles.

**Patterns:**
```python
# Isolation comes from real temp filesystems, not mocks.
findings = self.run_gate(
    {
        "scenes/main.tscn": (
            '[gd_scene load_steps=2 format=3]\n'
            '[ext_resource type="Script" path="res://scripts/missing.gd" id="1"]\n'
            '[node name="Main" type="Node2D"]\n'
        ),
    }
)
self.assert_has_code(findings, "missing-godot-resource")
```

In a temp directory `collect_git_files` fails gracefully: `git ls-files` errors and the gate returns `[]`. The tests pass an explicit file list anyway, so git is never needed.

**What to Mock:**
- Nothing. Write real files into a `TemporaryDirectory`.
- If a test ever needs `git`, run it against a temp `git init` repository rather than patching `subprocess.run`.

**What NOT to Mock:**
- The filesystem, regexes, or `Path` resolution. These are what the gate checks.
- Godot engine loading. The verifier must `load()` real resources after an import.

## Fixtures and Factories

**Test Data:**
```python
def test_accepts_clean_child_friendly_project_files(self):
    findings = self.run_gate(
        {
            "README.md": "# Project Camiel\n\nA small intro game.\n",
            "docs/README.md": "<markdown linking to docs/setup.md>",
            "docs/setup.md": "# Setup\n\nOpen the project in Godot.\n",
            "scenes/main.tscn": "[gd_scene format=3]\n[node name=\"Main\" type=\"Node2D\"]\n",
        }
    )
    self.assertEqual([], findings)
```

**Location:**
- Inline dict literals in each test method. There is no `fixtures/` directory.
- `run_gate` accepts `bytes` values for binary fixtures (for example PNG content when testing `missing-godot-import`).
- Godot expectations live as `const` dictionaries at the top of the verifier (`EXPECTED` in `scripts/tools/verify_camiel_resources.gd`). They mirror `ANIMATIONS` in `scripts/tools/build_camiel_resources.gd`, so update both together when adding an animation.

**Forbidden-phrase exemption:** `tests/test_quality_gate.py` and `scripts/tools/quality_gate.py` are in `FORBIDDEN_SCAN_EXEMPTIONS`, so test fixtures can contain blocked phrases. Any new test file that embeds blocked phrases must be added to that set. Otherwise the full-repo gate in CI fails on the test itself.

## Coverage

**Requirements:** None enforced. No coverage tool or threshold exists.

**Current coverage by area:**
- `scripts/tools/quality_gate.py`: 4 tests cover `forbidden-phrase`, `broken-markdown-link`, `missing-godot-resource`, and the clean path. Nothing tests `unsafe-markdown-link`, `empty-file`, `missing-godot-import`, `missing-required-file`, `format_github_error`, `main`, or `collect_git_files`.
- Camiel animations and scenes: `verify_camiel_resources.gd` covers the `SpriteFrames` animation names and frame counts, that `scenes/camiel.tscn` and `scenes/main.tscn` load, that the Camiel root is a `CharacterBody2D` with a script, and that Main contains a `Camiel` node.
- The smoke test (`--quit-after 2`) boots `run/main_scene` (`res://scenes/title_screen.tscn`) for 2 frames and catches parse errors in scripts loaded at startup and in the autoloads.
- Not covered automatically: every gameplay script (`scripts/camiel_controller.gd`, `scripts/lesson_*.gd`, `scripts/*_target.gd`, `scripts/count_challenge.gd`, `scripts/progress_tracker.gd`, `scripts/audio_manager.gd`, `scripts/accessibility.gd`, `scripts/mobile_controller.gd`) and the scenes `scenes/lesson_1.tscn` through `scenes/lesson_5.tscn` and `scenes/main_menu.tscn`. Parse errors in scripts not loaded during the 2-frame smoke run go undetected, apart from the quality gate's `res://` path check.

**View Coverage:**
```bash
# Not available. The closest equivalent is verbose unittest output:
python3 -m unittest tests.test_quality_gate -v
```

## Test Types

**Unit Tests:**
- Python only: `tests/test_quality_gate.py` calls `run_checks` directly against temp trees.
- Add a Python unit test in `tests/test_quality_gate.py` for any new `check_*` function in `scripts/tools/quality_gate.py`: one "blocks" test asserting the new finding code, and keep the clean-project test passing.

**Integration Tests:**
- `scripts/tools/verify_camiel_resources.gd` is an engine-level integration check of assets and scenes.
- To add checks for new scenes (for example every lesson scene loads and has a `BackButton`), extend this script, or add a sibling `scripts/tools/verify_<subject>.gd` with the same `extends SceneTree` / `_initialize` / `push_error` + `quit(1)` pattern. Then add a matching step to the `verify-godot` job in `.github/workflows/ci.yml`.

**E2E Tests:**
- Not used. The smoke run (`--quit-after 2`) is the only automated runtime check.
- Manual testing is required. Per `CONTRIBUTING.md`, run the main scene in Godot when a change affects gameplay, visuals, or input, and record the exact command or manual steps under "Test Notes" in the PR (`.github/PULL_REQUEST_TEMPLATE.md`).

## Common Patterns

**Async Testing:**
```gdscript
# Not used. The verifier is synchronous and runs in _initialize().
# If a runtime check must wait for frames, await inside a SceneTree script:
func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/lesson_3.tscn")
	var lesson := scene.instantiate()
	root.add_child(lesson)
	await process_frame
	if lesson.get_node_or_null("BackButton") == null:
		push_error("Lesson 3 has no BackButton.")
		quit(1)
		return
	lesson.queue_free()
	quit(0)
```

**Error Testing:**
```python
# Python: assert that a specific finding code is produced.
def test_blocks_ai_disclaimer_text(self):
    findings = self.run_gate({"README.md": "# Test\n\n<blocked self-disclaimer sentence>\n"})
    self.assert_has_code(findings, "forbidden-phrase")
```
```gdscript
# GDScript verifier: a failed expectation must exit non-zero so CI fails.
var actual := frames.get_frame_count(animation_name)
var expected := int(EXPECTED[animation_name])
if actual != expected:
	push_error("Animation %s has %d frames, expected %d" % [animation_name, actual, expected])
	quit(1)
	return
```

**Pre-PR checklist (local):**
```bash
python3 -m unittest tests.test_quality_gate
python3 scripts/tools/quality_gate.py --root .
"$GODOT" --headless --editor --path . --quit
"$GODOT" --headless --path . --script "res://scripts/tools/verify_camiel_resources.gd"
"$GODOT" --headless --path . --quit-after 2
# Then run the affected scene manually in the Godot editor.
```

---

*Testing analysis: 2026-09-11*
