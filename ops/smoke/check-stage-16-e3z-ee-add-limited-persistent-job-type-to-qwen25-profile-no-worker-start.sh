#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ee-add-limited-persistent-job-type-to-qwen25-profile-no-worker-start.md"
PROFILE="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }
[ -f "$PROFILE" ] || { echo "MISSING_PROFILE=$PROFILE"; exit 1; }
[ -f "$WORKER" ] || { echo "MISSING_WORKER=$WORKER"; exit 1; }

python3 "$WORKER" --self-test --profile-file "$PROFILE" >/tmp/e3z-ee-repo-self-test.out
grep -Fq "E3Z_EC_WORKER_GUARD_SELF_TEST_OK=1" /tmp/e3z-ee-repo-self-test.out || { echo "MISSING_EC_SELF_TEST_MARKER=1"; exit 1; }
grep -Fq "E3Z_CS_WORKER_SELF_TEST_OK=1" /tmp/e3z-ee-repo-self-test.out || { echo "MISSING_CS_SELF_TEST_MARKER=1"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_EE_ADD_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START"
  "stage16_e3z_limited_persistent_worker_one_job_proof"
  "qwen2.5:0.5b"
  "E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK"
  "qwen25_router_small includes"
  "qwen3_router_small does not include"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "REFUSE_WORKER_DISABLED"
  "jobs_total: 45"
  "job_results_total: 26"
  "jobs_status_running: 0"
  "jobs_max_id: 46"
  "APPROVE_STAGE_16_E3Z_EF_INSERT_ONE_FRESH_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY"
  "Do not call models in EE"
  "Do not mutate CT203 DB in EE"
  "Do not enable persistent worker behavior in EE"
  "Do not enable model concurrency"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

grep -Fq "stage16_e3z_limited_persistent_worker_one_job_proof" "$PROFILE" || { echo "MISSING_PROFILE_LIMITED_JOB_TYPE=1"; exit 1; }

echo "E3Z_EE_SMOKE_OK=1"
