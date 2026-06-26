#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ck-u-read-only-cleanup-status-taxonomy.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Read-Only Cleanup Status Taxonomy and Mutation Plan"
check "16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f"
check "CK_U_DRY_RUN_MODE=read_only"
check "CK_U_DRY_RUN_COUNT=440"
check "CK_U_DRY_RUN_MIN_ID=24"
check "CK_U_DRY_RUN_MAX_ID=570"
check "CK_U_DRY_RUN_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2"
check "CK_U_DRY_RUN_MUTATED=False"
check "CK_U_CANDIDATE_COUNT=440"
check "CK_U_CANDIDATE_MIN_ID=24"
check "CK_U_CANDIDATE_MAX_ID=570"
check "CK_U_CANDIDATE_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2"
check "CK_U_NON_CANDIDATE_QUEUED_COMPANION_COUNT=0"
check "CK_U_DB_INTEGRITY=ok"
check "status=queued count=465"
check "status=completed count=78"
check "status=forwarded count=18"
check "status=running count=10"
check "status=failed count=4"
check "job_type=companion.chat status=queued count=440"
check "job_type=companion.chat status=completed count=17"
check "job_type=companion.chat status=failed count=2"
check "CK_U_RECOMMENDED_CLEANUP_STATUS=failed"
check "CK_U_RECOMMENDATION_REASON=existing_non_executable_status_present"
check "CK_U_PROPOSED_MUTATION_NOT_EXECUTED=yes"
check "CK_U_PROPOSED_MUTATION_BACKUP_REQUIRED=yes"
check "CK_U_PROPOSED_MUTATION_EXPECTED_COUNT=440"
check "CK_U_PROPOSED_MUTATION_EXPECTED_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2"
check "CK_U_PROPOSED_MUTATION_SET_STATUS=failed"
check "CK_U_PROPOSED_MUTATION_SET_LAST_ERROR=stage16_ck_cleanup_old_mock_no_model_backlog"
check "Create a DB backup first"
check "Update only the exact candidates"
check "queued Companion count becomes zero"
check "no service, timer, worker, helper, model"

echo "PASS stage-16-fc-o45-e-ck-v cleanup status taxonomy record smoke"
