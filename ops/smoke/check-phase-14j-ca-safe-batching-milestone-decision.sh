#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CA smoke: safe batching milestone decision ==="

DOC="docs/phase-14j-ca-safe-batching-milestone-decision.md"

test -f "$DOC"

for marker in \
  "PHASE_14J_CA_SAFE_BATCHING_MILESTONE_DECISION" \
  "MUTATION_SCOPE=docs_smoke_only_post_patch_verification" \
  "MILESTONE_STATUS=first_bounded_static_ui_patch_completed" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "SOURCE_REFRESH_DECISION=defer_continue_same_chat" \
  "TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source" \
  "NEXT_BATCHING_DECISION=continue_safe_static_batches" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_OLLAMA_CALLS=forbidden" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "LANE_WORKER_ENABLEMENT=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "ROUTER_MODEL_SELECTION_ACTIVATION=not_performed" \
  "WARMUP_EXECUTION_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: milestone marker found: $marker"
done

echo "PASS: safe batching milestone decision smoke passed"
