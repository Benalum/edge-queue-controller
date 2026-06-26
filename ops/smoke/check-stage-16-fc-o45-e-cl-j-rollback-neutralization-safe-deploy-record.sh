#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-j-rollback-neutralization-safe-deploy-record.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Rollback, Neutralization, and Safe Backend Deploy Record"
check "feat: add authenticated companion study last message mvp"
check "fix: neutralize unsafe companion study last message branch"
check "ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5"
check "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2"
check "29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857"
check "stage16_fc_o45_e_cl_f_last_message_contract"
check "mode=deterministic_no_model"
check "model=backend-deterministic/no-model"
check "unsupported_companion_study_action"
check "Missing bearer token"
check "jobs_total=576"
check "results_total=83"
check "queued_companion=0"
check "cleanup_rows=440"
check "public_last_message_no_unauth_200=yes"
check "public_last_message_returns_400_unsupported=yes"
check "protected_status_route_requires_bearer_401=yes"
check "companion_chat_requires_bearer_401=yes"
check "companion_job_result_requires_bearer_401=yes"
check "edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled"
check "edge-queue-scheduler-one-shot.service active=inactive enabled=static"
check "edge-deterministic-companion-worker-once@999999.service active=inactive enabled=static"
check "source-only auth pinpoint"

echo "PASS stage-16-fc-o45-e-cl-j rollback neutralization safe deploy record smoke"
