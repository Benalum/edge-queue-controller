#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jm-ct204-bind-mount-preapply-inspection-record.md"

echo "=== smoke: Phase 14J-JM CT204 bind-mount pre-apply inspection record ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_record" "$DOC"
grep -F "Commit 66f5b82" "$DOC"
grep -F "PASS_PHASE_14J_JM_CT204_BIND_MOUNT_PREAPPLY_INSPECTION_READ_ONLY" "$DOC"
grep -F "Expected votes: 1" "$DOC"
grep -F "temporary PVEW single-node working state" "$DOC"
grep -F "/srv/apc-private-data" "$DOC"
grep -F "/dev/mapper/apc_private_data" "$DOC"
grep -F "/srv/apc-private-data/ct204" "$DOC"
grep -F "CT204: stopped" "$DOC"
grep -F "unprivileged: 1" "$DOC"
grep -F "existing mp entries: none" "$DOC"
grep -F "mp0: /srv/apc-private-data/ct204,mp=/mnt/apc-private-data,ro=1" "$DOC"
grep -F "VM200 config does not reference private data path" "$DOC"
grep -F "no crypttab/fstab persistence for private mount" "$DOC"
grep -F "APPROVE_PHASE_14J_JN_APPLY_CT204_READONLY_BIND_MOUNT_TO_PVEW_ENCRYPTED_STORAGE_NO_START" "$DOC"
grep -F "start CT204" "$DOC"
grep -F "move controller authority" "$DOC"

echo "PASS: Phase 14J-JM pre-apply inspection record doc validated"
