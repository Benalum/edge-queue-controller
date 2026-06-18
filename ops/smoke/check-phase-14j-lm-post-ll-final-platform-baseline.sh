#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-lm-post-ll-final-platform-baseline.md"

test -f "$DOC"
python3 -m py_compile edge_controller.py

grep -Fq "STAGE_14J_LJ_CURRENT_PVEW_STATUS_MODEL_V1" edge_controller.py
grep -Fq '"schema_version": 2' edge_controller.py

grep -Fq "overall_state: online" "$DOC"
grep -Fq "nodes: ct-203,pvew,vm-200,ct-204" "$DOC"
grep -Fq "normalized.schema_version: 2" "$DOC"
grep -Fq "private_storage_status" "$DOC"
grep -Fq "manual-unlock-only" "$DOC"
grep -Fq "ct204.expected_state: stopped" "$DOC"
grep -Fq "ct204.data_authority: false" "$DOC"
grep -Fq "CT203 DB integrity:" "$DOC"
grep -Fq "ok" "$DOC"
grep -Fq "VM200: running" "$DOC"
grep -Fq "CT203: running" "$DOC"
grep -Fq "CT204: stopped" "$DOC"
grep -Fq "No live infra mutation." "$DOC"
grep -Fq "No service restart/reload." "$DOC"
grep -Fq "No storage mutation." "$DOC"

echo "PASS check-phase-14j-lm-post-ll-final-platform-baseline"
