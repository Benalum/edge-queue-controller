#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jf-ct204-private-data-directories-record.md"

echo "=== smoke: Phase 14J-JF CT204 private data directories record ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_record" "$DOC"
grep -F "APPROVE_PHASE_14J_JF_CREATE_CT204_PRIVATE_DATA_BACKUP_DIRECTORIES_ONLY" "$DOC"
grep -F "/srv/apc-private-data/ct204/backups" "$DOC"
grep -F "/srv/apc-private-data/ct204/staging" "$DOC"
grep -F "/srv/apc-private-data/ct204/manifests" "$DOC"
grep -F "/srv/apc-private-data/ct204/exports" "$DOC"
grep -F "owner/group: root:root" "$DOC"
grep -F "permissions: 700" "$DOC"
grep -F "Marker permissions were set to 600" "$DOC"
grep -F "CT203 remains stopped" "$DOC"
grep -F "CT204 remains stopped" "$DOC"
grep -F "no CT bind mount was added" "$DOC"
grep -F "no DB dump, copy, import, migration, or controller authority move occurred" "$DOC"
grep -F "no pvesm add/set occurred" "$DOC"
grep -F "no keyfile was created" "$DOC"

echo "PASS: Phase 14J-JF directory record doc validated"
