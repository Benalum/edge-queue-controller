#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-c-r12-g3-foreground-oneshot-job48-completion.md"

fail=0

[ -f "$DOC" ] || {
  echo "FAIL: missing doc $DOC"
  exit 1
}

required=(
  "R12_G3_RESULT=job48_completed_by_foreground_oneshot"
  "R12_H_RESULT=job48_completion_final_baseline_clean"
  "E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK"
  "job48 status=completed"
  "job48 attempts=4"
  "job48_result_rows=1"
  "response_exact_expected_marker=True"
  "a567b6299a152552cee2aae209616c8d708bd47cd1aa02b8bd93194503818382"
  "edge_queue.sqlite3.stage16-e3z-ej-c-r12-g3-pre-job48-oneshot.20260622T234404Z.bak"
  "89cbc105f62c4b2c613028b1770a51a322c0b6174bb5bc9b9e3c3180d51f9dc5"
  "edge-ct101-ollama-worker.service active=inactive enabled=disabled"
  "ai-platform-laptop-queue-worker.service active=inactive enabled=masked"
  "NO service start/stop/restart/reload/enable/disable"
  "NO timer activation"
  "NO scheduler activation"
  "NO job insert"
  "NO mutation to jobs 37-47"
)

for needle in "${required[@]}"; do
  if ! grep -Fq "$needle" "$DOC"; then
    echo "FAIL: missing required text: $needle"
    fail=1
  fi
done

if grep -Eq 'http://(10|100|192\.168)\.[0-9]+\.[0-9]+\.[0-9]+|https://(10|100|192\.168)\.[0-9]+\.[0-9]+\.[0-9]+' "$DOC"; then
  echo "FAIL: raw private/Tailscale URL found"
  fail=1
fi

if grep -Eiq '(TOKEN|SECRET|PASSWORD|BEARER|AUTH)[[:space:]]*=[[:space:]]*[^<[:space:]]' "$DOC"; then
  echo "FAIL: possible secret assignment found"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "PASS: Stage 16 E3Z-EJ-C-R12-G3 completion doc smoke passed"
