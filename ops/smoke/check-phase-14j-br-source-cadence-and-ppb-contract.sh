#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BR reusable smoke: Source cadence and PPB contract ==="
echo "MUTATION_SCOPE=read_only_policy_contract"
echo "NO runtime activation"

BQ_DOC="docs/phase-14j-bq-parallel-safe-workstream-plan-and-static-surface-inventory.md"

test -f "$BQ_DOC"

echo
echo "=== BQ cadence and batching markers ==="
for marker in \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source" \
  "SAFE_BATCH_MODE=enabled_for_green_and_guarded_source_phases" \
  "PARALLELIZE_SAFE_GREEN_WORK" \
  "SERIALIZE_RUNTIME_CHANGES" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$BQ_DOC" >/dev/null
  echo "PASS: BQ marker present: $marker"
done

echo
echo "=== PPB policy markers in docs/source text ==="
ppb_marker_hits="$(grep -RIn --exclude-dir=.git --exclude='*.sqlite3' --exclude='*.db' -E 'PPB_RUN|Project Pilot Bridge|delete-only|hard_block|destructive repository|repository deletion|branch deletion' docs ops 2>/dev/null | wc -l | tr -d ' ')"
printf 'ppb_policy_marker_hits=%s\n' "$ppb_marker_hits"

if [ "$ppb_marker_hits" -le 0 ]; then
  echo "FAIL: PPB policy markers not found in docs/ops"
  exit 1
fi

echo
echo "=== PPB destructive action reminder ==="
echo "PPB must not be used for remote branch deletion, force local branch deletion, repository deletion, API deletion calls, metadata-directory removal, or repository-directory removal."

echo
echo "PASS: Source cadence and PPB policy contract smoke passed"
