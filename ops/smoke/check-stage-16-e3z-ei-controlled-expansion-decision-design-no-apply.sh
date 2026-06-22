#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ei-controlled-expansion-decision-design-no-apply.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Controlled Expansion Decision"
  "repository-only no-apply decision/design checkpoint"
  "job 45 direct installed-worker one-shot"
  "job 46 service-managed transient systemd one-shot"
  "job 47 bounded limited-persistent transient service proof"
  "E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK"
  "quiet-window DB signature: stable"
  "dev-mqueue.mount"
  "diagnostic noise"
  "edge_timers=<none>"
  "EJ — repeat limited persistent one-job proof with a fresh qwen25 job"
  "E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK"
  "stage16_e3z_limited_persistent_worker_repeat_proof"
  "Option B — add repeat-specific qwen25 job type"
  "Recommended"
  "qwen3 limited-persistent proof"
  "Not recommended yet"
  "scheduler/timer activation"
  "Not recommended yet"
  "EDGE_ALLOWED_JOB_IDS=<exact single fresh job id>"
  "EDGE_EXIT_AFTER_ONE_SUCCESS=1"
  "EDGE_MAX_RUNTIME_SECONDS=180"
  "no mutation of jobs 37 through 47"
  "APPROVE_STAGE_16_E3Z_EJ_A_ADD_REPEAT_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START"
  "After EJ-A through EJ-D succeed"
  "EDGE_MAX_COMPLETIONS=2"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EI_SMOKE_OK=1"
