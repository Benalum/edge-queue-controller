#!/usr/bin/env bash
set -euo pipefail
DOC="docs/phase-14j-jg-controller-db-backup-to-encrypted-storage-plan-no-apply.md"

echo "=== smoke: Phase 14J-JG controller DB backup plan, no apply ==="
test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "Commit 9db2a78" "$DOC"
grep -F "Laptop-local edge_queue.sqlite3 remains live controller data authority" "$DOC"
grep -F "/srv/apc-private-data/ct204/backups/controller-laptop" "$DOC"
grep -F "APPROVE_PHASE_14J_JH_CREATE_CONTROLLER_SQLITE_BACKUP_ON_PVEW_ENCRYPTED_STORAGE_NO_AUTHORITY_CHANGE" "$DOC"
grep -F "no import and no authority change" "$DOC"
grep -F "CT203 remains stopped" "$DOC"
grep -F "CT204 remains stopped" "$DOC"
grep -F "VM200 remains public/static only" "$DOC"
grep -F "any secret or DB content would be printed" "$DOC"

echo "PASS: Phase 14J-JG no-apply controller DB backup plan validated"
