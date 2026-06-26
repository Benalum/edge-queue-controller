#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ck-y-post-cleanup-fresh-companion-selector-proof.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Post-Cleanup Fresh Companion Selector Proof"
check "APPROVE_CK_Y_INSERT_ONE_FRESH_COMPANION_JOB_AND_RUN_SELECTOR_ONCE"
check "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419"
check "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a"
check "481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595"
check "1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41"
check "16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f"
check "REFUSE_EXPECTED_COUNT_MISMATCH expected=440 actual=0"
check "CK_Y_PRE_DB_INTEGRITY=ok"
check "CK_Y_PRE_JOBS_TOTAL=575"
check "CK_Y_PRE_RESULTS_TOTAL=82"
check "CK_Y_PRE_QUEUED_COMPANION=0"
check "CK_Y_JOB_ID=581"
check "job_type=companion.chat"
check "requested_model=qwen2.5:0.5b"
check "marker=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK"
check "created_at=2026-06-26T05:25:23.145463Z"
check "CK_Y_SELECTOR_PREFLIGHT_MATCH_COUNT=1"
check "id=581 status=queued attempts=0"
check "edge-deterministic-companion-worker-once@581.service"
check "service_result=success"
check "service_exec_main_status=0"
check "CK_Y_FINAL_STATUS=completed"
check "CK_Y_FINAL_ATTEMPTS=1"
check "CK_Y_FINAL_RESULT_ROWS=1"
check "CK_Y_FINAL_RESULT_MODEL=backend-deterministic/no-model"
check "CK_Y_FINAL_RESPONSE_TEXT=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK"
check "CK_Y_FINAL_RESULT_ERROR=None"
check "CK_Y_FINAL_JOBS_TOTAL=576"
check "CK_Y_FINAL_RESULTS_TOTAL=83"
check "CK_Y_FINAL_QUEUED_COMPANION=0"
check "edge-queue-scheduler-one-shot.timer=inactive"
check "edge-queue-scheduler-one-shot.service=inactive"
check "edge-deterministic-companion-worker-once@999999.service=inactive"
check "No persistent worker, scheduler, model, PVESO, or Ollama path ran"
check "clean post-backlog baseline"

echo "PASS stage-16-fc-o45-e-ck-z post-cleanup selector proof record smoke"
