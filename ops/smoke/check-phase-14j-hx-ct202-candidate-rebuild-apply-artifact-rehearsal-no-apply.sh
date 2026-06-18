#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hx-ct202-candidate-rebuild-apply-artifact-rehearsal-no-apply"
DOC="docs/${PHASE}.md"
HW_SCRIPT="ops/rebuild/phase-14j-hw-ct202-candidate-rebuild-apply-artifact-no-apply.sh"
HT_SCRIPT="ops/rehearsal/phase-14j-ht-ct202-private-rehearsal-artifact-no-restore-no-rebuild-no-apply.sh"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"
test -x "$HW_SCRIPT"
test -x "$HT_SCRIPT"

require_present() {
  local file="$1"
  local needle="$2"
  echo "CHECK: $needle"
  grep -Fq "$needle" "$file"
  echo "PASS: $needle"
}

require_absent() {
  local file="$1"
  local needle="$2"
  echo "CHECK_ABSENT: $needle"
  if grep -Fq "$needle" "$file"; then
    echo "FAIL: unexpected text present in $file: $needle"
    exit 1
  fi
  echo "PASS_ABSENT: $needle"
}

for needle in \
  'Phase 14J-HX - CT202 candidate rebuild apply artifact rehearsal, no apply' \
  'Previous checkpoint: Phase 14J-HW at commit `93c38fb`' \
  'This phase does not define the real candidate rebuild approval phrase.' \
  'This phase does not execute restore, rebuild, schema apply, data import, service activation, route mutation, or cutover.' \
  'It does not mutate CT202.' \
  'It does not open SQLite with `sqlite3`.' \
  'It does not dump SQL.' \
  'It does not print row content.' \
  'HW no-apply artifact exists and runs safely' \
  'HT private rehearsal artifact exists and runs safely' \
  'CT202 remains private candidate only' \
  'CT202 service remains disabled/inactive' \
  'CT202 onboot remains `0`' \
  'no checked listener on `7070`, `8787`, or `8765`' \
  'CT202 cutover readiness gate remains CLOSED' \
  'CT202 candidate mutation gate remains CLOSED' \
  'PASS_FOR_NEXT_NO_APPLY_DECISION_REVIEW_ONLY' \
  'This does not approve restore.' \
  'This does not approve rebuild.' \
  'This does not approve schema apply.' \
  'This does not approve data migration or import.' \
  'Phase 14J-HY - CT202 candidate rebuild no-apply decision review'
do
  require_present "$DOC" "$needle"
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
  require_absent "$DOC" "$needle"
done

echo
echo "=== run HW no-apply artifact ==="
APC_HW_APPROVAL="APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY" \
APC_EXPECTED_HEAD="$(git rev-parse --short HEAD)" \
APC_ALLOW_DIRTY="1" \
bash "$HW_SCRIPT" | tee /tmp/apc-hx-hw-output.txt

grep -Fq 'PASS: no-apply candidate rebuild artifact ran safely' /tmp/apc-hx-hw-output.txt
grep -Fq 'PASS: future candidate rebuild boundary summarized' /tmp/apc-hx-hw-output.txt
grep -Fq 'PASS: preservation design summarized' /tmp/apc-hx-hw-output.txt
grep -Fq 'PASS: no restore/rebuild/schema apply performed' /tmp/apc-hx-hw-output.txt
grep -Fq 'PASS: no route/cutover mutation' /tmp/apc-hx-hw-output.txt

echo
echo "=== run HT private rehearsal artifact ==="
APC_HT_APPROVAL="APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY" \
APC_EXPECTED_HEAD="$(git rev-parse --short HEAD)" \
APC_ALLOW_DIRTY="1" \
APC_HT_REMOTE_READONLY="1" \
bash "$HT_SCRIPT" | tee /tmp/apc-hx-ht-output.txt

grep -Fq 'PASS: private rehearsal artifact ran safely' /tmp/apc-hx-ht-output.txt
grep -Fq 'PASS: HP no-apply artifact ran' /tmp/apc-hx-ht-output.txt
grep -Fq 'PASS: HR no-restore artifact ran' /tmp/apc-hx-ht-output.txt
grep -Fq 'PASS: CT202 read-only posture checks passed' /tmp/apc-hx-ht-output.txt
grep -Fq 'PASS: HM/HN backup artifact checks passed' /tmp/apc-hx-ht-output.txt
grep -Fq 'PASS: no restore/rebuild/schema apply performed' /tmp/apc-hx-ht-output.txt
grep -Fq 'PASS: no route/cutover mutation' /tmp/apc-hx-ht-output.txt

echo "PASS: ${PHASE}"
