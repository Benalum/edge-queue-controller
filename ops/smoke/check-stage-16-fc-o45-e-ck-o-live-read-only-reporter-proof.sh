#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ck-n-r2-live-read-only-reporter-proof.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Corrected Live Read-Only Reporter Proof"
check "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2"
check "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419"
check "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a"
check "481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595"
check "1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41"
check "81030f3544dde5dc7437318bbd857591d0c3b6518c8fe6a3dd923df1a000286d"
check "CK_N_R2_DB_INTEGRITY=ok"
check "CK_N_R2_BEFORE_JOBS_TOTAL=575"
check "CK_N_R2_BEFORE_RESULTS_TOTAL=82"
check "CK_N_R2_BEFORE_ELIGIBLE_COMPANION_JOBS=440"
check "eligible_companion_jobs_read_only=yes"
check "eligible_companion_jobs_total=440"
check "eligible_companion_jobs_returned=25"
check "eligible_companion_jobs_report_done=yes"
check "CK_N_R2_JSON_OK=True"
check "CK_N_R2_JSON_DB_MODE=read_only"
check "CK_N_R2_JSON_TOTAL_ELIGIBLE=440"
check "CK_N_R2_JSON_RETURNED=25"
check "CK_N_R2_AFTER_JOBS_TOTAL=575"
check "CK_N_R2_AFTER_RESULTS_TOTAL=82"
check "CK_N_R2_AFTER_ELIGIBLE_COMPANION_JOBS=440"
check "CK_N_R2_DB_COUNTS_UNCHANGED=yes"
check "edge-queue-scheduler-one-shot.timer=inactive"
check "edge-queue-scheduler-one-shot.service=inactive"
check "edge-deterministic-companion-worker-once@999999.service=inactive"
check "opens SQLite in read-only mode"
check "no DB write"
check "no job mutation"
check "no result insert"
check "no service start"
check "no timer install"
check "no selector/manual-wrapper/helper invocation"
check "no model/helper/Ollama call"
check "440 eligible queued"

echo "PASS stage-16-fc-o45-e-ck-o live read-only reporter proof record smoke"
