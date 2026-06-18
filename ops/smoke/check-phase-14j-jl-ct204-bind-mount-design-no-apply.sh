#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jl-ct204-bind-mount-design-no-apply.md"

echo "=== smoke: Phase 14J-JL CT204 bind-mount design, no apply ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "Commit 6feaf18" "$DOC"
grep -F "/srv/apc-private-data/ct204" "$DOC"
grep -F "/mnt/apc-private-data" "$DOC"
grep -F "read-only preferred for first rehearsal" "$DOC"
grep -F "CT204 remains stopped" "$DOC"
grep -F "VM200 remains public/static only" "$DOC"
grep -F "APPROVE_PHASE_14J_JM_APPLY_CT204_READONLY_BIND_MOUNT_TO_PVEW_ENCRYPTED_STORAGE_NO_START" "$DOC"
grep -F "start CT204" "$DOC"
grep -F "change controller authority" "$DOC"
grep -F "quorum state prevents safe Proxmox config mutation" "$DOC"

echo "PASS: Phase 14J-JL no-apply CT204 bind-mount design validated"
