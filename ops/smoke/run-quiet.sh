#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${EDGE_SMOKE_LOG_DIR:-/tmp/edge-smoke-logs}"
mkdir -p "$LOG_DIR"

if [ "$#" -lt 2 ]; then
  echo "usage: ops/smoke/run-quiet.sh <label> <command> [args...]"
  exit 2
fi

label="$1"
shift

safe_label="$(echo "$label" | tr -c 'A-Za-z0-9_.-' '_' | sed 's/_$//')"
log="${LOG_DIR}/${safe_label}.log"

start_epoch="$(date +%s)"

if "$@" >"$log" 2>&1; then
  end_epoch="$(date +%s)"
  elapsed="$((end_epoch - start_epoch))"
  echo "PASS: ${label} (${elapsed}s) log=${log}"
else
  status="$?"
  end_epoch="$(date +%s)"
  elapsed="$((end_epoch - start_epoch))"

  echo "FAIL: ${label} (${elapsed}s, exit=${status}) log=${log}"
  echo "--- failure summary for ${label} ---"
  grep -nE '(^FAIL:|AssertionError|Traceback|Error:|error:|FAILED|Exception|No such file|permission denied|command not found|syntax error)' "$log" \
    | tail -80 || true
  echo "--- tail for ${label} ---"
  tail -120 "$log" || true

  exit "$status"
fi
