#!/usr/bin/env bash
# run_headless_check.sh
# One local/CI project check (D-09): guards, version pin, import, boots the
# main scene, runs the --script verifier, and runs behaviour probes, failing
# on any script/parse error even though Godot's own process exit code does
# not reflect one.
# Usage: GODOT=/path/to/Godot bash scripts/tools/run_headless_check.sh
# Env: GODOT (engine binary path), HEADLESS_CHECK_MAX_LIMIT_SECONDS (a
# positive integer that can only lower the watchdog limits below, never
# raise them, D-03).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DEFAULT_IMPORT_LIMIT=180
DEFAULT_RUN_LIMIT=60
DEFAULT_VERIFY_LIMIT=60
DEFAULT_PROBE_LIMIT=120

LOG_DIR="$(mktemp -d)"

fail() {
	local step="$1"
	local reason="$2"
	local logfile="${3:-}"
	echo "CHECK FAILED: ${step}: ${reason}"
	if [ -n "$logfile" ] && [ -f "$logfile" ]; then
		if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$logfile"; then
			:
		fi
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
			if kill -TERM "$pid" 2>/dev/null; then
				:
			fi
			sleep 5
			if kill -KILL "$pid" 2>/dev/null; then
				:
			fi
			if wait "$pid" 2>/dev/null; then
				:
			fi
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

# resolve_godot: the GODOT env var, when explicitly set, is authoritative —
# an invalid GODOT value fails hard rather than silently falling back to a
# different engine (T-01-11 spoofing/tampering). Only an UNSET GODOT falls
# through to `command -v godot`, then the hardcoded default path.
resolve_godot() {
	if [ -n "${GODOT:-}" ]; then
		if [ -x "${GODOT}" ]; then
			printf '%s\n' "${GODOT}"
			return 0
		fi
		return 1
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

# --- static guards (run before any engine invocation, D-01/D-07) ---

if CS_HIT=$(find "$ROOT" \( -path "$ROOT/.git" -o -path "$ROOT/.godot" \) -prune -o -type f \( -name '*.cs' -o -name '*.csproj' -o -name '*.sln' \) -print 2>/dev/null | sort | head -n 1) && [ -n "$CS_HIT" ]; then
	echo "CHECK FAILED: C# file found (D-01): ${CS_HIT}"
	exit 1
fi

if RAW_KEY_HIT=$(find "$ROOT/scenes" "$ROOT/scripts" -type d -path "$ROOT/scripts/tools" -prune -o -type f -name '*.gd' -print 2>/dev/null | sort | xargs grep -HnE 'is_(physical_)?key(_label)?_pressed' 2>/dev/null | head -n 1) && [ -n "$RAW_KEY_HIT" ]; then
	HIT_FILE="${RAW_KEY_HIT%%:*}"
	HIT_REST="${RAW_KEY_HIT#*:}"
	HIT_LINE="${HIT_REST%%:*}"
	echo "CHECK FAILED: raw key polling found (D-07); use InputMap actions: ${HIT_FILE}:${HIT_LINE}"
	exit 1
fi

# --- limit cap (D-03): can only lower the default watchdog limits ---

if [ -n "${HEADLESS_CHECK_MAX_LIMIT_SECONDS:-}" ]; then
	case "${HEADLESS_CHECK_MAX_LIMIT_SECONDS}" in
	'' | *[!0-9]*)
		echo "CHECK FAILED: invalid HEADLESS_CHECK_MAX_LIMIT_SECONDS"
		exit 2
		;;
	esac
	if [ "${HEADLESS_CHECK_MAX_LIMIT_SECONDS}" -eq 0 ]; then
		echo "CHECK FAILED: invalid HEADLESS_CHECK_MAX_LIMIT_SECONDS"
		exit 2
	fi
	MAX_LIMIT="${HEADLESS_CHECK_MAX_LIMIT_SECONDS}"
	IMPORT_LIMIT=$((DEFAULT_IMPORT_LIMIT < MAX_LIMIT ? DEFAULT_IMPORT_LIMIT : MAX_LIMIT))
	RUN_LIMIT=$((DEFAULT_RUN_LIMIT < MAX_LIMIT ? DEFAULT_RUN_LIMIT : MAX_LIMIT))
	VERIFY_LIMIT=$((DEFAULT_VERIFY_LIMIT < MAX_LIMIT ? DEFAULT_VERIFY_LIMIT : MAX_LIMIT))
	PROBE_LIMIT=$((DEFAULT_PROBE_LIMIT < MAX_LIMIT ? DEFAULT_PROBE_LIMIT : MAX_LIMIT))
else
	IMPORT_LIMIT=$DEFAULT_IMPORT_LIMIT
	RUN_LIMIT=$DEFAULT_RUN_LIMIT
	VERIFY_LIMIT=$DEFAULT_VERIFY_LIMIT
	PROBE_LIMIT=$DEFAULT_PROBE_LIMIT
fi

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

# [step] probes — every scripts/tools/probe_*.gd, in sorted order. A probe
# glob that matches nothing (deleted, renamed, moved, or a naming-convention
# drift) must fail loudly rather than let the check report success with zero
# behaviour verified — mirrors the non-vacuity guard in
# verify_3d_project.gd::_check_resources() for its .gd/.tscn lists.
PROBE_FILES="$(find "$ROOT/scripts/tools" -maxdepth 1 -type f -name 'probe_*.gd' 2>/dev/null | sort)"
if [ -z "$PROBE_FILES" ]; then
	echo "CHECK FAILED: no behaviour probes found under scripts/tools/probe_*.gd."
	exit 1
fi
while IFS= read -r PROBE_PATH; do
	PROBE_NAME="$(basename "$PROBE_PATH")"
	PROBE_LOG="${LOG_DIR}/probe_${PROBE_NAME%.gd}.log"
	run_step "probe ${PROBE_NAME}" "$PROBE_LIMIT" "$PROBE_LOG" "$GODOT_BIN" --headless --fixed-fps 60 --path "$ROOT" --script "res://scripts/tools/${PROBE_NAME}"
	if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$PROBE_LOG"; then
		fail "probe ${PROBE_NAME}" "error pattern found in probe log" "$PROBE_LOG"
	fi
done <<<"$PROBE_FILES"

rm -rf "$LOG_DIR"
echo "Headless check passed."
exit 0
