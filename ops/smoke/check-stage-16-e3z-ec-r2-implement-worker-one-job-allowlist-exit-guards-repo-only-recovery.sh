#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ec-r2-implement-worker-one-job-allowlist-exit-guards-repo-only-recovery.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"
PROFILE="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }
[ -f "$WORKER" ] || { echo "MISSING_WORKER=$WORKER"; exit 1; }

python3 -m py_compile "$WORKER"
python3 "$WORKER" --self-test --profile-file "$PROFILE" | tee /tmp/e3z-ec-r2-self-test.out
grep -Fq "E3Z_EC_WORKER_GUARD_SELF_TEST_OK=1" /tmp/e3z-ec-r2-self-test.out || { echo "MISSING_SELF_TEST_MARKER=E3Z_EC_WORKER_GUARD_SELF_TEST_OK"; exit 1; }
grep -Fq "E3Z_CS_WORKER_SELF_TEST_OK=1" /tmp/e3z-ec-r2-self-test.out || { echo "MISSING_SELF_TEST_MARKER=E3Z_CS_WORKER_SELF_TEST_OK"; exit 1; }

needles=(
  "Implement Worker One-Job Allowlist"
  "Repo Only Recovery"
  "EC-R1 wrote the repo worker file"
  "REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED"
  "ops/workers/ct101_minimal_ollama_worker.py"
  "EDGE_ALLOWED_JOB_IDS"
  "EDGE_EXIT_AFTER_ONE_SUCCESS"
  "EDGE_MAX_RUNTIME_SECONDS"
  "EDGE_REFUSE_IF_SCHEDULER_ACTIVE"
  "EDGE_REFUSE_IF_TIMER_ACTIVE"
  "EDGE_PROOF_MODE=limited_persistent_one_job"
  "--once --job-id"
  "REFUSE_WORKER_DISABLED"
  "REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID"
  "REFUSE_WORKER_EXIT_AFTER_ONE_SUCCESS_REQUIRED"
  "REFUSE_WORKER_MAX_RUNTIME_SECONDS_EXCEEDED"
  "REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED"
  "REFUSE_WORKER_EXACT_MARKER_MISMATCH"
  "E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1"
  "E3Z_EC_WORKER_GUARD_SELF_TEST_OK=1"
  "APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START"
  "Do not install this worker on CT101 in EC-R2"
  "Do not call models in EC-R2"
  "Proceed with ED"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

grep -Fq "REFUSE_MAIN_LOOP_REQUIRES_LIMITED_PROOF_MODE" "$WORKER" || { echo "MISSING_WORKER_LOOP_GUARD=1"; exit 1; }
grep -Fq "REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED" "$WORKER" || { echo "MISSING_WORKER_EXACT_CLAIM_REFUSAL=1"; exit 1; }
grep -Fq "E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1" "$WORKER" || { echo "MISSING_WORKER_SUCCESS_MARKER=1"; exit 1; }

echo "E3Z_EC_R2_SMOKE_OK=1"
