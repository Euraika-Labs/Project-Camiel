#!/usr/bin/env bash
# run_headless_check.sh
# One local/CI project check (D-09): imports the project, boots the main
# scene, and runs the --script verifier, failing on any script/parse error
# even though Godot's own process exit code does not reflect one.
# Usage: GODOT=/path/to/Godot bash scripts/tools/run_headless_check.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

IMPORT_LIMIT=180
RUN_LIMIT=60
VERIFY_LIMIT=60

LOG_DIR="$(mktemp -d)"

fail() {
	local step="$1"
	local reason="$2"
	local logfile="${3:-}"
	echo "CHECK FAILED: ${step}: ${reason}"
	if [ -n "$logfile" ] && [ -f "$logfile" ]; then
		grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$logfile" || true
		echo "--- last 40 lines of ${logfile} ---"
		tail -n 40 "$logfile"
	fi
	echo "Logs kept at: ${LOG_DIR}"
	exit 1
}

# run_with_timeout LIMIT LOGFILE COMMAND...
# Runs COMMAND in the background, polling once per second. At LIMIT seconds
# sends TERM, waits 5s, sends KILL, and returns 124. Otherwise returns
# COMMAND's own exit status. Pure bash: macOS ships no GNU timeout.
run_with_timeout() {
	local limit="$1"
	local logfile="$2"
	shift 2
	"$@" >>"$logfile" 2>&1 &
	local pid=$!
	local elapsed=0
	while kill -0 "$pid" 2>/dev/null; do
		if [ "$elapsed" -ge "$limit" ]; then
			kill -TERM "$pid" 2>/dev/null || true
			sleep 5
			kill -KILL "$pid" 2>/dev/null || true
			wait "$pid" 2>/dev/null || true
			return 124
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	wait "$pid"
	return $?
}

# run_step NAME LIMIT LOGFILE COMMAND...
# Runs COMMAND under the watchdog, announcing "[step] NAME" and failing hard
# on a stall (124, D-03) or a non-zero exit status. Leaves log-content checks
# to the caller, since the accepted error patterns differ per step.
run_step() {
	local name="$1"
	local limit="$2"
	local logfile="$3"
	shift 3
	echo "[step] ${name}"
	local status
	if run_with_timeout "$limit" "$logfile" "$@"; then
		status=0
	else
		status=$?
	fi
	if [ "$status" -eq 124 ]; then
		echo "CHECK FAILED: ${name} stalled after ${limit}s (Godot issue 122707, D-03). Stop and raise with the user; do not raise the limit."
		exit 1
	fi
	if [ "$status" -ne 0 ]; then
		fail "$name" "Godot exited with status ${status}" "$logfile"
	fi
}

resolve_godot() {
	if [ -n "${GODOT:-}" ] && [ -x "${GODOT}" ]; then
		printf '%s\n' "${GODOT}"
		return 0
	fi
	if command -v godot >/dev/null 2>&1; then
		command -v godot
		return 0
	fi
	if [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
		printf '%s\n' "/Applications/Godot.app/Contents/MacOS/Godot"
		return 0
	fi
	return 1
}

if ! GODOT_BIN="$(resolve_godot)"; then
	echo "CHECK FAILED: Godot 4.7.2 not found. Set GODOT=/path/to/Godot."
	exit 2
fi

VERSION_OUTPUT="$("$GODOT_BIN" --version)"
VERSION_LINE="$(printf '%s\n' "$VERSION_OUTPUT" | head -n 1)"
case "$VERSION_LINE" in
	4.7.2.stable*)
		;;
	*)
		echo "CHECK FAILED: Godot version is not 4.7.2.stable (found: ${VERSION_LINE})"
		exit 1
		;;
esac

# [step] import — a dedicated import pass before any scene loads (Pitfall 3).
IMPORT_LOG="${LOG_DIR}/import.log"
run_step "import" "$IMPORT_LIMIT" "$IMPORT_LOG" "$GODOT_BIN" --headless --editor --path "$ROOT" --quit
if grep -qE 'SCRIPT ERROR|Parse Error' "$IMPORT_LOG"; then
	fail "import" "error pattern found in import log" "$IMPORT_LOG"
fi

# [step] main scene — timed boot of the configured main scene.
MAIN_LOG="${LOG_DIR}/main_scene.log"
run_step "main scene" "$RUN_LIMIT" "$MAIN_LOG" "$GODOT_BIN" --headless --path "$ROOT" --quit-after 120
if ! grep -q 'Godot Engine v4.7.2.stable' "$MAIN_LOG"; then
	fail "main scene" "missing non-vacuity banner line" "$MAIN_LOG"
fi
if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$MAIN_LOG"; then
	fail "main scene" "error pattern found in main scene log" "$MAIN_LOG"
fi

# [step] verifier — load/instantiate every tracked script and scene.
VERIFY_LOG="${LOG_DIR}/verify.log"
run_step "verifier" "$VERIFY_LIMIT" "$VERIFY_LOG" "$GODOT_BIN" --headless --path "$ROOT" --script res://scripts/tools/verify_3d_project.gd
if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$VERIFY_LOG"; then
	fail "verifier" "error pattern found in verifier log" "$VERIFY_LOG"
fi
if ! grep -q '3D project verified:' "$VERIFY_LOG"; then
	fail "verifier" "missing success line" "$VERIFY_LOG"
fi

rm -rf "$LOG_DIR"
echo "Headless check passed."
exit 0
