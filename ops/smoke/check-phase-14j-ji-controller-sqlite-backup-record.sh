#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-ji-controller-sqlite-backup-record.md"

echo "=== smoke: Phase 14J-JI controller SQLite backup record ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_record" "$DOC"
grep -F "APPROVE_PHASE_14J_JH_CREATE_CONTROLLER_SQLITE_BACKUP_ON_PVEW_ENCRYPTED_STORAGE_NO_AUTHORITY_CHANGE" "$DOC"
grep -F "Source repo checkpoint: 128babe" "$DOC"
grep -F "/srv/apc-private-data/ct204/backups/controller-laptop" "$DOC"
grep -F "edge_queue_controller_backup_20260618T162743Z_head-128babe.sqlite3" "$DOC"
grep -F "edge_queue_controller_backup_20260618T162743Z_head-128babe.manifest.txt" "$DOC"
grep -F "Backup size bytes: 43700224" "$DOC"
grep -F "60627dfba7fbced05369068511dfabe6fc38cb7505a61ccf057bd7f01893ab53" "$DOC"
grep -F "Local SQLite integrity: ok" "$DOC"
grep -F "Remote SQLite integrity: ok" "$DOC"
grep -F "laptop-local edge_queue.sqlite3 remains live controller data authority" "$DOC"
grep -F "no DB import occurred" "$DOC"
grep -F "no controller authority move occurred" "$DOC"
grep -F "CT203 remains stopped" "$DOC"
grep -F "CT204 remains stopped" "$DOC"
grep -F "VM200 remains public/static only" "$DOC"

echo "PASS: Phase 14J-JI backup record doc validated"
