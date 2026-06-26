#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ck-p-read-only-eligible-companion-backlog-classification.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Read-Only Eligible Companion Backlog Classification"
check "81030f3544dde5dc7437318bbd857591d0c3b6518c8fe6a3dd923df1a000286d"
check "CK_P_DB_INTEGRITY=ok"
check "CK_P_JOBS_TOTAL=575"
check "CK_P_RESULTS_TOTAL=82"
check "CK_P_QUEUED_TOTAL=465"
check "CK_P_COMPANION_TOTAL=459"
check "CK_P_ELIGIBLE_COMPANION_TOTAL=440"
check "CK_P_MODEL_COUNT requested_model=mock/no-model count=440"
check "CK_P_DAY_COUNT day=2026-06-20 count=1 min_id=24 max_id=24"
check "CK_P_DAY_COUNT day=2026-06-24 count=1 min_id=130 max_id=130"
check "CK_P_DAY_COUNT day=2026-06-25 count=438 min_id=133 max_id=570"
check "CK_P_PROMPT_BUCKET bucket=say_hello_one_sentence count=437"
check "CK_P_PROMPT_BUCKET bucket=other_prompt count=2"
check "CK_P_PROMPT_BUCKET bucket=stage15e_mock_validation count=1"
check "id=24"
check "id=130"
check "id=133"
check "id=568"
check "id=569"
check "id=570"
check "CK_P_BACKLOG_CLASSIFICATION_DONE=yes"
check "CK_P_READ_ONLY_CLASSIFICATION_COMPLETE=yes"
check "old mock/no-model test traffic"
check "guarded cleanup or exclusion policy"
check "no DB write"
check "no job mutation"
check "no result insert"
check "no selector/manual-wrapper/helper invocation"
check "no model/helper/Ollama call"

echo "PASS stage-16-fc-o45-e-ck-q backlog classification record smoke"
