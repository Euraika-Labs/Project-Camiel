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

# Restores the copy to a known-good state before every case. Beyond the
# original zz_*/project.godot reset, this also restores the audio bus layout
# resource and every committed probe_*.gd (plus its .gd.uid sidecar) from
# the real repository -- so a case that removes one of those (Case 12's
# every-probe removal, Case 13's single-probe removal, Case 14's layout
# removal) can never leak into a later case that assumes a complete tree.
reset_copy() {
	find "${WORK_DIR}/scripts" "${WORK_DIR}/scenes" -mindepth 1 -maxdepth 1 -name 'zz_*' -exec rm -rf {} +
	cp "${REPO_ROOT}/project.godot" "${WORK_DIR}/project.godot"
	cp "${REPO_ROOT}/default_bus_layout.tres" "${WORK_DIR}/default_bus_layout.tres"
	local probe_file
	for probe_file in "${REPO_ROOT}"/scripts/tools/probe_*.gd "${REPO_ROOT}"/scripts/tools/probe_*.gd.uid; do
		cp "${probe_file}" "${WORK_DIR}/scripts/tools/$(basename "${probe_file}")"
	done
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

# --- Case 13: removing one named probe while others remain still passes (known gap) ---
# scripts/tools/run_headless_check.sh's non-vacuity guard (proven by Case 12
# above) only fails when the probe_*.gd glob matches NOTHING at all. With
# four probes now committed (probe_audio_buses.gd, probe_camiel_movement.gd,
# probe_menu_button.gd, probe_screen_flow.gd), deleting any ONE of them
# still leaves the glob non-empty, so the check goes on to report
# "Headless check passed." with a whole file's worth of assertions silently
# never having run. This case is not a fix -- it is a permanent, executable
# record of that gap, named for what it documents rather than for a
# guarantee the project does not have.
#
# The recommended fix is a fixed list of required probe base names
# (a REQUIRED_PROBES allow-list) checked by name inside
# run_headless_check.sh, independently of how many other probe_*.gd files
# happen to exist. That fix is deliberately NOT implemented in this phase:
# it changes the check's own contract and is a larger change than this
# phase's scope (see 02-VALIDATION.md, "Probe-presence guard gap"). Whoever
# implements the allow-list should expect this case to invert -- it should
# then assert the check FAILS when probe_screen_flow.gd is missing, not
# that it passes.
reset_copy
rm -f "${WORK_DIR}/scripts/tools/probe_screen_flow.gd" "${WORK_DIR}/scripts/tools/probe_screen_flow.gd.uid"
assert_result "removing one named probe (probe_screen_flow.gd) while others remain still passes -- known gap in the probe-presence guard" 0 "Headless check passed." -- \
	bash "${CHECK_SCRIPT}"

# --- Case 14: inert inline audio bus configuration fails, naming the audio probe ---
# The [audio_bus_layout] block once written directly inside project.godot is
# inert in Godot 4.7.2 (VF6, 02-RESEARCH.md): AudioServer.get_bus_count()
# stays at 1 at runtime no matter what buses that section declares. The only
# mechanism that actually creates buses is a committed
# res://default_bus_layout.tres resource (VF7). This case removes that
# working resource and plants the old inline Master/SFX section back into
# project.godot (the exact shape this file carried before plan 02-01, see
# git history), and requires the check to go red, attributing the failure
# to probe_audio_buses.gd specifically -- not to some other unrelated step.
# A future contributor who adds a third bus the old (inline) way would
# otherwise get a silent no-op; this case turns that into a red build.
reset_copy
rm -f "${WORK_DIR}/default_bus_layout.tres"
cat >>"${WORK_DIR}/project.godot" <<'EOF'

[audio_bus_layout]

bus/0/name="Master"
bus/0/volume_db=0.0
bus/0/send=""
bus/1/name="SFX"
bus/1/volume_db=0.0
bus/1/send="Master"
EOF
assert_result "inert inline audio bus configuration (no layout resource) fails, naming the audio probe" 1 "CHECK FAILED" "probe probe_audio_buses.gd" -- \
	bash "${CHECK_SCRIPT}"
cp "${REPO_ROOT}/default_bus_layout.tres" "${WORK_DIR}/default_bus_layout.tres"

# --- Case 15: generic ERROR: during import fails (CR-02) ---
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
