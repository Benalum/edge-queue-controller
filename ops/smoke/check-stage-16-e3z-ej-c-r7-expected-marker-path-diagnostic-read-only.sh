#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-c-r7-expected-marker-path-diagnostic-read-only.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Expected Marker Path Diagnostic"
  "REFUSE_EXPECTED_MARKER_NOT_FOUND"
  "read-only for live state"
  "no CT203 DB mutation"
  "no model call"
  "no job claim"
  "no worker start"
  "DB marker-path summary"
  "Worker/profile marker lookup summary"
  "structured field such as expected_marker"
  "If job 48 is now running again"
  "should not blindly retry"
  "EJ-C-R8"
  "E3Z_EJ_C_R7_EXPECTED_MARKER_PATH_DIAGNOSTIC_READ_ONLY_OK=1"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EJ_C_R7_SMOKE_OK=1"
