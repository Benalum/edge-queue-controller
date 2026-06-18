#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jj-controller-db-restore-rehearsal-plan-no-apply.md"

echo "=== smoke: Phase 14J-JJ restore rehearsal plan, no apply ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "Commit 25459ff" "$DOC"
grep -F "edge_queue_controller_backup_20260618T162743Z_head-128babe.sqlite3" "$DOC"
grep -F "60627dfba7fbced05369068511dfabe6fc38cb7505a61ccf057bd7f01893ab53" "$DOC"
grep -F "This phase does not restore, import, copy, migrate, or change controller authority" "$DOC"
grep -F "overwrite edge_queue.sqlite3" "$DOC"
grep -F "change controller authority" "$DOC"
grep -F "print DB row contents or secrets" "$DOC"
grep -F "APPROVE_PHASE_14J_JK_REHEARSE_CONTROLLER_SQLITE_BACKUP_RETRIEVAL_NO_RESTORE_NO_AUTHORITY_CHANGE" "$DOC"

echo "PASS: Phase 14J-JJ no-apply restore rehearsal plan validated"
