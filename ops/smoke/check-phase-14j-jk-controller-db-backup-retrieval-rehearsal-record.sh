#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jk-controller-db-backup-retrieval-rehearsal-record.md"

echo "=== smoke: Phase 14J-JK controller DB retrieval rehearsal record ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_record" "$DOC"
grep -F "APPROVE_PHASE_14J_JK_REHEARSE_CONTROLLER_SQLITE_BACKUP_RETRIEVAL_NO_RESTORE_NO_AUTHORITY_CHANGE" "$DOC"
grep -F "edge_queue_controller_backup_20260618T162743Z_head-128babe.sqlite3" "$DOC"
grep -F "60627dfba7fbced05369068511dfabe6fc38cb7505a61ccf057bd7f01893ab53" "$DOC"
grep -F "Rehearsal SQLite integrity: ok" "$DOC"
grep -F "Rehearsal page count: 10669" "$DOC"
grep -F "Rehearsal schema object count: 57" "$DOC"
grep -F "Rehearsal table count: 39" "$DOC"
grep -F "Rehearsal index count: 18" "$DOC"
grep -F "DB row contents were not printed" "$DOC"
grep -F "live_db_identity_before: 51:542960:43708416:1781800223" "$DOC"
grep -F "live_db_identity_after: 51:542960:43708416:1781800223" "$DOC"
grep -F "no DB restore occurred" "$DOC"
grep -F "no DB import occurred" "$DOC"
grep -F "no controller authority move occurred" "$DOC"
grep -F "CT203 remains stopped" "$DOC"
grep -F "CT204 remains stopped" "$DOC"
grep -F "temporary local rehearsal copy was removed by trap cleanup" "$DOC"

echo "PASS: Phase 14J-JK retrieval rehearsal record doc validated"
