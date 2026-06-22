#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-eh-read-only-postflight-idle-guard-after-limited-persistent-proof.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Read-Only Postflight Idle Guard"
  "job 47 completed attempts=1 result_rows=1 response=E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK"
  "E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1"
  "jobs_total: 46"
  "job_results_total: 27"
  "jobs_status_running: 0"
  "jobs_max_id: 47"
  "installed edge-ct101-ollama-worker.service inactive and disabled"
  "no active transient worker units"
  "no edge/queue/worker/scheduler timers active"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set"
  "only ollama container running"
  "qwen25 profile includes stage16_e3z_limited_persistent_worker_one_job_proof"
  "qwen3 profile excludes stage16_e3z_limited_persistent_worker_one_job_proof"
  "REFUSE_WORKER_DISABLED"
  "E3Z_EH_READ_ONLY_POSTFLIGHT_IDLE_GUARD_OK=1"
  "Run one more limited persistent proof job with the same controls"
  "Do not enable the installed persistent service yet"
  "Do not activate scheduler/timer yet"
  "Do not run jobs 37 through 47 again"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EH_SMOKE_OK=1"
