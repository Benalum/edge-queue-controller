#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hy-ct202-candidate-rebuild-no-apply-decision-review"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

require_present() {
  local needle="$1"
  echo "CHECK: $needle"
  grep -Fq "$needle" "$DOC"
  echo "PASS: $needle"
}

require_absent() {
  local needle="$1"
  echo "CHECK_ABSENT: $needle"
  if grep -Fq "$needle" "$DOC"; then
    echo "FAIL: unexpected text present: $needle"
    exit 1
  fi
  echo "PASS_ABSENT: $needle"
}

for needle in \
  'Phase 14J-HY - CT202 candidate rebuild no-apply decision review' \
  'Previous checkpoint: Phase 14J-HX at commit `f2e6882`' \
  'This phase is docs/smoke only.' \
  'This phase does not define the real candidate rebuild approval phrase.' \
  'This phase does not create an apply script.' \
  'PASS_FOR_NEXT_NO_APPLY_DECISION_REVIEW_ONLY' \
  'CONTINUE_NO_APPLY_PLANNING_UNTIL_SOURCE_REFRESH_OR_EXPLICIT_REAL_MUTATION_BOUNDARY' \
  'This does not approve restore.' \
  'This does not approve rebuild.' \
  'This does not approve schema apply.' \
  'laptop controller remains live authority' \
  'laptop-local `edge_queue.sqlite3` remains live DB authority' \
  'CT202 remains private candidate only' \
  'CT202 service remains disabled/inactive' \
  'CT202 onboot remains `0`' \
  'CT202 cutover readiness gate remains CLOSED' \
  'CT202 candidate mutation gate remains CLOSED' \
  'CT202 restore gate remains CLOSED' \
  'CT202 schema apply gate remains CLOSED' \
  'data authority selection gate remains CLOSED' \
  '43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314' \
  'dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491' \
  '3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6' \
  'target table count:' \
  '`39`' \
  '`credit_ledger`' \
  '`user_credit_wallets`' \
  '`workers`' \
  '`credit_reservations`' \
  'Real mutation boundary not yet opened' \
  'Source refresh and new-chat handoff through Phase 14J-HY' \
  'Do not run migration/import/copy/dump from this phase.'
do
  require_present "$needle"
done

for needle in \
  'APPROVE_CUTOVER_APPLY' \
  'APPROVE_DATA_MIGRATION' \
  'APPROVE_RUNTIME_APPLY' \
  'APPROVE_ROUTE_APPLY' \
  'APPROVE_CLOUDFLARE_APPLY' \
  'APPROVE_SECRET_APPLY' \
  'APPROVE_REBUILD_APPLY' \
  'APPROVE_SCHEMA_APPLY' \
  'APPROVE_RESTORE_APPLY' \
  'systemctl enable edge-queue-controller.service' \
  'pct set 202 -onboot 1' \
  'cloudflare tunnel route' \
  'cloudflared tunnel route' \
  'ollama serve' \
  'sqlite3 edge_queue.sqlite3 .dump'
do
  require_absent "$needle"
done

echo "PASS: ${PHASE}"
