#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-c-r3-stuck-running-job48-repair-decision-no-apply.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Stuck-Running Job 48 Repair Decision"
  "REFUSE_WORKER_EXACT_MARKER_MISMATCH"
  "job_48=status:running;attempts:1"
  "result_rows=0"
  "marker_present:1"
  "read-only for live state"
  "stale running claim"
  "No worker, transient, scheduler, or timer remained active"
  "reset only job 48 from stale running back to queued"
  "target job: 48 only"
  "repair action: set status=queued"
  "post repair expected: job 48 queued attempts=1 result_rows=0"
  "Do not blindly rerun the same command"
  "APPROVE_STAGE_16_E3Z_EJ_C_R4_RESET_STALE_RUNNING_JOB_48_TO_QUEUED_ONLY"
  "Do not rerun job 48 in R4"
  "Do not call models in R4"
  "Do not mutate jobs 37 through 47"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EJ_C_R3_SMOKE_OK=1"
