#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ck-l-read-only-reporter-install.md"

test -f "$DOC"

check() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check "Read-Only Eligible Companion Reporter Install"
check "/opt/edge-queue-controller/ops/workers/list-eligible-deterministic-companion-jobs.sh"
check "81030f3544dde5dc7437318bbd857591d0c3b6518c8fe6a3dd923df1a000286d"
check "stage-16-fc-o45-e-ck-l-install-reporter-20260626T045802Z"
check "1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2"
check "7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419"
check "265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a"
check "481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595"
check "1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41"
check "Template enabled state:"
check "static"
check "Example instance active state:"
check "inactive"
check "No persistent, general, or deterministic worker process was active"
check "job_type=companion.chat"
check "status=queued"
check "attempts=0"
check "result_rows=0"
check "opens SQLite in read-only mode"
check "does not insert jobs"
check "does not mutate jobs"
check "does not insert results"
check "does not start services"
check "does not call the selector wrapper"
check "does not call the manual wrapper"
check "does not call PVESO, Ollama, or any model endpoint"
check "Run the reporter once against the live DB in read-only mode"

echo "PASS stage-16-fc-o45-e-ck-m-r2 read-only reporter install record smoke"
