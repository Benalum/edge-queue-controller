#!/usr/bin/env bash
set -euo pipefail

SRC="edge_controller.py"
DOC="docs/stage-16-e3z-bo-disabled-ct203-native-sqlite-claim-complete-fail-no-runtime.md"

need_src=(
  "stage-16-e3z-bo"
  "claim_job_ids are required"
  "_E3Z_BL_RETIRED_PROOF_JOB_IDS = {29, 30, 31, 32, 33, 34}"
  "BEGIN IMMEDIATE"
  "UPDATE jobs SET status = 'running', attempts = attempts + 1"
  "INSERT INTO job_results"
  "UPDATE jobs SET status = 'completed'"
  "UPDATE jobs SET status = 'failed', last_error = ?"
  "edge_worker_job_claim"
  "edge_worker_job_complete"
  "edge_worker_job_fail"
)

need_doc=(
  "Implemented the CT203-native SQLite worker API"
  "It does not require worker registry tables"
  "requires exact claim_job_ids"
  "uses BEGIN IMMEDIATE"
  "This stage does not start CT101 worker service, Docker, Ollama, scheduler, or timer"
)

for needle in "${need_src[@]}"; do
  grep -Fq "$needle" "$SRC" || { echo "MISSING_SRC=$needle"; exit 1; }
done

for needle in "${need_doc[@]}"; do
  grep -Fq "$needle" "$DOC" || { echo "MISSING_DOC=$needle"; exit 1; }
done

python3 -m py_compile "$SRC"

echo "E3Z_BO_R2_SMOKE_OK=1"
