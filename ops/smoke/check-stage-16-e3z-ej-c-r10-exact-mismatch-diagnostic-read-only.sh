#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-c-r10-exact-mismatch-diagnostic-read-only.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Exact Mismatch Diagnostic"
  "REFUSE_WORKER_EXACT_MARKER_MISMATCH"
  "read-only for live state"
  "no CT203 DB mutation"
  "no model call"
  "no job claim"
  "no worker start"
  "DB and prompt diagnostic summary"
  "CT101 runtime and worker diagnostic summary"
  "marker extractor is now working"
  "remaining failure is output compliance"
  "not another same-prompt retry"
  "known-good legacy wording"
  "E3Z_EJ_C_R10_EXACT_MISMATCH_DIAGNOSTIC_READ_ONLY_OK=1"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EJ_C_R10_SMOKE_OK=1"
