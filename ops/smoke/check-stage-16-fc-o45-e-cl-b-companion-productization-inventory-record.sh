#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-a-r2-companion-productization-inventory.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Companion Productization Inventory"
check "d89f376"
check "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2"
check "7a72ae2d644f04dbcbf4c580722525fb32f19da8063ccc3c730077cf2908257ed6f2b3a136b0e317909df6d" || true
check "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419"
check "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a"
check "481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595"
check "1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41"
check "16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f"
check "edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled"
check "edge-queue-scheduler-one-shot.service active=inactive enabled=static"
check "edge-deterministic-companion-worker-once@999999.service active=inactive enabled=static"
check "/api/companion/chat"
check "/api/companion/study/action"
check "/api/companion/voice/status"
check "backend-deterministic/no-model"
check "CL_A_DB_INTEGRITY=ok"
check "CL_A_JOBS_TOTAL=576"
check "CL_A_RESULTS_TOTAL=83"
check "CL_A_QUEUED_COMPANION=0"
check "CL_A_QUEUED_ANY=25"
check "CL_A_RUNNING_ANY=10"
check "CL_A_CLEANUP_ROWS=440"
check "CL_A_CK_Y_JOB id=581 status=completed attempts=1 requested_model=qwen2.5:0.5b result_rows=1 result_model=backend-deterministic/no-model response_text=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK"
check "SyntaxError: unexpected character after line continuation character"
check "CL_A_R2_CLEANUP_TOOL_OK=True"
check "CL_A_R2_CLEANUP_TOOL_MODE=read_only"
check "CL_A_R2_CLEANUP_TOOL_CANDIDATE_COUNT=0"
check "CL_A_R2_CLEANUP_TOOL_ID_SHA256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
check "CL_A_R2_CLEANUP_TOOL_MUTATED=False"
check "CL_A_R2_DB_INTEGRITY=ok"
check "CL_A_R2_JOBS_TOTAL=576"
check "CL_A_R2_RESULTS_TOTAL=83"
check "CL_A_R2_QUEUED_COMPANION=0"
check "CL_A_R2_CLEANUP_ROWS=440"
check "CL_A_R2_DB_VALIDATION_DONE=yes"
check "HTTP 401"
check "Missing bearer token"
check "queued_companion=0"
check "cleanup_tool_candidate_count=0"
check "authenticated Companion/Study last-message MVP path"

echo "PASS stage-16-fc-o45-e-cl-b companion productization inventory record smoke"
