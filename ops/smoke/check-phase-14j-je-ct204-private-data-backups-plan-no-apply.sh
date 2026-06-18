#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-je-ct204-private-data-backups-plan-no-apply.md"

echo "=== smoke: Phase 14J-JE CT204 private data/backups plan, no apply ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "Commit 3935f45" "$DOC"
grep -F "/srv/apc-private-data" "$DOC"
grep -F "/root/apc-private-storage-unlock-mount.sh" "$DOC"
grep -F "/srv/apc-private-data/ct204/backups" "$DOC"
grep -F "/srv/apc-private-data/ct204/staging" "$DOC"
grep -F "/srv/apc-private-data/ct204/manifests" "$DOC"
grep -F "/srv/apc-private-data/ct204/exports" "$DOC"
grep -F "CT204 remains stopped and non-authoritative" "$DOC"
grep -F "APPROVE_PHASE_14J_JF_CREATE_CT204_PRIVATE_DATA_BACKUP_DIRECTORIES_ONLY" "$DOC"
grep -F "Do not use VM200 for private data" "$DOC"
grep -F "Do not use local-lvm as the private data target" "$DOC"
grep -F "Do not treat CT204 as authoritative" "$DOC"

echo "PASS: Phase 14J-JE no-apply CT204 private data/backups plan validated"
