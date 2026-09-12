#!/usr/bin/env bash
# test_headless_check.sh
# Self-test proving each failure direction of scripts/tools/run_headless_check.sh
# (FOUND-06, D-09): every case plants one fault in a temp copy of the working
# tree, runs the check, and asserts its exit code and a required output
# substring. Fake engines are small executable shell scripts written into a
# separate temp directory (never the copied tree).
# Usage: bash scripts/tools/test_headless_check.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="$(mktemp -d)"
FAKES_DIR="$(mktemp -d)"
CHECK_SCRIPT="${WORK_DIR}/scripts/tools/run_headless_check.sh"

CASE_COUNT=0

cleanup() {
	rm -rf "$WORK_DIR" "$FAKES_DIR"
}
trap cleanup EXIT

echo "[setup] copying working tree to ${WORK_DIR}"
rsync -a --exclude '.git/' --exclude '.godot/' --exclude '.planning/' --exclude '.pi/' "${REPO_ROOT}/" "${WORK_DIR}/"

reset_copy() {
	find "${WORK_DIR}/scripts" "${WORK_DIR}/scenes" -mindepth 1 -maxdepth 1 -name 'zz_*' -exec rm -rf {} +
	cp "${REPO_ROOT}/project.godot" "${WORK_DIR}/project.godot"
}

# assert_result NAME EXPECTED_EXIT SUBSTRING... -- COMMAND...
assert_result() {
	local name="$1"
	local expected_exit="$2"
	shift 2

	local required=()
	while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
		required+=("$1")
		shift
	done
	shift # drop the -- separator

	CASE_COUNT=$((CASE_COUNT + 1))

	local output
	local actual_exit
	if output="$("$@" 2>&1)"; then
		actual_exit=0
	else
		actual_exit=$?
	fi

	local ok=1
	if [ "$actual_exit" -ne "$expected_exit" ]; then
		ok=0
	fi
	local substr
	for substr in "${required[@]}"; do
		if ! printf '%s' "$output" | grep -qF -- "$substr"; then
			ok=0
		fi
	done

	if [ "$ok" -eq 1 ]; then
		echo "PASS case ${CASE_COUNT}: ${name}"
	else
		echo "FAIL case ${CASE_COUNT}: ${name}"
		echo "  expected exit ${expected_exit}, required substrings: ${required[*]}"
		echo "  actual exit ${actual_exit}"
		echo "  last 30 output lines:"
		printf '%s\n' "$output" | tail -n 30
		exit 1
	fi
}

# --- fake engines (live outside the copied tree) ---

FAKE_WRONG_VERSION="${FAKES_DIR}/godot_wrong_version.sh"
cat >"${FAKE_WRONG_VERSION}" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then
	echo "4.7.1.stable.official.fake"
	exit 0
fi
exit 0
EOF
chmod +x "${FAKE_WRONG_VERSION}"

FAKE_STALL="${FAKES_DIR}/godot_stall.sh"
cat >"${FAKE_STALL}" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then
	echo "4.7.2.stable.official.fake"
	exit 0
fi
sleep 30
exit 0
EOF
chmod +x "${FAKE_STALL}"

# --- Case 1: fresh copy, no .godot cache, passes ---
reset_copy
assert_result "fresh copy with no .godot cache passes" 0 "Headless check passed." -- \
	bash "${CHECK_SCRIPT}"

# --- Case 2: planted parse error fails (D-09) ---
reset_copy
cat >"${WORK_DIR}/scripts/zz_parse_error.gd" <<'EOF'
# zz_parse_error.gd
# Self-test fixture: intentionally invalid GDScript syntax for the D-09 red path.
extends Node

func _ready() -> void:
	if true
		print("unreachable")
EOF
assert_result "planted parse error fails" 1 "Parse Error" -- \
	bash "${CHECK_SCRIPT}"

# --- Case 3: planted runtime script error fails ---
reset_copy
cat >"${WORK_DIR}/scripts/zz_runtime_error.gd" <<'EOF'
# zz_runtime_error.gd
# Self-test fixture: reads a missing Dictionary key in _ready to trigger a
# runtime SCRIPT ERROR that Godot's own process exit code does not reflect.
extends Node3D

func _ready() -> void:
	var data := {}
	print(data["missing_key"])
EOF
cat >"${WORK_DIR}/scenes/zz_runtime_error.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/zz_runtime_error.gd" id="1"]

[node name="ZzRuntimeError" type="Node3D"]
script = ExtResource("1")
EOF
sed -i.bak 's#run/main_scene=".*"#run/main_scene="res://scenes/zz_runtime_error.tscn"#' "${WORK_DIR}/project.godot"
rm -f "${WORK_DIR}/project.godot.bak"
assert_result "planted runtime script error fails" 1 "SCRIPT ERROR" -- \
	bash "${CHECK_SCRIPT}"

# --- Case 4: planted scene with a missing ext_resource script fails ---
reset_copy
cat >"${WORK_DIR}/scenes/zz_broken.tscn" <<'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/zz_missing.gd" id="1"]

[node name="ZzBroken" type="Node3D"]
script = ExtResource("1")
EOF
assert_result "planted scene with missing ext_resource fails" 1 "CHECK FAILED" -- \
	bash "${CHECK_SCRIPT}"

# --- Case 5: planted C# file rejected (D-01) ---
reset_copy
cat >"${WORK_DIR}/scripts/zz_planted.cs" <<'EOF'
// zz_planted.cs
// Self-test fixture: a C# file the D-01 guard must reject before any engine runs.
EOF
assert_result "C# file rejected" 1 "D-01" -- \
	bash "${CHECK_SCRIPT}"

# --- Case 6: raw key-state polling rejected (D-07) ---
reset_copy
cat >"${WORK_DIR}/scripts/zz_raw_keys.gd" <<'EOF'
# zz_raw_keys.gd
# Self-test fixture: raw key-state polling that the D-07 guard must reject.
extends Node

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_W):
		pass
EOF
assert_result "raw key-state polling rejected" 1 "D-07" -- \
	bash "${CHECK_SCRIPT}"

# --- Case 7: wrong base renderer rejected ---
reset_copy
sed -i.bak 's#renderer/rendering_method="gl_compatibility"#renderer/rendering_method="forward_plus"#' "${WORK_DIR}/project.godot"
rm -f "${WORK_DIR}/project.godot.bak"
assert_result "wrong base renderer rejected" 1 "CHECK FAILED" -- \
	bash "${CHECK_SCRIPT}"

# --- Case 8: wrong engine version rejected (D-02) ---
reset_copy
assert_result "wrong engine version rejected" 1 "4.7.2" -- \
	env GODOT="${FAKE_WRONG_VERSION}" bash "${CHECK_SCRIPT}"

# --- Case 9: engine stall reported, limit cap enforced (D-03) ---
reset_copy
assert_result "engine stall reported" 1 "stalled" "D-03" -- \
	env GODOT="${FAKE_STALL}" HEADLESS_CHECK_MAX_LIMIT_SECONDS=3 bash "${CHECK_SCRIPT}"

# --- Case 10: missing engine binary exits 2 ---
reset_copy
assert_result "missing engine binary exits 2" 2 "not found" -- \
	env GODOT=/nonexistent/Godot bash "${CHECK_SCRIPT}"

# --- Case 11: invalid limit override exits 2 ---
reset_copy
assert_result "invalid limit override exits 2" 2 "HEADLESS_CHECK_MAX_LIMIT_SECONDS" -- \
	env HEADLESS_CHECK_MAX_LIMIT_SECONDS=abc bash "${CHECK_SCRIPT}"

# --- Case 12: zero behaviour probes fails (CR-01) ---
# Removing every probe_*.gd must not let the check silently pass with no
# behaviour verified (the vacuity bug: an empty glob took the "no probes"
# branch straight through to "Headless check passed." / exit 0).
reset_copy
find "${WORK_DIR}/scripts/tools" -maxdepth 1 -type f -name 'probe_*.gd' -exec rm -f {} +
find "${WORK_DIR}/scripts/tools" -maxdepth 1 -type f -name 'probe_*.gd.uid' -exec rm -f {} +
assert_result "zero behaviour probes fails" 1 "no behaviour probes found" -- \
	bash "${CHECK_SCRIPT}"

# --- Case 13: generic ERROR: during import fails (CR-02) ---
# The import step's log scan omitted the generic `ERROR:` pattern used by
# every other step (main scene, verifier, probes), so an engine-level import
# failure phrased as `ERROR: ...` (not `SCRIPT ERROR:`/`Parse Error:`) was
# silently ignored. A corrupted image file with no .gd/.tscn extension and
# unreachable from any tracked scene reproduces this: Godot's import pass
# logs `ERROR: Error importing '...'.` but its own process exit code stays 0
# (F9), so before this fix the whole check still reported
# "Headless check passed."
reset_copy
printf 'not a real png file, just garbage bytes 0123456789' >"${WORK_DIR}/assets/zz_broken.png"
assert_result "generic ERROR during import fails" 1 "CHECK FAILED" "error pattern found in import log" -- \
	bash "${CHECK_SCRIPT}"
rm -f "${WORK_DIR}/assets/zz_broken.png" "${WORK_DIR}/assets/zz_broken.png.import"

echo "Headless check self-test passed."
