#!/usr/bin/env bash
set -Eeuo pipefail
DOC="docs/stage-16-e3z-z-ct101-llms-start-activation-plan-no-apply.md"
required_markers=(
  "E3Z_Z_DOC_MARKER_NO_APPLY=1"
  "E3Z_Z_DOC_MARKER_CT101_TARGET=1"
  "E3Z_Z_DOC_MARKER_APPROVAL_REQUIRED=1"
  "E3Z_Z_DOC_MARKER_NO_TIMER_ACTIVATION=1"
  "E3Z_Z_DOC_MARKER_NO_DB_WRITE=1"
  "E3Z_Z_DOC_MARKER_COMPANION_VERTICAL_SLICE_PREP=1"
)
for marker in "${required_markers[@]}"; do
  grep -F -- "$marker" "$DOC" >/dev/null || { echo "missing_required_marker=$marker"; exit 1; }
done
# Guard against accidentally presenting this as an apply script.
grep -F -- "pct start 101" "$DOC" >/dev/null || { echo "missing_future_start_command_reference"; exit 1; }
grep -F -- "No CT101 start without explicit CT start approval" "$DOC" >/dev/null || { echo "missing_explicit_ct_start_boundary"; exit 1; }
echo "E3Z_Z_SMOKE_OK=1"
